# Traefik Proxy for Local Development

Prerequisites:

- [Docker](https://www.docker.com/)
- [mkcert](https://github.com/FiloSottile/mkcert):

Setup:

1. Use `mkcert` to generate local SSL certificates for your test domain:

```bash
cd certs && mkcert example.test "*.example.test"
```

2. Copy `traefik.config.sample.toml` to `traefik.config.toml` and add your own SSL certificates
3. Add the certificate config to `traefik.config.toml`:

```toml
  [[tls.certificates]]
    certFile = "/etc/certs/example.test+1.pem"
    keyFile = "/etc/certs/example.test+1-key.pem"
```

4. Start docker compose:

```bash
docker-compose up -d
```
