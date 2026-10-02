# syntax=docker/dockerfile:1

# ---------- Etapa 1: build ----------
# Imagen con JDK 21 + Maven: solo se usa para compilar, no llega a producción.
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copiar primero solo el pom.xml y descargar dependencias.
# Docker cachea esta capa: si solo cambia el código, no se vuelven a descargar.
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

# Copiar el código fuente y empaquetar el jar ejecutable.
# Los tests se corren aparte (mvn test) para que el build de la imagen sea rápido.
COPY src ./src
RUN mvn -B -q package -DskipTests

# ---------- Etapa 2: runtime ----------
# Solo el JRE (sin JDK ni Maven): imagen más pequeña y con menos superficie de ataque.
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Usuario sin privilegios: si alguien compromete la app, no es root dentro del contenedor.
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

COPY --from=build /app/target/students-api.jar app.jar

EXPOSE 8080

# La JVM usa como máximo el 75 % de la memoria asignada al contenedor (ej. 768 MB de 1 GB en Fargate).
ENV JAVA_OPTS="-XX:MaxRAMPercentage=75.0"

# Docker marca el contenedor como healthy/unhealthy consultando Actuator.
HEALTHCHECK --interval=30s --timeout=5s --start-period=40s --retries=3 \
  CMD wget -qO- http://localhost:8080/actuator/health || exit 1

# exec: la JVM queda como PID 1 y recibe directamente el SIGTERM de Docker/ECS (apagado limpio).
ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
