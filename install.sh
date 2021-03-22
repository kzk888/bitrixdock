#!/bin/bash
set -e

RELEASE_FILE=/etc/os-release
OS=$(egrep '^(NAME)=' $RELEASE_FILE | tr -d '"' | tr -d 'NAME' | tr -d '=')
WORK_PATH=/var/www
MYSQL_AUTH_FILE=/var/www/mysql_auth

# choosing ACTION
echo -e "\e[33mSelect action: \nI - add new website;\nR - remove website;\nS - generate SSL letsencrypt for website;\nF - create FTP account to website;\e[39m"
read ACTION
until [[ $PHP_VERSION != "I" || $PHP_VERSION != "R" ]]
do
    echo -e "\e[33mSelect action: \nI - add new website;\nR - remove website;\nS - generate SSL letsencrypt for website;\nF - create FTP account to website;\e[39m"
    read ACTION
done

if [[ $ACTION == "I" ]]
then
  #checking OS
  echo -e "\e[33mChecking OS \e[39m"
  if [[ $OS != "Ubuntu" ]]
  then
          echo -e "\e[31m    OS must be Ubuntu 18.04 \e[39m" EXIT
  else
          echo -e "\e[32m    OS is Ubuntu \e[39m"
  fi

  #checking is git installed
  echo -e "\e[33mChecking GIT \e[39m"
  if hash git > /dev/null 2>&1
  then
          echo -e "\e[32m    GIT installed \e[39m"
  else
          echo -e "\e[31m    GIT not installed, install started \e[39m" && apt-get install -y git
  fi

  #checking is docker installed
  echo -e "\e[33mChecking DOCKER \e[39m"
  if hash docker > /dev/null 2>&1
  then
          echo -e "\e[32m    DOCKER installed \e[39m"
  else
          echo -e "\e[31m    DOCKER not installed, install started \e[39m" && cd /usr/local/src && wget -qO- https://get.docker.com/ | sh
  fi

  #checking is installed docker-compose
  echo -e "\e[33mChecking DOCKER-COMPOSE \e[39m"
  if hash docker-compose > /dev/null 2>&1
  then
          echo -e "\e[32m    DOCKER-COMPOSE installed \e[39m"
  else
          echo -e "\e[31m    DOCKER-COMPOSE not installed, install started \e[39m" && curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && source ~/.bashrc
  fi

  #show message that all required packets installed
  echo -e "\n\e[32mAll required packets installed \e[39m\n\n"

  # downloading docker from git source
  DOCKER_FOLDER_PATH=$WORK_PATH/bitrixdock
  if [ ! -d "$DOCKER_FOLDER_PATH" ]
  then
    echo -e "\e[33mDocker containers is not installed. Installation starting... \e[39m\n"

    cd $WORK_PATH && \
    git clone https://github.com/kzk888/bitrixdock.git && \
    cd /var/ && chmod -R 775 www/ && chown -R root:www-data www/ && \
    cd $DOCKER_FOLDER_PATH

    echo -e "\n\e[33mCopy environment setting file and starting configuration \e[39m"
    cp -f .env_template .env && \
    echo -e "\e[32mDone \e[39m\n"

    # chosing PHP version
    echo -e "\e[33mSelect PHP version [5.6, 7.1, 7.4]: \e[39m"
    read PHP_VERSION
    until [[ $PHP_VERSION != "5.6" || $PHP_VERSION != "7.1" || $PHP_VERSION != "7.4" ]]
    do
        echo -e "\e[33mSelect PHP version [5.6, 7.1, 7.4]: \e[39m"
        read PHP_VERSION
    done
    SELECTED_PHP_VERSION=php71
    if [[ $PHP_VERSION == "5.6" ]]; then
      SELECTED_PHP_VERSION=php56
    elif [[ $PHP_VERSION == "7.4" ]]; then
      SELECTED_PHP_VERSION=php74
    fi
    sed -i "s/#PHP_VERSION#/$SELECTED_PHP_VERSION/g" $DOCKER_FOLDER_PATH/.env

    # chosing MYSQL version
    echo -e "\e[33mSelect MYSQL version [5.7, 8.0]: \e[39m"
    read MYSQL_VERSION
    until [[ $MYSQL_VERSION != "5.7" || $MYSQL_VERSION != "8.0" ]]
    do
        echo -e "\e[33mSelect MYSQL version [5.7, 8.0]: \e[39m"
        read MYSQL_VERSION
    done
    SELECTED_MYSQL_VERSION=mysql57
    if [[ $MYSQL_VERSION == "8.0" ]]; then
      SELECTED_MYSQL_VERSION=php80
    fi
    sed -i "s/#DB_SERVER_TYPE#/$SELECTED_MYSQL_VERSION/g" $DOCKER_FOLDER_PATH/.env

    # set database root password
    echo -e "\e[33mSet MYSQL database ROOT PASSWORD: \e[39m"
    read MYSQL_DATABASE_ROOT_PASSWORD
    until [[ ! -z "$MYSQL_DATABASE_ROOT_PASSWORD" ]]
    do
        echo -e "\e[33mSet MYSQL database ROOT PASSWORD: \e[39m"
      read MYSQL_DATABASE_ROOT_PASSWORD
    done
    sed -i "s/#DATABASE_ROOT_PASSWORD#/$MYSQL_DATABASE_ROOT_PASSWORD/g" $DOCKER_FOLDER_PATH/.env
    echo -e "[client]\nuser=root\npassword="$MYSQL_DATABASE_ROOT_PASSWORD > $MYSQL_AUTH_FILE

    echo -e "\n\e[32mStarting DOCKER containers \e[39m\n"
    docker-compose up -d

    sleep 10

    docker exec -it darbit_docker_webserver /bin/bash -c "apt-get update -y" > /dev/null 2>&1 && \
    docker exec -it darbit_docker_webserver /bin/bash -c "apt install python-certbot-nginx -y" > /dev/null 2>&1

    echo -e "\n\e[32mcertbot installed on nginx container \e[39m\n"
  else
    cd $DOCKER_FOLDER_PATH
    echo -e "\n\e[32mStarting DOCKER containers \e[39m\n"
    docker-compose up -d

    sleep 10

    docker exec -it darbit_docker_webserver /bin/bash -c "apt-get update -y" > /dev/null 2>&1 && \
    docker exec -it darbit_docker_webserver /bin/bash -c "apt install python-certbot-nginx -y" > /dev/null 2>&1

    echo -e "\n\e[32mcertbot installed on nginx container \e[39m\n"
  fi

  #checking site name domain
  echo -e "\n\n\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
  read SITE_NAME
  domainRegex="(^([a-zA-Z0-9](([a-zA-Z0-9-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{0,10}$)"
  until [[ $SITE_NAME =~ $domainRegex ]]
  do
      echo -e "\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
      read SITE_NAME
  done

  #checking site installation type
  echo -e "\e[33mSite installation type? (C - clear install bitrixsetup.php / R - restore from backup): \e[39m"
  read INSTALLATION_TYPE
  until [[ $INSTALLATION_TYPE == [CR] ]]
  do
      echo -e "\e[33mSite installation type? (C - clear install bitrixsetup.php / R - restore from backup): \e[39m"
      read INSTALLATION_TYPE
  done

  #checking is site directory exist
  WORK_PATH_WEBSITE=$WORK_PATH"/bitrix/"
  if [ ! -d "$WORK_PATH_WEBSITE" ]
  then
    mkdir -p $WORK_PATH/bitrix/
  fi
  WEBSITE_FILES_PATH=$WORK_PATH/bitrix/$SITE_NAME
  if [ ! -d "$WEBSITE_FILES_PATH" ]
  then
    echo -e "\e[33mCreating website folder \e[39m"
    mkdir -p $WEBSITE_FILES_PATH && \
    cd $WEBSITE_FILES_PATH && \
    if [[ $INSTALLATION_TYPE == "C" ]]; then wget http://www.1c-bitrix.ru/download/scripts/bitrixsetup.php; elif [[ $INSTALLATION_TYPE == "R" ]]; then wget http://www.1c-bitrix.ru/download/scripts/restore.php; fi && \
    cd /var/ && chmod -R 775 www/ && chown -R root:www-data www/

    echo -e "\n\e[33mConfiguring NGINX conf file \e[39m"
    cp -f $DOCKER_FOLDER_PATH/nginx/conf/default.conf_template $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf && \
    sed -i "s/#SITE_NAME#/$SITE_NAME/g" $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf && \
    sed -i "s|#SITE_PATH#|$WEBSITE_FILES_PATH|g" $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf && \
    echo -e "\e[32mDone \e[39m\n"

    cd $DOCKER_FOLDER_PATH && \
    docker-compose stop web_server && \
    docker-compose rm -f web_server && \
    docker-compose build web_server && \
    docker-compose up -d

    echo -e "\n\e[33mConfiguring MySQL database \e[39m"

    PROJECT_CLEARED_NAME=${SITE_NAME%*.*} && echo $output | tr '.' '_' | tr '-' '_'
    DATABASE_NAME=$PROJECT_CLEARED_NAME"_db"
    DATABASE_USER=$PROJECT_CLEARED_NAME"_user"
    DATABASE_PASSWORD=$(openssl rand -base64 32)
    sleep 5
    mysql --defaults-extra-file=$MYSQL_AUTH_FILE -P 3306 --protocol=tcp -e "CREATE DATABASE $DATABASE_NAME; CREATE USER '$DATABASE_USER'@'%' IDENTIFIED BY '$DATABASE_PASSWORD'; GRANT ALL PRIVILEGES ON $DATABASE_NAME.* TO '$DATABASE_USER'@'%'; FLUSH PRIVILEGES;"

    echo -e "\e[33mDatabase server: db \e[39m"
    echo -e "\e[33mDatabase name: "$DATABASE_NAME" \e[39m"
    echo -e "\e[33mDatabase user: "$DATABASE_USER" \e[39m"
    echo -e "\e[33mDatabase password: "$DATABASE_PASSWORD" \e[39m"
  else
    echo -e "\e[31m    By path $WEBSITE_FILES_PATH website exist. Please remove folder and restart installation script. \e[39m"
  fi
