#!/bin/sh

docker compose -f docker-compose.yml down -v
docker ps | grep b2b