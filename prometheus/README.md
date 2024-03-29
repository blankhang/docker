# Prometheus + grafana 数据监控平台部署


---
Prometheus 是一个非常流行的开源监控系统，用于监控和报警。它最初由 SoundCloud 开发，并于2012年发布为开源项目。Prometheus 可以收集、存储和查询各种不同类型的指标数据，并提供灵活且强大的查询语言 PromQL 来分析和可视化这些数据。

以下是 Prometheus 的一些主要特点：
1. 多维度数据模型：Prometheus 采用多维度数据模型，使用键值对标识指标，并支持对指标进行标签化。这使得用户可以根据不同的维度对指标进行灵活的查询和聚合。
2. 强大的查询语言：PromQL 是 Prometheus 的查询语言，它提供了丰富的操作符和函数，用于对指标数据进行复杂的查询、聚合和计算。使用 PromQL，用户可以轻松地创建自定义的仪表盘和报警规则。
3. 可视化和告警：Prometheus 提供了内置的图形界面和可视化工具，用于创建仪表盘、图表和报表，帮助用户直观地理解和分析指标数据。同时，Prometheus 还支持自定义报警规则，并能够发送报警通知，及时响应和处理异常情况。
4. 分布式架构和可扩展性：Prometheus 具有分布式架构和水平扩展能力，可以适应大规模环境下的监控需求。它支持多个数据采集节点和存储节点，可以灵活地扩展系统容量和性能。
5. 生态系统和整合性：Prometheus 拥有丰富的生态系统，提供了大量的第三方工具和库，用于与其他系统进行整合和拓展。例如，Grafana 可以与 Prometheus 结合使用，实现更强大的数据可视化和分析功能。

总的来说，Prometheus 是一个功能强大、易于部署和扩展的监控系统，适用于各种规模的应用和基础设施。它通过收集和分析指标数据，帮助用户及时发现、诊断和解决系统中的问题，提升系统的可靠性和性能。


---
快速部署
当前服务器IP为 192.168.50.11
当前目录为 /docker/docker-stack/prometheus/  

代码在 https://github.com/blankhang/docker/tree/master/prometheus

请将 docker-stack.yml中的`node.hostname`修改为你自己想要部署的节点名

