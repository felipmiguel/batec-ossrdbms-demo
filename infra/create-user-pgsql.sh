PGSQL_SERVER=$1
DATABASE_NAME=$2
APPLICATION_LOGIN_NAME=$3
APPLICATION_IDENTITY_APPID=$4
ADMIN_USER=$5

az extension add --name rdbms-connect --upgrade

echo 'Getting password for current user'
ADMIN_PASSWORD=$(az account get-access-token --resource-type oss-rdbms -o tsv --query accessToken)

cat <<EOF > pgsqluser.sql
SET aad_validate_oids_in_tenant = off;
REVOKE ALL PRIVILEGES ON DATABASE "${DATABASE_NAME}" FROM "${APPLICATION_LOGIN_NAME}";
DROP USER IF EXISTS "${APPLICATION_LOGIN_NAME}";
CREATE ROLE "${APPLICATION_LOGIN_NAME}" WITH LOGIN PASSWORD '${APPLICATION_IDENTITY_APPID}' IN ROLE azure_ad_user;
GRANT ALL PRIVILEGES ON DATABASE "${DATABASE_NAME}" TO "${APPLICATION_LOGIN_NAME}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "${APPLICATION_LOGIN_NAME}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "${APPLICATION_LOGIN_NAME}";
EOF

az postgres flexible-server execute --name ${PGSQL_SERVER} --file-path pgsqluser.sql --admin-password "${ADMIN_PASSWORD}" --admin-user "${ADMIN_USER}" --verbose
rm pgsqluser.sql
