FROM phusion/passenger-ruby21
MAINTAINER Enderson Maia <endersonmaia@gmail.com>

# Set correct environment variables.
ENV HOME /root
ENV REDMINE_VERSION 2.6.0
ENV REDMINE_APP_PATH /home/app/redmine-$REDMINE_VERSION
ENV REDMINE_DATA_PATH /home/app/redmine-data
ENV BUILD_PATH /build

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Enabling nginx and passenger
RUN rm -f /etc/service/nginx/down

RUN mkdir -p $REDMINE_APP_PATH
RUN mkdir -p $REDMINE_DATA_PATH

COPY image/ $BUILD_PATH

RUN mkdir -p /etc/my_init.d
RUN cp $BUILD_PATH/redmine.init.sh /etc/my_init.d #201411041543
RUN chmod +x /etc/my_init.d/redmine.init.sh

RUN $BUILD_PATH/redmine.sh

VOLUME [ $REDMINE_DATA_PATH ]

# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*