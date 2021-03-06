#!/bin/bash
set -e

tmp_dir=/tmp/$$

source_rabbitmq="/etc/apt/sources.list.d/rabbitmq-server.list"
erlang_dep="https://packages.erlang-solutions.com/erlang/debian/pool/esl-erlang_21.3.6-1~ubuntu~xenial_amd64.deb"
plugins="https://dl.bintray.com/rabbitmq/community-plugins/3.7.x/rabbitmq_delayed_message_exchange/rabbitmq_delayed_message_exchange-20171201-3.7.x.zip"

install_erlang21() {

test -d ${tmp_dir} || mkdir -p ${tmp_dir}
cd ${tmp_dir} && wget ${erlang_dep} 
sudo dpkg -i `basename ${erlang_dep}` || sudo apt-get -f install -y  && sudo dpkg -i `basename ${erlang_dep}`

}

install_rabbitmq() {

wget -O - 'https://dl.bintray.com/rabbitmq/Keys/rabbitmq-release-signing-key.asc' | sudo apt-key add -
sudo test -e ${source_erlang} && rm -f ${source_erlang}
sudo echo "deb https://dl.bintray.com/rabbitmq/debian xenial main" > ${source_rabbitmq}
sudo apt update && apt install rabbitmq-server -y


#install plugins
sudo apt install unzip -y
test -d ${tmp_dir} || mkdir -p ${tmp_dir}
cd ${tmp_dir} && wget ${plugins} 
unzip `basename ${plugins}`
plugins_dir=$(find /usr/lib/rabbitmq/lib/ -type d -name "rabbitmq_server*")
sudo mv rabbitmq_delayed_message_exchange-20171201-3.7.x.ez ${plugins_dir}/plugins/

#enable plugins
sudo rabbitmq-plugins enable rabbitmq_management
sudo rabbitmq-plugins enable rabbitmq_delayed_message_exchange


mkdir -p /data/rabbitmq
chown -R rabbitmq.rabbitmq /data/rabbitmq
echo "RABBITMQ_MNESIA_BASE=/data/rabbitmq/mnesia" >> /etc/rabbitmq/rabbitmq-env.conf
echo "RABBITMQ_LOG_BASE=/data/rabbitmq/log"  >> /etc/rabbitmq/rabbitmq-env.conf
systemctl restart rabbitmq-server.service


#set admin passwd
sudo rabbitmqctl add_user admin advance.ai2016
sudo rabbitmqctl set_user_tags admin administrator
sudo rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
systemctl restart rabbitmq-server.service

#set started
sudo systemctl enable rabbitmq-server


test -d ${tmp_dir} && rm -rf ${tmp_dir}

}

install_erlang21 && install_rabbitmq

