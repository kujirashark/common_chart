#! /bin/bash
docker pull apache/apisix:2.13.1-alpine
docker pull busybox:1.28
docker pull apache/apisix-dashboard:2.10.1-alpine
docker pull quay.io/coreos/etcd:v3.4.16
docker pull apache/apisix-ingress-controller:1.4.0
docker pull bitnami/bitnami-shell:11-debian-11-r43

docker save apache/apisix:2.13.1-alpine \
    busybox:1.28 \
    apache/apisix-dashboard:2.10.1-alpine \
    quay.io/coreos/etcd:v3.4.16 \
    bitnami/bitnami-shell:11-debian-11-r43 \
    apache/apisix-ingress-controller:1.4.0 >apisix_images.tar
