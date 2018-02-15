#!/usr/bin/env bash

# stellar search app config. There here-document is used so that we get
# environment variable expansion
stellar_search_config() {
    cat <<EOF
---
logging:
  level:
    au.com.d2dcrc: DEBUG

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
