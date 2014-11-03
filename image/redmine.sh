#!/bin/bash
set -e
source /build/buildconfig
set -x

APP_PATH=${REDMINE_APP_PATH}
DATA_PATH=${REDMINE_DATA_PATH}
CACHE_DIR=${BUILD_PATH}/cache

# Install Redmine, use local copy if available
if [ ! -f ${CACHE_DIR}/redmine-${REDMINE_VERSION}.tar.gz ]; then
  curl "http://www.redmine.org/releases/redmine-${REDMINE_VERSION}.tar.gz" -o ${CACHE_DIR}/redmine-${REDMINE_VERSION}.tar.gz
fi

tar -xzf ${CACHE_DIR}/redmine-${REDMINE_VERSION}.tar.gz --strip=1 -C $APP_PATH

# Organizing dirs
mkdir -p  ${APP_PATH}/tmp         \
          ${APP_PATH}/tmp/pdf     \
          ${APP_PATH}/tmp/pids    \
          ${APP_PATH}/tmp/sockets

mkdir -p  ${DATA_PATH}/tmp               \
          ${DATA_PATH}/tmp/plugin_assets \
          ${DATA_PATH}/tmp/thumbnails    \
          ${DATA_PATH}/files

rm -rf ${APP_PATH}/files
ln -sf ${DATA_PATH}/files ${APP_PATH}/files

rm -rf ${APP_PATH}/public/plugin_assets
ln -sf ${DATA_PATH}/tmp/plugin_assets ${APP_PATH}/public/plugin_assets

rm -rf ${APP_PATH}/tmp/thumbnails
ln -sf ${DATA_PATH}/tmp/thumbnails ${APP_PATH}/tmp/thumbnails

ln -sf ${DATA_PATH}/tmp/secret_token.rb ${APP_PATH}/config/initializers/secret_token.rb

chown -R app:app ${APP_PATH} ${DATA_PATH}
chmod -R u+rwX ${DATA_PATH}

# install gems, use cache if available
if [ -d "${CACHE_DIR}" ]; then
  /sbin/setuser app mkdir ${APP_PATH}/vendor/cache/
  mv ${CACHE_DIR}/*.gem ${APP_PATH}/vendor/cache/
fi

cp ${APP_PATH}/config/database.yml.example ${APP_PATH}/config/database.yml
cd ${APP_PATH}; /sbin/setuser app bundle install --without development tests --path ${APP_PATH}/vendor/bundle

# Configuring nginx
sed 's/user www-data/user app/' -i /etc/nginx/nginx.conf
rm -f /etc/nginx/sites-enabled/default
cp /build/config/nginx/redmine.conf /etc/nginx/sites-enabled/redmine.conf
sed 's|{{APP_PATH}}|'"${APP_PATH}"'|' -i /etc/nginx/sites-enabled/redmine.conf