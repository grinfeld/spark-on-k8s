SPARK_VERSION ?= 2.4.5
SPARK_VERSION_SUFFIX ?= -bin-hadoop2.7
K8S_VERSION ?= v1.18.2
HELM_VERSION ?= v3.2.1
MIRROR ?= archive.apache.org

OS ?= $(shell uname -s | tr '[:upper:]' '[:lower:]')
ARCH ?= amd64

.PHONY: all
all: k8s-tooling docker-build

#################
## k8s tooling ##
#################

tmp/create:
	mkdir -p "tmp"

bin/kubectl:
	curl -Lo bin/kubectl https://storage.googleapis.com/kubernetes-release/release/$(K8S_VERSION)/bin/$(OS)/$(ARCH)/kubectl
	chmod +x bin/kubectl

tmp/helm:
	curl -Lo tmp/helm.tar.gz https://get.helm.sh/helm-$(HELM_VERSION)-$(OS)-$(ARCH).tar.gz
	tar xvzf tmp/helm.tar.gz
	mv $(OS)-$(ARCH) tmp/helm
	rm -f tmp/helm.tar.gz

bin/helm: tmp/helm
	cp -a tmp/helm/helm bin/helm
	chmod +x bin/helm

.PHONY: helm-repo-update
helm-repo-update: bin/helm
	./bin/helm repo update

.PHONY: helm-init
helm-init: bin/helm
	./bin/helm init --wait

.PHONY: switch/context
helm-init: switch/context
	.bin/kubectl config use-context docker-desktop

.PHONY: k8s-tooling
k8s-tooling: tmp/create bin/kubectl switch/context bin/helm

###############################################################################
##                   Spark docker image building                             ##
## see: https://github.com/apache/spark/blob/master/bin/docker-image-tool.sh ##
###############################################################################

tmp/spark.tgz:
	curl -Lo tmp/spark.tgz https://${MIRROR}/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}${SPARK_VERSION_SUFFIX}.tgz

# preventing issue https://issues.apache.org/jira/browse/SPARK-28921 from happening
.PHONY: patch-SPARK-28921
patch-SPARK-28921:
	curl -Lo tmp/kubernetes-model-4.4.2.jar https://repo1.maven.org/maven2/io/fabric8/kubernetes-model/4.4.2/kubernetes-model-4.4.2.jar
	curl -Lo tmp/kubernetes-model-common-4.4.2.jar https://repo1.maven.org/maven2/io/fabric8/kubernetes-model-common/4.4.2/kubernetes-model-common-4.4.2.jar
	curl -Lo tmp/kubernetes-client-4.4.2.jar https://repo1.maven.org/maven2/io/fabric8/kubernetes-client/4.4.2/kubernetes-client-4.4.2.jar

tmp/spark: tmp/spark.tgz patch-SPARK-28921
	cd tmp && tar xvzf spark.tgz && rm -rf spark && mv spark-${SPARK_VERSION}${SPARK_VERSION_SUFFIX} spark && rm -rfv spark/jars/kubernetes-*.jar && cp -av kubernetes-*.jar spark/jars/

.PHONY: docker-build
docker-build: tmp/spark
	cd tmp/spark && ./bin/docker-image-tool.sh -t latest build

.PHONY: clean
clean:
	rm -rf tmp/* bin/*
