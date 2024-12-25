#!/bin/sh

docker compose -f docker-compose.yml down
docker ps | grep b2b