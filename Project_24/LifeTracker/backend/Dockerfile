FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

ENV SPRING_PROFILES_ACTIVE=prod

COPY target/*.jar /app/lifetracker.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/lifetracker.jar"]
