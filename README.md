# Spark on K8s with Docker Desktop

The source is https://github.com/olxgroup-oss/spark-on-k8s (https://spark.apache.org/docs/latest/running-on-kubernetes.html)
and reference https://medium.com/faun/apache-spark-on-kubernetes-docker-for-mac-2501cc72e659

## Objective

Running k8s locally without installing minikube and docker registry

## Pre-requisites

(from original article)

- [docker](https://docs.docker.com/install/)
- [direnv](https://direnv.net/docs/installation.html)
- [make](https://www.gnu.org/software/make/)
- [curl](https://curl.haxx.se/)
- [tar](https://www.gnu.org/software/tar/)

## Instructions

```bash
Go to Docker preferences -> Kubernetes and check "enable Kubernetes" option (and restart docker) 

# this will install k8s tooling locally, initialize helm and build spark dockers locally 
make

# if everything goes well, you should see spark images by typing

# it's included in 'make', but if you need to re-run building spark images again, just execute
make docker-build

# once your images are pushed, let's run a sample spark job (first on client mode)
tmp/spark/bin/spark-submit \
    --master k8s://https://kubernetes.docker.internal:6443 \
    --deploy-mode client \
    --conf spark.kubernetes.container.image=spark:latest \
    --class org.apache.spark.examples.SparkPi \
    local://<replace with project directory here>/tmp/spark/examples/jars/spark-examples_2.11-2.4.5.jar

# ... and now, the same job but from within a pod in cluster mode
./bin/kubectl apply -f clustermode-podspec-with-rbac.yaml # make sure you check the contents of this file to understand better how it works

# in case you want to rerun the example above, make sure you delete the pod first
./bin/kubectl delete pod spark-submit-example

# check the executor pods in another terminal window while running
./bin/kubectl get pods -w

# deletes
make clean
```

If you have multiple k8s contexts

``kubectl config get-contexts``

    CURRENT   NAME                                                 CLUSTER                                              AUTHINFO                                             NAMESPACE
              docker-desktop                                       docker-desktop                                       docker-desktop
              docker-for-desktop                                   docker-desktop                                       docker-desktop
    *         minikube                                             minikube                                             minikube

you can manual to switch to other contexts: 

``kubectl config use-context docker-desktop``

Check k8s cluster end-point: 

``kubectl cluster-info``

If you want to run k8s web dashboard, run

``minikube dashboard``