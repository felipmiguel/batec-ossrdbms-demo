cd core
terraform init
terraform apply -auto-approve

ACR_NAME=$(terraform output -raw container_registry_name)
MYSQL_SERVER=$(terraform output -raw mysql_server_name)
MYSQL_DATABASE_NAME=$(terraform output -raw mysql_database_name)
MYSQL_ADMIN_USER=$(terraform output -raw mysql_user_name)
PGSQL_SERVER=$(terraform output -raw pgsql_server_name)
PGSQL_DATABASE_NAME=$(terraform output -raw pgsql_database_name)
PGSQL_ADMIN_USER=$(terraform output -raw pgsql_user_name)
MSI_LOGIN_NAME=$(terraform output -raw msi_database_login_name)
MSI_CONTAINER_IDENTITY=$(terraform output -raw container_apps_identity)
CONTAINER_APP_ENVIRONMENT=$(terraform output -raw container_environment_name)
RESOURCE_GROUP=$(terraform output -raw resource_group)
APPINSIGHTS_CONNECTIONSTRING=$(terraform output -raw application_insights_connection_string)

APPLICATION_IDENTITY_APPID=$(az identity show --id "${MSI_CONTAINER_IDENTITY}" -o tsv --query clientId)

MYSQL_CONNECTION_STRING="Server=${MYSQL_SERVER}.mysql.database.azure.com;Database=${MYSQL_DATABASE_NAME};SslMode=Required"
PGSQL_CONNECTION_STRING="Server=${PGSQL_SERVER}.postgres.database.azure.com;Database=${PGSQL_DATABASE_NAME};Ssl Mode=Require;Port=5432;Trust Server Certificate=true"

# create database schema using ef tools
cd ../../src/repo.mysql
cat <<EOF > appsettings.json
{
    "ConnectionStrings": {
        "DefaultConnection": "${MYSQL_CONNECTION_STRING};UserID=${MYSQL_ADMIN_USER};"
    }
}
EOF
dotnet ef database update

cd ../repo.pgsql
cat <<EOF > appsettings.json
{
    "ConnectionStrings": {
        "DefaultConnection": "${PGSQL_CONNECTION_STRING};User Id=${PGSQL_ADMIN_USER};"
    }
}
EOF
dotnet ef database update


cd ../../infra
pwd
# create mysq login for managed identity
./create-user-mysql.sh $MYSQL_SERVER $MYSQL_DATABASE_NAME $MSI_LOGIN_NAME $APPLICATION_IDENTITY_APPID $MYSQL_ADMIN_USER

# create postgresql login for managed identity
./create-user-pgsql.sh $PGSQL_SERVER $PGSQL_DATABASE_NAME $MSI_LOGIN_NAME $APPLICATION_IDENTITY_APPID $PGSQL_ADMIN_USER



# create docker image for the app
cd ../src
az acr build -t $ACR_NAME.azurecr.io/todoapi:latest -t $ACR_NAME.azurecr.io/todoapi:1.0.0 -r $ACR_NAME .

# create docker image for the web
cd web
az acr build -t $ACR_NAME.azurecr.io/todoweb:latest -t $ACR_NAME.azurecr.io/todoweb:1.0.0 -r $ACR_NAME .

az containerapp create -n mysqlapi -g ${RESOURCE_GROUP} \
    --image ${ACR_NAME}.azurecr.io/todoapi:1.0.0 --environment ${CONTAINER_APP_ENVIRONMENT} \
    --ingress external --target-port 80 \
    --registry-server ${ACR_NAME}.azurecr.io --registry-identity "${MSI_CONTAINER_IDENTITY}" \
    --user-assigned ${MSI_CONTAINER_IDENTITY} \
    --cpu 0.25 --memory 0.5Gi \
    --env-vars TargetDb="MySql" MySqlConnection="${MYSQL_CONNECTION_STRING};UserID=${MSI_LOGIN_NAME};" UserAssignedManagedClientId="${APPLICATION_IDENTITY_APPID}"

az containerapp ingress cors update -n mysqlapi -g ${RESOURCE_GROUP} --allowed-origins "*" --allowed-methods "*"

az containerapp create -n pgsqlapi -g ${RESOURCE_GROUP} \
    --image ${ACR_NAME}.azurecr.io/todoapi:1.0.0 --environment ${CONTAINER_APP_ENVIRONMENT} \
    --ingress external --target-port 80 \
    --registry-server ${ACR_NAME}.azurecr.io --registry-identity "${MSI_CONTAINER_IDENTITY}" \
    --user-assigned ${MSI_CONTAINER_IDENTITY} \
    --cpu 0.25 --memory 0.5Gi \
    --env-vars TargetDb="Postgresql" PgSqlConnection="${PGSQL_CONNECTION_STRING};User Id=${MSI_LOGIN_NAME};" UserAssignedManagedClientId="${APPLICATION_IDENTITY_APPID}"
az containerapp ingress cors update -n pgsqlapi -g ${RESOURCE_GROUP} --allowed-origins "*" --allowed-methods "*"

MYSQLAPI_FQDN=$(az containerapp show -n mysqlapi -g ${RESOURCE_GROUP} -o tsv --query "properties.configuration.ingress.fqdn")
PGSQLAPI_FQDN=$(az containerapp show -n pgsqlapi -g ${RESOURCE_GROUP} -o tsv --query "properties.configuration.ingress.fqdn")

az containerapp create -n mysqlweb -g ${RESOURCE_GROUP} \
    --image ${ACR_NAME}.azurecr.io/todoweb:1.0.0 --environment ${CONTAINER_APP_ENVIRONMENT} \
    --ingress external --target-port 80 \
    --registry-server ${ACR_NAME}.azurecr.io --registry-identity "${MSI_CONTAINER_IDENTITY}" \
    --cpu 0.25 --memory 0.5Gi \
    --env-vars REACT_APP_API_BASE_URL="https://${MYSQLAPI_FQDN}" REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING="${APPINSIGHTS_CONNECTIONSTRING}"

az containerapp create -n pgsqlweb -g ${RESOURCE_GROUP} \
    --image ${ACR_NAME}.azurecr.io/todoweb:1.0.0 --environment ${CONTAINER_APP_ENVIRONMENT} \
    --ingress external --target-port 80 \
    --registry-server ${ACR_NAME}.azurecr.io --registry-identity "${MSI_CONTAINER_IDENTITY}" \
    --cpu 0.25 --memory 0.5Gi \
    --env-vars REACT_APP_API_BASE_URL="https://${PGSQLAPI_FQDN}"  REACT_APP_APPLICATIONINSIGHTS_CONNECTION_STRING="${APPINSIGHTS_CONNECTIONSTRING}"