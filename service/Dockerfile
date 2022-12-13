FROM eclipse-temurin:17-jre-alpine
VOLUME /tmp
COPY target/*.jar kg-statistics.jar
ENV JAVA_OPTS=""
ENTRYPOINT exec java $JAVA_OPTS -jar /kg-statistics.jar