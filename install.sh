#!/usr/bin/env bash

help_option()
{
  echo
  echo '**********************************************'
  echo '* Symfony installation and setup with docker *'
  echo '**********************************************'
  echo
  echo 'Usage: ./install.sh path [OPTION]'
  echo 'Installs Symfony application and setup docker with PHP, NginX and MySQL.'
  echo
  echo 'Optional parameters:'
  echo "-w, --web       Installs full web application. 'symfony/website-skeleton'."
  echo "                If this option is not provided 'symfony/skeleton' are used."
  echo '-h, --help      Information.'
  echo

  exit 0;
}

if [[ $# -eq 0 ]] ; then
    echo 'Please provide application name'
    exit 1
fi

web=0
application_full_path=$1

while [ "$1" != "" ]; do
    case $1 in
        -w | --web ) shift
            web=1
            ;;
        -h | --help )
            help_option
            ;;
    esac
    shift
done

if [ $web = 0 ]; then
  symfony_application="symfony/skeleton"
else
  symfony_application="symfony/website-skeleton"
fi

echo 'Installation has started...'

composer create-project $symfony_application $application_full_path
cd $application_full_path
composer require --dev symfony/phpunit-bridge
php bin/phpunit

application_name=$(basename $application_full_path)
container_name="${application_name//-/_}"
docker_compose_file="${application_full_path}/docker-compose.yml"
docker_nginx_dir=${application_full_path}/docker/build/nginx/
docker_php_dir=${application_full_path}/docker/build/php/
init_file=${application_full_path}/bin/init.sh

mkdir ${application_full_path}/docker
mkdir ${application_full_path}/docker/build
mkdir $docker_nginx_dir
mkdir $docker_php_dir

docker_nginx_config="${docker_nginx_dir}/default.conf"
docker_php_file="${docker_php_dir}/Dockerfile"

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
          - 3306:3306
        volumes:
          - ./docker/volumes/mysql/data:/var/lib/mysql
    php_${container_name}:
        container_name: php_${container_name}
        build: ./docker/build/php
        tty: true
        environment:
          PHP_IDE_CONFIG: serverName=nginx_${container_name}
          XDEBUG_CONFIG: remote_host=\${HOST_IP}
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
RUN echo 'xdebug.idekey=PHPSTORM' >> /usr/local/etc/php/php.ini

WORKDIR /var/www/${application_name}/

EXPOSE 9001
EOF

cp $application_full_path/.env $application_full_path/.env.dist
cat > $init_file <<EOF
#!/usr/bin/env bash

rm -rf .env

export eth_interface=$(ip token | grep -v lo | grep -v br- | grep -v veth | grep -v docker | grep -v wlan | grep -v wlp | awk '{print $4}')
export host_ip=$(ifconfig $eth_interface | grep inet | grep -v inet6 | awk '{print $2}')

echo 'HOST_IP='$host_ip >> .env
echo '' >> .env

echo 'Host ip' $host_ip 'added to .env file.'

cat .env.dist >> .env
echo '.env.dist content added to .env file.'

docker-compose down || true
docker-compose build
docker-compose up -d
EOF

cat > $application_full_path/gitignore <<EOF
/.idea
/docker/volumes/

EOF

cat .gitignore >> gitignore
cp gitignore .gitignore
rm gitignore

chmod +x $init_file
