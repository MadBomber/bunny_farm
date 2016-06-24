#!/bin/bash

rabbitmq-server -detached

rabbitmqadmin declare user name=guest password=guest tag=administrator
rabbitmqadmin declare vhost=sandbox
rabbitmqadmin declare permission vhost=sandbox user=guest configure=.* write=.* read=.*