```yaml
version: '3.9'

x-logging:
  &default-logging
  driver: "json-file"
  options:
    max-size: "1m"
    max-file: "1"
    tag: "{{.Name}}"

services:

  cadvisor:
    image: gcr.io/cadvisor/cadvisor
    container_name: cadvisor
    restart: unless-stopped
    privileged: true
    deploy:
      mode: global
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:rw
      - /sys:/sys:ro
      - /var/lib/docker:/var/lib/docker:ro
      # https://github.com/google/cadvisor/issues/1565#issuecomment-718812180
      - /var/run/docker.sock:/var/run/docker.sock
      #- /dev/disk:/dev/disk:ro
    ports:
      - 8080:8080
    networks:
      - monitoring
    logging: *default-logging

  node-exporter:
    image: prom/node-exporter
    container_name: node-exporter
    restart: unless-stopped
    deploy:
      mode: global
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.ignored-mount-points'
      - "^/(sys|proc|dev|host|etc|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs)($$|/)"
    ports:
      - 9100:9100
    networks:
      - monitoring
    logging: *default-logging

  mysql-exporter:
    image: prom/mysqld-exporter
    container_name: mysql-exporter
    restart: unless-stopped
    deploy:
      placement:
        constraints:
          - 'node.hostname == vm-ubuntu-11'
    #environment:
    # NOT WORKING wi
    #  - DATA_SOURCE_NAME="root:root@(192.168.50.11:3306)/"
    volumes:
      - /docker/docker-stack/prometheus/configs/mysql-exporter/my.cnf:/.my.cnf
    command: --config.my-cnf=/.my.cnf
    depends_on:
      - alertmanager
    ports:
      - 9104:9104
    networks:
      - monitoring
    logging: *default-logging

  redis-exporter:
    image: oliver006/redis_exporter
    container_name: redis-exporter
    restart: unless-stopped
    command:
      - "-redis.password-file=/redis_passwd.json"
    deploy:
      placement:
        constraints:
          - 'node.hostname == vm-ubuntu-11'
    #environment:
    #  - REDIS_ADDR=192.168.50.11:6379
    volumes:
      - /docker/docker-stack/prometheus/configs/redis-exporter/redis_passwd.json:/redis_passwd.json
    depends_on:
      - alertmanager
    ports:
      - 9121:9121
    networks:
      - monitoring
    logging: *default-logging

  grafana:
    image: grafana/grafana
    container_name: grafana
    restart: unless-stopped
    user: "0"
    deploy:
      placement:
        constraints:
          - 'node.hostname == vm-ubuntu-11'
    environment:
      - GF_AUTH_ANONYMOUS_ENABLED=true
      - GF_AUTH_ANONYMOUS_ORG_ROLE=Admin
      - GF_USERS_DEFAULT_THEME=dark
      - GF_LOG_MODE=console
      - GF_LOG_LEVEL=critical
      - GF_PANELS_ENABLE_ALPHA=true
      - GF_INSTALL_PLUGINS=grafana-polystat-panel
    volumes:
      - /docker/docker-stack/prometheus/configs/grafana/provisioning/dashboards.yml:/etc/grafana/provisioning/dashboards/provisioning-dashboards.yaml:ro
      - /docker/docker-stack/prometheus/configs/grafana/provisioning/datasources.yml:/etc/grafana/provisioning/datasources/provisioning-datasources.yaml:ro
      - /docker/docker-stack/prometheus/dashboards/node-metrics.json:/var/lib/grafana/dashboards/node-metrics.json:ro
      - /docker/docker-stack/prometheus/dashboards/container-metrics.json:/var/lib/grafana/dashboards/container-metrics.json:ro
      - /docker/docker-stack/prometheus/grafana-data:/var/lib/grafana
    depends_on:
      - prometheus
    ports:
      - 3000:3000
    networks:
      - monitoring
    logging: *default-logging

  alertmanager:
    image: prom/alertmanager
    container_name: alertmanager
    deploy:
      placement:
        constraints:
          - 'node.hostname == vm-ubuntu-11'
    command:
      - '--config.file=/etc/alertmanager/config.yml'
      - '--log.level=error'
      - '--storage.path=/alertmanager'
      - '--web.external-url=http://localhost:9093'
    volumes:
      - /docker/docker-stack/prometheus/configs/alertmanager/alertmanager-fallback-config.yml:/etc/alertmanager/config.yml
    ports:
      - 9093:9093
    networks:
      - monitoring
    logging: *default-logging


  prometheus:
    image: prom/prometheus
    container_name: prometheus
    restart: unless-stopped
    user: "0"
    deploy:
      placement:
        constraints:
          - 'node.hostname == vm-ubuntu-11'
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--log.level=error'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=7d'
      - '--web.console.libraries=/usr/share/prometheus/console_libraries'
      - '--web.console.templates=/usr/share/prometheus/consoles'
      - '--web.external-url=http://localhost:9090'
    volumes:
      - /docker/docker-stack/prometheus/configs/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - /docker/docker-stack/prometheus/configs/prometheus/recording-rules.yml:/etc/prometheus/recording-rules.yml
      - /docker/docker-stack/prometheus/configs/prometheus/alerting-rules.yml:/etc/prometheus/alerting-rules.yml
      - /docker/docker-stack/prometheus/prometheus-data:/prometheus
    depends_on:
      - alertmanager
    ports:
      - 9090:9090
    networks:
      - monitoring
    logging: *default-logging


networks:
  monitoring:
    driver: overlay
```

