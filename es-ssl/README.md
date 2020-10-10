# Docker elasticsearch with certificates
### 创建 es 数据目录
### Create elasticsearch data directory
```shell script
# 所有 es 相关的数据将存储于 /docker/es 下
# All elasticsearch data will be store in /docker/es
mkdir -p /docker/es/certs &&
mkdir -p /docker/es/data/es01 &&
mkdir -p /docker/es/data/es02 &&
mkdir -p /docker/es/data/es03 &&
mkdir -p /docker/es/logs/es01 &&
mkdir -p /docker/es/logs/es02 &&
mkdir -p /docker/es/logs/es03
```

### 给数据目录授权
### Authorize the data directory
```shell script
chmod 777 -R /docker/es/certs /docker/es/data /docker/es/logs
```

### 运行临时 es 容器用来创建证书
### Run temporary elasticsearch container to create certificate files
```shell script
docker run -dit --name=es elasticsearch:6.8.10 /bin/bash

# 进入 es 容器内部
# Into the es container
docker exec -it es /bin/bash

# 生成 ca 文件: elastic-stack-ca.p12 全部回车空密码
# Generate ca file: elastic-stack-ca.p12 All questions directly press Enter
bin/elasticsearch-certutil ca

# 然后使用 ca 生成 cert 文件: elastic-certificates.p12 全部回车空密码
# Then use ca to generate the cert file: elastic-certificates.p12  All questions directly press Enter
bin/elasticsearch-certutil cert --ca elastic-stack-ca.p12

# 退出容器
# Exit container
exit
```
### 将证书从容器内复制到宿主机 /docker/es/certs
### Copy the certificate from the container to the host docker/es/certs
```shell script
docker cp es:/usr/share/elasticsearch/elastic-certificates.p12 /docker/es/certs
```
### 关闭 清理临时 es 容器
### Close clean up temporary es container
```shell script
docker kill es && docker rm es
```


### 创建 .env 变量配置文件
### Create .env variable configuration file
```shell script
echo '
# es 容器内的证书存储位置
# certificate storage location in elasticsearch container
CERTS_DIR=/usr/share/elasticsearch/config/certificates
# elastic 用户的密码, 请在修改后再进行下面的操作!
# Elastic user's password, please perform the following operations after modification!
ELASTIC_PASSWORD=pleaseChangeMe
' > /docker/es/.env
```

###　创建 instances.yml 文件
###　Create instances.yml file
```shell script
echo "
instances:
  - name: es01
    dns:
      # es容器的dns名
      - es01
      - localhost
    ip:
      # 使用IP访问时此处要改成调用容器的IP
      # 不一定是容器自身的IP, 而是各个服务进行调用的IP
      # 否则证书认证将无法通过
      # 可填多个IP
      - 127.0.0.1

  - name: es02
    dns:
      - es02
      - localhost
    ip:
      # 使用IP访问时此处要改成调用容器的IP
      # 不一定是容器自身的IP, 而是各个服务进行调用的IP
      # 否则证书认证将无法通过
      # 可填多个IP
      - 127.0.0.1

  - name: es03
    dns:
      - es03
      - localhost
    ip:
      # 使用IP访问时此处要改成调用容器的IP
      # 不一定是容器自身的IP, 而是各个服务进行调用的IP
      # 否则证书认证将无法通过
      # 可填多个IP
      - 127.0.0.1
" > /docker/es/instances.yml
```

### 创建 create-certs.yml
### Create create-certs.yml
```shell script
echo "
version: '2.2'

services:
  create_certs:
    container_name: create_certs
    image: docker.elastic.co/elasticsearch/elasticsearch:6.8.10
    command: >
      bash -c '
        if [[ ! -d config/certificates/certs ]]; then
          mkdir config/certificates/certs;
        fi;
        if [[ ! -f /local/certs/bundle.zip ]]; then
          bin/elasticsearch-certgen --silent --in config/certificates/instances.yml --out config/certificates/certs/bundle.zip;
          # 将新生成的证书文件放到"config/certificates/certs"
          unzip config/certificates/certs/bundle.zip -d config/certificates/certs; 
        fi;
        chgrp -R 0 config/certificates/certs
      '
    # user: ${UID:-1000}
    user: root
    working_dir: /usr/share/elasticsearch
    volumes: ['.:/usr/share/elasticsearch/config/certificates']
" > /docker/es/create-certs.yml
```

