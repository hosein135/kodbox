#!/bin/bash

txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgre=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
bldyel=${txtbld}$(tput setaf 11) #  yellow
txtrst=$(tput sgr0)             # Reset
info=${bldyel}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}

function echoblue () {
  echo "${bldblu}$1${txtrst}"
}
function echored () {
  echo "${bldred}$1${txtrst}"
}
function echogreen () {
  echo "${bldgre}$1${txtrst}"
}
function echoyellow () {
  echo "${bldyel}$1${txtrst}"
}

function sed_configuration() {
	orig=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 1 | head -n 1)
	origparm=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
		if [[ -z $origparm ]];then
			origparm=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 2 | head -n 1)
		fi
	dest=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 1 | head -n 1)
	destparm=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
		if [[ -z $destparm ]];then
			destparm=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 2 | head -n 1)
		fi
case ${dest} in
	\#${orig})
			sed -i "/^$dest.*$destparm/c\\${1}" $2
		;;
	\;${orig})
			sed -i "/^$dest.*$destparm/c\\${1}" $2
		;;
	${orig})
			if [[ $origparm != $destparm ]]; then
				sed -i "/^$orig/c\\${1}" $2
				else
					if [[ -z $(grep '[A-Z\_A-ZA-Z]$origparm' $2) ]]; then
						fullorigparm3=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
						fullorigparm4=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 4 | head -n 1)
						fullorigparm5=$(echo $1 | tr -s ' ' '|' | cut -d '|' -f 5 | head -n 1)
						fulldestparm3=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 3 | head -n 1)
						fulldestparm4=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 4 | head -n 1)
						fulldestparm5=$(grep -E "^(#|\;|)$orig" $2 | tr -s ' ' '|' | cut -d '|' -f 5 | head -n 1)
						sed -i "/^$dest.*$fulldestparm3\ $fulldestparm4\ $fulldestparm5/c\\$orig\ \=\ $fullorigparm3\ $fullorigparm4\ $fullorigparm5" $2
					fi
			fi
		;;
		*)
			echo ${1} >> $2
		;;
	esac
}

clear
echoyellow "INSTALLING UNZIP AND UNRAR"
sleep 2
sudo apt update
sudo apt --force-yes --yes install unzip unrar

clear
echoyellow "INSTALLING GIT"
sleep 2
sudo apt update
sudo apt --force-yes --yes install git

clear
echoyellow "INSTALLING CURL"
sleep 2
sudo apt update
sudo apt --force-yes --yes install curl

clear
echoyellow "INSTALANDO MYSQL"
sleep 2
sudo apt update
sudo apt --force-yes --yes install mysql-server mysql-client

clear
echoyellow "CONFIGURANDO MYSQL"
sleep 2
mysql -u root -e "CREATE USER 'kodbox'@'localhost' IDENTIFIED BY 'kodbox';"
mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'kodbox'@'localhost' WITH GRANT OPTION;"
mysql -u root -e "CREATE DATABASE kodbox;"
mysql -u root -e "FLUSH PRIVILEGES"

clear
echoyellow "INSTALLING PHP AND APACHE"
sleep 2
sudo apt update
sudo sudo apt --force-yes --yes install apache2 php libapache2-mod-php php-{mongodb,odbc,sqlite3,curl,gd,imagick,intl,apcu,memcache,imap,pgsql,mysql,ldap,tidy,xmlrpc,pspell,mbstring,xml,gd,intl,zip,bz2}

clear
echoyellow "CLONING SOURCES FROM THE KODBOX REPOSITORY"
sleep 2
cd /var/www
DIR=0;
while [[ ${DIR} == 0 ]]; do
  rm -rf kodbox
  git clone https://github.com/kalcaddle/kodbox.git kodbox
  if [[ -d kodbox ]]; then
    DIR=1;
  else
    DIR=0;
  fi
done

sudo sed -i "s|'Asia/Shanghai'|'Asia/Tehran'|g" /var/www/kodbox/config/config.php
sudo sed -i "s|define('BASIC_PATH'.*|define('BASIC_PATH','/var/www/kodbox/');|g" /var/www/kodbox/config/config.php

clear
echoyellow "CONFIGURING APACHE"
sleep 2
cat << APADEF > /etc/apache2/sites-available/kodbox.conf
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html

    Alias /kodbox /var/www/kodbox

    <Directory /var/www/html>
        Options -Indexes +FollowSymLinks +ExecCGI +Includes
        AllowOverride All
        Require all granted
    </Directory>

    <Directory /var/www/kodbox>
        Options -Indexes +FollowSymLinks +ExecCGI +Includes
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>

APADEF

PHPPATH=/etc/php/$(ls /etc/php | tail -n 1)/apache2/php.ini
sed_configuration "short_open_tag = On" "$PHPPATH"
sed_configuration 'date.timezone = "Asia/Tehran"' "$PHPPATH"

sudo a2enmod rewrite
sudo a2dissite 000-default
sudo chown www-data -R /var/www
sudo chmod 775 -R /var/www
sudo a2ensite kodbox

clear
echoyellow "SERVICES RESTARTED"
sleep 2
sudo /etc/init.d/apache2 restart
sleep 10

clear
echogreen "INSTALLATION COMPLETED, KODBOX INSTALLED, ACCESS THROUGH YOUR WEB BROWSER AT http://$(ip addr show | grep 'inet ' | grep brd | tr -s ' ' '|' | cut -d '|' -f 3 | cut -d '/' -f 1 | head -n 1)/kodbox A MYSQL BASE HAS ALREADY BEEN CREATED NAME:kodbox USER:kodbox PASSWORD:kodbox"
exit 0
