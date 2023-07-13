server:
  extraArgs:
    - --insecure
  ingress:
    enabled: true
    hosts:
      - ${argo_hostname}
    tls:
      - secretName: argocd-tls
        hosts:
          - ${argo_hostname}
  config:
    admin.enabled: "false"
    url: https://${argo_hostname}
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
      g, "Admin", role:admin
      g, "Viewer", role:readonly
    scopes: '[roles]'
configs:
  secret:
    createSecret: false
