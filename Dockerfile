#
#    Copyright 2016-2024 the original author or authors.
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

# Build the first image
FROM eclipse-temurin:17-jre AS app-image
ADD target/mybatis-spring-boot-jpetstore-2.0.0-SNAPSHOT.jar /app.jar
ADD opentelemetry-javaagent.jar /opentelemetry-javaagent.jar
ENTRYPOINT ["java", "-javaagent:/opentelemetry-javaagent.jar", "-jar", "/app.jar"]

# Build the second image
FROM otel/opentelemetry-collector-contrib:latest AS otel-image
WORKDIR /etc/otelcol-contrib
COPY otel-config.yaml /etc/otelcol-contrib/config.yaml