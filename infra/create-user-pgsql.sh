PGSQL_SERVER=$1
DATABASE_NAME=$2
APPLICATION_LOGIN_NAME=$3
APPLICATION_IDENTITY_APPID=$4
ADMIN_USER=$5

az extension add --name rdbms-connect --upgrade

echo 'Getting password for current user'
ADMIN_PASSWORD=$(az account get-access-token --resource-type oss-rdbms -o tsv --query accessToken)

cat <<EOF > pgsqluser.sql
select * from pgaadauth_create_principal_with_oid('${APPLICATION_LOGIN_NAME}', '${APPLICATION_IDENTITY_APPID}', 'service', false, false);
GRANT ALL PRIVILEGES ON DATABASE "${DATABASE_NAME}" TO "${APPLICATION_LOGIN_NAME}";
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO "${APPLICATION_LOGIN_NAME}";
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO "${APPLICATION_LOGIN_NAME}";
EOF

az postgres flexible-server execute --name ${PGSQL_SERVER} --file-path pgsqluser.sql --admin-password "${ADMIN_PASSWORD}" --admin-user "${ADMIN_USER}" --verbose
rm pgsqluser.sql
