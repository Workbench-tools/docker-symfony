# docker-symfony

Setup and run Symfony application with PHP, NginX and MySQL using docker.

---
### Prerequisites
This script was written primary for Ubuntu, for other OS this script may not work. 

For successful installation following programs should run on your machine: `docker`, `docker-compose`, `ip`, `ifconfig`, `composer`, `php`.

---

### Installation

In terminal run `wget https://raw.githubusercontent.com/Workbench-tools/installs/master/docker-symfony/install.sh` to download installation file.

Make downloaded file executable `sudo chmod +x install.sh`.

Install by running `./install.sh {/var/www/application-name}`.

This will install a microservice based application. If you want a website based application use `--web` option `./install.sh {/var/www/application-name} --web`. For more information use `--help` option.

CD into application folder `cd /var/www/application-name`.

Run `bin/init.sh` to build docker containers and run application. First time running this command it will take for a while. Also, important to note that docker will be running in the background. If want to stop it you have to cd in `/var/www/application-name` and run `docker-compose down`.

Before you run `bin/init.sh` command have a look at `/var/www/application-name/docker-compose.yaml` file. If for example mysql runs on your machine default port 3306 this command will fail because of port conflict.

Type in your browser `localhost:8000` to see if your application up and running.

---

### Other information

If you run command `./install.sh {/var/www/simple-application}`. All containers will be named by application name using underscores `{php|mysql|nginx}_simple_application`.

| MySQL |       |
| ----- | ----- |
| port  | 3306 |
| user  | root |
| password | root |
| database | simple_application |

| NginX |       |
| ----- | ----- |
| localhost  | 8000 |
