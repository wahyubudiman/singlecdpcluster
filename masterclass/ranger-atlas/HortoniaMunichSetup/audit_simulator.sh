#Basic script to simulate hive queries from random users across random tables

export kdc_realm=${kdc_realm:-HWX.COM}
export hive_port=10000   ## if LLAP is not enabled

##export hive_port=10500   ## if LLAP is enabled

users=("joe_analyst" "kate_hr" "sasha_eu_hr" "ivanna_eu_hr" "john_finance" "mark_bizdev" "jermy_contractor" "diane_csr" "etl_user")
tables=("salary.summary_08" "salary.summary_07" "salary.salary_07" "salary.salary_08" "hortoniabank.ww_customers" "hortoniabank.us_customers" "finance.tax_2009" "finance.tax_2010" "finance.tax_2015" "cost_savings.claim_savings" "claim.provider_summary" "consent_master.consent_data")

# Seed random generator
RANDOM=$$$(date +%s)


while [ 1 ]
do
    # Get random expression...
    selecteduser=${users[$RANDOM % ${#users[@]} ]}

    selectedtable=${tables[$RANDOM % ${#tables[@]} ]}

    if [ -d "/etc/security/keytabs/" ]; then
       kinit -kt /etc/security/keytabs/${selecteduser}.keytab  ${selecteduser}/$(hostname -f)@${kdc_realm}
       beeline_url="jdbc:hive2://localhost:${hive_port}/default;principal=hive/$(hostname -f)@${kdc_realm}"
    else
       beeline_url="jdbc:hive2://localhost:${hive_port}/default"
    fi
    
    # Write to Shell
    echo "$selecteduser: select * from $selectedtable"
    beeline -n $selecteduser -u ${beeline_url} -e "select * from $selectedtable limit 5"

	#sleep for random time between 1-10s
    randomsleep=$(( ( RANDOM % 10 )  + 1 ))
    sleep ${randomsleep}
done
