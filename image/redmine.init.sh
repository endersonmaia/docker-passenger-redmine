#!/bin/bash
set -x

APP_PATH=${REDMINE_APP_PATH}
DATA_PATH=${REDMINE_DATA_PATH}

if [ ! -n "${MYSQL_PORT_3306_TCP_ADDR}" ]; then
  echo "ERROR: "
  echo "You must link a MySQL container."
  exit 1
fi

DB_TYPE=mysql
DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}
DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}

DB_NAME=${DB_NAME:-redmine_production}
DB_USER=${DB_USER:-root}

cp /build/config/redmine/database.yml ${APP_PATH}/config/database.yml

/sbin/setuser app sed 's/{{DB_ADAPTER}}/mysql2/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/{{DB_ENCODING}}/utf8/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/#reconnect: false/reconnect: false/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/{{DB_HOST}}/'"${DB_HOST}"'/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/{{DB_PORT}}/'"${DB_PORT}"'/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/{{DB_NAME}}/'"${DB_NAME}"'/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/{{DB_USER}}/'"${DB_USER}"'/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/{{DB_PASS}}/'"${DB_PASS}"'/' -i ${APP_PATH}/config/database.yml
/sbin/setuser app sed 's/{{DB_POOL}}/'"${DB_POOL}"'/' -i ${APP_PATH}/config/database.yml

# recreate the tmp directory
rm -rf ${DATA_PATH}/tmp
/sbin/setuser app mkdir -p ${DATA_PATH}/tmp/
chmod -R u+rwX ${DATA_PATH}/tmp/
/sbin/setuser app mkdir -p ${DATA_PATH}/tmp/thumbnails
/sbin/setuser app mkdir -p ${DATA_PATH}/tmp/plugin_assets

# copy the installed gems to tmp/bundle and move the Gemfile.lock
/sbin/setuser app cp -a ${APP_PATH}/vendor/bundle ${DATA_PATH}/tmp/
/sbin/setuser app cp -a ${APP_PATH}/Gemfile.lock ${DATA_PATH}/tmp/

cd ${APP_PATH}

echo "Migrating database. Please be patient, this could take a while..."
/sbin/setuser app bundle exec rake db:migrate RAILS_ENV=production
/sbin/setuser app bundle exec rake tmp:cache:clear RAILS_ENV=production >/dev/null
/sbin/setuser app bundle exec rake tmp:sessions:clear RAILS_ENV=production >/dev/null
/sbin/setuser app bundle exec rake generate_secret_token RAILS_ENV=production >/dev/null

# remove vendor/bundle and symlink to ${DATA_DIR}/tmp/bundle
rm -rf ${APP_PATH}/vendor/bundle ${APP_PATH}/Gemfile.lock
ln -sf ${DATA_PATH}/tmp/bundle ${APP_PATH}/vendor/bundle
ln -sf ${DATA_PATH}/tmp/Gemfile.lock ${APP_PATH}/Gemfile.lock