# Azure DevOps - Spring Boot, Ansible, Docker, Kubernetes, and SonarQube CI/CD Pipeline

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Technologies Used](#technologies-used)
4. [Terraform Setup](#terraform-setup)
5. [Ansible Setup](#ansible-setup)
    - [Minikube Setup with Ansible](#minikube-setup-with-ansible)
    - [SonarQube Setup with Ansible](#sonarqube-setup-with-ansible)
6. [Dockerizing the Spring Boot App](#dockerizing-the-spring-boot-app)
7. [Azure DevOps Self-hosted Agent](#azure-devops-self-hosted-agent)
8. [SonarQube Integration with Azure DevOps](#sonarqube-integration-with-azure-devops)
9. [Pipeline Configuration](#pipeline-configuration)
10. [Deploying to Minikube](#deploying-to-minikube)
11. [Conclusion](#conclusion)

## 1. Introduction
This project demonstrates the complete CI/CD pipeline from building a Spring Boot application to deploying it in a Kubernetes cluster using Minikube, Ansible, Docker, and Terraform. The pipeline also integrates SonarQube for code quality checks.

## 2. Project Structure
```
.
├── ansible
│   ├── ansible.cfg
│   ├── inventory
│   ├── key.pem
│   ├── playbook.yml
│   └── roles
│       ├── docker
│       ├── jenkins
│       ├── jenkinsconfig
│       ├── minikube
│       ├── oc-cli
│       └── sonar
├── azure-pipelines.yml
├── kubernetes
│   ├── deployment.yaml
│   └── ingress.yaml
├── spring-boot-app
│   ├── build.gradle
│   ├── Dockerfile
│   └── src
├── terraform
    ├── main.tf
    ├── terraform.tfvars
    └── vars.tf
```

## 3. Technologies Used
- **Terraform**: Used for infrastructure provisioning on AWS, creating the necessary EC2 instance and related resources.
- **Ansible**: Automated tool installations and configurations on the EC2 instance.
- **Docker**: Containerizes the Spring Boot application.
- **Kubernetes (Minikube)**: Hosts the application within the EC2 instance.
- **SonarQube**: Code quality analysis tool integrated with Azure DevOps.
- **Azure DevOps**: CI/CD pipeline setup.

## 4. Terraform Setup
Terraform is used to provision an AWS `t3.xlarge` EC2 instance with the required Ubuntu image and disk space. It also sets up the necessary networking (VPC, Subnets, etc.) for the instance.

```bash
terraform init
terraform apply
```

## 5. Ansible Setup
Ansible playbooks are used to automate the configuration of  Docker, SonarQube, and Minikube.

### Minikube Setup with Ansible
Ansible configures Minikube as the local Kubernetes cluster on the EC2 instance using the `minikube` role.
```yaml
ansible-playbook -i inventory playbook.yml -t minikube
```

### SonarQube Setup with Ansible
SonarQube is deployed using Docker Compose, which is managed by Ansible. PostgreSQL is also part of the Docker Compose setup.
```yaml
ansible-playbook -i inventory playbook.yml -t sonar
```
- Sample image showing SonarQube service connection setup:  
  ![SonarQube Service Connection](https://github.com/omaRouby/Azure-DevOps/blob/main/screenshots/sonar-service-connection.png)

## 6. Dockerizing the Spring Boot App
The `Dockerfile` builds the Spring Boot application using Gradle and then packages it in a slim OpenJDK image for running the app.

```dockerfile
FROM gradle:7.5.1-jdk11 AS build
WORKDIR /app
COPY gradle gradle
COPY gradlew .
COPY build.gradle .
COPY settings.gradle .
COPY src src
RUN ./gradlew build --no-daemon

FROM openjdk:11-jre-slim
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

## 7. Azure DevOps Self-hosted Agent
The EC2 instance is configured as a self-hosted Azure DevOps agent to run the CI/CD pipeline.

- Sample image showing agent setup step 1:  
  ![Self-hosted Agent Setup 1](https://github.com/omaRouby/Azure-DevOps/blob/main/screenshots/self-hostagent-setup1.png)
- Sample image showing agent setup step 2:  
  ![Self-hosted Agent Setup 2](https://github.com/omaRouby/Azure-DevOps/blob/main/screenshots/self-hostagent-setup2.png))

## 8. SonarQube Integration with Azure DevOps
SonarQube is integrated with Azure DevOps to analyze the code quality. A service connection is set up in Azure DevOps to allow communication between SonarQube and the pipeline. The SonarQube token is generated and added to the pipeline configuration.

- Sample image showing SonarQube token setup:  
  ![SonarQube Token](https://github.com/omaRouby/Azure-DevOps/blob/main/screenshots/sonar-qube%20token.png)

## 9. Pipeline Configuration

The CI/CD pipeline builds, tests, analyzes, and deploys the application using the following steps:

```yaml
trigger:
  branches:
    include:
      - main

pool:
  name: Default
  demands:
    - agent.name -equals ubuntu-ec2-agent

variables:
  dockerRegistryServiceConnection: 'omarrouby'
  imageName: 'omarrouby/spring-app'

stages:
  - stage: CodeAnalysis
    displayName: 'Code Linting, Testing, and SonarQube Analysis'
    jobs:
      - job: LintAndTest
        displayName: 'Lint Code and Run Unit Tests'
        steps:
          - task: Bash@3
            displayName: 'Lint Code'
            inputs:
              targetType: 'inline'
              script: |
                echo "Running lint checks..."
                cd spring-boot-app/spring-boot-app
                ./gradlew check

          - task: Bash@3
            displayName: 'Run Unit Tests'
            inputs:
              targetType: 'inline'
              script: |
                echo "Running unit tests..."
                cd spring-boot-app/spring-boot-app
                ./gradlew test

      - job: SonarQubeAnalysis
        displayName: 'SonarQube Analysis'
        steps:
          - task: SonarQubePrepare@6
            inputs:
              SonarQube: 'sonarqube'
              scannerMode: 'CLI'
              configMode: 'manual'
              cliProjectKey: 'azuredevops'
              cliProjectName: 'azuredevops'

          - task: SonarQubeAnalyze@6
            inputs:
              jdkversion: 'JAVA_HOME_17_X64'

          - task: SonarQubePublish@6
            inputs:
              pollingTimeoutSec: '300'

  - stage: BuildAndDeploy
    displayName: 'Build, Push Docker Image, and Deploy to Minikube'
    jobs:
      - job: BuildAndPush
        displayName: 'Build and Push Docker Image'
        steps:
          - task: Docker@2
            displayName: 'Build and Push Docker Image'
            inputs:
              command: 'buildAndPush'
              containerRegistry: 'omarrouby'
              repository: '$(imageName)'
              dockerfile: 'spring-boot-app/spring-boot-app/Dockerfile'
              tags: |
                latest
              buildContext: 'spring-boot-app/spring-boot-app'

      - job: DeployToMinikube
        displayName: 'Deploy to Minikube'
        steps:
          - task: Kubernetes@1
            displayName: 'Deploy to Minikube'
            inputs:
              connectionType: 'None'
              namespace: 'default'
              useConfigFile: true
              configFile: '$(System.DefaultWorkingDirectory)/kubernetes/*.yaml'
              arguments: ''

```

- Sample image showing build success:  
  ![Build Success](https://github.com/omaRouby/Azure-DevOps/blob/main/screenshots/build-succes.png)

- Sample image showing job success:  
  ![Job Success](https://github.com/omaRouby/Azure-DevOps/blob/main/screenshots/job-success.png)

## 10. Deploying to Minikube

The Kubernetes `deployment.yaml` and `ingress.yaml` files are used to deploy the Spring Boot application to the Minikube cluster.

```bash
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/ingress.yaml
```
- Sample image showing kubectl output:  
  ![kubectl get all](https://github.com/omaRouby/Azure-DevOps/blob/main/screenshots/kubectl-get-all.png)

## 11. Conclusion
The project successfully demonstrates the automation of the CI/CD pipeline with Azure DevOps, from building a Spring Boot application, checking code quality with SonarQube, Dockerizing the application, and deploying it to Minikube.

---
