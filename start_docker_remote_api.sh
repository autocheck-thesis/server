#!/usr/bin/env bash

docker run -p 2375:2375 -v /var/run/docker.sock:/var/run/docker.sock --restart unless-stopped -d jarkt/docker-remote-api