## Introduction

This is the sample project to describe how to initiate & provision a serverless platform on AWS cloud using Terraform & SAM.
The approach is:

- Use Terraform:
  - To initiate & provision all the required infrastructures such as IAM role, policy, lambda, sqs, dynamodb, code pipeline,...
  - Use AWS Code Pipeline to integrate with Terraform image in docker-hup for CI/CD action.
- Use SAM:
  - To develop, test & debug the source code of lambda function.
  - Build the lambda package used to deploy by Terraform.

# Sample architecture

This project is to build a simple Todo application which allow user to record their todo action with some simple description likes Todo, Desc & Status. The AWS structure is:

![Sample Architecture](https://github.com/duc-hectre/duc-hectre/blob/main/TF-SAM-APPROACH-1.png?raw=true)

# Get started.

Regarding to this sample. The project structure looks like image below.

![Sample project structure](https://github.com/duc-hectre/duc-hectre/blob/main/tf_1_project_structure.png?raw=true)

In which, we have 3 main parts:

### Lambda Function part

First is the Lambda block which contains the definition of the lambda function including unit test, integration test if any.
This is the main block for code logic which will be used to build the package & deploy to AWS Lambda.
If any new functions need to be develop, they will be define here.

### Terraform part

This is the part that contains all the terraform code to initiate & manage infrastructures needed for our application. All the services on AWS will be defined here such as Lambda function configuration, IAM Roles & policies, SQS, CloudWatch, AWS Code Pipeline,...

### SAM part

This is the part to defines SAM template which support us to run Lambda function locally for testing & debugging.
If any lambda function need to be debugged or troubleshooted, we create the corresponding a simple sam template and link the URI to the proper lambda code defined in Lambda Part, then configure the debug profiles to start debugging.

Try to keep the SAM template as simple as possible so that we don't have to spend a lot effort of defining the template, mostly focus on Lambda config, environment variables and input events used for testing.

Regarding to details of configuration as well as surrounding services, they had already been defined in Terraform part.

### How to run the project.

Following the steps below to get the project starts.

1. **Install prerequisites**

   - Install AWS CLI tool
     An AWS account with proper permission with the services we are intend to initiate & use.

   - Install AWS CLI tool [Installing or updating the latest version of the AWS CLI - AWS Command Line Interface ](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

   - Install AWS SAM CLI tool [Installing the AWS SAM CLI - AWS Serverless Application Model ](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html)

   - Install Docker - that use to simulate the AWS environment for debugging

   - Install some extensions for VS Code:

     - AWS Toolkit [AWS Toolkit for Visual Studio Code - AWS Toolkit for VS Code ](https://docs.aws.amazon.com/toolkit-for-vscode/latest/userguide/welcome.html)

     - Terraform

2. **Run locally**

   To run the lambda locally. Navigate the corresponding SAM folder of lambda function then using SAM CLI below:

   ```
   cd ./sam/todo_handler
   sam local invoke -d 3000 -e event.json TodoFunction
   ```

   or

   ```
   cd ./sam/todo_persist
   sam local invoke -d 3000 -e event.json TodoPersistFunction
   ```

   for example a SAM template for TodoFunction to handler user request from API gateway and send data to SQS.

   ```
    AWSTemplateFormatVersion: '2010-09-09'
    Transform: AWS::Serverless-2016-10-31
    Description: >
    Todo lambda function
    Globals:
    Function:
        Timeout: 3

    Resources:
    TodoFunction:
        Type: AWS::Serverless::Function
        Properties:
        FunctionName: test-test_tag-tf-sam-lambda-todo-handler
        CodeUri: ../../lambda/src/todo_handler/
        Handler: main.lambda_handler
        Runtime: python3.8
        Architectures:
            - x86_64
        Events:
            GetHello:
            Type: Api
            Properties:
                Path: /todo
                Method: any
        Environment:
            Variables:
            DYNAMO_TABLE_NAME: "tf_sam_todo_table"
            SQS_URL: "https://sqs.ap-southeast-1.amazonaws.com/983670951732/rf_sam_todo_queue"

    Outputs:
    TodoFunction:
        Description: "Hello World Lambda Function ARN"
        Value: !GetAtt TodoFunction.Arn
   ```

3. **Debug**

   To debug the lambda function, open the launch.json file located in ./vscode/ folder, then add new SAM profile or edit the existing profiles to set difference input according to different scenarios to test.
   Pay attention to these parameters **TemplatePath, LogicalId, API** accordingly.

   ```
   {
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
        "type": "aws-sam",
        "request": "direct-invoke",
        "name": "SAM local debug - todo-handler - POST",
        "invokeTarget": {
            "target": "api",
            "templatePath": "${workspaceFolder}/sam/todo_handler/template.yaml",
            "logicalId": "TodoFunction"
        },
        "api": {
            "path": "/todo",
            "httpMethod": "post",
            "payload": {
            "json": { "todo": "Initiate sam project 01" }
            }
        }
        },
        {
        "type": "aws-sam",
        "request": "direct-invoke",
        "name": "SAM local debug - todo-handler - GET",
        "invokeTarget": {
            "target": "api",
            "templatePath": "${workspaceFolder}/sam/todo_handler/template.yaml",
            "logicalId": "TodoFunction"
        },
        "api": {
            "path": "/todo",
            "httpMethod": "get"
        }
        },
        {
        "type": "aws-sam",
        "request": "direct-invoke",
        "name": "SAM local debug - todo-persisit - SQS",
        "invokeTarget": {
            "target": "template",
            "templatePath": "${workspaceFolder}/sam/todo_persist/template.yaml",
            "logicalId": "TodoPersistFunction"
        },
        "sam": {
            "localArguments": ["-e", "${workspaceFolder}/sam/todo_persist/events/event.json"]
        }
        }
    ]
    }
   ```

   Once ok, can use F5 in VS Code to start the lambda function & debug.

4. **Build**

   To build the deployment package of lambda function. Navigate the corresponding SAM folder of lambda function then using SAM CLI below:

   ```
   cd ./sam/todo_handler
   sam build
   ```

   The package will be generated & located inside the corresponding .aws-sam folder by default:
   .\sam\todo_handler\.aws-sam\build\TodoFunction

   We can use this package folder as input for Terraform **archive_file** resource to build the .zip package. Or we can use _sam deploy_ to let SAM create .zip package & upload it to S3 bucket. After that it can be used to deploy to lambda function defined by Terraform.

   In this example, we use _sam build_ to generate the package folder and use archive_file of terraform to zip the package.

5. **Deploy**

   As mentioned earlier, we use Terraform as the main method to initiate & define the AWS resources. To deploy whole the application manually, we use Terraform CLI as below:

   First, initiate the terraform library & modules.

   ```
   terraform init
   ```

   Then validate the Terraform configuration.

   ```
   terraform validate
   ```

   Create plan to deploy

   ```
   terraform plan
   ```

   Apply the changes to deploy.

   ```
   terraform apply --auto-approve
   ```

   In this example, we use Terraform to define a AWS Code Pipeline to auto test & deploy the application to AWS cloud. Use can find the definition under main.tf file located in the root folder.

   ```
    module "aws_tf_cicd_pipeline" {
        source = "./modules/aws_tf_cicd_pipeline"

        environment       = var.environment
        region            = var.region
        resource_tag_name = var.resource_tag_name

        cicd_name                      = "tf-cicd-todo"
        codestar_connector_credentials = var.codestar_connector_credentials
        pipeline_artifact_bucket       = "tf-cicd-todo-artifact-bucket"
    }
   ```

   For details of Pipeline definition, refer to the terraform module located in _./modules/aws_tf_cicd_pipeline_

   ![CI/CD pipeline](https://github.com/duc-hectre/duc-hectre/blob/main/tf_1_cicd_pipeline.png?raw=true)

6. **Destroy**

   To destroy all the AWS resources defined by Terraform, using the CLI below:

   ```
   terraform destroy
   ```