elif [[ $ACTION == "S" ]]
then
  #checking site name domain
  echo -e "\n\n\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
  read SITE_NAME
  domainRegex="(^([a-zA-Z0-9](([a-zA-Z0-9-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{0,10}$)"
  until [[ $SITE_NAME =~ $domainRegex ]]
  do
      echo -e "\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
      read SITE_NAME
  done

  WEBSITE_FILES_PATH=$WORK_PATH/bitrix/$SITE_NAME
  #checking is site directory exist
  if [ ! -d "$WEBSITE_FILES_PATH" ]
  then
    echo -e "\e[31m    By path $WEBSITE_FILES_PATH website not exist. Please, restart script and enter correct website name [example: mail.ru]. \e[39m"
  else
    #checking site installation type
    echo -e "\e[33mDo you want install SSL from letsencrypt? (Y/N): \e[39m"
    read SSL_INSTALL_ACTION
    until [[ $SSL_INSTALL_ACTION != "Y" || $SSL_INSTALL_ACTION != "N" ]]
    do
        echo -e "\e[33mDo you want install SSL from letsencrypt? (Y/N): \e[39m"
        read SSL_INSTALL_ACTION
    done

    if [[ $SSL_INSTALL_ACTION == "Y" ]]
    then
        echo -e "\e[33mPrepare to sending request to generate certificate for domains - $SITE_NAME, www.$SITE_NAME (Attention! Be sure that domain www.$SITE_NAME is correctly setup in domain control panel with A or CNAME dns record) \e[39m"
        echo -e "\e[33mIs domains settings correct setup in domain control panel? (Y/N): \e[39m"
        read IS_CORRECT_DOMAIN
        until [[ $IS_CORRECT_DOMAIN != "Y" || $IS_CORRECT_DOMAIN != "N" ]]
        do
            echo -e "\e[33mIs domains settings correct setup in domain control panel? (Y/N): \e[39m"
            read IS_CORRECT_DOMAIN
        done

        if [[ $SSL_INSTALL_ACTION == "Y" ]]
        then
            docker exec -it darbit_docker_webserver /bin/bash -c "apt-get update -y"  > /dev/null 2>&1 && \
            docker exec -it darbit_docker_webserver /bin/bash -c "apt install python-certbot-nginx -y"  > /dev/null 2>&1 && \
            docker exec -it darbit_docker_webserver /bin/bash -c "certbot --nginx -d $SITE_NAME -d www.$SITE_NAME"

            DOCKER_FOLDER_PATH=$WORK_PATH/bitrixdock
            mv $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf.old && \
            docker cp darbit_docker_webserver:/etc/nginx/conf.d/$SITE_NAME.conf $DOCKER_FOLDER_PATH/nginx/conf/conf.d/ && \
            docker cp darbit_docker_webserver:/etc/letsencrypt/ /var/www/bitrixdock/nginx/letsencrypt/
        fi
    fi
  fi
