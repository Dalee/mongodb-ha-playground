#!/usr/bin/env bash

#
#
#
echo "==> Installing software (if needed, may take few minutes)..."
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927 > /dev/null 2>&1
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list > /dev/null
sudo apt-get -qq update
sudo apt-get -qq -y install \
    haproxy \
    mongodb-org=3.2.14 \
    jq

#
#
#
echo "==> Stopping MongoDB-HA..."
sudo systemctl stop mongod.service 2>/dev/null
sudo systemctl disable mongod.service 2>/dev/null
sudo systemctl stop haproxy mongodb-arbiter mongodb-27017 mongodb-27018 2>/dev/null

#
#
#
echo "==> Setting up MongoDB-HA..."

sudo cp -f /vagrant/hosts.conf /etc/hosts
sudo cp -f /vagrant/mongodb-arbiter.service /etc/systemd/system/mongodb-arbiter.service
sudo cp -f /vagrant/mongodb-27017.service /etc/systemd/system/mongodb-27017.service
sudo cp -f /vagrant/mongodb-27018.service /etc/systemd/system/mongodb-27018.service
sudo systemctl daemon-reload

sudo mkdir -p /data/mongodb-farm
sudo rm -rf /data/mongodb-farm/*
sudo mkdir -p /data/mongodb-farm/27017
sudo mkdir -p /data/mongodb-farm/27018
sudo mkdir -p /data/mongodb-farm/arbiter

sudo cp -f /vagrant/mongodb-27017.conf /data/mongodb-farm/mongodb-27017.conf
sudo cp -f /vagrant/mongodb-27018.conf /data/mongodb-farm/mongodb-27018.conf
sudo cp -f /vagrant/mongodb-arbiter.conf /data/mongodb-farm/mongodb-arbiter.conf
sudo chown -R vagrant:vagrant /data/mongodb-farm

sudo mkdir -p /data/haproxy
sudo cp -f /vagrant/haproxy.conf /etc/haproxy/haproxy.cfg

#
#
#
echo "==> Starting MongoDB-HA..."
sudo systemctl start \
    haproxy \
    mongodb-27017 \
    mongodb-27018 \
    mongodb-arbiter

#
#
#
echo "==> Initializing MongoDB-HA ReplicaSet..."
SOCKET_STATUS="1"
while [ "${SOCKET_STATUS}" != "0" ]
do
    echo "MongoDB startup is in progress..."
    sleep 1
    nc -z -w2 127.0.0.1 27017
    SOCKET_STATUS=$?
done
mongo --quiet --port 27017 < /vagrant/rs0-initialize.js

#
#
#
echo "==> Creating MongoDB-HA Sample database and record..."
IS_MASTER="false"
while [ "${IS_MASTER}" != "true" ]
do
    echo "MongoDB replication setup is in progress..."
    sleep 1
    IS_MASTER=$(mongo --quiet --port 27017 --eval "JSON.stringify(db.isMaster())" | jq '.ismaster')
done
mongo --quiet --port 27017 < /vagrant/rs0-sample-database.js
