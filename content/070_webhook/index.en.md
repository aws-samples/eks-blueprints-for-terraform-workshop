---
title: "On-Demand Reconciliation"
weight: 70
---

<!-- cspell:disable-next-line -->

::video{id=OuNChAxm3Ys}

## On-Demand Reconciliation

By default, ArgoCD checks for changes every 3 minutes. Since we'll be making frequent changes throughout this workshop, waiting isn't practical.

Options to trigger immediate sync:

- Manual: Use the "Sync" button in ArgoCD dashboard or ArgoCD CLI
- Automated: Configure webhooks for real-time notifications

**Webhook Setup with CodeCommit:**
CodeCommit generates EventBridge events for various activities (branch creation, commits, etc.). We'll configure EventBridge to listen specifically for commit events and automatically notify ArgoCD to reconcile the repository.

![ArgoCD Webhook](/static/images/webhook/webhook.png)

This gives us quick feedback when we push changes to codecommit.
