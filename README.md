# docker-symfony

Setup and run Symfony application with PHP, NginX and MySQL using docker.

---
### Prerequisites

Assume that docker and docker-compose runs on your machine.

---

### Installation

In terminal run `wget https://raw.githubusercontent.com/Workbench-tools/docker-symfony/master/install.sh` to download installation file.

Install by running `./install.sh {/var/www/application-name}`. If you will be asked for permissions run `sudo bash install.sh {/var/www/application-name}` instead.

This will install micro service based application. If you want website use `--web` option `./install.sh {/var/www/application-name} --web`. For more information use `--help` option.

CD into application folder `cd /var/www/application-name`.

Run `./init.sh` to build docker containers and run application. 
Before you run this command have a look at `/var/www/application-name/docker-compose.yaml` file. If for example mysql runs on your machine default port 3306 this command will fail because of port conflict.

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