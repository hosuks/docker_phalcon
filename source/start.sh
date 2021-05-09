#!/bin/bash
DATA_DIR=/home/httpd

echo 'make directory';
mkdir -p /etc/supervisor /var/log/{supervisor,php-fpm}

echo 'set permission.';
set -e
chown -R www.www $DATA_DIR

# @TODO https://github.com/YahnisElsts/plugin-update-checker/issues/56
#/usr/local/php/lib/phpdoc project:run -d /home/httpd/Apps -t /home/docs --ignore "Libraries/*/*" --template="responsive-twig"

echo 'start supervisord.';
SVD_PATH=$(whereis supervisord | awk '{print $2}')
$SVD_PATH -n -c /etc/supervisor/supervisord.conf