配置`prometheus`核心配置文件 https://github.com/blankhang/docker/blob/master/prometheus/configs/prometheus/prometheus.yml
```yaml
global:
  scrape_interval: 60s # Set the scrape interval to every 5 seconds. Default is every 1 minute.
  evaluation_interval: 60s # Evaluate rules every 15 seconds. The default is every 1 minute.
# scrape_timeout is set to the global default (10s).  
  external_labels:
    namespace: local

rule_files:
  - /etc/prometheus/recording-rules.yml
  - /etc/prometheus/alerting-rules.yml

alerting:
  alertmanagers:
    - scheme: http
      static_configs:
        - targets: ['alertmanager:9093']

scrape_configs:
  - job_name: prometheus
    static_configs:
      - targets: [ 'localhost:9090' ]
        labels:
          container: 'prometheus'

  - job_name: alertmanager
    static_configs:
      - targets: [ 'alertmanager:9093' ]
        labels:
          container: 'alertmanager'

  - job_name: node-exporter
    static_configs:
      - targets: 
        - '192.168.50.11:9100'
        - '192.168.50.12:9100'
        - '192.168.50.13:9100'
        - '192.168.50.14:9100'
        - '192.168.50.15:9100'

  - job_name: cadvisor
    static_configs:
      - targets:
        - '192.168.50.11:8080'
        - '192.168.50.12:8080'
        - '192.168.50.13:8080'
        - '192.168.50.14:8080'
        - '192.168.50.15:8080'

  - job_name: mysql-exporter
    static_configs: 
      - targets: [ '192.168.50.11:9104' ] 
        # labels: 
        #   instance: 'mysql-exporter'

  - job_name: redis-exporter
    # https://github.com/oliver006/redis_exporter/blob/master/README.md
    #redis grafana dashboard id 763
    static_configs:
      - targets: 
        - 'redis://192.168.50.11:6379'
    metrics_path: /scrape        
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: 192.168.50.11:9121

  - job_name: minio
    # minio grafana dashboard id 13502
    # https://grafana.com/grafana/dashboards/13502-minio-dashboard/
    # see more
    # https://github.com/minio/minio/blob/master/docs/metrics/prometheus/README.md
    # MinIO deployments started with MINIO_PROMETHEUS_AUTH_TYPE set to "public" can omit the bearer_token field. 
    #bearer_token: TOKEN
    metrics_path: /minio/v2/metrics/cluster
    scrape_interval: 60s
    params:
      format: [ 'prometheus' ]    
    scheme: http
    tls_config:
      insecure_skip_verify: true
    static_configs:
      - targets:
        - '192.168.50.11:9000'
        - '192.168.50.12:9000'
        - '192.168.50.13:9000'
        - '192.168.50.14:9000'

  - job_name: jenkins
    # https://grafana.com/grafana/dashboards/9964-jenkins-performance-and-health-overview/
    # dashboard id 9964
    # jenkins need install https://plugins.jenkins.io/prometheus/ first
    # http://<jenkinsIP>:<Port>/prometheus/
    metrics_path: /prometheus
    scheme: http
    static_configs:
      - targets:
        - '192.168.50.11:8888'

  - job_name: emqx
    # https://grafana.com/grafana/dashboards/17446-emqx/
    # dashboard id 17446
    metrics_path: /api/v5/prometheus/stats
    scrape_interval: 60s
    honor_labels: true
    static_configs:
      # EMQX IP address and port
      - targets: ['192.168.50.11:18083']

  #- job_name: nginx
  #nginx grafana dashboard id 9614
  

  - job_name: nacos
    # dashboard id 13221
    scrape_interval: 60s
    metrics_path: '/nacos/actuator/prometheus'
    static_configs:
      - targets: ['192.168.50.11:8848']
        labels:
          instance: nacos


  - job_name: springboot-wifi
    # dashboard id 4701
    scrape_interval: 60s
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['192.168.50.2:9100']
```


