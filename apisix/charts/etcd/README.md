# etcd
Helm chart for coreos etcd 3.4+

## Overview

This is a chart based on the incubator chart from helm/charts. Dusted off to function with etcd 3.4 and updated for helm3. It also
adds support for:

* Restore from snapshot
* CronJob to make snapshots
* Prometheus operator support

## Helm Repository

```bash
$ helm repo add mkhpalm https://mkhpalm.github.io/helm-charts/
$ helm repo update
```

## Configuration

The following table lists the configurable parameters of the etcd chart and their default values.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| auth.client.enableAuthentication | bool | `false` |  |
| auth.client.secureTransport | bool | `false` |  |
| auth.peer.enableAuthentication | bool | `false` |  |
| auth.peer.secureTransport | bool | `false` |  |
| auth.peer.useAutoTLS | bool | `false` |  |
| clientPort | int | `2379` |  |
| component | string | `"etcd"` |  |
| extraEnv | list | `[]` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"quay.io/coreos/etcd"` |  |
| image.tag | string | `"v3.4.16"` |  |
| memoryMode | bool | `false` |  |
| nodeSelector | object | `{}` |  |
| peerPort | int | `2380` |  |
| persistentVolume.enabled | bool | `false` |  |
| podAnnotations | object | `{}` |  |
| podMonitor.enabled | bool | `false` |  |
| podMonitor.interval | string | `"30s"` |  |
| podMonitor.metricRelabelings | list | `[]` |  |
| podMonitor.relabelings | list | `[]` |  |
| podMonitor.scheme | string | `"http"` |  |
| podMonitor.scrapeTimeout | string | `"30s"` |  |
| podMonitor.tlsConfig | object | `{}` |  |
| podSecurityContext.fsGroup | int | `1001` |  |
| prometheusRules.enabled | bool | `false` |  |
| prometheusRules.rules | list | `[]` |  |
| replicas | int | `3` |  |
| resources | object | `{}` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `1001` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| snapshot.backup.claimName | string | `nil` |  |
| snapshot.backup.enabled | bool | `false` |  |
| snapshot.backup.historyLimit | int | `1` |  |
| snapshot.backup.resources | object | `{}` |  |
| snapshot.backup.schedule | string | `"*/30 * * * *"` |  |
| snapshot.backup.size | string | `"10Gi"` |  |
| snapshot.backup.snapshotHistoryLimit | int | `1` |  |
| snapshot.backup.storageClassName | string | `"default"` |  |
| snapshot.restore.claimName | string | `nil` |  |
| snapshot.restore.enabled | bool | `false` |  |
| snapshot.restore.fileName | string | `nil` |  |
| tolerations | list | `[]` |  |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install --name my-release -f values.yaml mkhpalm/etcd
```
> **Tip**: You can use the default [values.yaml](values.yaml)
# To install the chart with secure transport enabled
First you must create a secret which would contain the client certificates: cert, key and the CA which was to used to sign them.
Create the secret using this command:
```bash
$ kubectl create secret generic etcd-client-certs --from-file=ca.crt=path/to/ca.crt --from-file=cert.pem=path/to/cert.pem --from-file=key.pem=path/to/key.pem
```
Deploy the chart with the following flags enabled:
```bash
$ helm install --name my-release --set auth.client.secureTransport=true --set auth.client.enableAuthentication=true --set auth.client.existingSecret=etcd-client-certs --set auth.peer.useAutoTLS=true mkhpalm/etcd
```
Reference to how to generate the needed certificate:
> Ref: https://coreos.com/os/docs/latest/generate-self-signed-certificates.html

# Deep dive

## Cluster Health

```
$ for i in <0..n>; do kubectl exec <release-podname-$i> -- sh -c 'etcdctl endpoint health'; done
```
eg.
```
$ for i in {0..2}; do kubectl -n ops exec named-lynx-etcd-$i -- sh -c 'etcdctl endpoint health'; done
127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.880348ms
127.0.0.1:2379 is healthy: successfully committed proposal: took = 2.616944ms
127.0.0.1:2379 is healthy: successfully committed proposal: took = 3.2329ms
```

## Failover

If any etcd member fails it gets re-joined eventually.
You can test the scenario by killing process of one of the replicas:

```shell
$ ps aux | grep etcd-1
$ kill -9 ETCD_1_PID
```

```shell
$ kubectl get pods -l "app.kubernetes.io/instance=${RELEASE-NAME},app.kubernetes.io/name=etcd"
NAME                 READY     STATUS        RESTARTS   AGE
etcd-0               1/1       Running       0          54s
etcd-2               1/1       Running       0          51s
```

After a while:

```shell
$ kubectl get pods -l "app.kubernetes.io/instance=${RELEASE-NAME},app.kubernetes.io/name=etcd"
NAME                 READY     STATUS    RESTARTS   AGE
etcd-0               1/1       Running   0          1m
etcd-1               1/1       Running   0          20s
etcd-2               1/1       Running   0          1m
```

You can check state of re-joining from ``etcd-1``'s logs:

```shell
$ kubectl logs etcd-1
Waiting for etcd-0.etcd to come up
Waiting for etcd-1.etcd to come up
ping: bad address 'etcd-1.etcd'
Waiting for etcd-1.etcd to come up
Waiting for etcd-2.etcd to come up
Re-joining etcd member
Updated member with ID 7fd61f3f79d97779 in cluster
2016-06-20 11:04:14.962169 I | etcdmain: etcd Version: 2.2.5
2016-06-20 11:04:14.962287 I | etcdmain: Git SHA: bc9ddf2
...
```

## Scaling using kubectl

This is for reference. Scaling should be managed by `helm upgrade`

The etcd cluster can be scale up by running ``kubectl patch`` or ``kubectl edit``. For instance,

```sh
$ kubectl get pods -l "app.kubernetes.io/instance=${RELEASE-NAME},app.kubernetes.io/name=etcd"
NAME      READY     STATUS    RESTARTS   AGE
etcd-0    1/1       Running   0          7m
etcd-1    1/1       Running   0          7m
etcd-2    1/1       Running   0          6m

$ kubectl patch statefulset/etcd -p '{"spec":{"replicas": 5}}'
"etcd" patched

$ kubectl get pods -l "app.kubernetes.io/instance=${RELEASE-NAME},app.kubernetes.io/name=etcd"
NAME      READY     STATUS    RESTARTS   AGE
etcd-0    1/1       Running   0          8m
etcd-1    1/1       Running   0          8m
etcd-2    1/1       Running   0          8m
etcd-3    1/1       Running   0          4s
etcd-4    1/1       Running   0          1s
```

Scaling-down is similar. For instance, changing the number of replicas to ``4``:

```sh
$ kubectl edit statefulset/etcd
statefulset "etcd" edited

$ kubectl get pods -l "app.kubernetes.io/instance=${RELEASE-NAME},app.kubernetes.io/name=etcd"
NAME      READY     STATUS    RESTARTS   AGE
etcd-0    1/1       Running   0          8m
etcd-1    1/1       Running   0          8m
etcd-2    1/1       Running   0          8m
etcd-3    1/1       Running   0          4s
```

Once a replica is terminated (either by running ``kubectl delete pod etcd-ID`` or scaling down),
content of ``/var/run/etcd/`` directory is cleaned up.
If any of the etcd pods restarts (e.g. caused by etcd failure or any other),
the directory is kept untouched so the pod can recover from the failure.
