apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: grafana-cert
  namespace: ${namespace}
spec:
  # Secret names are always required.
  secretName: grafana-tls

  duration: 2160h0m0s # 90d
  renewBefore: 360h0m0s # 15d
  subject:
    organizations:
      - jetstack
  # The use of the common name field has been deprecated since 2000 and is
  # discouraged from being used.
  commonName: grafana.spykerman.co.uk
  # I would prefer to be explicit and set isCA to false, but the terraform provider for
  # kubernetes is not great and wants to use null, complaining that things are not consistent
  # isCA: false
  privateKey:
    algorithm: RSA
    encoding: PKCS1
    size: 2048
  usages:
    - server auth
    - client auth
  # At least one of a DNS Name, URI, or IP address is required.
  dnsNames:
    - ${hostname}
  # Issuer references are always required.
  issuerRef:
    name: cluster-issuer
    # We can reference ClusterIssuers by changing the kind here.
    # The default value is Issuer (i.e. a locally namespaced Issuer)
    kind: ClusterIssuer
    # This is optional since cert-manager will default to this value however
    # if you are using an external issuer, change this to that issuer group.
    group: cert-manager.io
