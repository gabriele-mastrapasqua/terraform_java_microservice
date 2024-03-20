# Use a base image with Java and Maven installed
FROM amazoncorretto:11.0.22-al2023 as build

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven project file (pom.xml) and download dependencies
COPY ./build.gradle ./gradlew /app/
COPY ./gradle /app/gradle
RUN ./gradlew --no-daemon dependencies

# Copy the application source code
COPY . /app/

# Build the application
RUN ./gradlew --no-daemon build

# Use a lighter base image for the final image
FROM amazoncorretto:11.0.22-al2023-headless

# Set the working directory inside the container
WORKDIR /app

# Copy the compiled application from the build stage
COPY --from=build /app/build/libs/*.jar /app/app.jar

# Expose the port that the application listens on
EXPOSE 5000

# Command to run the application when the container starts
CMD ["java", "-jar", "app.jar"]
