#!/usr/bin/bash

#
# NOTE: those variables values must be the same of the terraform vars used to bootstrp
# the beanstalk env
#
# change names accordingly, override also terraform vars in the case.
#
JAVA_JAR_NAME="rest-service-0.0.1-SNAPSHOT"
BEANSTALK_APP_NAME="JavaMicroTerraformTestApp"
BEANSTALK_ENV_NAME="JavaMicroTerraformTestEnv"
BEANSTALK_APP_VERSION="v1"
BEANSTALK_S3_DEPLOY_BUCKET="${BEANSTALK_ENV_NAME}.applicationversion.bucket"
BEANSTALK_S3_DEPLOY_KEY="beanstalk/${JAVA_JAR_NAME}"

# build the jar file
echo "build java jar..."
cd code
./gradleW clean && ./gradleW build

# upload the new artifact
echo "deploy on s3 the new app version..."
aws s3 cp code/build/libs/$JAVA_JAR_NAME s3://$BEANSTALK_S3_DEPLOY__BUCKET/$BEANSTALK_S3_DEPLOY_KEY

# update beanstalk env with the new app
echo "update beanstalk with the new app version..."
aws elasticbeanstalk update-environment --application-name $BEANSTALK_APP_NAME --environment-name $BEANSTALK_ENV_NAME --version-label $BEANSTALK_APP_VERSION
