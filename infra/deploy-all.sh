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


APPLICATION_IDENTITY_APPID=$(az identity show --id "${MSI_CONTAINER_IDENTITY}" -o tsv --query clientId)
cd ..
# create mysq login for managed identity
./create-user-mysql.sh $MYSQL_SERVER $MYSQL_DATABASE_NAME $MSI_LOGIN_NAME $APPLICATION_IDENTITY_APPID $MYSQL_ADMIN_USER

# create postgresql login for managed identity
./create-user-pgsql.sh $PGSQL_SERVER $PGSQL_DATABASE_NAME $MSI_LOGIN_NAME $APPLICATION_IDENTITY_APPID $PGSQL_ADMIN_USER

# create docker image for the app
cd ../src
az acr build -t $ACR_NAME.azurecr.io/todoapi:latest -t $ACR_NAME.azurecr.io/todoapi:1.0.0 -r $ACR_NAME .
