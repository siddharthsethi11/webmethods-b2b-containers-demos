#!/bin/bash
set -e

# Define environment variables
export POSTGRES_TN_DB=webmisdb
export POSTGRES_TN_DBUSER=webmisdbuser
export POSTGRES_TN_DBPASSWORD=myStrongPassword123!
export MWS_ADMIN_PASSWORD=SomeNewStrongPassword123!

# Cleanup function
cleanup() {
    # Stop and remove containers if they exist
    for container in mws postgres dbconfig msr; do
        if docker ps -a --format '{{.Names}}' | grep -q "^${container}\$"; then
            echo "Removing container $container..."
            docker rm -f $container
        fi
    done

    # Remove network if exists
    if docker network ls --format '{{.Name}}' | grep -q '^ibm_demos_b2b_net$'; then
        echo "Removing network ibm_demos_b2b_net..."
        docker network rm ibm_demos_b2b_net
    fi

    # Clean up volumes
    echo "Removing volumes..."
    docker volume prune -f
}

# Create network if not exists
create_network() {
    if ! docker network inspect ibm_demos_b2b_net >/dev/null 2>&1; then
        echo "Creating network ibm_demos_b2b_net..."
        docker network create ibm_demos_b2b_net
    fi
}

# Main execution
cleanup
create_network

# Start PostgreSQL
echo "Starting PostgreSQL..."
docker run -d \
    --name postgres \
    -p 5432:5432 \
    -v postgres_data:/var/lib/postgresql/data:rw \
    -e POSTGRES_DB=$POSTGRES_TN_DB \
    -e POSTGRES_USER=$POSTGRES_TN_DBUSER \
    -e POSTGRES_PASSWORD=$POSTGRES_TN_DBPASSWORD \
    --network ibm_demos_b2b_net \
    postgres:14

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
docker exec -i postgres bash -c \
    'while ! pg_isready -U $POSTGRES_USER -d $POSTGRES_DB; do sleep 2; done'

# Extra delay of 2 minutes to ensure PostgreSQL is fully up
echo "PostgreSQL appears ready. Waiting an extra 2 minutes..."
sleep 120

# Run DB configuration
echo "Running DB configuration..."
docker run -d \
    --name dbconfig \
    -e DB_ACTION=create \
    -e DB_TYPE=POSTGRESQL \
    -e DB_NAME=$POSTGRES_TN_DB \
    -e DB_HOST=postgres \
    -e DB_PORT=5432 \
    -e DB_USER=$POSTGRES_TN_DBUSER \
    -e DB_PASSWORD=$POSTGRES_TN_DBPASSWORD \
    -e PRODUCT_VERSION="11.1" \
    -e PRODUCT_NAMES="IS,PRE,TN,MWS,Monitor" \
    -e RUN_FINAL_INVENTORY="true" \
    -e WAITFOR_DB_HOST="true" \
    -e WAITFOR_DB_TIMEOUT_SEC="30" \
    --network ibm_demos_b2b_net \
    amajusag/webmethods-dbconfig:11.1

# Start MWS
echo "Starting MWS..."
docker run -d \
    --name mws \
    -p 8585:8585 \
    -e SCRIPTS_LOGGER_LEVEL="1" \
    -e JAVA_MIN_MEM="1g" \
    -e JAVA_MAX_MEM="1g" \
    -e JAVA_OPTS="-server -Dtest=1 -Dtes2=2 -Dtest3=3" \
    -e DB_TYPE="postgresql" \
    -e DB_URL="jdbc:wm:postgresql://postgres:5432;DatabaseName=$POSTGRES_TN_DB" \
    -e DB_USERNAME="$POSTGRES_TN_DBUSER" \
    -e DB_PASSWORD="$POSTGRES_TN_DBPASSWORD" \
    -e SYSADMIN_PASSWORD="$MWS_ADMIN_PASSWORD" \
    -e POST_STARTUP_COMMANDS="ls -al; echo \"testing!\"" \
    -v mws_data:/opt/softwareag/MWS/volumes/data \
    -v mws_logs:/opt/softwareag/MWS/volumes/logs \
    --network ibm_demos_b2b_net \
    amajusag/webmethods-mws:11.1

# Start MSR
echo "Starting MSR..."
docker run -d \
    --name msr \
    --network ibm_demos_b2b_net \
    -p 5555:5555 \
    -v ./application.properties:/opt/softwareag/IntegrationServer/application.properties:ro \
    -e ADMIN_PASSWORD=$MWS_ADMIN_PASSWORD \
    -e JAVA_CUSTOM_OPTS="-server -Dtest=1 -Dtes2=2 -Dtest=3" \
    -e JAVA_MIN_MEM=1g \
    -e JAVA_MAX_MEM=1g \
    -e TN_DB_URL="jdbc:wm:postgresql://postgres:5432;DatabaseName=$POSTGRES_TN_DB" \
    -e TN_DB_USER=$POSTGRES_TN_DBUSER \
    -e TN_DB_PASSWORD=$POSTGRES_TN_DBPASSWORD \
    amajusag/webmethods-msr-b2b:11.1.1
	
echo "All services started successfully!"