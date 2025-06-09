---
title: "GitOps Bridge"
weight: 40
hidden: true
---




### App of Apps

In the previous chapter, you deployed a single application using an Argo CD Application object. That worked great — but what happens when:

* You have multiple microservices 
* You need to deploy them to multiple environments like dev and uat
* You want to scale this process without overwhelming the platform team?

This is where the App of Apps pattern comes in. In this example you want to deploy E-Commerce(ecomm) app with 3 microservices( auth, orders, payments)

### Basic Setup Without App of Apps
Let’s say a developer wants to deploy a microservices app to to dev. They create Argo CD Application manifests like this:

<!-- ```
├── dev/
    ├── auth.yaml
    ├── orders.yaml
    └── payments.yaml
└── uat/
    ├── auth.yaml
    ├── orders.yaml
    └── payments.yaml
├── deploy/
    ├── uat-apps.yaml      
    └── dev-apps.yaml      
``` -->
Then they send these manifests to the platform team, who manually creates six Argo CD Applications (three per environment). As the number of apps and environments grows, this becomes unmanageable.

### Automate with App of Apps

With the App of Apps pattern, we break the responsibilities like this:

✅ Developers: Still write Argo CD Application YAMLs for each service in each environment.

✅ Platform Team: Adds a layer to automate deployment and structure.

They also create environment-level ApplicationSets, like:

├── deploy/
│   ├── dev-apps.yaml      # points to dev/auth.yaml, dev/orders.yaml...
│   └── uat-apps.yaml      # points to uat/auth.yaml, uat/orders.yaml...

These ApplicationSets generate actual Argo CD Applications automatically.

Then the platform team creates a single root Application like this:

├── appofapps/
│   └── ecomm.yaml   # deploys dev-apps.yaml and uat-apps.yaml

And finally, a root.yaml Application is created to sync everything in the appofapps/ folder.


Let's say you need to deploy a micrservices application(auth, orders,paymers) to dev and UAT environment. Developer can create these ArgoCD Application objects and send them to platform team to deploy the application. 


├── dev/
  ├── auth.yaml
  ├── orders.yaml
  └── payments.yaml
└── uat/
  ├── auth.yaml
  ├── orders.yaml
  └── payments.yaml

Let's see how this can be automated.

Developers still responsible to create ArgoCD application for each environment. These are stored in an application git repository. They also create env deployment files dev-apps.yaml and uat-apps.yaml. These application set point to Application in corresponding folders.

├── dev/
  ├── auth.yaml
  ├── orders.yaml
  └── payments.yaml
└── uat/
  ├── auth.yaml
  ├── orders.yaml
  └── payments.yaml
└── deploy/
  ├── dev-apps.yaml
  └── uat-apps.yaml

To deploy an application, platform team creates an ArgoCD Application for each application. 

├── appofapps/
  └── ecomm.yaml

Then Platform team has to create root.yaml once. This will deploy all applications in appofapps folder.
If you need to enroll a new applicaiton, platform creates a new application in appofapps folder and everything is automated.



In the previous chapter, you deployed an application using an Application object. This application was deployed to the hub-cluster.
To deploy the same application to the spoke-cluster, you would need to create another Application.

Benefits of the Split
Platform team controls structure and environment-level control.

Developers have full ownership of what runs in each app.

Keeps Git clean and security boundaries cleat