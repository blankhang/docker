# blankhang/elasticsearch:9.4.4 — 全插件版
# analysis-ik / analysis-pinyin / analysis-stconvert
# 插件：https://release.infinilabs.com/

FROM elasticsearch:9.4.4

# --batch：非交互；URL 安装会按 plugin-descriptor 落到正确目录
RUN bin/elasticsearch-plugin install --batch \
      https://release.infinilabs.com/analysis-ik/stable/elasticsearch-analysis-ik-9.4.4.zip && \
    bin/elasticsearch-plugin install --batch \
      https://release.infinilabs.com/analysis-pinyin/stable/elasticsearch-analysis-pinyin-9.4.4.zip && \
    bin/elasticsearch-plugin install --batch \
      https://release.infinilabs.com/analysis-stconvert/stable/elasticsearch-analysis-stconvert-9.4.4.zip && \
    bin/elasticsearch-plugin list
