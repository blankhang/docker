# es8.18.1


```shell
#create data dirs and set up permission
mkdir -p data-kibana
mkdir -p data-elasticsearch
sudo chmod -R 1000:1000 data-*

#run
docker-compose up -d


# run 
docker exec -it [your elasticsearch docker name] bash

# install analysis-ik plugin
mkdir -p /tmp/ik && \
    cd /tmp/ik && \
    curl -L -o ik.zip https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-9.2.3.zip && \
    unzip ik.zip -d /usr/share/elasticsearch/plugins/ik && \
    rm ik.zip

# run to config your es/logstash/kibana/etc... password
/usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

# or run to just config only kibana_system's password
/usr/share/elasticsearch/bin/elasticsearch-reset-password -u kibana_system
```

