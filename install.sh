#!/bin/bash
set -e

RELEASE_FILE=/etc/os-release
OS=$(egrep '^(NAME)=' $RELEASE_FILE | tr -d '"' | tr -d 'NAME' | tr -d '=')
WORK_PATH=/var/www

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

#checking site name domain
echo -e "\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
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
WEBSITE_FILES_PATH=$WORK_PATH"/"$SITE_NAME
if [ ! -d "$WEBSITE_FILES_PATH" ]
then
	echo -e "\e[33mStopping all docker instances \e[39m"
	docker stop $(docker ps -a -q) > /dev/null 2>&1 || true
	echo -e "\e[32mDone \e[39m\n"

	echo -e "\e[33mCreating website folder and downloading docker-compose sources \e[39m"
	WEBSITE_DOCKER_FOLDER_PATH=$WEBSITE_FILES_PATH/$SITE_NAME"_dock"

	mkdir -p $WEBSITE_FILES_PATH && \
	mkdir -p $WEBSITE_FILES_PATH/bitrix && \
	cd $WEBSITE_FILES_PATH/bitrix && \
	if [[ $INSTALLATION_TYPE == "C" ]]; then wget http://www.1c-bitrix.ru/download/scripts/bitrixsetup.php; elif [[ $INSTALLATION_TYPE == "R" ]]; then wget http://www.1c-bitrix.ru/download/scripts/restore.php; fi && \
	cd $WEBSITE_FILES_PATH && \
	git clone https://github.com/kzk888/bitrixdock.git && \
	mv $WEBSITE_FILES_PATH/bitrixdock $WEBSITE_DOCKER_FOLDER_PATH && \
	cd /var/ && chmod -R 775 www/ && chown -R root:www-data www/ && \
	cd $WEBSITE_DOCKER_FOLDER_PATH

	echo -e "\n\e[33mCopying environment setting file and launch autoconfiguration \e[39m"
	cp -f .env_template .env && \
	sed -i "s/#SITE_NAME#/$SITE_NAME/g" $WEBSITE_DOCKER_FOLDER_PATH/.env && \
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
	sed -i "s/#PHP_VERSION#/$SELECTED_PHP_VERSION/g" $WEBSITE_DOCKER_FOLDER_PATH/.env

	# set database name
	echo -e "\e[33mSet MYSQL database name: \e[39m"
	read MYSQL_DATABASE_NAME
	until [[ ! -z "$MYSQL_DATABASE_NAME" ]]
	do
	    echo -e "\e[33mSet MYSQL database name: \e[39m"
		read MYSQL_DATABASE_NAME
	done
	sed -i "s/#DATABASE_NAME#/$MYSQL_DATABASE_NAME/g" $WEBSITE_DOCKER_FOLDER_PATH/.env

	# set database user
	echo -e "\e[33mSet MYSQL database user: \e[39m"
	read MYSQL_DATABASE_USER
	until [[ ! -z "$MYSQL_DATABASE_USER" ]]
	do
	    echo -e "\e[33mSet MYSQL database user: \e[39m"
		read MYSQL_DATABASE_USER
	done
	sed -i "s/#DATABASE_USER#/$MYSQL_DATABASE_USER/g" $WEBSITE_DOCKER_FOLDER_PATH/.env

	# set database user password
	echo -e "\e[33mSet MYSQL database user PASSWORD: \e[39m"
	read MYSQL_DATABASE_USER_PASSWORD
	until [[ ! -z "$MYSQL_DATABASE_USER_PASSWORD" ]]
	do
	    echo -e "\e[33mSet MYSQL database user PASSWORD: \e[39m"
		read MYSQL_DATABASE_USER_PASSWORD
	done
	sed -i "s/#DATABASE_USER_PASSWORD#/$MYSQL_DATABASE_USER_PASSWORD/g" $WEBSITE_DOCKER_FOLDER_PATH/.env

	# set database root password
	echo -e "\e[33mSet MYSQL database ROOT PASSWORD: \e[39m"
	read MYSQL_DATABASE_ROOT_PASSWORD
	until [[ ! -z "$MYSQL_DATABASE_ROOT_PASSWORD" ]]
	do
	    echo -e "\e[33mSet MYSQL database ROOT PASSWORD: \e[39m"
		read MYSQL_DATABASE_ROOT_PASSWORD
	done
	sed -i "s/#DATABASE_ROOT_PASSWORD#/$MYSQL_DATABASE_ROOT_PASSWORD/g" $WEBSITE_DOCKER_FOLDER_PATH/.env
	sed -i "s|#WEBSITE_PATH#|$WEBSITE_FILES_PATH/bitrix|g" $WEBSITE_DOCKER_FOLDER_PATH/.env

	echo -e "\n\e[33mConfiguring NGINX conf file \e[39m"
	sed -i "s/#SITE_NAME#/$SITE_NAME/g" $WEBSITE_DOCKER_FOLDER_PATH/nginx/conf/default.conf && \
	sed -i "s|#SITE_PATH#|$WEBSITE_FILES_PATH/bitrix|g" $WEBSITE_DOCKER_FOLDER_PATH/nginx/conf/default.conf && \
	echo -e "\e[32mDone \e[39m\n"

	# echo -e "\n\e[33mConfiguring SUBNET \e[39m"
	# SUBNET_MASK=$(printf "10.%d.%d" "$((RANDOM % 256))" "$((RANDOM % 256))") && \
	# sed -i "s/#SUBNET_MASK#/$SUBNET_MASK/g" $WEBSITE_DOCKER_FOLDER_PATH/.env && \
	# echo -e "\e[32mDone \e[39m\n"


	echo -e "\e[32mRun DOCKER \e[39m"
	docker-compose up -d
else
	echo -e "\e[31m    By path $WEBSITE_FILES_PATH website exist. Please remove folder and restart installation script. \e[39m"
fi