---
title: 'Fork workshop repo'
weight: 10
---

### 1. Github account

You need to have a github account. 

If you don't have an account

1. Navigate to https://github.com/
2. Click Sign up
3. Follow the prompts to create an account

### 2. Fork the workshop repository 
Forking a repository makes a copy of the workshop files into your github account. You will update your repository throughout the workshop.

1. Navigate to https://github.com/aws-samples/eks-blueprints-for-terraform-workshop
2. On the top-right corner of the page, click Fork

    ![GitHub Fork](/static/images/github-fork.png)
3. Under "Owner," select the dropdown menu and click an owner for the forked repository
4. Set the repository name as tfblueprint
5. Click Create Fork

### 3. Generate Github access token
Throughout the workshop you will be updating the forked repository. You will use token to authenticate to github.

1. Navigate to https://github.com
2. In the upper-right corner of any page, click your profile photo, then click Settings

   ![GitHub Fork](/static/images/github-setting.png)
3. On the left sidebar, click Developer settings
4. In the left sidebar, under Personal access tokens, click Fine-grained tokens
5. Click Generate new token. Use the default value for any field that is not explicitly specified in the steps below.
6. Under Token name, enter a name for the token
7. Under Expiration, select an expiration for the token
8. Under Repository access, click "Only select repositories" and   select the forked tfblueprint repository
9. Under Permissions, select Repository Permissions
10. Select Action dropdown and select "Read and Write"

    ![GitHub Fork](/static/images/github-permission.png)
11. Click Generate Token. Store this token safely. You will need this token throughout the workshop. If you loose generate a new token.

