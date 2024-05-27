# es8.11.4


```shell
#create data dirs and set up permission
mkdir -p data-kibana
mkdir -p data-elasticsearch
sudo chmod -R 777 data-*

#run
docker-compose up -d


# change password run
docker exec -it [your elasticsearch docker name] bash

# then run to config your es/logstash/kibana/etc... password
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

# or run to just config only kibana_system's password
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system
```

