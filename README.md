# Inception-of-Things (IoT)

A 42 School project introducing Kubernetes through three progressive parts: K3s with Vagrant, K3s Ingress routing, and K3d with Argo CD.

---

## Requirements

- [Vagrant](https://www.vagrantup.com/)
- [VirtualBox](https://www.virtualbox.org/) (or any Vagrant-compatible provider)
- [Docker](https://www.docker.com/) (for Part 3)
- [K3d](https://k3d.io/) (for Part 3)

The root `scripts/setup.sh` script can install Vagrant and VirtualBox on a Debian/Ubuntu host automatically.

---

## Part 1 — K3s and Vagrant

**Location:** `p1/`

Sets up two virtual machines connected over a private network:

| Machine | Hostname | IP | K3s role |
|---|---|---|---|
| Server | `tclaerebS` | `192.168.56.110` | Controller (server mode) |
| Worker | `tclaerebSW` | `192.168.56.111` | Agent (worker mode) |

The server writes its node token to a shared `/vagrant/node-token.tmp` file which the agent reads to join the cluster. The file is deleted after the agent registers.

```sh
cd p1
vagrant up
vagrant ssh tclaerebS
kubectl get nodes -o wide
```

---

## Part 2 — K3s and Three Simple Applications

**Location:** `p2/`

One VM (`<USER>S` at `192.168.56.110`) running K3s in server mode, hosting three web applications routed by an Ingress controller based on the HTTP `Host` header.

| Host | Application | Replicas |
|---|---|---|
| `app1.com` | app1 | 1 |
| `app2.com` | app2 | 3 |
| `app3.com` (default) | app3 | 1 |

Each app serves a static HTML page via an nginx container. The configuration for each app lives in `p2/confs/appN/` (deployment, service, index.html). The Ingress rules are defined in `p2/confs/ingress.yaml`.

```sh
cd p2
vagrant up
# Test routing from your host:
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl http://192.168.56.110  # returns app3 (default)
```

---

## Part 3 — K3d and Argo CD

**Location:** `p3/`

Runs entirely inside a single VM. No Vagrant multi-machine setup — K3d creates a lightweight Kubernetes cluster inside Docker.

### What gets installed

`p3/scripts/install.sh` installs: `curl`, Docker, K3d, `kubectl`, then:

1. Creates a K3d cluster with a load balancer exposing port 80.
2. Creates two namespaces:
   - `argocd` — runs the Argo CD control plane.
   - `dev` — hosts the deployed application.
3. Deploys Argo CD into the `argocd` namespace.

### Running it

```sh
cd p3
make          # installs everything and starts port-forwarding argocd-server on port 8001
```

Argo CD UI will be available at `https://<VM_IP>:8001`.

The cluster name is defined at the top of the Makefile (`CLUSTER_NAME`).

### Continuous deployment flow

```
GitHub repo (manifests/) --> Argo CD (argocd ns) --> deploys app (dev ns)
```

Updating the image tag in your GitHub repository triggers Argo CD to automatically sync and redeploy the application in the `dev` namespace.

---

## Repository structure

```
.
├── p1/
│   ├── Vagrantfile
│   └── scripts/
│       ├── server.sh       # installs K3s in server mode
│       └── agent.sh        # installs K3s in agent mode, joins the cluster
├── p2/
│   ├── Vagrantfile
│   ├── scripts/
│   │   └── server.sh       # installs K3s + deploys all apps and ingress
│   └── confs/
│       ├── app1/           # deployment, service, index.html
│       ├── app2/
│       ├── app3/
│       └── ingress.yaml
├── p3/
│   ├── Vagrantfile
│   ├── Makefile
│   ├── scripts/
│   │   └── install.sh      # installs Docker, K3d, kubectl, ArgoCD
│   └── confs/
│       └── argocd/
│           └── ingress.yaml
└── scripts/
    └── setup.sh            # installs Vagrant + VirtualBox on the host
```