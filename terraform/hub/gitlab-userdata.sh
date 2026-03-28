#!/bin/bash
set -e

# Install Docker
dnf install docker -y
systemctl start docker
systemctl enable docker

# Write TLS cert and key from Terraform
mkdir -p /opt/gitlab-ssl
cat > /opt/gitlab-ssl/gitlab.crt <<'CERT'
${tls_cert}
CERT
cat > /opt/gitlab-ssl/gitlab.key <<'KEY'
${tls_key}
KEY

# Run GitLab CE (HTTPS with Terraform-generated cert)
docker run -d \
  --name gitlab \
  -p 443:443 \
  -v gitlab_config:/etc/gitlab \
  -v gitlab_logs:/var/log/gitlab \
  -v gitlab_data:/var/opt/gitlab \
  -v /opt/gitlab-ssl:/etc/gitlab/ssl:ro \
  --restart always \
  -e GITLAB_OMNIBUS_CONFIG="external_url 'https://${nlb_dns_name}'; \
    letsencrypt['enable'] = false; \
    nginx['ssl_certificate'] = '/etc/gitlab/ssl/gitlab.crt'; \
    nginx['ssl_certificate_key'] = '/etc/gitlab/ssl/gitlab.key'; \
    nginx['redirect_http_to_https'] = false; \
    nginx['listen_port'] = 443; \
    nginx['listen_https'] = true; \
    gitlab_rails['monitoring_whitelist'] = ['0.0.0.0/0'];" \
  gitlab/gitlab-ce:latest

# Wait for GitLab to be ready
echo "Waiting for GitLab to start..."
until docker exec gitlab curl -skf https://localhost/gitlab/-/readiness > /dev/null 2>&1; do
  sleep 10
  echo "Still waiting..."
done
echo "GitLab is ready!"

# Relax password policy for workshop users
docker exec gitlab gitlab-rails runner '
  settings = ApplicationSetting.current
  settings.password_number_required = false
  settings.password_lowercase_required = false
  settings.password_uppercase_required = false
  settings.password_symbol_required = false
  settings.password_dictionary_check = false
  settings.save!
  puts "SUCCESS: Password policy relaxed"
'

# Create admin user and PAT
docker exec gitlab gitlab-rails runner '
  org = Organizations::Organization.first
  u = User.new(
    username: "gitlab",
    email: "admin@example.com",
    name: "GitLab Admin",
    password: "argocdonaws",
    password_confirmation: "argocdonaws",
    admin: true,
    organization_id: org.id
  )
  u.build_namespace(path: u.username, name: u.username, organization_id: org.id)
  u.skip_confirmation!
  if u.save
    puts "SUCCESS: User created!"
    token = u.personal_access_tokens.create(
      name: "codeconnections",
      scopes: ["api", "admin_mode"],
      expires_at: 1.year.from_now
    )
    token.set_token("glpat-workshop-token-12345")
    token.save!
    puts "SUCCESS: PAT created: #{token.token}"
  else
    puts "FAILED: #{u.errors.full_messages}"
  end'

# Create repo
docker exec gitlab gitlab-rails runner "
  user = User.find_by_username('gitlab')
  org = Organizations::Organization.default_organization
  project_params = {
    name: 'guestbook',
    path: 'guestbook',
    namespace_id: user.namespace.id,
    organization_id: org.id,
    visibility_level: Gitlab::VisibilityLevel::PRIVATE
  }
  project = Projects::CreateService.new(user, project_params).execute
  if project.persisted?
    puts 'SUCCESS: Project Created at ' + project.full_path
  else
    puts 'ERROR: ' + project.errors.full_messages.to_sentence
  end"

# Add manifest files to repo
docker exec gitlab gitlab-rails runner "
  user = User.find_by_username('gitlab')
  project = Project.find_by_full_path('gitlab/guestbook')

  deploy_yaml = <<~YAML
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: guestbook-ui
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: guestbook-ui
      template:
        metadata:
          labels:
            app: guestbook-ui
        spec:
          containers:
          - image: quay.io/argoprojlabs/argocd-e2e-container:0.2
            name: guestbook-ui
            ports:
            - containerPort: 80
  YAML

  svc_yaml = <<~YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: guestbook-ui
    spec:
      ports:
      - port: 80
        targetPort: 80
      selector:
        app: guestbook-ui
  YAML

  result = ::Files::MultiService.new(project, user, {
    branch_name: 'main',
    commit_message: 'Initial commit of guestbook app',
    actions: [
      { action: 'create', file_path: 'guestbook-ui-deployment.yaml', content: deploy_yaml },
      { action: 'create', file_path: 'guestbook-ui-svc.yaml', content: svc_yaml }
    ]
  }).execute

  puts result[:status] == :success ? 'SUCCESS: Files are now in GitLab!' : \"ERROR: \#{result[:message]}\"
"

# Refresh project authorizations
docker exec gitlab gitlab-rails runner "
  user = User.find_by_username('gitlab')
  if user
    user.refresh_authorized_projects
    puts 'SUCCESS: Project authorizations refreshed.'
  else
    puts 'ERROR: User gitlab not found.'
  end"

# Create argocd-bot service account with Reporter (read-only) access to the repo
docker exec gitlab gitlab-rails runner '
  org = Organizations::Organization.first
  bot = User.new(
    username: "argocd-bot",
    email: "argocd-bot@example.com",
    name: "ArgoCD Bot",
    password: "argocdonaws",
    password_confirmation: "argocdonaws",
    admin: false,
    organization_id: org.id
  )
  bot.build_namespace(path: bot.username, name: bot.username, organization_id: org.id)
  bot.skip_confirmation!
  if bot.save(validate: false)
    puts "SUCCESS: argocd-bot user created"
    org.organization_users.create!(user: bot, access_level: :default)
    project = Project.find_by_full_path("gitlab/guestbook")
    member = project.add_member(bot, Gitlab::Access::REPORTER)
    if member.persisted?
      puts "SUCCESS: argocd-bot added as Reporter to #{project.full_path}"
    else
      puts "FAILED to add to project: #{member.errors.full_messages}"
    end
  else
    puts "FAILED: #{bot.errors.full_messages}"
  end'

echo "GitLab setup complete!"