elif [[ $ACTION == "R" ]]
then
  #checking site name domain
  echo -e "\n\n\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
  read SITE_NAME

  domainRegex="(^([a-zA-Z0-9](([a-zA-Z0-9-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{0,10}$)"

  until [[ $SITE_NAME =~ $domainRegex ]]
  do
      echo -e "\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
      read SITE_NAME
  done

  WEBSITE_FILES_PATH=$WORK_PATH/bitrix/$SITE_NAME
  #checking is site directory exist
  if [ ! -d "$WEBSITE_FILES_PATH" ]
  then
    echo -e "\e[31m    By path $WEBSITE_FILES_PATH website not exist. Please, restart script and enter correct website name [example: mail.ru]. \e[39m"
  else
    rm -rf $WEBSITE_FILES_PATH
    echo -e "\e[32mWebsite folder removed \e[39m\n"

    DOCKER_FOLDER_PATH=$WORK_PATH/bitrixdock
    rm -rf $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf

    cd $DOCKER_FOLDER_PATH && \
    docker-compose stop web_server && \
    docker-compose rm -f web_server && \
    docker-compose build web_server && \
    docker-compose up -d

    echo -e "\e[32mWebsite nginx conf removed \e[39m\n"

    PROJECT_CLEARED_NAME=${SITE_NAME%*.*} && echo $output | tr '.' '_' | tr '-' '_'
    DATABASE_NAME=$PROJECT_CLEARED_NAME"_db"
    DATABASE_USER=$PROJECT_CLEARED_NAME"_user"

    mysql --defaults-extra-file=$MYSQL_AUTH_FILE -P 3306 --protocol=tcp -e "DROP DATABASE $DATABASE_NAME; DROP USER '$DATABASE_USER'@'%';"

    echo -e "\e[32mWebsite database and user removed \e[39m\n"
  fi
fi