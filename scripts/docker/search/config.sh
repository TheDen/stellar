#!/usr/bin/env bash

# stellar search app config. There here-document is used so that we get
# environment variable expansion
stellar_search_config() {
    cat <<EOF
---
logging:
  level:
    au.csiro.data61.stellar: DEBUG

spring:

  datasource:
    url: "jdbc:postgresql://db:5432/${STELLAR_SEARCH_DB_NAME}"
    username: "${STELLAR_SEARCH_DB_USERNAME}"
    password: "${STELLAR_SEARCH_DB_PASSWORD}"

security.basic.enabled: false

management:
  security.enabled: false
  info.git.mode: full

elasticsearch.rest-client:
  addresses:
    - elasticsearch:9200
EOF

}

# stellar search postgres db init 'drop-in' config.
stellar_search_db_config() {
    cat <<EOF
CREATE ROLE "${STELLAR_SEARCH_DB_USERNAME}" WITH LOGIN PASSWORD '${STELLAR_SEARCH_DB_PASSWORD}' ;
CREATE DATABASE "${STELLAR_SEARCH_DB_NAME}" ;
GRANT ALL PRIVILEGES ON DATABASE "${STELLAR_SEARCH_DB_NAME}" TO "${STELLAR_SEARCH_DB_USERNAME}" ;
EOF

}

stellar_search_kibana_config() {
    cat <<EOF
---
server.name: kibana
server.host: "0"
elasticsearch.url: http://elasticsearch:9200
EOF
}

stellar_search_elasticsearch_config() {
    cat <<EOF
---
cluster.name: "docker-cluster"
network.host: 0.0.0.0
discovery.zen.minimum_master_nodes: 1
discovery.type: single-node
bootstrap.memory_lock: true
EOF
}
