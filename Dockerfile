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

# Docker Image for Splunk OTel Collector
FROM quay.io/signalfx/splunk-otel-collector:latest

# ENV SPLUNK_ACCESS_TOKEN= ACCESS Token 
ENV SPLUNK_REALM=us1

EXPOSE 13133 14250 14268 4317 4318 6060 7276 8888 9080 9411 9943

CMD ["splunk-otel-collector"]

# Docker Image for jpetstore
# FROM eclipse-temurin:17-jre

# ADD target/mybatis-spring-boot-jpetstore-2.0.0-SNAPSHOT.jar /app.jar
# ADD ./splunk-otel-javaagent.jar /splunk-otel-javaagent.jar

# ENTRYPOINT java -javaagent:splunk-otel-javaagent.jar -jar app.jar