# Use an official Gradle image to build the project
FROM gradle:7.5.1-jdk11 AS build

# Set the working directory in the container
WORKDIR /app

# Copy the Gradle wrapper files and project files into the container
COPY gradle gradle
COPY gradlew .
COPY build.gradle .
COPY settings.gradle .

# Copy the source code
COPY src src

# Build the application
RUN ./gradlew build --no-daemon

# Use an official OpenJDK runtime image for the final run stage
FROM openjdk:11-jre-slim

# Set the working directory in the container
WORKDIR /app

# Copy the built JAR from the previous build stage
COPY --from=build /app/build/libs/*.jar app.jar

# Expose the application port
EXPOSE 8080

# Command to run the app
ENTRYPOINT ["java", "-jar", "app.jar"]

