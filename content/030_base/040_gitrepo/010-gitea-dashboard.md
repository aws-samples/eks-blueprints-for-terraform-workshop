---
title: "Gitea Dashboard"
weight: 10
---

### 1. Check the local filesystem for GitOps files

The GitOps manifests content has already been set up and synchronized to our local IDE across the three repositories we mentioned:

![git_local_ide](/static/images/git_local_ide.jpg)

### 2. Sync with Argo CD

Later in the workshop, we will use Argo CD to synchronize from the Gitea Git repositories.

While we can access the Gitea server to view the repositories, during the workshop we will primarily interact with our local filesystem and use `git push` commands.

To find our Gitea URL, we can execute:

:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
gitea_credentials
:::

:::alert{header="Important" type="info"}
Throughout the workshop, we use several bash functions. To learn more about any function, we can execute `type <function_name>` to find its source file:

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

We can click on the output link to open it in our browser. The first time, we will need to enter the provided login and password.

![gitea login](/static/images/gitea_login.jpg)

After logging in, we can navigate through the repositories and files:

![CodeCommit Repository](/static/images/gitea_repos.jpg)
