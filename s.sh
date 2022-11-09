registry=atomdatatech.images:5000

function exec_cmd() {
    $1
    if [ $? -ne 0 ]; then
        echo "***************重新执行命令************"
        echo "sudo $1"

    else
        echo "命令++++++++++ $1 执行成功++++++++++++++"
    fi

}
app_image=(apache/apisix:2.13.1-alpine
    # busybox:1.28
    # apache/apisix-dashboard:2.10.1-alpine
    # quay.io/coreos/etcd:v3.4.16
    # apache/apisix-ingress-controller:1.4.0
    # bitnami/bitnami-shell:11-debian-11-r43
)

for image in ${app_image[@]}; do
    echo "执行镜像处理命令"
    echo "docker pull ${image}"
    exec_cmd "docker pull ${image}"
    echo "docker tag ${image} $registry/${image}"
    exec_cmd "docker tag ${image} $registry/${image}"
    echo "docker push $registry/${image}"
    exec_cmd "docker push $registry/${image}"
    echo "docker rmi ${image}"
    exec_cmd "docker rmi ${image}"
    echo "docker rmi $registry/${image}"
    exec_cmd "docker rmi $registry/${image}"
    echo ===========================
done
