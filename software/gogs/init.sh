#!/bin/bash

# create gogs local data store directory
mkdir  -p /docker/gogs/{data,log}
chmod 755 /docker/gogs/{data,log}

# create gogs's docker-compose file
cat << 'EOF' > /docker/gogs/docker-compose.yml
version: '3.8'

services:
  gogs:
    image: gogs/gogs
    container_name: gogs
    restart: always
    #privileged: true
    healthcheck:
      test: curl -s https://localhost:3000 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 5s
      timeout: 10s
      retries: 3
    environment:
      TZ: "Asia/Shanghai"
    volumes:
      - "./gogs_data:/data"
      - "./gogs_log:/var/log/gogs"
    ports:
      - "3000:3000"
EOF

# create gogs start script
cat << 'EOF' > /docker/gogs/start.sh
#!/bin/bash

# start gogs docker
docker-compose -f /docker/gogs/docker-compose.yml up -d
EOF
# make start.sh runnable
chmod +x /docker/gogs/start.sh


echo 'gogs init success'
echo -e "\033[36m you can now start gogs via start.sh \033[0m"
