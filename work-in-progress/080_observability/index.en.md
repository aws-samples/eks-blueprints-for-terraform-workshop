---
title : "Observability"
weight : 40
hidden: true
---
Now let's explore some observability options available via EKS Blueprints Addons.

In IT and cloud computing, observability is the ability to measure a system’s current state based on the data it generates, such as logs, metrics, and traces. It helps us detect, investigate and remediate issues with running systems and applications as well as improve operational availability or Mean Time To Recover (MTTR). 

![Logs-Metrics-Traces](/static/images/logs-metrics-traces.png)

* For Logs – we look to collect and aggregate log files from resources and then filter out some actionable insights from background noise.

* For Metrics – we want to collect and visualize data regarding the health and performance of resources, usually measured over intervals of time. 

* For Traces – we just want to follow the path of a request, as it passes though different services. Tracing helps developers understand how their application and its underlying services are performing. 
It also helps to identify and troubleshoot the root cause of performance issues and/or some errors.

When we talk about EKS clusters observability, we think of measuring Pods and Containers, Applications, master and worker compute resources. 
We will now review and show how easy it is to setup basic observability of your EKS clusters provisioned by EKS Blueprints.