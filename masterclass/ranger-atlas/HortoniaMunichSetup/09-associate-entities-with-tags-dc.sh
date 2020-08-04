atlas_host=${atlas_host:-$(hostname -f)}
atlas_pass=${atlas_pass:-admin}

atlas_curl="curl -u admin:${atlas_pass}"
atlas_url="http://${atlas_host}:31000/api/atlas"

cluster_name=cm

##Tagging Hive Tables

#fetch guid for table worldwidebank.eu_countries@${cluster_name}
guid=$(${atlas_curl} ${atlas_url}/v2/entity/uniqueAttribute/type/hive_table?attr:qualifiedName=worldwidebank.eu_countries@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add REFERENCE_DATA tag
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"REFERENCE_DATA","values":{}}'


#fetch guid for table consent_master.eu_countries@${cluster_name}
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_table?attr:qualifiedName=consent_master.eu_countries@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add REFERENCE_DATA tag
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"REFERENCE_DATA","values":{}}'



#fetch guid for table consent_master.consent_data
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_table?attr:qualifiedName=consent_master.consent_data@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add REFERENCE_DATA tag
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"REFERENCE_DATA","values":{}}'


#fetch guid for table consent_master.consent_data_trans
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_table?attr:qualifiedName=consent_master.consent_data_trans@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add REFERENCE_DATA tag
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"REFERENCE_DATA","values":{}}'



	
## tag hive tables with attribute


#fetch guid for table cost_savings.claim_savings@${cluster_name}
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_table?attr:qualifiedName=cost_savings.claim_savings@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add DATA_QUALITY tag with score=0.51
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"DATA_QUALITY", "values":{"score": "0.51"}}'



## Tagging Hive columns

#fetch guid for table claim.provider_summary.providername@${cluster_name}
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=claim.provider_summary.providername@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add VENDOR_PII tag with type=vendor
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"VENDOR_PII", "values":{"type": "vendor"}}'


#fetch guid for  finance.tax_2015.ssn
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=finance.tax_2015.ssn@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add FINANCE_PII tag with type=finance
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"FINANCE_PII", "values":{"type": "finance"}}'


#fetch guid for finance.tax_2015.fed_tax
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=finance.tax_2015.fed_tax@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add EXPIRES_ON tag with expiry_date=2016
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"EXPIRES_ON", "values":{"expiry_date": "2016-12-31T00:00:00.000Z"}}'


#fetch guid for worldwidebank.us_customers.ccnumber
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=worldwidebank.us_customers.ccnumber@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add PII tag with type=ccn
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"PII", "values":{"type": "ccn"}}'


#fetch guid for worldwidebank.us_customers.mrn
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=worldwidebank.us_customers.mrn@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add PII tag with type=MRN
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"PII", "values":{"type": "MRN"}}'


#fetch guid for worldwidebank.us_customers.nationalid
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=worldwidebank.us_customers.nationalid@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add PII tag with type=MRN
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"PII", "values":{"type": "ssn"}}'



#fetch guid for worldwidebank.us_customers.password
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=worldwidebank.us_customers.password@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add PII tag with type=Password
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"PII", "values":{"type": "Password"}}'


#fetch guid for worldwidebank.us_customers.emailaddress
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=worldwidebank.us_customers.emailaddress@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add PII tag with type=Email
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"PII", "values":{"type": "Email"}}'


#fetch guid for table hr.employees_encrypted.phone@${cluster_name}
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=hr.employees_encrypted.phone@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add ENCRYPTED tag with type=phone
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"ENCRYPTED", "values":{"type": "phone"}}'


 
#fetch guid for table hr.employees_encrypted.email@${cluster_name}
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hive_column?attr:qualifiedName=hr.employees_encrypted.email@${cluster_name} | jq '.entity.guid'  | tr -d '"')

#add ENCRYPTED tag with type=email
${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"ENCRYPTED", "values":{"type": "email"}}'


#create entities for kafka topic FOREX
${atlas_curl}  ${atlas_url}/v2/entity -X POST -H 'Content-Type: application/json' -d @- <<EOF
{  
   "entity":{  
      "typeName":"kafka_topic",
      "attributes":{  
         "description":null,
         "name":"FOREX",
         "owner":null,
         "qualifiedName":"FOREX@${cluster_name}",
         "topic":"FOREX",
         "uri":"none"
      },
      "guid":-1
   },
   "referredEntities":{  
   }
}
EOF

#create entities for kafka topics PRIVATE and associte with SENSITIVE tag
${atlas_curl}  ${atlas_url}/v2/entity -X POST -H 'Content-Type: application/json' -d @- <<EOF
{  
   "entity":{  
      "typeName":"kafka_topic",
      "attributes":{  
         "description":null,
         "name":"PRIVATE",
         "owner":null,
         "qualifiedName":"PRIVATE@${cluster_name}",
         "topic":"PRIVATE",
         "uri":"none"
      },
      "guid":-1
   },
   "referredEntities":{  
   }
}
EOF

guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/kafka_topic?attr:qualifiedName=PRIVATE@${cluster_name} | jq '.entity.guid'  | tr -d '"')

${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"SENSITIVE","values":{}}'

#tag t_private as SENSITITVE
guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hbase_table?attr:qualifiedName=default:t_private@${cluster_name} | jq '.entity.guid'  | tr -d '"')

${atlas_curl} ${atlas_url}/entities/${guid}/traits \
  -X POST -H 'Content-Type: application/json' \
  --data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"SENSITIVE","values":{}}'


#create entities for HDFS path /sensitive and associate with SENSITIVE tag
hdfs_prefix="hdfs://$(hostname -f):8020"
hdfs_path="/sensitive"
${atlas_curl}  ${atlas_url}/v2/entity -X POST -H 'Content-Type: application/json' -d @- <<EOF
{  
   "entity":{  
      "typeName":"hdfs_path",
      "attributes":{  
         "description":null,
         "name":"${hdfs_path}",
         "owner":null,
         "qualifiedName":"${hdfs_prefix}${hdfs_path}",
         "clusterName":"${cluster_name}",
         "path":"${hdfs_prefix}${hdfs_path}"
      },
      "guid":-1
   },
   "referredEntities":{  
   }
}
EOF

guid=$(${atlas_curl}  ${atlas_url}/v2/entity/uniqueAttribute/type/hdfs_path?attr:qualifiedName=${hdfs_prefix}${hdfs_path} | jq '.entity.guid'  | tr -d '"')

${atlas_curl} ${atlas_url}/entities/${guid}/traits \
-X POST -H 'Content-Type: application/json' \
--data-binary '{"jsonClass":"org.apache.atlas.typesystem.json.InstanceSerialization$_Struct","typeName":"SENSITIVE","values":{}}'

