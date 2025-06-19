
# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu

ENV ES_VERSION=8.18.1

FROM elasticsearch:${ES_VERSION}


RUN mkdir -p /tmp/ik && \
    cd /tmp/ik && \
    curl -L -o ik.zip https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-${ES_VERSION}.zip && \
    unzip ik.zip -d /usr/share/elasticsearch/plugins/ik && \
    rm ik.zip
