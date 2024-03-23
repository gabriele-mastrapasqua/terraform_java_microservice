#!/bin/bash

#
# NOTE: those variables values must be the same of the terraform vars used to bootstrp
# the beanstalk env
#
# change names accordingly, override also terraform vars in the case.
#
JAVA_ARTIFACT_NAME="rest-service-0.0.1-SNAPSHOT.jar"
BEANSTALK_APP_NAME="java-terraform-test-app"
BEANSTALK_ENV_NAME="java-terraform-test-env"
BEANSTALK_APP_VERSION="v1"
BEANSTALK_S3_DEPLOY_BUCKET="java-test-artifacts-beanstalk"
BEANSTALK_S3_DEPLOY_KEY="beanstalk/${JAVA_ARTIFACT_NAME}"

# build the jar file
echo "build java jar..."
cd code
./gradlew clean && ./gradlew build

# test
echo "print all ENVs"
export
echo $AWS_ACCESS_KEY_ID >> .env
cat .env


# upload the new artifact
echo "deploy on s3 the new app version..."
aws s3 cp "build/libs/${JAVA_ARTIFACT_NAME}" "s3://${BEANSTALK_S3_DEPLOY_BUCKET}/${BEANSTALK_S3_DEPLOY_KEY}"

# update beanstalk env with the new app
echo "update beanstalk with the new app version..."
aws elasticbeanstalk update-environment --application-name $BEANSTALK_APP_NAME --environment-name $BEANSTALK_ENV_NAME --version-label $BEANSTALK_APP_VERSION
