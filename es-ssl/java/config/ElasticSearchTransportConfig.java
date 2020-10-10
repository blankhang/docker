package com.blankhang.es.config.elasticsearch;

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
