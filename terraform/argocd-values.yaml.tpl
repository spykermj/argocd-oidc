server:
  extraArgs:
    - --insecure
  ingress:
    enabled: true
    hosts:
      - ${argo_hostname}
  config:
    admin.enabled: "false"
    url: https://${argo_hostname}/
    oidc.config: |
      name: Azure
      issuer: https://login.microsoftonline.com/${azure_tenant}/v2.0
      clientID: $oidc.azure.clientId
      clientSecret: $oidc.azure.clientSecret
      requestedScopes:
        - openid
        - profile
        - email
  rbacConfig:
    policy.default: role:null
    policy.csv: |
      p, role:org-admin, applications, create, */*, allow
      p, role:org-admin, applications, update, */*, allow
      p, role:org-admin, applications, delete, */*, allow
      p, role:org-admin, applications, sync, */*, allow
      p, role:org-admin, applications, override, */*, allow
      p, role:org-admin, applications, action/*, */*, allow
      p, role:org-admin, certificates, create, *, allow
      p, role:org-admin, certificates, update, *, allow
      p, role:org-admin, certificates, delete, *, allow
      p, role:org-admin, clusters, create, *, allow
      p, role:org-admin, clusters, update, *, allow
      p, role:org-admin, clusters, delete, *, allow
      p, role:org-admin, repositories, create, *, allow
      p, role:org-admin, repositories, update, *, allow
      p, role:org-admin, repositories, delete, *, allow
      p, role:org-admin, projects, create, *, allow
      p, role:org-admin, projects, update, *, allow
      p, role:org-admin, projects, delete, *, allow
      p, role:org-admin, accounts, update, *, allow
      p, role:org-admin, gpgkeys, create, *, allow
      p, role:org-admin, gpgkeys, delete, *, allow
      p, role:org-admin, exec, create, */*, allow

      g, role:org-admin, role:readonly
      g, "Admin", role:org-admin
      g, "Viewer", role:readonly
    scopes: '[roles]'
configs:
  secret:
    createSecret: false
