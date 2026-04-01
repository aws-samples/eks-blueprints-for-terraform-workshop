---
title: "CodeConnections"
weight: 010
---

In this chapter, you'll connect ArgoCD to a private GitLab repository using AWS CodeConnections. CodeConnections works by registering an OAuth application on your GitLab instance, then using OAuth tokens to securely access repositories. AWS manages the token lifecycle — including automatic renewal and secure storage — so there are no long-lived credentials to manage or rotate.

::alert[In this chapter, AWS CodeConnections is used to connect ArgoCD to a private GitLab repository. GitLab runs on a private network and CodeConnections accesses it through a VPC configuration. However, the CodeConnections OAuth setup requires your browser to reach GitLab directly to approve the connection. Since workshop participants don't have VPN access to the private network, GitLab is exposed via an internet-facing network load balancer for this step. In your organization, you would complete the OAuth handshake from a machine on the private network and keep GitLab fully private. ]{header="Important" type="warning"}

### 1. Access the Gitlab

You can access the gitlab url from the terminal:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
gitlab_url
:::
<!-- prettier-ignore-end -->

![Gitlab Initial](/static/images/codeconnections/gitlab-initial.png)

You will login with credentials **gitlab/argocdonaws**

::alert[You'll see a browser warning about an untrusted certificate. This is expected — the workshop uses a self-signed cert. Proceed past the warning to access GitLab. ]{header="Important" type="warning"}

On the left navigation select Projects. Then select "Gitlab Admin / guestbook" project.

![Guestbook Project](/static/images/codeconnections/guestbook-project.png)

We will be accessing guestbook repo with CodeConnections.

### 2. Set up Host

A CodeConnections Host represents the connection to your self-managed Git provider (in this case, GitLab). When you create a host with a VPC configuration, AWS places Elastic Network Interfaces (ENIs) into your VPC subnets. These ENIs allow CodeConnections to communicate with your private GitLab instance without exposing it to the internet.

![Guestbook Project](/static/images/codeconnections/eni.png)

::alert[The host has already been created for you as part of the workshop setup, since it takes several minutes to become active.]{header="Note" type="info"}

Navigate to **AWS Console → CodeCommit → Settings → Connections → Hosts**.

Select the host and click **Set up host**.

![Setup Host](/static/images/codeconnections/setup-host.png)

Enter the PAT:

A PAT with `api` and `admin_mode` scopes has been pre-created for the `gitlab` admin user as part of the workshop setup.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=text }
glpat-workshop-token-12345
:::
<!-- prettier-ignore-end -->

::alert[This PAT has `api` and `admin_mode` scopes. The `api` scope allows CodeConnections to interact with the GitLab API, and `admin_mode` is required to register the OAuth application on the GitLab instance.]{header="Note" type="info"}

After submitting, the host status should change from **Pending** to **Active**.

The host registers an OAuth application on your GitLab instance using a Personal Access Token (PAT), which is used only during setup.

You can verify that the OAuth application was registered by navigating to **GitLab Console → Admin Area → Applications**. You should see the application created by CodeConnections.

![Oauth App](/static/images/codeconnections/oauth-app.png)

### 3. Create Connection

A Connection represents an authorized link between AWS and your Git provider. It uses the Host you set up in the previous step to reach your GitLab instance and completes an OAuth handshake to obtain access tokens. Once the connection is active, AWS services like ArgoCD can use it to access your repositories.

Navigate to **AWS Console → CodeCommit → Settings → Connections**.

Click **Create connection**.

![Create Connection](/static/images/codeconnections/create-connection.png)

1. Select **GitLab Self Managed** as the provider
2. Enter a connection name (e.g., `gitlab-connection`)
3. Under **URL**, enter the "Endpoint" from Hosts tab or you can get this from the terminal:
   <!-- prettier-ignore-start -->
   :::code{showCopyAction=true showLineNumbers=false language=bash }
   gitlab_url
   :::
   <!-- prettier-ignore-end -->
4. Make sure **Use a VPC** is selected
5. Click **Connect to GitLab self-managed**

![Create Connection Values](/static/images/codeconnections/create-connection-values.png)

### 4. Update Connection

::alert[Before proceeding, make sure you are logged out of the GitLab console. If you're still logged in as the `gitlab` admin user, the OAuth authorization will use the admin's credentials instead of the dedicated service account, giving the connection full access to all repos. Log out first — the OAuth flow will prompt you to log in with the correct user.]{header="Important" type="warning"}

The connection will be created in **Pending** status. Click **Update pending connection** to complete the OAuth handshake.

This will redirect your browser to your GitLab instance. Log in with credentials **argocd-bot/argocdonaws** and click **Authorize AWS Connector for Gitlab Self-Managed** to grant CodeConnections access.

In the "Confirm Installation with Host Instance" dialog, click **Continue**.

When you clicked **Authorize**, CodeConnections used the OAuth application registered on your GitLab instance (during host setup) to obtain an OAuth token on behalf of the `argocd-bot` user. This token inherits the permissions of `argocd-bot` — which has Reporter (read-only) access to the `guestbook` repository. Going forward, any AWS service that uses this connection will access GitLab through this OAuth token, scoped to what `argocd-bot` can see and do.

After confirmation, the connection status should change from **Pending** to **Available**.

::alert[The `argocd-bot` user has the **Reporter** role on the `guestbook` repository. This is a read-only role that allows cloning and pulling code, viewing pipelines, and browsing repository content — but cannot push, create branches, or merge. This follows the principle of least privilege, since ArgoCD only needs to read manifests from the repository.]{header="Note" type="info"}

![Argocd bot token](/static/images/codeconnections/argocd-bot-token.png)

## Validate CodeConnections

Now that the connection is active, let's validate it end-to-end by deploying an application from the GitLab repository through CodeConnections. We'll grant the ArgoCD capability permission to use the connection, create an AppProject to scope access, and then create an Application that pulls manifests from the `guestbook` repo.

### 5. Add CodeConnection access

The ArgoCD capability role needs `codeconnections:UseConnection` permission to access repositories through the connection.

<!-- prettier-ignore-start -->

:::code{showCopyAction=true showLineNumbers=false language=bash}
cat <<'EOF' >> ~/environment/hub/main.tf
resource "aws_iam_role_policy" "argocd_codeconnection" {
  name = "argocd-codeconnection-access"
  role = aws_iam_role.eks_capability_argocd.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "codeconnections:UseConnection"
        Resource = "*"
      }
    ]
  })
}

