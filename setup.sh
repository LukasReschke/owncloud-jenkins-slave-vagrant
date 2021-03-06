#!/bin/bash
#
# ownCloud
#
# @author Thomas Müller
# @copyright 2014 Thomas Müller thomas.mueller@tmit.eu
#

set -e

killall java || true

# read config
if [ -f ./jenkins.config ]; then
  source ./jenkins.config
  set
  if [ -z "$SLAVE_NAME" ]; then
    echo "Configuration parameter <SLAVE_NAME> is missing."
    exit
  fi
  if [ -z "$SLAVE_SECRET" ]; then
    echo "Configuration parameter <SLAVE_SECRET> is missing."
    exit
  fi
else
  echo "Configuration file <jenkins.config> is missing."
  exit
fi

# update base system
sudo apt-get update && sudo apt-get -y upgrade

# install jenkins dependencies
sudo apt-get -y install default-jre-headless git ant phpunit curl
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> ~/.ssh/config
#wget https://phar.phpunit.de/phpunit.phar
#chmod +x phpunit.phar
#sudo mv phpunit.phar /usr/local/bin/phpunit

# install owncloud dependencies
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password your_password'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password your_password'
sudo apt-get -y install mysql-server postgresql
sudo apt-get -y install php5 php5-sqlite php5-pgsql php5-mysqlnd php5-gd php5-intl php5-curl php5-ldap php5-dev
sudo apt-get -y install smbclient

# setup mysql
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest0; grant all on oc_autotest0.* to 'oc_autotest0'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest1; grant all on oc_autotest1.* to 'oc_autotest1'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest2; grant all on oc_autotest2.* to 'oc_autotest2'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest3; grant all on oc_autotest3.* to 'oc_autotest3'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest4; grant all on oc_autotest4.* to 'oc_autotest4'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest5; grant all on oc_autotest5.* to 'oc_autotest5'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest6; grant all on oc_autotest6.* to 'oc_autotest6'@'localhost' IDENTIFIED BY 'owncloud';"
mysql -u root -pyour_password -e "CREATE DATABASE IF NOT EXISTS oc_autotest7; grant all on oc_autotest7.* to 'oc_autotest7'@'localhost' IDENTIFIED BY 'owncloud';"

# setup pgsql
sudo su - postgres <<'EOF'
psql -c "DROP DATABASE IF EXISTS oc_autotest0;"
psql -c "DROP DATABASE IF EXISTS oc_autotest1;"
psql -c "DROP DATABASE IF EXISTS oc_autotest2;"
psql -c "DROP DATABASE IF EXISTS oc_autotest3;"
psql -c "DROP DATABASE IF EXISTS oc_autotest4;"
psql -c "DROP DATABASE IF EXISTS oc_autotest5;"
psql -c "DROP DATABASE IF EXISTS oc_autotest6;"
psql -c "DROP DATABASE IF EXISTS oc_autotest7;"
psql -c "DROP ROLE IF EXISTS oc_autotest0; CREATE USER oc_autotest0 WITH SUPERUSER PASSWORD 'owncloud';"
psql -c "DROP ROLE IF EXISTS oc_autotest1; CREATE USER oc_autotest1 WITH SUPERUSER PASSWORD 'owncloud';"
psql -c "DROP ROLE IF EXISTS oc_autotest2; CREATE USER oc_autotest2 WITH SUPERUSER PASSWORD 'owncloud';"
psql -c "DROP ROLE IF EXISTS oc_autotest3; CREATE USER oc_autotest3 WITH SUPERUSER PASSWORD 'owncloud';"
psql -c "DROP ROLE IF EXISTS oc_autotest4; CREATE USER oc_autotest4 WITH SUPERUSER PASSWORD 'owncloud';"
psql -c "DROP ROLE IF EXISTS oc_autotest5; CREATE USER oc_autotest5 WITH SUPERUSER PASSWORD 'owncloud';"
psql -c "DROP ROLE IF EXISTS oc_autotest6; CREATE USER oc_autotest6 WITH SUPERUSER PASSWORD 'owncloud';"
psql -c "DROP ROLE IF EXISTS oc_autotest7; CREATE USER oc_autotest7 WITH SUPERUSER PASSWORD 'owncloud';"
EOF
sudo bash -c 'cat > /etc/postgresql/9.4/main/pg_hba.conf <<DELIM
# Database administrative login by Unix domain socket
local   all             postgres                                peer
# all local connections are trusted
local	all		all					trust
# "local" is for Unix domain socket connections only
local   all             all                                     peer
# IPv4 local connections:
host    all             all             127.0.0.1/32            md5
# IPv6 local connections:
host    all             all             ::1/128                 md5
DELIM'

