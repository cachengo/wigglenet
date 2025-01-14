# This makefile just has useful shortcuts for testing locally with kind. If you want to build the 
# project itself, do so via the go toolchain or Dockerfile.

.PHONY: image kind-default kind-no-podcidr kind-v4-only patch-ipv6-cidr deploy restart logs

kind-default:
	kind create cluster --config testing/cluster.yaml

kind-no-podcidr:
	kind create cluster --config testing/cluster_no_podcidr.yaml

kind-v4-only:
	kind create cluster --config testing/cluster_v4_only.yaml

kind-v6-singlestack:
	kind create cluster --config testing/cluster_v6_singlestack.yaml

image: 
	docker build -t wigglenet .
	kind load docker-image wigglenet

# Patch manifest to use local Docker image instead of one from Dockerhub
deploy:
	sed 's\tibordp/wigglenet:.*\wigglenet\g' ./deploy/manifest.yaml \
		| sed 's/Always/Never/g' \
		| kubectl --context=kind-kind apply -f -

restart:
	kubectl --context=kind-kind delete pod -n kube-system -l app=wigglenet

logs:
	kubectl --context=kind-kind logs -n kube-system -l app=wigglenet

patch-ipv6-cidr:
	echo "2001:db8:0:1::/64" | docker exec -i kind-control-plane tee /etc/wigglenet/cidrs.txt
	echo "2001:db8:0:2::/64" | docker exec -i kind-worker tee /etc/wigglenet/cidrs.txt
	echo "2001:db8:0:3::/64" | docker exec -i kind-worker2 tee /etc/wigglenet/cidrs.txt
	echo "2001:db8:0:4::/64" | docker exec -i kind-worker3 tee /etc/wigglenet/cidrs.txt
