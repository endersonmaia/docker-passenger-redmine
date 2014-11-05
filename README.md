# Redmine Docker image

This is a Redmine Docker image based on http://phusion.github.io/baseimage-docker/ and in the work of http://www.damagehead.com/docker-redmine/

## Quickstart

Star a mysql docker container:

    docker run -d --name=mysql    \
    -e MYSQL_ROOT_PASSWORD="root" \
    -e MYSQL_USER="redmine"       \
    -e MYSQL_PASSWORD="p@$$W0rD"  \
    -e MYSQL_DATABASE="redmine"   \
    mysql

And start your Redmine docker container, linked with the mysql container:

    docker run --name=redmine \
    --link mysql:mysql        \
    -p 80:80                  \
    enderson/redmine:2.6.0
    
If everything goes fine, you can access your redmine application at http://localhost.
