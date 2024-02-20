
# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu


FROM elasticsearch:${ELK_VERSION} AS Baseline

FROM eclipse-temurin:20.0.1_9-jdk


ARG VERSION
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV VERSION=${ELK_VERSION}

WORKDIR /crack

COPY --from=Baseline /usr/share/elasticsearch/lib /usr/share/elasticsearch/lib
COPY --from=Baseline /usr/share/elasticsearch/modules/x-pack-core /usr/share/elasticsearch/modules/x-pack-core
COPY build_crack_jar.sh /crack

RUN apt update && apt install -y zip && apt-get clean
CMD [ "bash", "build_crack_jar.sh" ]