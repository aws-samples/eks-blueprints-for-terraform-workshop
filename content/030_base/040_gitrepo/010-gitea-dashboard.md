---
title: "Gitea Dashboard"
weight: 10
---

<!-- cspell:disable-next-line -->

::video{id=kRUM9ABx97s}

You can access the Gitea server to view the repositories.

To find our Gitea URL, you can execute:
<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash highlightLines='0'}
gitea_credentials
:::
<!-- prettier-ignore-end -->

:::alert{header="Important" type="info"}
Throughout the workshop, we use several bash functions. To learn more about any function, we can execute `type <function_name>` to find its source file:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=json }
type gitea_credentials
:::
<!-- prettier-ignore-end -->

example output

```
gitea_credentials is a shell function from /home/ec2-user/.bashrc.d/argocd.bash
```

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
