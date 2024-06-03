---
title: 'Create provisioner'
weight: 2
---

### Step 3: Create a Karpenter Provisioner within our ArgoCD workload repository

#### Go to your workload repository

In order for our cluster to take advantage of Karpenter, we need to configure a [provisioner](https://karpenter.sh/preview/concepts/provisioners/).

Go back to your ArgoCD workload repository fork in codespace and create a new file `karpenter.yaml` inside the `teams/team-riker/dev/templates`.
Copy/Paste the following command in your codespace shell to create the file.

::alert[While I used this approach in the workshop for convenience, it is advisable to enable this provisioner centrally, preferably by the platform team.]{header="Important"}

Add the `karpenter.yaml` file by copying the new command in your codespace or by downloading the file : [karpenter.yaml](:assetUrl{path="/karpenter.yaml" source=s3})  

```yaml
cat << EOF > teams/team-riker/dev/templates/karpenter.yaml 
{{ if .Values.spec.karpenterInstanceProfile }}
apiVersion: karpenter.k8s.aws/v1alpha1
kind: AWSNodeTemplate
metadata:
  name: karpenter-default
  labels:
    {{- toYaml .Values.labels | nindent 4 }}  
spec:
  instanceProfile: '{{ .Values.spec.karpenterInstanceProfile }}'
  subnetSelector:
    kubernetes.io/cluster/{{ .Values.spec.clusterName }}: '*'
    kubernetes.io/role/internal-elb: '1' # to select only private subnets
  securityGroupSelector:
    aws:eks:cluster-name: '{{ .Values.spec.clusterName }}' # Choose only security groups of nodes
  tags:
    karpenter.sh/cluster_name: {{.Values.spec.clusterName}}
    karpenter.sh/provisioner: default
  metadataOptions:
    httpEndpoint: enabled
    httpProtocolIPv6: disabled
    httpPutResponseHopLimit: 2
    httpTokens: required
---
apiVersion: karpenter.sh/v1alpha5
kind: Provisioner
metadata:
  name: default
  labels:
    {{- toYaml .Values.labels | nindent 4 }}
spec:
  consolidation:
    enabled: true
  #ttlSecondsAfterEmpty: 60 # mutual exclusive with consolitation
  requirements:
    - key: "karpenter.k8s.aws/instance-category"
      operator: In
      values: ["c", "m"]
    - key: karpenter.k8s.aws/instance-cpu
      operator: Lt
      values:
        - '33'    
    - key: 'kubernetes.io/arch'
      operator: In
      values: ['amd64']
    - key: karpenter.sh/capacity-type
      operator: In
      values: ['on-demand']
    - key: kubernetes.io/os
      operator: In
      values:
        - linux
  providerRef:
    name: karpenter-default

  ttlSecondsUntilExpired: 2592000 # 30 Days = 60 * 60 * 24 * 30 Seconds;
  
  # Priority given to the provisioner when the scheduler considers which provisioner
  # to select. Higher weights indicate higher priority when comparing provisioners.
  # Specifying no weight is equivalent to specifying a weight of 0.
  weight: 1
  limits:
    resources:
      cpu: '2k'
  labels:
    billing-team: default
    team: default
    type: karpenter
    
  # Do we want to apply some taints on the nodes ?  
  # taints:
  #   - key: karpenter
  #     value: 'true'
  #     effect: NoSchedule

  # Karpenter provides the ability to specify a few additional Kubelet args.
  # These are all optional and provide support for additional customization and use cases.
  kubeletConfiguration:
    containerRuntime: containerd
    maxPods: 110     
    systemReserved:
      cpu: '1'
      memory: 5Gi
      ephemeral-storage: 2Gi
{{ end }}
EOF
```


This creates a default provisioner and a node template that will be used by Karpenter to create EKS nodes.
- We have set dedicated **labels** that can be used by pods as nodeSelectors.
- We can add **taints** to the nodes so that workloads could need to tolerate those taints to be scheduled on Karpenter's nodes.
- We specify some requirements around instances types, capacity, and architecture; each provisioner is highly customizable; you can find more information in the [documentation](https://karpenter.sh/preview/concepts/provisioners/).
- You can create many different Karpenter provisioners, and even make them default for every additional workload by not specifying any taints.
- You can also define priority between different provisioners, so that you can use in priority your nodes that benefit from AWS Reserved Instances prices. You can find more information in the [documentation](https://karpenter.sh/preview/concepts/scheduling/).

::alert[We just configured our **AWSNodeTemplate** and **Provisioner** to be created only if the Helm value **karpenterInstanceProfile** exist via the line 2 (`{{ if .Values.spec.karpenterInstanceProfile }}`). That means that we will need to activate this variable to really deploy the karpenter objects; this will be done in next section.]{header="Important"}

Add, Commit and push the code:

```bash
git add teams/team-riker/dev/templates/karpenter.yaml
git commit -m "Add Karpenter provisioner"
git push
```

This provisioner will be used by Karpenter when deploying workloads that use nodeSelector with the labels we defined (`type=karpenter`), but we need to activate it through or Helm value `karpenterInstanceProfile` first.

For now, we should have no Karpenter nodes in our cluster. Let's check this with our alias to list our nodes:

```bash
kubectl get nodes
# or :
#kubectl get nodes -L karpenter.sh/capacity-type -L topology.kubernetes.io/zone -L karpenter.sh/provisioner-name
```

```
NAME                                        STATUS   ROLES    AGE   VERSION                CAPACITY-TYPE   ZONE         PROVISIONER-NAME
ip-10-0-10-190.eu-west-1.compute.internal   Ready    <none>   14d   v1.24.13-eks-0a21954                  eu-west-1a
ip-10-0-11-188.eu-west-1.compute.internal   Ready    <none>   14d   v1.24.13-eks-0a21954                 eu-west-1b
ip-10-0-12-127.eu-west-1.compute.internal   Ready    <none>   14d   v1.24.13-eks-0a21954                   eu-west-1c
```

We can see our actual managed node groups, 1 in each AZ, and there should not already be nodes managed by Karpenter.

We need to scale our workload so that Karpenter can scale nodes.

::alert[Go to Next section so we can activate our provisioner]{header="Important"}