#! /bin/bash
cur_path=$(dirname $(readlink -f $0))
echo $cur_path
echo '切换到执行目录'
cd $cur_path
registry=$1
name_space=$2
if [ ! -n "$1" ]; then
    echo "脚本参数一缺失,请输入镜像服务器地址,在试"
    exit 1
fi
if [ ! -n "$2" ]; then
    echo "脚本参数二缺失,请输入命名空间,在试"
    exit 1
fi
sudo docker load <apisix_images.tar

sudo docker tag apache/apisix:2.13.1-alpine $registry/apache/apisix:2.13.1-alpine
sudo docker tag busybox:1.28 $registry/busybox:1.28
sudo docker tag apache/apisix-dashboard:2.10.1-alpine $registry/apache/apisix-dashboard:2.10.1-alpine
sudo docker tag quay.io/coreos/etcd:v3.4.16 $registry/quay.io/coreos/etcd:v3.4.16
sudo docker tag apache/apisix-ingress-controller:1.4.0 $registry/apache/apisix-ingress-controller:1.4.0
sudo docker tag bitnami/bitnami-shell:11-debian-11-r43 $registry/bitnami/bitnami-shell:11-debian-11-r43

sudo docker push $registry/busybox:1.28
sudo docker push $registry/apache/apisix:2.13.1-alpine
sudo docker push $registry/apache/apisix-dashboard:2.10.1-alpine
sudo docker push $registry/quay.io/coreos/etcd:v3.4.16
sudo docker push $registry/apache/apisix-ingress-controller:1.4.0
sudo docker push $registry/bitnami/bitnami-shell:11-debian-11-r43

sudo docker rmi apache/apisix:2.13.1-alpine
sudo docker rmi busybox:1.28
sudo docker rmi apache/apisix-dashboard:2.10.1-alpine
sudo docker rmi quay.io/coreos/etcd:v3.4.16
sudo docker rmi apache/apisix-ingress-controller:1.4.0
sudo docker rmi bitnami/bitnami-shell:11-debian-11-r43

sudo docker rmi $registry/busybox:1.28
sudo docker rmi $registry/apache/apisix:2.13.1-alpine
sudo docker rmi $registry/apache/apisix-dashboard:2.10.1-alpine
sudo docker rmi $registry/quay.io/coreos/etcd:v3.4.16
sudo docker rmi $registry/apache/apisix-ingress-controller:1.4.0
sudo docker rmi $registry/bitnami/bitnami-shell:11-debian-11-r43

sudo helm upgrade --install apisix apisix-0.9.4.tgz --namespace $name_space --create-namespace \
    --set apisix.initCImage.image=$registry/busybox \
    --set apisix.image.repository=$registry/apache/apisix \
    --set etcd.image.repository=$registry/quay.io/coreos/etcd \
    --set etcd.volumePermissions.image.registry=$registry \
    --set dashboard.image.repository=$registry/apache/apisix-dashboard \
    --set ingress-controller.image.repository=$registry/apache/apisix-ingress-controller \
    --set ingress-controller.config.apisix.serviceNamespace=$name_space \
    --set ingress-controller.initContainer.image=$registry/busybox
