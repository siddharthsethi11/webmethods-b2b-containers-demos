Docker Setup
===================

Container-based deployment of webMethods Active Transfer solution, including:
 - Microservice Runtime with Trading Network (B2B) package
 - My WebMethods Server (MWS)
 - DB Configurator Job
 - Postgres DB

Requirements
------------------------------------------------

### Requirement 0: Docker environment

The server should have a functional Docker environment where you can run both "docker" and "docker compose" commands.

__IMPORTANT__: This deployment has been tested with Docker engine only. Using anything else (ie. podman) has not been tested and might require adjustments.

### Requirement 1: Login to Docker registries

You need to get Access to the custom Github Container registry ("sag-gov-integration-unit" container registry) and ability to pull down the images for the pre-built containers for MWS, MFT, DB Configurator... 

Then, in order to pull the containers from the registries, you will need to login to them.

Login to the current Github registry using your github user + "Personal access tokens":

```bash
docker login ghcr.io
```

### Requirement 2: Create Docker Network

We are going to create the network manually - This approach allows you to connect containers defined across multiple docker-compose.yml files to the same network.

```sh
docker network create ibm_demos_b2b_net
```

### Requirement 3: Pull the latest containers

Make sure you have the latest containers...

```sh
sh pull-all.sh
```

Start/Stop the stack - Quick and Easy
------------------------------------------------

Start all the containers and perform initialkization if needed:

```sh
sh start-all.sh
```

Stop containers (don't delete the data in the volumes)

```sh
sh start-all.sh
```

Destroy all containers, including data in the volumes

```sh
sh destroy-all.sh
```


Start the stack - Steps by Steps (This is for first time only)
------------------------------------------------

### Network



### Database backend

NOTE: On first start, it's best to start the stack in controlled order so all the assets are created correctly
Since "docker compose" does not easily offer an easy way to start multiple components in a specific controlled order... let's perform several docker compose operations at first:

```sh
docker compose up -d postgres dbconfig
```

... wait for postgres healthy (docker ps | grep postgres) ...

NOTE 1: the container "dbconfig" is a job... it should have run, setup the tables needed in postgres, and terminated (it's expected)
If you want to check the status or logs for it, run:  
"docker ps -a | grep dbconfig", find the ID, and run "docker logs <dbconfig container id>"

NOTE 2: For postgres admin password, find it in the [.env](.env) file, in the variable POSTGRES_PASSWORD


### MWS backend

Then:

```sh
docker compose up -d mws
```

... wait for healthy (docker ps | grep mws)
NOTE: this will take several minutes, depending on the resources assigned to your docker environment.

### MSR TN

Then:
```
docker compose up -d msr
```

Access the Admin UI
------------------------------------------------

UIs:
- MSR Admin UI: http://localhost:5555
  - User = "Administrator"
  - Password = "SomeNewStrongPassword123!" (Note: find it or change it in the [.env](.env) file in the variable MSR_ADMIN_PASSWORD)
- MWS Admin UI: http://localhost:8585 
  - User = "sysadmin"
  - Password = "SomeNewStrongPassword123!" (Note: find it or change it in the [.env](.env) file in the variable MWS_ADMIN_PASSWORD)

NOTE: replace localhost with the Server's IP if running this stack on a remote server...

## Destroy the stack + keep data

docker compose down

## Destroy the stack + destroy the data too

docker compose down -v
