MYSQL_SERVER=$1
DATABASE_NAME=$2
APPLICATION_LOGIN_NAME=$3
APPLICATION_IDENTITY_APPID=$4
ADMIN_USER=$5

az extension add --name rdbms-connect --upgrade

echo 'Getting password for current user'
ADMIN_PASSWORD=$(az account get-access-token --resource-type oss-rdbms -o tsv --query accessToken)

cat <<EOF > mysqluser.sql
SET aad_auth_validate_oids_in_tenant = OFF;
DROP USER IF EXISTS '${APPLICATION_LOGIN_NAME}'@'%';
CREATE AADUSER '${APPLICATION_LOGIN_NAME}' IDENTIFIED BY '${APPLICATION_IDENTITY_APPID}';
GRANT ALL PRIVILEGES ON ${DATABASE_NAME}.* TO '${APPLICATION_LOGIN_NAME}'@'%';
FLUSH privileges;
EOF
az mysql flexible-server execute --name ${MYSQL_SERVER} --file-path mysqluser.sql --admin-password "${ADMIN_PASSWORD}" --admin-user "${ADMIN_USER}" --verbose
rm mysqluser.sql