这个生成的 elastic-certificates.p12 就是我们需要使用的
This generated elastic-certificates.p12 is what we need to use
### 创建 es docker-compose.yml 文件
### Create es docker-compose.yml file
```shell script
cat > /docker/es/docker-compose.yml <<\EOF

version: '2.2'

services:
  es01:
    container_name: es01
    image: docker.elastic.co/elasticsearch/elasticsearch:6.8.10
    restart: always
    # 生产环境建议设置ulimits
    # It is recommended to set ulimits in production environment
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
      nproc:
        soft: 65536
        hard: 65536
    environment:
      - cluster.name=es
      - node.name=es01
      - node.master=true
      - node.data=true
      - transport.tcp.port=9300
      
      # 生产环境建议开启
      # Production environment recommended to open
      - bootstrap.memory_lock=true
      - bootstrap.system_call_filter=false
      - discovery.zen.minimum_master_nodes=2
      # elastic用户的密码, 需要在".env"文件中修改
      # The password of the elastic user needs to be modified in the ".env" file before use in production environment
      - ELASTIC_PASSWORD=$ELASTIC_PASSWORD
      - 'ES_JAVA_OPTS=-Xms256m -Xmx256m'
      - xpack.security.enabled=true
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.truststore.type=PKCS12
      - xpack.security.transport.ssl.keystore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.transport.ssl.truststore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.keystore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.http.ssl.truststore.path=$CERTS_DIR/elastic-certificates.p12
    volumes:  
      - /docker/es/certs:$CERTS_DIR
      - /docker/es/data/es01:/usr/share/elasticsearch/data
      - /docker/es/logs/es01:/usr/share/elasticsearch/logs  
    ports:
      - 9200:9200
      - 9300:9300
    healthcheck:
      test: curl --cacert $CERTS_DIR/ca/ca.crt -s https://localhost:9200 >/dev/null; if [[ $$? == 52 ]]; then echo 0; else echo 1; fi
      interval: 30s
      timeout: 10s
      retries: 5

  es02:
    container_name: es02
    image: docker.elastic.co/elasticsearch/elasticsearch:6.8.10
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
      nproc:
        soft: 65536
        hard: 65536
    environment:
      - cluster.name=es
      - node.name=es02
      - bootstrap.memory_lock=true
      - bootstrap.system_call_filter=false
      - discovery.zen.minimum_master_nodes=2
      - ELASTIC_PASSWORD=$ELASTIC_PASSWORD
      - discovery.zen.ping.unicast.hosts=es01
      - 'ES_JAVA_OPTS=-Xms256m -Xmx256m'
      - xpack.security.enabled=true
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.truststore.type=PKCS12
      - xpack.security.transport.ssl.keystore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.transport.ssl.truststore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.keystore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.http.ssl.truststore.path=$CERTS_DIR/elastic-certificates.p12
    volumes:  
      - /docker/es/certs:$CERTS_DIR
      - /docker/es/data/es02:/usr/share/elasticsearch/data
      - /docker/es/logs/es02:/usr/share/elasticsearch/logs      

  es03:
    container_name: es03
    image: docker.elastic.co/elasticsearch/elasticsearch:6.8.10
    restart: always
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
      nproc:
        soft: 65536
        hard: 65536
    environment:
      - cluster.name=es
      - node.name=es03
      - bootstrap.memory_lock=true
      - bootstrap.system_call_filter=false
      - discovery.zen.minimum_master_nodes=2
      - ELASTIC_PASSWORD=$ELASTIC_PASSWORD
      - discovery.zen.ping.unicast.hosts=es01
      - 'ES_JAVA_OPTS=-Xms256m -Xmx256m'
      - xpack.security.enabled=true
      - xpack.security.transport.ssl.enabled=true
      - xpack.security.transport.ssl.verification_mode=certificate
      - xpack.security.transport.ssl.truststore.type=PKCS12
      - xpack.security.transport.ssl.keystore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.transport.ssl.truststore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.http.ssl.enabled=true
      - xpack.security.http.ssl.keystore.path=$CERTS_DIR/elastic-certificates.p12
      - xpack.security.http.ssl.truststore.path=$CERTS_DIR/elastic-certificates.p12
    volumes:
      - /docker/es/certs:$CERTS_DIR
      - /docker/es/data/es03:/usr/share/elasticsearch/data
      - /docker/es/logs/es03:/usr/share/elasticsearch/logs   

  wait_until_ready:
    image: docker.elastic.co/elasticsearch/elasticsearch:6.8.10
    command: /usr/bin/true
    depends_on: { 'es01': { 'condition': 'service_healthy' } }
EOF
```

