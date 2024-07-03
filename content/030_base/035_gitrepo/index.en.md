---
title: 'Setup Git Repository'
weight: 35
---


For this workshop, we will use AWS CodeCommit to create two git repositories - one for developers to store application Kubernetes manifests, and one for platform engineers to store infrastructure artifacts. The first repository called "Application repository" will be used by developers working on the webstore application. They will push Kubernetes YAML files to deploy the app in this repository. 
The second repository named "Platform repository" will contain addons, application deployment and project. We will also create an IAM user called "gitops-user" with permissions to access both repositories. 