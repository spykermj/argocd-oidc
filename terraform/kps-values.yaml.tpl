grafana:
  ingress:
    enabled: true
    hosts:
      - ${grafana_hostname}
    tls:
      - secretName: grafana-tls
        hosts:
          - ${grafana_hostname}

  grafana.ini:
    auth.azuread:
      name: "Azure AD"
      enabled: true
      allow_sign_up: true
      auto_login: false
      scopes: "openid email profile"
      auth_url: https://login.microsoftonline.com/${azure_tenant}/oauth2/v2.0/authorize
      token_url: https://login.microsoftonline.com/${azure_tenant}/oauth2/v2.0/token
      allowed_domains: ""
      allowed_groups: ""
      allowed_organizations: 38d1ad1e-dfb8-4806-a4c2-e3944a7e9f98
      role_attribute_strict: true
      allow_assign_grafana_admin: true
      skip_org_role_sync: false
      use_pkce: true
    server:
      root_url: https://${grafana_hostname}

  envFromSecret: grafana-azure-oauth2
