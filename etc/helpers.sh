#!/bin/bash

export DB_HOST="${DB_HOST:-mysql}"
export DB_USER="${DB_USER:-root}"
export DB_PASS="${DB_PASS:-root}"
export DB_NAME="${DB_NAME:-drupal8}"
export BASE_PATH="${BASE_PATH:-/var/www/html}"
export ROOT_PATH="${ROOT_PATH:-/var/www/html/web}"
export CONF_PATH="${CONF_PATH:-/mnt/etc}"
export THEME_PATH="${THEME_PATH:-/var/www/html/web/themes/custom/world101_theme}"

# download application dependencies
build_dependencies () {
  if [ "$(ls -I .gitkeep -A $BASE_PATH)" ]; then
    printf "\n\n >> previous installation found so running: composer install \n\n"
    cd $BASE_PATH && composer install --prefer-dist
  else
    printf "\n\n >> no previous installation found so running: composer create-project \n\n"
    rm -r $BASE_PATH/.gitkeep
    cd $BASE_PATH && composer create-project drupal-composer/drupal-project:8.x-dev $BASE_PATH --stability dev --no-interaction
  fi
}

# setup application developer friendly settings
build_settings () {
  printf "\n\n >> setting up application configuration files \n\n"

  chmod 755 $BASE_PATH/web/sites/default

  SETTING1=$BASE_PATH/web/sites/development.services.yml
  if [ -f "$SETTING1" ]; then chown www-data:www-data $SETTING1 && chmod 777 $SETTING1; fi
  cp $CONF_PATH/drupal/development.services.yml $SETTING1 && chmod 444 $SETTING1

  SETTING2=$BASE_PATH/web/sites/default/settings.local.php
  if [ -f "$SETTING2" ]; then chown www-data:www-data $SETTING2 && chmod 777 $SETTING2; fi
  cp $CONF_PATH/drupal/settings.local.php $SETTING2 && chmod 444 $SETTING2

  SETTING3=$BASE_PATH/web/sites/default/settings.php
  if [ -f "$SETTING3" ]; then chown www-data:www-data $SETTING3 && chmod 777 $SETTING3; fi
  cp $CONF_PATH/drupal/settings.php $SETTING3 && chmod 444 $SETTING3
}

# import a database dump when mysql service is available
build_database () {
  while ! mysqladmin ping -h"$DB_HOST" --silent; do
    printf "\n\n >> waiting until database service is ready... \n\n"
    sleep 1
  done

  EXISTS=$(mysql -h $DB_HOST -u $DB_USER -p$DB_PASS --batch --skip-column-names -e "SHOW DATABASES LIKE '"$DB_NAME"';")

  if [ "$EXISTS" = "" ]; then
    printf "\n\n >> importing database from %s/_dumps/%s.sql.tar.gz \n\n" $CONF_PATH $DB_NAME

    cd $CONF_PATH/_dumps/
    tar -zxf $DB_NAME.sql.tar.gz
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e "CREATE DATABASE $DB_NAME;"
    mysql -h $DB_HOST -u $DB_USER -p$DB_PASS $DB_NAME < $DB_NAME.sql
    rm $DB_NAME.sql
  else
    printf "\n\n >> database already detected so skiping import \n\n"
  fi
}

# compile frontend assets
build_frontend () {
  printf "\n\n >> building the application frontend \n\n"

  cd $THEME_PATH \
    && npm install --max-old-space-size=512 \
    && npm install -g bower \
    && bower install --allow-root \
    && npm run build
}

# post container initialization commands
closure () {
  printf "\n\n >> running post initialization actions \n\n"

  printf "\n\n >>>>>>>>>> $BASE_PATH \n\n"

  # reset the admin password
  cd $BASE_PATH/web; drush upwd --password="admin" "admin"

  # update drupal
  update_d8

  # output system status
  debug
}

# destroy the current database and import a fresh one
reset_db () {
  printf "\n\n >> re-importing the database \n\n"

  # removes the current database
  mysql -h $DB_HOST -u $DB_USER -p$DB_PASS -e "DROP DATABASE $DB_NAME;"

  # import the database from scratch
  build_database
}

# update application dependencies run database updates
update_d8 () {
  printf "\n\n >> running application update process \n\n"

  # running application update database script
  cd $BASE_PATH/web; drush updb --entity-updates -y

  # import latest configuration
  cd $BASE_PATH/web; drush config-import -y
}

# shows the status of the startup process
debug () {
  printf "\n\n >> outputting debug information \n\n"

  # debug info from with drush and drupal console
  cd $BASE_PATH/web && drush status && drupal site:status
}