sudo service postgresql restart

#setup oracle
if [ ! -f  /usr/lib/oracle/11.2/client64/bin/sqlplus ]; then
  sudo dpkg --add-architecture i386
  sudo apt-get update
  sudo bash ~/setup-oracle.sh
  sudo bash -c 'cat > /etc/php5/mods-available/oci8.ini <<DELIM
  extension=oci8.so
DELIM'
  sudo php5enmod oci8

  # increase open cursors
  sqlplus -s -l / as sysdba <<EOF
    ALTER SYSTEM SET open_cursors = 800 SCOPE=BOTH;
EOF

fi

# install php 5.3
if [ ! -f  /home/vagrant/.phpenv/bin/phpenv ]; then
  sudo apt-get install libxml2-dev re2c libmcrypt-dev libcurl3-openssl-dev bison flex libjpeg62-dev libpng-dev libtidy-dev libxslt-dev libreadline-dev libldap2-dev libpq-dev libbz2-dev libicu-dev libircclient-dev 
  export PHPENV_ROOT=/home/vagrant/.phpenv
  rm -rf phpenv-install.sh
  wget https://raw.github.com/CHH/phpenv/master/bin/phpenv-install.sh
  bash phpenv-install.sh
  mkdir /home/vagrant/.phpenv/plugins
  cd /home/vagrant/.phpenv/plugins && git clone git://github.com/CHH/php-build.git
  echo 'PATH=$HOME/.phpenv/bin:$PATH # Add phpenv to PATH for scripting' >> /home/vagrant/.bashrc
  echo 'eval "$(phpenv init -)"' >> /home/vagrant/.bashrc

  export PATH="/home/vagrant/.phpenv/bin:$PATH"
  export PHP_BUILD_CONFIGURE_OPTS="--with-libdir=/lib/x86_64-linux-gnu --with-ldap --with-pgsql --with-mysql --with-pear --with-bz2 --enable-hash --with-mhash=yes --enable-intl --with-pdo-pgsql --with-pdo-mysql --with-readline"
  export LDFLAGS="-lstdc++"
# export PHP_BUILD_CONFIGURE_OPTS="--enable-fileinfo --enable-hash --enable-json --enable-bcmath --with-bz2 --enable-ctype --with-iconv --with-gettext --with-pcre-regex --enable-phar --enable-simplexml --enable-dom --with-libxml-dir=/usr --enable-tokenizer --with-mhash=yes --with-gd --enable-calendar --enable-cli --enable-cgi --enable-gd-native-ttf --enable-mbregex --enable-wddx --enable-zend-multibyte --with-iodbc --with-ldap-sasl --with-ldap --with-pgsql --with-pear"
  php_versions=( 5.3.28 5.4.32 5.5.16 5.6.0 )
  for php_version in ${php_versions[@]} do
    echo $php_version
    echo "Install PHP $php_version"
    phpenv install $php_version
    # install oci
    export ORACLE_HOME=/usr/lib/oracle/11.2/client64
    phpenv local $php_version
    echo "extension = oci8.so" >> ~/.phpenv/versions/$(phpenv version-name)/etc/php.ini

  done
fi

# install nodejs
sudo apt-get -y install curl
curl -sL https://deb.nodesource.com/setup | sudo bash -
sudo apt-get -y install nodejs

# setup work space
sudo mkdir -p /var/jenkins
sudo chown vagrant /var/jenkins

cd /var/jenkins
rm -rf slave.jar
wget --no-check-certificate https://ci.owncloud.org/jnlpJars/slave.jar

#start the slave
echo "Starting Jenkins slave $SLAVE_NAME"
java -jar slave.jar -noCertificateCheck -jnlpUrl https://ci.owncloud.org/computer/$SLAVE_NAME/slave-agent.jnlp -secret $SLAVE_SECRET &

