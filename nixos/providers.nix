{ pkgs, config, ... }:
{
  sops.secrets = {
    authelia_argocd_client_secret_hash = {
      owner = config.systemd.services.authelia-main.serviceConfig.User;
    };
  };
  sops.templates."authelia/providers.yaml" = {
    owner = config.systemd.services.authelia-main.serviceConfig.User;
    content = ''
      identity_providers:
        oidc:
          hmac_secret: ${config.sops.placeholder.hmac_secret}
          jwks:
            - key: {{ secret "${config.sops.secrets.authelia_oidc_private_key.path}" | mindent 10 "|" | msquote }}
              key_id: oidc_key
          clients:
            - client_id: 'argocd'
              client_name: ArgoCD
              client_secret: ${config.sops.placeholder.authelia_argocd_client_secret_hash}
              public: false
              authorization_policy: one_factor
              redirect_uris:
                - https://argocd.k3s.home/auth/callback
              scopes:
                - openid
                - groups
                - email
                - profile
              userinfo_signed_response_alg: none
    '';
  };
}
