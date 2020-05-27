#!/usr/bin/env bash

# run this script after running make, otherwise it will fail
./bin/kubectl cluster-info|grep "Kubernetes master"|awk '{print $6}'