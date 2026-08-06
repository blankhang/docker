# Add your elasticsearch plugins setup here
# Example: RUN elasticsearch-plugin install analysis-icu
#
# IK 需与 ES 对齐；若构建 404，见 https://release.infinilabs.com/analysis-ik/stable/

FROM elasticsearch:9.5.0

RUN mkdir -p /tmp/ik && \
    cd /tmp/ik && \
    curl -L -o ik.zip https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-9.5.0.zip && \
    unzip ik.zip -d /usr/share/elasticsearch/plugins/ik && \
    rm ik.zip
