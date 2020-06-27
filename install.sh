#!/usr/bin/env bash

echo 'Installation has started...'

web=0
application_full_path=$1

while [ "$1" != "" ]; do
    case $1 in
        -w | --web )           shift
                                web=1
                                ;;
    esac
    shift
done

if [ $web = 0 ]; then
  symfony_application="symfony/skeleton"
else
  symfony_application="symfony/website-skeleton"
fi

composer create-project $symfony_application $application_full_path

application_name=$(basename $application_full_path)

docker_compose_file="${application_full_path}/docker-compose.yml"

container_name="${application_name//-/_}"

cat > $docker_compose_file <<EOF
version: '3.5'
services:
    mysql_${container_name}:
        container_name: mysql_${container_name}
        image: mysql:latest
        restart: on-failure
        environment:
            MYSQL_DATABASE: ${container_name}
            MYSQL_USER: root
            MYSQL_PASSWORD: root
            MYSQL_ROOT_PASSWORD: root
        ports:
          - 3301:3306
        volumes:
          - ./docker/volumes/mysql/data:/var/lib/mysql
    php_${container_name}:
        container_name: php_${container_name}
        build: ./docker/build/php
        tty: true
        depends_on:
            - mysql_${container_name}
        volumes:
          - .:/var/www/${application_name}
    nginx_${container_name}:
        container_name: nginx_${container_name}
        image: nginx:latest
        restart: on-failure
        ports:
          - 8000:80
        volumes:
          - ./:/var/www/${application_name}
          - ./docker/build/nginx/default.conf:/etc/nginx/conf.d/default.conf
        depends_on:
          - php_${container_name}
          - mysql_${container_name}
EOF

docker_nginx_dir=${application_full_path}/docker/build/nginx/
docker_php_dir=${application_full_path}/docker/build/php/

mkdir ${application_full_path}/docker
mkdir ${application_full_path}/docker/build
mkdir $docker_nginx_dir
mkdir $docker_php_dir

docker_nginx_config="${docker_nginx_dir}/default.conf"
docker_php_file="${docker_php_dir}/Dockerfile"

cat > $docker_nginx_config <<EOF
server {
    listen 80;
    server_name nginx_${container_name};
    root /var/www/${application_name}/public;
    client_max_body_size 100M;

    location / {
        try_files \$uri /index.php\$is_args\$args;
    }

    location ~ ^/index\\.php(/|$) {
        # Connect to the Docker service using php
        fastcgi_pass php_${container_name}:9000;
        fastcgi_split_path_info ^(.+\\.php)(/.*)\$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        internal;
    }
    location ~ \.php$ {
        return 404;
    }

    error_log /var/log/nginx/error.log;
    access_log /var/log/nginx/access.log;
}
EOF

cat > $docker_php_file <<EOF
FROM php:fpm
RUN apt-get update && apt-get install -y --no-install-recommends \\
        libxml2-dev \\
        git \\
        vim \\
    && docker-php-ext-install \\
        pdo_mysql \\
        soap \\
        bcmath \\
        opcache

RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
RUN chmod +x /usr/local/bin/composer

RUN pecl install xdebug && docker-php-ext-enable xdebug
RUN echo 'xdebug.remote_port=9001' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_enable=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_autostart=1' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.remote_connect_back=0' >> /usr/local/etc/php/php.ini
RUN echo 'xdebug.idekey=PHPSTORM' >> /usr/local/etc/php/php.ini

WORKDIR /var/www/${application_name}/

EXPOSE 9001
EOF