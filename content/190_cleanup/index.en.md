---
title: "Clean up"
weight: 190
---

In this workshop, we have created a VPC and multiple EKS clusters. Although the clusters were created using Terraform, the Applications were deployed using Argo CD.

As Terraform is not aware of the Argo CD Applications installed on each EKS cluster, we need to clean up those applications before destroying the clusters with Terraform.

To simplify this process, we have prepared a `destroy.sh` script that will properly clean up the installed resources in the appropriate order.

If we have deployed additional resources that may have created Cloud resources, we should also clean those up prior to destroying the clusters. Otherwise, those resources may not be properly cleaned up.

### Using the cleanup script

We can execute the cleanup script to remove all resources. The script may display some errors during execution, which is normal as it repeats certain actions until cleanup succeeds.

```bash
$BASE_DIR/hack/scripts/destroy.sh
```

::alert[Removing resources in this specific order ensures dependencies are deleted entirely. VPCs, subnets, and IP addresses attached to ENIs are all deleted last.]{header="Important"}

> Congratulations! We should have now removed everything installed by the workshop.
