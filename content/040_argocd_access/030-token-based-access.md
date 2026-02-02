---
title: "Token-Based Access"
weight: 30
---

::alert[This chapter covers account tokens. We recommend project-based tokens which provide better security through limited scope, as covered in the "RBAC Access" chapter.]{header=Alert}

ArgoCD supports token-based authentication for programmatic access and CLI usage. For example you can provide scoped down token for monitoring agent that only has access to health of applications or an Agentic Agent only has read only access.

ArgoCD cli is already installed for the workshop.

### Token Characteristics

- Duration: Tokens are time bound.
- Scope: Inherit the same permissions as the user who generated them
- Usage: Primarily for CLI access and automation
- Security: Should be treated as sensitive credentials

### Account Token ArgoCD Dashboard

1. On ArgoCD dashboard, navigate to Settings → Accounts and select your account
   ![Accounts Token](/static/images/access/accounts_token.png)
2. Select Generate New and copy the generated token
   ![Accounts Token](/static/images/access/accounts_token_generate.png)
3. On VSCode terminal set ARGOCD_AUTH_TOKEN to the generated token (starts with `eyJ...`)
4. On VSCode terminal set ARGOCD_SERVER to api endpoint. To get the API type argocd_url on VSCode terminal.
   ::alert[Copy Argo API endpoint without https://.]{header=Warning}
5. On VSCode terminal set ARGOCD_OPTS="--grpc-web"
6. Execute cli "argocd account get" to get account details

Example

<!-- prettier-ignore-start -->
:::code{showCopyAction=false showLineNumbers=false language=yaml }
export ARGOCD_AUTH_TOKEN=eeyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ.....
export ARGOCD_SERVER=e6476cxxxx.eks-capabilities.xxxxx.amazonaws.com
export ARGOCD_OPTS="--grpc-web"
argocd account get
Name:               48c1c3f0-4071-7075-acf7-aee48ddb7cb9
Enabled:            true
Capabilities:       apiKey

Tokens:
ID                                    ISSUED AT             EXPIRING AT
30f74d1a-33c2-4095-9bb5-2ccc2fc257fb  2026-01-05T13:22:58Z  2026-01-06T01:22:58Z
:::
<!-- prettier-ignore-end -->

### Token Security

Security Best Practices:

- Never share tokens in plain text
- Store tokens securely (password managers, secure vaults)
- Rotate tokens regularly
- Revoke unused or compromised tokens immediately
