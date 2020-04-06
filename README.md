# Traefik Proxy for Local Development

### Install on Mac:

Run the one-line installation script below.

**via curl**

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/zerooneagency/traefik/v0.0.2/bin/traefik-setup.sh)"
```

**via wget**

```sh
sh -c "$(wget -O- https://raw.githubusercontent.com/zerooneagency/traefik/v0.0.2/bin/traefik-setup.sh)"
```

> Traefik will be installed under the `~/.traefik/` folder.

### Starting Traefik:

After the setup script is done Traefik should be up and running. If you ever need to restart it, use the following script:

```sh
~/.traefik/bin/traefik
```

> Tip: Add the `~/.traefik/bin` folder to your PATH so you can run `traefik` without the full path.

### Setting up a new domain:

The following command will generate an SSL certificate for the new domain `example.test` and restart Traefik (if it wasn't already running):

```sh
~/.traefik/bin/traefik example.test
```
