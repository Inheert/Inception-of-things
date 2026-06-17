CLUSTER_NAME="CrazyCluster"
PRIVATE_IP=$(shell ip a show eth1 | grep -Eo 'inet ([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')

all: install run

clean:
	@rm -f logs/display.log
	@sudo ./scripts/cleaning.sh $(CLUSTER_NAME)

fclean: clean

install:
	@sudo ./scripts/install.sh $(CLUSTER_NAME)
	@rm -f kubectl kubectl.sha256

run:
	@sudo ./scripts/run.sh $(CLUSTER_NAME)

get-health:
	@sudo ./scripts/health.sh

watch-health:
	@while true; do clear; sudo ./scripts/health.sh; sleep 2; done
