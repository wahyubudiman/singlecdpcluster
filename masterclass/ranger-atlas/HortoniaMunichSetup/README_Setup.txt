Follow the instructions below to create Atlas/Ranger demo environment for HDP2.6.1 for HortoniaBank

- Install latest Ambari (2.5.1)
- Install latest HDP (2.6.1)
- Stop SmartSense; turn-on maintanence mode
- Stop Ambari Metrics; turn-on maintanence mode
- Add Ranger Service; enable Ranger plugin for Hive; enable audit-to-solr-cloud; disable audit-to-hdfs
- Create a folder under /tmp called HortoniaBank on host where Atlas/Ranger are running and copy unzipped content into that folder
- 
- Modify following properties in env-atlas.sh to reflect your VM's settings
		export ATLAS_URL=http://localhost:21000
		export ATLAS_USER=admin
		export ATLAS_PASS=admin
- Modify the following properties to reflect the correct setting for your VM:
	export RANGER_ADMIN_URL=http://localhost:6080
	export RANGER_ADMIN_USER=admin
	export RANGER_ADMIN_PASS=admin
- cd /tmp/HortoniaBank and run the scripts in sequence
- execute: ./01-atlas-import-classification.sh
- execute: ./02-atlas-import-entities.sh
- execute: ./03-update-servicedefs.sh
- execute: ./04-create-os-users.sh
- execute: su hdfs -c ./05-create-hdfs-user-folders.sh
- execute: su hdfs -c ./06-copy-data-to-hdfs.sh
- execute: ./07-create-hive-schema.sh
- From Ranger Admin UI:
  - add tag-based policy service cl1_tag 
  - remove all policies in cl1_tag
  - import policies from file RangerPolicies_cl1_tag.json
  - update service configuration for cl1_hive, to set cl1_tag as its tag-service
  - remove all policies in cl1_hive
  - import policies from file RangerPolicies_cl1_hive.json
