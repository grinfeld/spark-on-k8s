#!/usr/bin/env bash

cat > clustermode-podspec-with-rbac.yaml << EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  name: spark
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: spark-cluster-role
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list", "create", "delete"]
- apiGroups: [""] # "" indicates the core API group
  resources: ["services"]
  verbs: ["get", "create", "delete"]
- apiGroups: [""] # "" indicates the core API group
  resources: ["configmaps"]
  verbs: ["get", "create", "delete"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: spark-cluster-role-binding
subjects:
- kind: ServiceAccount
  name: spark
  namespace: default
roleRef:
  kind: ClusterRole
  name: spark-cluster-role
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: Pod
metadata:
  name: spark-submit-example
spec:
  serviceAccountName: spark
  containers:
  - name: spark-submit-example
    args:
    - /opt/spark/bin/spark-submit
    - --master
    - k8s://https://kubernetes.docker.internal:6443
    - --deploy-mode
    - cluster
    - --conf
    - spark.kubernetes.container.image=spark:latest
    - --conf
    - spark.kubernetes.authenticate.driver.serviceAccountName=spark
    - --class
    - org.apache.spark.examples.SparkPi
    - local:///opt/spark/examples/jars/spark-examples_2.11-2.4.5.jar
    env:
    - name: SPARK_HOME
      value: /opt/spark
    resources: {}
    image: localhost/spark:latest
    imagePullPolicy: Always
EOF
