---
title: "CodeConnections"
weight: 010
---

::alert[In this chapter, AWS CodeConnections is used to connect ArgoCD to a private GitLab repository. GitLab runs on a private network and CodeConnections accesses it through a VPC configuration. However, the CodeConnections OAuth setup requires your browser to reach GitLab directly to approve the connection. Since workshop participants don't have VPN access to the private network, GitLab is exposed via an internet-facing load balancer for this step. In your organization, you would complete the OAuth handshake from a machine on the private network (e.g., via VPN) and keep GitLab fully private ]{header="Important" type="warning"}

### 1. Access the Gitlab

You can access the gitlab url from the terminal:

<!-- prettier-ignore-start -->
:::code{showCopyAction=true showLineNumbers=false language=bash }
gitlab_url
:::
<!-- prettier-ignore-end -->

You will login with credentials **gitlab/argocdonaws**

::alert[You'll see a browser warning about an untrusted certificate. This is expected — the workshop uses a self-signed cert. Proceed past the warning to access GitLab ]{header="Important" type="warning"}

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
3. Under **URL**, enter the host provider URL. You can get this from the terminal:
   <!-- prettier-ignore-start -->
   :::code{showCopyAction=true showLineNumbers=false language=bash }
   gitlab_url
   :::
   <!-- prettier-ignore-end -->
4. Make sure **Use a VPC** is selected
5. Click **Connect to GitLab self-managed**

![Create Connection Values](/static/images/codeconnections/create-connection-values.png)

### 4. Update Connection

The connection will be created in **Pending** status. Click **Update pending connection** to complete the OAuth handshake.

This will redirect your browser to your GitLab instance. Log in with credentials **gitlab/argocdonaws** and click **Authorize** to grant CodeConnections access.

<!-- TODO: Add screenshot of GitLab OAuth authorize page -->

After authorization, the connection status should change from **Pending** to **Available**.

<!-- TODO: Add screenshot of connection in Available status -->
