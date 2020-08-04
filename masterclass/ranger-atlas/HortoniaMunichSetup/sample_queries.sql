
-- Joe analyst queries

-- Dynamic Column Masking: MRN/password cols masked via classification policy. Others masked via Hive col policy. Custom masks for Birthday/Age.
SELECT surname, streetaddress, country, age, nationalid, ccnumber, mrn, birthday FROM worldwidebank.us_customers LIMIT 10

-- Prohibition policy: Prevent toxic joins (prevent join of Zipcode, Insuranceid, Blood group)
select zipcode, insuranceid, bloodtype from worldwidebank.ww_customers limit 10

-- Prohibition policy - dropping insuranceid allows query to run
select zipcode, bloodtype from worldwidebank.ww_customers limit 10

-- Leased Data Asset: Lifecycle controlled by Classification based policy (fed_tax is tagged with EXPIRED_ON which is restricted to analysts)
select fed_tax from finance.tax_2015


-- Analyst prohibited from accessing personal data through Data Classification based policy (SSN column is tagged with PII which analysts cannot access)
select ssn from finance.tax_2015


-- Querying for columns other than fed_tax/ssn works
select state_tax from finance.tax_2015


-- Data Quality annotation based policy: Don't waste time on poor quality datasets! (Analysts should not access table tagged with DATA_QUALITY score < 60%)
select * from cost_savings.claim_savings limit 5


-- Decrypt UDF: US employee sees decrypted versions of email and phone number
select * from  hr.employees_encrypted



-- Ivanna EU HR queries

-- EU employee can not access us_customers table
select * from worldwidebank.us_customers limit 10

-- Row Level Security - Customer data filtered to EU persons only based on location
select distinct(country) from worldwidebank.ww_customers


-- HR analyst can see unmasked records - but only for EU customers who have given consent
SELECT surname, streetaddress, country, age, nationalid, ccnumber, mrn, birthday FROM worldwidebank.ww_customers LIMIT 10


-- Analysts only see portion of customers - only those who have given consent. (Table actually has ~29k rows)
SELECT count(*) FROM worldwidebank.ww_customers

-- Analyst CAN'T see a customer who has not given consent (Row filtering)
SELECT insuranceid, surname, streetaddress, country, age FROM worldwidebank.ww_customers where insuranceid='23182722'

-- Analyst CAN see a customer who has given consent (Row filtering)
SELECT insuranceid, surname, streetaddress, country, age FROM worldwidebank.ww_customers where insuranceid='62517316'

-- HR Analyst not be able to update consent master data tagged as REFERENCE_DATA (Tag based policy)
update  consent_master.consent_data_trans set  loyaltyconsent='NO' where insuranceid='57155949'

-- HR analyst can access table tagged with DATA_QUALITY even though it's score < 60% (joe_analyst can not access)
select * from cost_savings.claim_savings limit 5

-- Decrypt UDF: EU employee only see AES-256 encrypted versions of email and phone number
select * from  hr.employees_encrypted






