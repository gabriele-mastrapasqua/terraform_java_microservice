# Terraform beanstalk
This is a test in terraform to create a Beanstalk java microservice with RDS.

## Build the code artifact
Run: 
```bash 
cd ../code
./gradlew clean && ./gradlew build
```
this will generate a jar file.

## Deploy infra using terraform
Prerequisites:
- aws account and cli installed
- jar built so we can bootstrap the first app version generating the first time the beanstalk env

Then run:
```bash
terraform init
terraform plan
terraform apply -auto-approve
terraform destroy
```
