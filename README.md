# TFPhoenix
Create a production ready infrastructure for the Phoenix Application.

Requirements:

* AWS as the provider
* Terraform installed and configured with an AWS access key associated with a user belonging to a group with the following permissions:
  * CloudWatchFullAccess
  * AmazonDynamoDBFullAccess
  * AmazonEC2FullAccess
  * IAMFullAccess
  * AutoScalingFullAccess
* t2.micro instances are used for the computational part
* A db.t3.medium instance is used for DocumentDB

# Architecture:
I used Terraform to create the architecture in AWS using IaaS services.
The application is downloaded, installed, and started as a service with each instance generation by the load balancer.

# Initialization:
Once the project is cloned, use one of the terraform/dev, terraform/staging, terraform/production folders depending on the CI/CD paradigm you want to use. Rename the terraform.ftvars file to terraform.tfvars and set the SSH key to access the instances if needed. In the same file, you can set:

* The AWS region
* The project name if you want to reuse it for other Node.js applications that meet the same requirements
* The GitHub URL of the Node.js app. This variable can be used to install development, staging, or production versions of the Phoenix app or other projects with the same requirements.
* Then run:
```
cd terraform/[dev/staging/production]
terraform apply
```

# Documentation
In the following articles of the GitHub wiki, you will find:

* The [ToDo](https://github.com/jiojio74/TFPhoenix/wiki/ToDo) list I followed before implementing the project.
* [Notes](https://github.com/jiojio74/TFPhoenix/wiki) on how I proceeded with the implementation.
* Documentation on how the [modules](https://github.com/jiojio74/TFPhoenix/wiki/Modules-documentation) work.
* Possible [improvements](https://github.com/jiojio74/TFPhoenix/wiki/Improvements).

# Requirements solutions:
1. Automate the creation of the infrastructure and the setup of the application. Done using Terraform.
2. Recover from crashes. Implement a method autorestart the service on crash. Done by configuring a service on the instance that restarts on failure.
3. Backup the logs and database with rotation of 7 days. Done using DocumentDB's autobackup and the CloudWatch agent installed on the instances.
4. Notify any CPU peak. Partially done with a CloudWatch alarm, missing the action to use Amazon SNS.
5. Implements a CI/CD pipeline for the code. Implemented with folder-based logic.
6. Scale when the number of request are greater than 100 req /min. Implemented using a CloudWatch alarm that monitors incoming requests to the load balancer.