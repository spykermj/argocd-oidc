server:
  extraArgs:
    - --insecure
  ingress:
    enabled: true
    hosts:
      - ${argo_hostname}
  config:
    admin.enabled: "false"
    url: https://${argo_hostname}
    dex.config: |
      logger:
        level: debug
        format: json
      connectors:
      - type: saml
        id: saml
        name: saml
        config:
          entityIssuer: ${issuer}
          ssoURL: https://login.microsoftonline.com/${azure_tenant}/saml2
          caData: |
            ${cert}
          redirectURI: https://${argo_hostname}/api/dex/callback
          usernameAttr: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
          emailAttr: http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress
          groupsAttr: http://schemas.microsoft.com/ws/2008/06/identity/claims/role
  rbacConfig:
    policy.default: role:null
    policy.csv: |
      g, "Admin", role:admin
      g, "Viewer", role:readonly
