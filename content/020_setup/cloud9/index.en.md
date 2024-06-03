---
title: AWS Cloud9 Setup
weight: 12
---

During the initial setup, Cloud9 creates an EC2 instance and connects the Cloud9 IDE to this newly created instance. Cloud9 also initializes itself with managed IAM credentials that we will uses to interract with AWS services.

1. Open the Cloud9 service

![](/static/images/c9-open-ide.png)

1. Run the GetCallerIdentity command to confirm that Cloud9 IDE is using the **eks-blueprints-for-terraform-workshop-admin** we set as the IAM role for the Cloud9 instance

:::code{language=shell showLineNumbers=false showCopyAction=true}
aws sts get-caller-identity --query Arn | grep eks-blueprints-for-terraform-workshop-admin
:::

```
{
    "UserId": "AROA6NAAL5J5H22JSBCPA:i-09e1d15b60696663c",
    "Account": "0123456789",
    "Arn": "arn:aws:sts::0123456789:assumed-role/eks-blueprints-for-terraform-workshop-admin/i-09e1d15b60696663c"
}
```



1. Check you have the backup code source for the Workshop

```bash
ls -la ~/environment/code-eks-blueprint
```

At an AWS Event this will already contain files, but if you are on your own this should be empty, in this case run the following content to retrieve the Workshop Code:

```bash
curl ':assetUrl{path="/code-eks-blueprint.zip" source=s3}' -o code-eks-blueprint.zip
unzip -o code-eks-blueprint.zip -d ~/environment/code-eks-blueprint
```


When bootstrapping the IDE we already preinstall some tools such as:

- jq
- aws cli
- c9 helper to open files `c9 open file.txt`
- copilot
- configure some environment variables (check `~/.bashrc`)
- get the backup code in the `code-eks-blueprint` directory
- copilot cli
