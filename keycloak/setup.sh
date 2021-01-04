#!/bin/bash

################
# HEALTH CHECK #
################

latest_response="./latest_response"
expected_status="200"
health_check_url="http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/auth/realms/master"
sleep=5

wait_service() {
    echo 'health checking'
    echo -n > "${latest_response}"
    curl -is "${health_check_url}" > "${latest_response}"
    http_status=$(head -1 ${latest_response} | cut -d' ' -f2)
}

wait_service
while [ "${http_status}" != "${expected_status}" ]; do
   echo 'health checking status: KO'
   sleep ${sleep}
   wait_service
done

echo 'health checking status: OK'

################
# PROVISIONING #
################

realm="oauth2_application"

# LOGIN
curl --location --request POST "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/auth/realms/master/protocol/openid-connect/token" \
 --header 'Content-Type: application/x-www-form-urlencoded' \
 --data-urlencode 'grant_type=password' \
 --data-urlencode 'username=admin' \
 --data-urlencode 'password=password' \
 --data-urlencode 'client_id=admin-cli' > "./login.json"

access_token=$(cat login.json | jq '.access_token' | cut -d '"' -f 2)

# CREATE REALM oauth2_application

curl --location --request POST "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/auth/admin/realms" \
--header "Authorization: Bearer ${access_token}" \
--header 'Content-Type: application/json' \
--data-raw '{
    "enabled":true,
    "id":"oauth2_application",
    "realm":"oauth2_application"
}' > "./realms.json"

# CREATE LDAP CONNECTION

curl --location --request POST "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/auth/admin/realms/${realm}/components" \
--header "Authorization: Bearer ${access_token}" \
--header 'Content-Type: application/json' \
-d @"./ldap/config.json"  > "components_ldap.json"

# GET ID

curl "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/auth/admin/realms/${realm}/components" \
--header "Authorization: Bearer ${access_token}"  > "components.json"
ldap_id=$(cat components.json | jq -c '.[] | select(.name | contains("ldap_connection"))' | jq '.id' | head -1 | cut -d '"' -f 2)

# SYNC USERS

curl --location --request POST "http://${KEYCLOAK_HOST}:${KEYCLOAK_PORT}/auth/admin/realms/${realm}/user-storage/${ldap_id}/sync?action=triggerFullSync" \
--header "Authorization: Bearer ${access_token}" \
--data-raw '{}' 