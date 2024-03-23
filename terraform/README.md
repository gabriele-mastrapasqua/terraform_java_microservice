# Terraform beanstalk
This is a test in terraform to create a Beanstalk java microservice with RDS.


## How to deploy infra and the v1 of the code

## Build the code artifact
Run: 
```bash 
cd ../code
./gradleW clean && ./gradleW build
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
terraform apply
```
