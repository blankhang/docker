
# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu

FROM elasticsearch:9.2.3

RUN mkdir -p /tmp/ik && \
    cd /tmp/ik && \
    curl -L -o ik.zip https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-9.2.3.zip && \
    unzip ik.zip -d /usr/share/elasticsearch/plugins/ik && \
    rm ik.zip
