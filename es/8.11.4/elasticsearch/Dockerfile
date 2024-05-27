
# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu


FROM elasticsearch:8.11.4


RUN apt update && apt install -y zip && apt-get clean && mkdir -p /tmp/ik && \
                                                                 cd /tmp/ik && \
                                                                 curl -L -o ik.zip https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-8.11.4.zip && \
                                                                 unzip ik.zip -d /usr/share/elasticsearch/plugins/ik && \
                                                                 rm ik.zip
