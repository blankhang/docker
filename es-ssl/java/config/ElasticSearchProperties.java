package com.renice.web.config.elasticsearch;

import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.HashMap;
import java.util.Map;

/**
 * ElasticSearchProperties
 *
 * @author blank
 * @since 2019-10-08 下午 12:05
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
