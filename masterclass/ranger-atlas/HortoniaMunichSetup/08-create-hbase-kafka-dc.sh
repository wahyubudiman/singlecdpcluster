#if kafka broker var is set, use it. Else use current host
kafka_broker=${kafka_broker:-$(hostname -f)}

echo "kafka_broker detected as ${kafka_broker}"
echo "enable_kerberos detected as ${enable_kerberos}"
echo "kdc_realm detected as ${kdc_realm}"

if [ "${enable_kerberos}" = true  ]; then
   kinit -kt /etc/security/keytabs/etl_user.keytab etl_user/$(hostname -f)@${kdc_realm}
fi   

cat << EOF > /tmp/jaas.conf
KafkaClient {
com.sun.security.auth.module.Krb5LoginModule required
useTicketCache=true;
};
EOF

cat << EOF > /tmp/client.properties
security.protocol=SASL_PLAINTEXT
sasl.kerberos.service.name=kafka
EOF


echo "Creating Hbase tables..."

cat << EOF > /tmp/hbase.sh
create 't_private','cf1','cf2'
create 't_forex','cf1','cf2'

list
exit
EOF


hbase shell /tmp/hbase.sh


cat << EOF > /tmp/forex.csv
UTC time,EUR/USD
2018-03-26T09:00:00Z,1.231
2018-03-26T10:00:00Z,1.232
2018-03-26T11:00:00Z,1.233
2018-03-26T12:00:00Z,1.231
2018-03-26T13:00:00Z,1.234
2018-03-26T14:00:00Z,1.230
2018-03-26T15:00:00Z,1.232
EOF


cat << EOF > /tmp/private.csv
123-45-67890
321-54-09876
800-60-32982
333-22-09873
222-98-21816
111-44-91021
999-11-56101
098-45-10927
EOF

echo "Creating HDFS sensitive dir..."
hdfs dfs -mkdir /sensitive
hdfs dfs -put /tmp/private.csv /sensitive/



echo "Creating Kafka topics..."

if [ "${enable_kerberos}" = true  ]; then   
  kinit -kt /etc/security/keytabs/log_monitor.keytab log_monitor/$(hostname -f)@${kdc_realm}
fi

/opt/cloudera/parcels/CDH/lib/kafka/bin/kafka-topics.sh --create --zookeeper $(hostname -f):2181/kafka --replication-factor 1 --partitions 1 --topic FOREX
/opt/cloudera/parcels/CDH/lib/kafka/bin/kafka-topics.sh --create --zookeeper $(hostname -f):2181/kafka --replication-factor 1 --partitions 1 --topic PRIVATE
/opt/cloudera/parcels/CDH/lib/kafka/bin/kafka-topics.sh --zookeeper $(hostname -f):2181/kafka --list






echo "Publishing test data to Kafka topics..."
sleep 5

#if [ "${enable_kerberos}" = true  ]; then  
#   security_protocol=SASL_PLAINTEXT
#else
#   security_protocol=PLAINTEXT
#fi

#HDP 3.0 commands
#/usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh --security-protocol ${security_protocol} --broker-list ${kafka_broker}:6667 --topic PRIVATE < /tmp/private.csv
#/usr/hdp/current/kafka-broker/bin/kafka-console-producer.sh --security-protocol ${security_protocol} --broker-list ${kafka_broker}:6667 --topic FOREX <  /tmp/forex.csv

export KAFKA_OPTS="-Djava.security.auth.login.config=/tmp/jaas.conf"

#push data to kafka topics
/opt/cloudera/parcels/CDH/lib/kafka/bin/kafka-console-producer.sh --producer.config /tmp/client.properties --broker-list $(hostname -f):9092 --topic PRIVATE   < /tmp/private.csv
/opt/cloudera/parcels/CDH/lib/kafka/bin/kafka-console-producer.sh --producer.config /tmp/client.properties --broker-list $(hostname -f):9092 --topic FOREX   < /tmp/forex.csv

#test data got pushed
/opt/cloudera/parcels/CDH/lib/kafka/bin/kafka-console-consumer.sh --consumer.config /tmp/client.properties  --bootstrap-server $(hostname -f):9092 --topic PRIVATE --from-beginning --max-messages 5
/opt/cloudera/parcels/CDH/lib/kafka/bin/kafka-console-consumer.sh --consumer.config /tmp/client.properties  --bootstrap-server $(hostname -f):9092 --topic FOREX --from-beginning --max-messages 5



if [ "${enable_kerberos}" = true  ]; then 
   echo "Allowing Zeppelin to kinit as joe/ivanna/etluser.."
   chown joe_analyst:zeppelin /etc/security/keytabs/joe_analyst.keytab
   chmod g+r /etc/security/keytabs/joe_analyst.keytab

   chown ivanna_eu_hr:zeppelin /etc/security/keytabs/ivanna_eu_hr.keytab
   chmod g+r /etc/security/keytabs/ivanna_eu_hr.keytab

   chown etl_user:zeppelin /etc/security/keytabs/etl_user.keytab
   chmod g+r /etc/security/keytabs/etl_user.keytab
   
   chown root:hadoop /etc/security/keytabs/log_monitor.keytab
   chmod g+r /etc/security/keytabs/log_monitor.keytab
fi
