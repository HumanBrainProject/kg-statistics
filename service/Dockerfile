FROM openjdk:11-jre-slim
VOLUME /tmp
COPY target/*.jar kg-statistics.jar
ENV JAVA_OPTS=""
ENTRYPOINT exec java $JAVA_OPTS -jar /kg-statistics.jar