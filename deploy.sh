#!/usr/bin/bash
JAVA_JAR_NAME="rest-service-0.0.1-SNAPSHOT"
BEANSTALK_APP_NAME="JavaMicroTerraformTestApp"
BEANSTALK_ENV_NAME="JavaMicroTerraformTestEnv"
BEANSTALK_APP_VERSION="v1"

#aws elasticbeanstalk create-application-version --application-name YourAppName --version-label v1 --source-bundle S3Bucket=your-bucket-name,S3Key=path/to/your/$JAVA_JAR_NAME
aws elasticbeanstalk update-environment --application-name $BEANSTALK_APP_NAME --environment-name $BEANSTALK_ENV_NAME --version-label $BEANSTALK_APP_VERSION
