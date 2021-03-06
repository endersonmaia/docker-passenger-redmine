#!/bin/bash
set -e
source /build/buildconfig
set -x

# Enabling nginx and passenger
rm -f /etc/service/nginx/down

mkdir -p  $REDMINE_APP_PATH
mkdir -p  $REDMINE_DATA_PATH

cp $BUILD_PATH/redmine.init.sh /etc/my_init.d/30-redmine.sh

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

cp ${BUILD_PATH}/config/redmine/database.yml ${APP_PATH}/config/database.yml

# install gems, use cache if available
/sbin/setuser app mkdir ${APP_PATH}/vendor/cache/
for gem in $(ls -1 ${CACHE_DIR}/*.gem);do
  mv $gem ${APP_PATH}/vendor/cache/
done

cd ${APP_PATH}; /sbin/setuser app bundle install --without development tests --path ${APP_PATH}/vendor/bundle

# Configuring nginx
sed 's/user www-data/user app/' -i /etc/nginx/nginx.conf
rm -f /etc/nginx/sites-enabled/default
cp /build/config/nginx/redmine.conf /etc/nginx/sites-enabled/redmine.conf
sed 's|{{APP_PATH}}|'"${APP_PATH}"'|' -i /etc/nginx/sites-enabled/redmine.conf
