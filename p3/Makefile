CLUSTER_NAME="CrazyCluster"
PRIVATE_IP=$(shell ip a show eth1 | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

all: install clean run-argocd

clean:
	@rm kubectl kubectl.sha256

install:
	@sudo sh ./scripts/install.sh $(CLUSTER_NAME)

run-argocd:
	@sudo kubectl port-forward svc/argocd-server -n argocd 8001:443 --address $(PRIVATE_IP)

