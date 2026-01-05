---
title: "First Login Walkthrough"
weight: 20
---


This section walks through the complete login process using the `argoadmin` user. This same process applies to other users created in Identity Center.

::alert[Make sure you have copied argoadmin temporary generated password as described in "ArgoCD Authentication Setup>User Management>Generate Passwrod temporary for argoadmin" section.]{header=Tip}

### 1. Initiate Login

![Login Via SSO](/static/images/access/login_via_sso.png)

Select "LOG IN VIA SSO"

### 2: Identity Center Authentication

 Enter `argoadmin` as the username and Click "Next" 

![Enter UserId](/static/images/access/enter_userid.png)

Enter Temporary Password and Click "Sign in"

![Enter Password](/static/images/access/enter_password.png)

### 3: Password Reset (First Login)

Enter the new password and confirm the password.

![Set New Password](/static/images/access/set_new_password.png)


### 4: Access ArgoCD Dashboard

After successful authentication, you'll be redirected to ArgoCD dashboard.

![Argo Dashboard](/static/images/access/argo_dashboard.png)