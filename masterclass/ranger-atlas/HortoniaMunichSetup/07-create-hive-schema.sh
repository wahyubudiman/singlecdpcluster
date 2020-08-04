export beeline_url="jdbc:hive2://localhost:10000"

beeline -u ${beeline_url} -n hive -f ./data/HiveSchema.hsql

if [ "${enable_hive_acid}" = true  ]; then
  beeline -u ${beeline_url} -n hive -f data/TransSchema.hsql
fi
