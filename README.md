# jpetstore-otel

This application is a web application modified by [JPetStore](https://github.com/kazuki43zoo/mybatis-spring-boot-jpetstore) Spring Boot version to demenstorate [OpenTelemetry](https://opentelemetry.io/docs/). 
The application is deployed on GCP Cloud Run.
There is a OpenTelemetry Collector that collects telemetry data and sends to [Splunk Observability Cloud](https://www.splunk.com/en_us/products/observability-cloud.html) for monitoring.

We will walk through this sample to understand how is it built and learn how to run it.

## Requirements

* Java 8+ (JDK 1.8+)

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
* Jib 3.3.2
* OpenTelemetry 1.28.0
* etc ...

## Build an application image 

### Add [Jib](https://github.com/GoogleContainerTools/jib)
In pom.xml, define how to use Jib to build a Docker image
``` xml
<plugin>
    <groupId>com.google.cloud.tools</groupId>
    <artifactId>jib-maven-plugin</artifactId>
    <version>${jib-maven-plugin.version}</version>
    <configuration>
        <from>
            <image>gcr.io/distroless/java17-debian12</image>
            <platforms>
                <platform>
                    <architecture>amd64</architecture>
                    <os>linux</os>
                </platform>
            </platforms>
        </from>
        <container>
            <jvmFlags>
                <jvmFlag>-javaagent:/otelagent/opentelemetry-javaagent.jar</jvmFlag>
            </jvmFlags>
        </container>
        <extraDirectories>
            <paths>
                <path>
                    <from>${project.build.directory}/agent</from>
                    <into>/otelagent</into>
                </path>
            </paths>
        </extraDirectories>
    </configuration>
    <executions>
        <execution>
            <phase>package</phase>
            <goals>
                <goal>dockerBuild</goal>
            </goals>
        </execution>
    </executions>
</plugin>
```
The config of OpenTelemetry agent JAR
```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-dependency-plugin</artifactId>
    <executions>
        <execution>
            <id>copy-agent</id>
            <phase>package</phase>
            <goals>
                <goal>copy</goal>
            </goals>
            <configuration>
                <artifactItems>
                    <artifactItem>
                        <groupId>io.opentelemetry.javaagent</groupId>
                        <artifactId>opentelemetry-javaagent</artifactId>
                        <version>${opentelemetry.version}</version>
                        <outputDirectory>${project.build.directory}/agent</outputDirectory>
                        <destFileName>opentelemetry-javaagent.jar</destFileName>
                    </artifactItem>
                </artifactItems>
            </configuration>
        </execution>
    </executions>
</plugin>
```
### Build Image
  ```
  $ ./mvnw clean package -DskipTests=true
  ```
## OpenTelemetry Collector
[otel-config.yaml](https://github.com/scw0108/jpetstore-otel/blob/master/otel-config.yaml)
### Receivers
* otlp
### Exporters
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
### Service
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
### Build image
 ```
  $ docker build -t <your image tag> .
  ```
### RUM Config
In order to send data to Splunk Observability Cloud's RUM, each html files need to add these sections.
``` html
<script src="https://cdn.signalfx.com/o11y-gdi-rum/v0.18.0/splunk-otel-web.js" crossorigin="anonymous"></script>
<script>
    SplunkRum.init({
        realm: "us1",
        rumAccessToken: // RUM Token,
        applicationName: "jpetstore-otel-demo",
        deploymentEnvironment: "lab",
        debug: true
    });
</script>
```
Add recode function
```html
<script src="https://cdn.signalfx.com/o11y-gdi-rum/v0.18.0/splunk-otel-web-session-recorder.js" crossorigin="anonymous"></script>
<script>
    SplunkSessionRecorder.init({
        app: "jpetstore-otel-demo",
        realm: "us1",
        rumAccessToken: // RUM Token
    });
</script>
```
## GCP
### Artifact Registry
Images are pushed to here
### Cloud Run
In [cloud-run.yaml](https://github.com/scw0108/jpetstore-otel/blob/master/cloud-run.yaml), there are two containers
  1. jpetstore-app
  2. collector

Some OTel evironment variable need to define
```yaml
- name: OTEL_EXPORTER_OTLP_ENDPOINT
  value: "http://0.0.0.0:4317"
- name: OTEL_SERVICE_NAME
  value: "jpetstore-otel-demo"
- name: OTEL_TRACES_SAMPLER
  value: "always_on"
- name: OTEL_METRICS_EXPORTER
  value: "otlp"           
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
