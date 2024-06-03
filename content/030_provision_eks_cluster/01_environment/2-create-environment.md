---
title : "Create the environment"
weight : 2
---

Next, run the following Terraform CLI commands to provision the AWS resources:

```bash
# Initialize Terraform so that we get all the required modules and providers
cd ~/environment/eks-blueprint/environment
terraform init
```

::::expand{header="View Terraform Output:"}
::::expand{header="View Terraform Output:"}
:::code{showCopyAction=false language=hcl}
Initializing modules...
Downloading registry.terraform.io/terraform-aws-modules/vpc/aws 3.14.0 for vpc...
- vpc in .terraform/modules/vpc

Initializing the backend...

Initializing provider plugins...
- Finding gavinbunney/kubectl versions matching ">= 1.14.0"...
- Finding hashicorp/aws versions matching ">= 3.63.0, >= 3.72.0"...
- Finding hashicorp/kubernetes versions matching ">= 2.10.0"...
- Finding hashicorp/helm versions matching ">= 2.4.1"...
- Installing gavinbunney/kubectl v1.14.0...
- Installed gavinbunney/kubectl v1.14.0 (self-signed, key ID AD64217B5ADD572F)
- Installing hashicorp/aws v4.16.0...
- Installed hashicorp/aws v4.16.0 (signed by HashiCorp)
- Installing hashicorp/kubernetes v2.11.0...
- Installed hashicorp/kubernetes v2.11.0 (signed by HashiCorp)
- Installing hashicorp/helm v2.5.1...
- Installed hashicorp/helm v2.5.1 (signed by HashiCorp)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
:::
::::

```bash
# It is always a good practice to use a dry-run command
# It is always a good practice to use a dry-run command
terraform plan
```

If there are no errors, you can proceed with deployment:
If there are no errors, you can proceed with deployment:
```bash
# The auto-approve flag avoids you having to confirm that you want to provision resources.
cd ~/environment/eks-blueprint/environment
terraform apply -auto-approve
```

At this stage, we have created our VPC; you can see it in the console using this [deep link](https://console.aws.amazon.com/vpc/home?#vpcs:tag:Name=eks-blueprint)
At this stage, we have created our VPC; you can see it in the console using this [deep link](https://console.aws.amazon.com/vpc/home?#vpcs:tag:Name=eks-blueprint)

Next, we will create the basic cluster with a managed node group.