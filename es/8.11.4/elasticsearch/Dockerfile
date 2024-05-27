
# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu


FROM elasticsearch:8.11.4 AS Baseline

FROM eclipse-temurin:21-jdk


ARG VERSION
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV VERSION=${ELK_VERSION}

WORKDIR /crack

COPY --from=Baseline /usr/share/elasticsearch /usr/share/elasticsearch

COPY build_crack_jar.sh /crack

RUN apt update && apt install -y zip && apt-get clean && rm-rf /usr/share/elasticsearch/jdk && mkdir -p /tmp/ik && \
                                                                 cd /tmp/ik && \
                                                                 curl -L -o ik.zip https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-8.11.4.zip && \
                                                                 unzip ik.zip -d /usr/share/elasticsearch/plugins/ik && \
                                                                 rm ik.zip
CMD [ "bash", "build_crack_jar.sh" ]
