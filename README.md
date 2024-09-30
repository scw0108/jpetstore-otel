# jpetstore-otel

This application is a web application modified by [JPetStore](https://github.com/kazuki43zoo/mybatis-spring-boot-jpetstore) Spring Boot version to demonstrate [OpenTelemetry](https://opentelemetry.io/docs/). 

The application is deployed on GCP Cloud Run, where it includes an OpenTelemetry Collector that collects telemetry data and sends it to [Splunk Observability Cloud](https://www.splunk.com/en_us/products/observability-cloud.html) for monitoring. Additionally, it utilizes Splunk RUM (Real User Monitoring) and APM (Application Performance Monitoring) to enhance visibility into user interactions and application performance.

We will walk through this sample to understand how is it built and learn how to run it.

## Requirements

* Java 11+

## Stacks

* MyBatis Spring Boot Starter 2.2 (MyBatis 3.5, MyBatis Spring 2.0)
* Spring Boot 2.7 (Spring Framework 5.3, Spring Security 5.7)
* Thymeleaf 3.0
* Hibernate Validator 6.2 (Bean Validation 2.0)
* HSQLDB 2.5 (Embed Database)
* Flyway 8.5 (DB Migration)
* Tomcat 9.0 (Embed Application Server)
* Groovy 4.0 (Use multiple line string on MyBatis Mapper method)
* Lombok 1.18
* Selenide 6.5
* Selenium 4.1
* OpenTelemetry 1.28.0
* etc ...

## Build an application image 
### RUM Config
To send data to Splunk Observability Cloud's Real User Monitoring (RUM), each HTML file needs to include the following sections:
#### Initialize the Splunk RUM Library:
``` html
<script src="https://cdn.signalfx.com/o11y-gdi-rum/v0.18.0/splunk-otel-web.js" crossorigin="anonymous"></script>
<script>
    SplunkRum.init({
        realm: "us1",
        rumAccessToken: "<Your RUM Token>",
        applicationName: "jpetstore-otel-demo",
        deploymentEnvironment: "lab",
        debug: true
    });
</script>
```
#### Add Session Recording Functionality:
```html
<script src="https://cdn.signalfx.com/o11y-gdi-rum/v0.18.0/splunk-otel-web-session-recorder.js" crossorigin="anonymous"></script>
<script>
    SplunkSessionRecorder.init({
        app: "jpetstore-otel-demo",
        realm: "us1",
        rumAccessToken: "<Your RUM Token>"
    });
</script>
```
### Create Jar File
```
$ ./mvnw clean package -DskipTests=true
```
### Build Docker Image
This section outlines how to build the Docker image using a Java agent for sending telemetry data.
#### Download Splunk Agent Jar
[splunk-otel-javaagent.jar](https://github.com/signalfx/splunk-otel-java/releases/tag/v2.7.0)
#### Dockerfile
```dockerfile
FROM eclipse-temurin:17-jre

# Add the Spring Boot application JAR to the container
ADD target/mybatis-spring-boot-jpetstore-2.0.0-SNAPSHOT.jar /app.jar

# Add the Splunk OpenTelemetry Java agent JAR to the container
ADD ./splunk-otel-javaagent.jar /splunk-otel-javaagent.jar

# Set the entry point for the container, including the Java agent for sending data
ENTRYPOINT ["java", "-javaagent:splunk-otel-javaagent.jar", "-jar", "/app.jar"]
```

## OpenTelemetry Collector
### First Version
In this version, I manually configure the collector. You can find the configuration details in the [otel-config.yaml](https://github.com/scw0108/jpetstore-otel/blob/master/otel-config.yaml)
#### Receivers
* otlp
#### Exporters
* sapm
``` yaml
access_token: # Token
access_token_passthrough: true
endpoint: # https://ingest.us1.signalfx.com/v2/trace
max_connections: 100
num_workers: 8
log_detailed_response: true
```
* signalfx:
```yaml
access_token: # Token
realm: us1
api_url: # https://api.us1.signalfx.com
ingest_url: # https://ingest.us1.signalfx.com
sync_host_metadata: true
```
#### Service
```yaml
traces:
    receivers: [otlp]
    processors: [memory_limiter, batch, filter/drop_actuator, resourcedetection]
    exporters: [sapm]
```
```yaml
metrics:
    receivers: [otlp, hostmetrics]
    processors: [memory_limiter, batch, resourcedetection,filter/drop_actuator, resource]
    exporters: [signalfx]
```
#### Build image
```dockerfile
FROM otel/opentelemetry-collector-contrib:latest

# Set the working directory for the OpenTelemetry Collector
WORKDIR /etc/otelcol-contrib

# Copy the OpenTelemetry configuration file into the container
COPY otel-config.yaml /etc/otelcol-contrib/config.yaml
```
#### Result
However, I was unable to send Server Time to Splunk Observability Cloud to connect RUM and APM, so I switched to using Second Version.

### Second Version
#### Use Splunk OTel Collector
In this setup, we utilize the Splunk OpenTelemetry Collector, which allows us to save time by simplifying the collector configuration process. Furthermore, this approach helps decrease the likelihood of encountering configuration-related bugs.

```dockerfile
FROM quay.io/signalfx/splunk-otel-collector:latest

# Set the Splunk access token (replace with your actual access token)
# ENV SPLUNK_ACCESS_TOKEN=<Your Access Token>

# Specify the Splunk realm for data ingestion
ENV SPLUNK_REALM=us1

# Expose necessary ports for the Splunk OpenTelemetry Collector
EXPOSE 13133 14250 14268 4317 4318 6060 7276 8888 9080 9411 9943
```

## GCP
### Artifact Registry
This is where images are pushed.
### Cloud Run
In [cloud-run.yaml](https://github.com/scw0108/jpetstore-otel/blob/master/cloud-run.yaml), there are two containers
  1. **jpetstore-app**
  2. **collector**

**Some OTel evironment variable need to define**
```yaml
- name: SPLUNK_TRACE_RESPONSE_HEADER_ENABLED
  value: "true"
- name: spring.profiles.active
  value: test,gcp
- name: JAVA_TOOL_OPTIONS
  value: -Djava.security.egd=file:/dev/./urandom -Dfile.encoding=UTF-8
- name: OTEL_SERVICE_NAME
  value: "jpetstore-otel-test"
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://localhost:4318"
- name: OTEL_SERVICE_NAME
  value: "jpetstore-otel-demo"
- name: OTEL_RESOURCE_ATTRIBUTES
  value: "deployment.environment=lab,service.version=0.0.0"       
```
https://opentelemetry.io/docs/specs/otel/configuration/sdk-environment-variables/

Deploy on Cloud Run
```
$ gcloud run services replace cloud-run.yaml
```

## Default active accounts (ID/PASSWORD)

* j2ee/tBp5DvBR
* ACID/ACID

## Splunk APM

## Splunk RUM
