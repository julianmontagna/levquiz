#!/bin/bash

# load helpers
. /helpers.sh

# initializes database, composer dependencies, drupal settings and frontend assets
if [ "$INSTALL" = "TRUE" ]; then
  # download application dependencies
  build_dependencies
  # setup application developer friendly settings
  build_settings
  # import a database dump when mysql service is available
  build_database
  # compile frontend assets
  build_frontend
  # post container initialization commands
  closure
fi

# execute docker cmd replacement
printf "\n\n >> starting the app \n\n"
exec "apache2-foreground"
