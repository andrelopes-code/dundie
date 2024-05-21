
if [ -d "dundie-api" ] && [ -d "dundie-next-app" ]; then
    sudo rm -rf dundie-api dundie-next-app
    echo "Removing dundie-api and dundie-next-app"
fi

git clone https://github.com/andrelopes-code/dundie-api
git clone https://github.com/andrelopes-code/dundie-next-app

secrets_file="dundie-api/.secrets.toml"
API_ROUTE_FILE="dundie-next-app/src/constants/apiRoute.ts"
DEFAULT_TOML_FILE="dundie-api/dundie/default.toml"

if [ -n "$GITPOD_WORKSPACE_ID" ]; then
    API_URL="https://80-${GITPOD_WORKSPACE_ID}.${GITPOD_WORKSPACE_CLUSTER_HOST}/api"
else
    API_URL="http://localhost/api"
fi

BASE_API_URL="http://api:8000"
SECRET_KEY=$(openssl rand -hex 32)

# Create secrets.toml file
if [ ! -f $secrets_file ]; then
    echo "[development]" > $secrets_file
    echo "dynaconf_merge = true" >> $secrets_file
    echo "" >> $secrets_file
    echo "[development.security]" >> $secrets_file
    echo "ADMIN_PASS = \"admin\"" >> $secrets_file
    echo "DELIVERY_PASS = \"delivery\"" >> $secrets_file
    echo "SECRET_KEY = \"$SECRET_KEY\"" >> $secrets_file
fi

sed -i "s|const PRIVATE_API_URL = .*;|const PRIVATE_API_URL = \"$BASE_API_URL\";|g" "$API_ROUTE_FILE"
sed -i "s|const API_URL = .*;|const API_URL = \"$API_URL\";|g" "$API_ROUTE_FILE"
sed -i "s|PWD_RESET_URL = .*\".*\"|PWD_RESET_URL = \"$BASE_API_URL/forgot-password\"|g" "$DEFAULT_TOML_FILE"

# Start environment with docker compose
docker compose build
docker compose down
docker compose up -d

sleep 2

# Initial data in database
docker compose exec api alembic stamp base
docker compose exec api alembic upgrade head
docker compose exec api dundie initialize

clear
echo -e "\033[1;35m    ____  ____  _   ________\n   / __ \/ __ \/ | / / ____/\n  / / / / / / /  |/ / __/   \n / /_/ / /_/ / /|  / /___   \n/_____/\____/_/ |_/_____/   \n                           "
echo -e "\033[1;35mAcesse: $(echo $API_URL | sed 's/\/api$//')"
echo "Login: admin"
echo "Password: admin"
