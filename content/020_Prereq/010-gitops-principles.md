---
title: "GitOps Principles"
weight: 10
---


::video{id=7g0PJBIca6Y thumbnail="/static/images/thumbnail/prereq-gitops-principles.png"}

### GitOps Principles

GitOps is defined by four [core principles](https://opengitops.dev).

#### Declarative
A system managed by GitOps must have its desired state expressed declaratively.

#### Versioned and Immutable
Desired state is stored in a way that enforces immutability, versioning and retains a complete version history.


#### Pulled Automatically
Software agents automatically pull the desired state declarations from the source.


#### Continuously Reconciled
Software agents continuously observe actual system state and attempt to apply the desired state.