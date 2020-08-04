spark-shell --jars /opt/cloudera/parcels/CDH/jars/hive-warehouse-connector-assembly*.jar     \
            --conf spark.sql.hive.hiveserver2.jdbc.url="jdbc:hive2://$(hostname -f):10000/default;"    \
            --conf "spark.sql.hive.hiveserver2.jdbc.url.principal=hive/$(hostname -f)@CLOUDERA.COM"    \
            --conf spark.security.credentials.hiveserver2.enabled=false   \
            -i spark_sql.scala
