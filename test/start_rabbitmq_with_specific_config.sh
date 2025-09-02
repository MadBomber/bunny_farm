#!/bin/bash

rabbitmq-server -detached

sleep 5

rabbitmqadmin -u guest -p guest declare user name=guest password=guest tags=administrator
rabbitmqadmin -u guest -p guest declare vhost name=sandbox
rabbitmqadmin -u guest -p guest declare permission vhost=sandbox user=guest configure='.*' write='.*' read='.*'

