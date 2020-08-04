import json
import uuid
import time
import json
import uuid
import sys
import requests
from requests.auth import HTTPBasicAuth


def modify_service_configs(serviceName, config_type, configs_dict, clustername, username, password):
    # Step 1: Find the latest version of the config type that you need to update.
    url = 'http://localhost:8080/api/v1/clusters/' + clustername + '?fields=Clusters/desired_configs'
    basic_auth = HTTPBasicAuth(username, password)
    response = requests.get(url=url, auth=basic_auth, verify=False)
    json_data = json.loads(response._content)
    print json_data
    tag = json_data['Clusters']['desired_configs'][config_type]['tag']
    new_tag = "version" + str(uuid.uuid4())

    # Step 2: Read the config type with correct tag
    url = 'http://localhost:8080/api/v1/clusters/' + clustername + '/configurations?type=' + config_type + '&tag=' + tag
    response = requests.get(url=url, auth=basic_auth, verify=False)
    json_data = json.loads(response._content)
    try:
        for config in configs_dict.keys():
            json_data['items'][0]['properties'][config] = configs_dict.get(config)
        json_data = '{"Clusters":{"desired_config":{"tag":"' + new_tag + '", "type":"' + config_type + '", "properties":' + str(
            json.dumps(json_data['items'][0]['properties'])) + '}}}'
    except KeyError:
        properties = {}
        for config in configs_dict.keys():
            properties[config] = configs_dict.get(config)
        json_data = '{"Clusters":{"desired_config":{"tag":"' + new_tag + '", "type":"' + config_type + '", "properties":' + str(
            json.dumps(properties)) + '}}}'

    # Step 3: Save a new version of the config and apply it using one call
    url = 'http://localhost:8080/api/v1/clusters/' + clustername
    requests.put(url=url, data=json_data, auth=basic_auth, headers={'X-Requested-By': 'ambari'},
                 verify=False)
    time.sleep(3)


if __name__ == "__main__":
    print sys.argv[0]
    print sys.argv[1]
    modify_service_configs(sys.argv[2], sys.argv[3], {sys.argv[4]: sys.argv[5]}, sys.argv[1], sys.argv[6], sys.argv[7])