创建 mysql exporter 监控账号   
mysql5.7
```mysql
# 创建名为 'exporter' 的用户，并指定该用户仅能从本地主机 (localhost) 连接到数据库。密码为 'exporter'。
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'exporter' WITH MAX_USER_CONNECTIONS 3;

# 授予 'exporter' 用户 PROCESS 和 REPLICATION CLIENT 权限，以便该用户可以查看进程列表和执行复制相关操作。
GRANT PROCESS, REPLICATION CLIENT TO 'exporter'@'localhost';

# 授予 'exporter' 用户对 performance_schema 数据库的 SELECT 权限，以允许该用户查询性能相关的信息。
GRANT SELECT ON performance_schema.* TO 'exporter'@'localhost';

# 授予 'exporter' 用户对 information_schema 数据库的 SELECT 权限，以允许该用户查询数据库的元数据信息。
GRANT SELECT ON information_schema.* TO 'exporter'@'localhost';
```
mysql8
```mysql
# 创建名为 'exporter' 的用户，并指定该用户仅能从本地主机 (localhost) 连接到数据库。密码为 'exporter'。
CREATE USER 'exporter'@'localhost' IDENTIFIED BY 'exporter';
ALTER USER 'exporter'@'localhost' WITH MAX_USER_CONNECTIONS 3;

# 授予 'exporter' 用户 PROCESS 和 REPLICATION CLIENT 权限，以便该用户可以查看进程列表和执行复制相关操作。
GRANT PROCESS, REPLICATION CLIENT ON *.* TO 'exporter'@'localhost';

# 授予 'exporter' 用户对 performance_schema 数据库的 SELECT 权限，以允许该用户查询性能相关的信息。
GRANT SELECT ON performance_schema.* TO 'exporter'@'localhost';

# 授予 'exporter' 用户对 information_schema 数据库的 SELECT 权限，以允许该用户查询数据库的元数据信息。
GRANT SELECT ON information_schema.* TO 'exporter'@'localhost';
```
修改`/configs/mysql-exporter/my.cnf` 文件，改成你的mysql的 ip、端口以及上面刚配置的用户名、密码。
```
[client]
host=192.168.50.11
port=3306
user=exporter
password=exporter
```
修改`/configs/redis-exporter/redis_passwd.json` json配置文件，改成你的redis的 ip、端口、密码 无密码留空。
```json
{
  "redis://192.168.50.11:6379":""
}
```
支持多节点配置
```json
{
  "redis://NODE1IP:PORT":"PWD",
  "redis://NODE2IP:PORT":"PWD",
  "redis://NODE3IP:PORT":"PWD"
}
```


执行 [start-prometheus-stack.sh](https://github.com/blankhang/docker/blob/master/prometheus/start-prometheus-stack.sh)
```shell
docker stack deploy --resolve-image always -c prometheus-stack.yml prometheus-stack

```

grafana 的`模板id`在此配置文件的注释中有 也可以去grafana官网搜索
https://github.com/blankhang/docker/blob/master/prometheus/configs/prometheus/prometheus.yml

访问 prometheus
http://192.168.50.11:9090/targets 
将会显示所有配置在`configs/prometheus/prometheus.yml`服务的状态

![prometheus-targets](https://github.com/blankhang/docker/assets/3981276/bc2a8644-d652-4b53-9631-aae3e07c7817)

### 然后配置 grafana
http://192.168.50.11:3000/
1. 配置 dashboard 点击右上角 选择  Import dashboard  
2. 输入模板ID 如 redis的模板 763 点击 Load
3. 访问 dashboard 查看监控效果

redis模板 763
![prometheus-grafana-redis-dashboard](https://github.com/blankhang/docker/assets/3981276/29ce79d1-b2dd-4749-ba0f-2c3a2447a136)

minio模板 13502
![prometheus-grafana-minio-dashboard](https://github.com/blankhang/docker/assets/3981276/e040de4b-8a10-42a2-ba0f-230d23e70abd)

nacos模板 13221
![prometheus-grafana-nacos-dashboard](https://github.com/blankhang/docker/assets/3981276/e474b1f6-e3ca-49ba-bbc4-a5ecb90909cd)

linux host模板 12633
![prometheus-grafana-linux-host-dashboard](https://github.com/blankhang/docker/assets/3981276/dec2e93e-850b-4e4c-be39-9e15cd71b2b9)

jvm模板 4701  
jvm项目pom中添加如下依赖
```pom
        <!--这个依赖用于把数据转换为prometheus格式使用-->
        <!-- https://mvnrepository.com/artifact/io.micrometer/micrometer-registry-prometheus -->
        <dependency>
            <groupId>io.micrometer</groupId>
            <artifactId>micrometer-registry-prometheus</artifactId>
            <version>1.11.0</version>
        </dependency>
```
然后springboot中security配置需要放行 prometheus url
```java
/**
 * spring security配置
 *
 * @author blank
 */
@EnableGlobalMethodSecurity(prePostEnabled = true, securedEnabled = true)
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    
    @Override
    protected void configure (HttpSecurity httpSecurity) throws Exception { 
        httpSecurity.antMatchers("/actuator/prometheus").permitAll();
    }
}
```
![prometheus-grafana-jvm-dashboard](https://github.com/blankhang/docker/assets/3981276/81fad8fb-970b-45a1-aaeb-d5997d0dcb9c)

