---
title: "GitOps files"
weight: 10
---

### 1. Check the local filesystem for GitOps files

We have already setup for you content for our Gitops manifests spread into the 3 repositories that we mentioned that have been synced into your local IDE:

![git_local_ide](/static/images/git_local_ide.jpg)

### 2. Sync with ArgoCD

Later in the workshop we are going to use ArgoCD to synchronize from the Gitea Git repositories.

If you like you can access the Gitea server to see the repositories, but we will just use our local filesystem and `git push` commands to interact with it during the workshop.

You can find your Gitea URL by executing:

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
gitea_credentials
:::

:::alert{header="Important" type="info"}
We are using several bash functions in the workshop. If you want to know more about them, you can execute `type <function_name>` to find the source file of the function

```bash
type gitea_credentials
```

example output

```
gitea_credentials is a shell function from /home/ec2-user/.bashrc.d/argocd.bash
```

:::

Example output

```
Gitea Username: workshop-user
Gitea Password: 8yJPQ4IMsW97EQdKXJXGqRlIty6n3B
https://d3aeqzejs2v8j.cloudfront.net/gitea/workshop-user/
```

Then You can click on the output link to open it in your browser, and the first time it will ask you to enter the output login and password.

![gitea login](/static/images/gitea_login.jpg)

From then, you can navigate the repositories and files:

![CodeCommit Repository](/static/images/gitea_repos.jpg)