### 生成证书
### Generate certificate
```shell script
cd /docker/es/ && docker-compose -f create-certs.yml up

Pulling create_certs (docker.elastic.co/elasticsearch/elasticsearch:6.8.10)...
6.8.10: Pulling from elasticsearch/elasticsearch
Digest: sha256:f8e21f6b2ef75dcda374da505fcb0ff4bf7e8d025f12096c498123fa4e372c1b
Status: Downloaded newer image for docker.elastic.co/elasticsearch/elasticsearch:6.8.10
Creating create_certs ... done
Attaching to create_certs
create_certs    | Archive:  config/certificates/certs/bundle.zip
create_certs    |    creating: config/certificates/certs/ca/
create_certs    |   inflating: config/certificates/certs/ca/ca.crt  
create_certs    |   inflating: config/certificates/certs/ca/ca.key  
create_certs    |    creating: config/certificates/certs/es01/
create_certs    |   inflating: config/certificates/certs/es01/es01.crt  
create_certs    |   inflating: config/certificates/certs/es01/es01.key  
create_certs    |    creating: config/certificates/certs/es02/
create_certs    |   inflating: config/certificates/certs/es02/es02.crt  
create_certs    |   inflating: config/certificates/certs/es02/es02.key  
create_certs    |    creating: config/certificates/certs/es03/
create_certs    |   inflating: config/certificates/certs/es03/es03.crt  
create_certs    |   inflating: config/certificates/certs/es03/es03.key  
create_certs exited with code 0
```
### 给生成的证书文件修改访问权限
### Modify the access permissions for the generated certificate file
```shell script
chmod 777 -R /docker/es/certs 
```

### 通过 docker-compose 启动 es
### Start elasticsearch via docker-compose
```shell script
cd /docker/es && docker-compose up -d
```

---
# SpringBoot java client elasticsearch configuration
### 将服务器上生成的证书 elastic-certificates.p12 复制到 resources 目录中
### Copy the certificate elastic-certificates.p12 generated on the server to the resources directory

### 配置 Maven pom.xml 添加 es springboot-starter 依赖
### Configure Maven pom.xml to add elasticsearch springboot-starter dependency
```shell script
<!-- https://mvnrepository.com/artifact/org.springframework.boot/spring-boot-starter-data-elasticsearch -->
    <dependency>
      <groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-elasticsearch</artifactId>
    </dependency>
```