EOF

cd ~/environment/hub
terraform apply --auto-approve
:::
<!-- prettier-ignore-end -->

### 6. Create Project

The `default` AppProject is locked down. We create a dedicated `codeconnections-demo` project that allows CodeConnections repo URLs as sources and restricts deployments to the hub cluster.

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
mkdir -p ~/environment/basics
cd ~/environment/basics
cp  $WORKSHOP_DIR/gitops/templates/project/codeconnections-demo.yaml ~/environment/basics
kubectl apply -f codeconnections-demo.yaml.yaml
:::
<!-- prettier-ignore-end -->

### 7. Create Application

Navigate to the ArgoCD dashboard and click **+ NEW APP**. Enter the following values:

| Field            | Value                               |
| ---------------- | ----------------------------------- |
| Application Name | `guestbook-codeconnections`         |
| Project          | `codeconnections-demo`              |
| Sync Policy      | `Automatic`                         |
| Revision         | `HEAD`                              |
| Path             | `.`                                 |
| Cluster URL      | Select the `argocd-hub` cluster URL |
| Namespace        | `default`                           |

For the **Source** repository URL, run the following command in your terminal and paste the output:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
codeconnection_url
:::
<!-- prettier-ignore-end -->

This returns a URL in the format `https://codeconnections.<region>.amazonaws.com/git-http/<account-id>/<region>/<connection-id>/gitlab/guestbook.git`.

Click **CREATE**.

ArgoCD will use the CodeConnection to pull manifests from the GitLab `guestbook` repository and deploy the application to the hub cluster.

<!-- TODO: Add screenshot of guestbook application synced -->
