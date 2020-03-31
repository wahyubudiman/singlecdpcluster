# Demo single CDP 7 with worlwidebankdemo data
Single node CDP 7.0.3 including:
Cloudera Manager (60 day trial license included) - for managing the services
Kerberos - for authentication (via local MIT KDC)○Ranger - for authorization (via both resource/tag based policies for accessand masking)
○Atlas - for governance (classification/lineage/search)
○Zeppelin - for running/visualizing Hive queries
○Impala/Hive 3 - for Sql access and ACID capabilities
○Spark/HiveWarehouseConnector - for running secure SparkSQL queries
●Worldwide Bank artifacts
○Demo hive tables
○Demo tags/attributes and lineage in Atlas
○Demo Zeppelin notebooks to walk through demo scenario
○Ranger policies across HDFS, Hive/Impala, Hbase, Kafka, SparkSQL toshowcase:
■Tag based policies across HDP components
■Row level security in Hive columns
■Dynamic tag based masking in Hive columns
■Hive UDF execution authorization
■Atlas capabilities like
●Classifications (tags) and attributes
●Tag propagation
●Data lineage
●Business glossary:categories and terms
■GDPR Scenarios around consent and data erasure via Hive ACID
○Hive ACID / MERGE labs