### 配置 application.yml
### Configure application.yml
```shell script
spring:
  data:
    elasticsearch:
      repositories:
        enabled: true
      user: elastic
      password: plelaseChangeMe
      cluster-name: es
      host: YOU_SERVER_IP
      tcpPort: 9300
      httpPort: 9200
      schema: https
      pckCertificatesPath: elastic-certificates.p12
      certificatesType: pkcs
      pkcsClientFilePath: elastic-certificates.p12
```
### 配置 ElasticSearchProperties.java
### Configure ElasticSearchProperties.java
```java
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.HashMap;
import java.util.Map;

/**
 * ElasticSearchProperties
 *
 * @author blank
 * @since 2020-07-02 下午 12:05
 **/
@ConfigurationProperties(prefix = "spring.data.elasticsearch")
@Data
public class ElasticSearchProperties {
    private String clusterName;
    private String host;
    private String schema;
    private int tcpPort;
    private int httpPort;
    private String user;
    private String password;
    private String pckCertificatesPath;
    private String certificatesType;
    private String pkcsClientFilePath;
    private Map<String, String> properties = new HashMap<>();
}
```
### 配置 ElasticSearchTransportConfig.java
### Configure ElasticSearchTransportConfig.java
```java
import lombok.extern.slf4j.Slf4j;
import org.elasticsearch.client.transport.TransportClient;
import org.elasticsearch.common.lease.Releasable;
import org.elasticsearch.common.settings.Settings;
import org.elasticsearch.common.transport.TransportAddress;
import org.elasticsearch.xpack.client.PreBuiltXPackTransportClient;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.elasticsearch.core.ElasticsearchTemplate;
import org.springframework.util.ReflectionUtils;

import javax.annotation.Resource;
import java.net.InetAddress;
import java.net.URISyntaxException;
import java.net.UnknownHostException;
import java.nio.file.Paths;

/**
 * ES配置
 *
 * @author blank
 * @since 2019-10-08 上午 11:49
 **/
@Slf4j
@EnableConfigurationProperties(ElasticSearchProperties.class)
@Configuration
public class ElasticSearchTransportConfig implements DisposableBean {

    @Resource
    private ElasticSearchProperties properties;

    private Releasable releasable;

    /**
     * TransportClient 只支持到 6.X 版本的 ES 后面 7.X 不推荐 需要使用 RestClient
     * 而 springboot data es 整合的又是 TransportClient 如果 直接用 RestClient 改动量太大
     * https://blog.csdn.net/taoli1986/article/details/83818188
     * https://segmentfault.com/a/1190000022102940
     */
    @Bean
    public TransportClient getTransportClient() throws UnknownHostException, URISyntaxException {
        log.info("init TransportClient");
        String path = Paths.get(getClass().getClassLoader().getResource(properties.getPckCertificatesPath()).toURI()).toString();
        TransportClient client = new PreBuiltXPackTransportClient(Settings.builder()
                .put("cluster.name", properties.getClusterName())
                // missing authentication credentials for action
                .put("xpack.security.user", String.format("%s:%s", properties.getUser(), properties.getPassword()))
                .put("xpack.security.transport.ssl.enabled", true)
                .put("xpack.security.transport.ssl.verification_mode", "certificate")
                .put("xpack.security.transport.ssl.keystore.path", path)
                .put("xpack.security.transport.ssl.truststore.path", path)
                .build()).addTransportAddress(new TransportAddress(InetAddress.getByName(properties.getHost()), properties.getTcpPort()));
        log.info("=======================");
        log.info("==   init ES   ==");
        log.info("=======================");
        return client;
    }

    @Bean
    public ElasticsearchTemplate elasticsearchTemplate() throws Exception {
        return new ElasticsearchTemplate(getTransportClient());
    }

    /**
     * 重写销毁方法调用关闭连接
     *
     * @author blank
     * @date 2019-10-9 上午 9:29
     */
    @Override
    public void destroy() {
        if (this.releasable != null) {
            try {
                if (log.isInfoEnabled()) {
                    log.info("Closing Elasticsearch client");
                }
                try {
                    this.releasable.close();
                } catch (NoSuchMethodError ex) {
                    // Earlier versions of Elasticsearch had a different method
                    // name
                    ReflectionUtils.invokeMethod(ReflectionUtils.findMethod(Releasable.class, "release"), this.releasable);
                }
            } catch (final Exception ex) {
                if (log.isErrorEnabled()) {
                    log.error("Error closing Elasticsearch client: ", ex);
                }
            }
        }
    }
}

```