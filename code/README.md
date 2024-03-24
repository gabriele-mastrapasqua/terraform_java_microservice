# Java sample application
Java 11, mysql connector, simple api endpoint to fetch a current date from the db.

## build locally

```bash
./gradlew clean && ./gradlew build
```


## use docker compose to run locally
This will spin up also a mysql 8.0 container and sets the correct env variables to be used by the application.

```bash
docker-compose up --build
```
