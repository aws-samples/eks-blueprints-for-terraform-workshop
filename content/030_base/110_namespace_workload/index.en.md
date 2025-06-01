---
title: "Namespace And Workload Autoamtion"
weight: 110
---

Deploying an application is a two step process

* ![Platform Task](/static/images/platform-task.png) The platform team onboards the application by creating a namespace and automating its deployment.  

* ![Developer Task](/static/images/developer-task.png) The developer deploys the application using the provided automation.

In this section, you will take on the role of a ![Platform Task](/static/images/platform-task.png) platform engineer and set up the automation that makes application onboarding easy and repeatable.


We’ll use the following folder structure in the **platform Git** repository to onboard applications:

![Platform Repo Folders](/static/images/platform-repo-folders.png)

This structure ensures that onboarding a new application is as simple as committing configuration files to the correct location. Argo CD will automatically create the namespace and deploy the application based on this setup



