#!/usr/bin/env bash
exec bundle exec /var/www/svccat/bin/rails server -b 'ssl://0.0.0.0:5000?key=/var/www/svccat/config/ssl/localhost.key&cert=/var/www/svccat/config/ssl/localhost.crt' 

