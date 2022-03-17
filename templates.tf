data "template_file" "portworx_storagecluster" {
  template = <<EOF
kind: StorageCluster
apiVersion: core.libopenstorage.org/v1
metadata:
  name: ${local.px_cluster_id}
  namespace: kube-system
  annotations:%{if !local.px_enterprise }${indent(4, "\nportworx.io/misc-args: \"--oem esse\"")}%{endif}
    portworx.io/is-openshift: "true"
spec:
  image: portworx/oci-monitor:2.7.0
  imagePullPolicy: Always
  kvdb:
    internal: true
  cloudStorage:
    deviceSpecs:
    - type=Premium_LRS,size=${var.disk_size}
    kvdbDeviceSpec: type=Premium_LRS,size=${var.kvdb_disk_size}
    journalDeviceSpec: auto
  secretsProvider: ${local.secret_provider}
  stork:
    enabled: true
    args:
      webhook-controller: "false"
  autopilot:
    enabled: true
    providers:
    - name: default
      type: prometheus
      params:
        url: http://prometheus:9090%{if var.px_enable_monitoring}${indent(2, "\nmonitoring:")}
    prometheus:
      enabled: true%{endif}
      exportMetrics: true%{if var.px_enable_csi}${indent(2, "\nfeatureGates:")}
    CSI: "true"%{endif}
  deleteStrategy:
    type: UninstallAndWipe
  env:
    - name: AZURE_CLIENT_ID
      valueFrom:
        secretKeyRef:
          name: px-azure
          key: AZURE_CLIENT_ID
    - name: AZURE_TENANT_ID
      valueFrom:
        secretKeyRef:
          name: px-azure
          key: AZURE_TENANT_ID
    - name: AZURE_CLIENT_SECRET
      valueFrom:
        secretKeyRef:
          name: px-azure
          key: AZURE_CLIENT_SECRET
%{if !local.px_enterprise}
---
apiVersion: v1
kind: Secret
metadata:
  name: px-essential
  namespace: kube-system
data:
  px-essen-user-id: ${var.portworx_config.user_id}
  px-osb-endpoint: ${var.portworx_config.osb_endpoint}
%{endif}
EOF
}


#based on https://install.portworx.com/?comp=pxoperator
data "template_file" "portworx_operator" {
  template = <<EOF
%{if var.provision}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: portworx-operator
  namespace: kube-system
---
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: px-operator
spec:
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: false
  volumes:
  - secret
  runAsUser:
    rule: 'RunAsAny'
  seLinux:
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: portworx-operator
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["*"]
  - apiGroups: ["policy"]
    resources: ["podsecuritypolicies"]
    resourceNames: ["px-operator"]
    verbs: ["use"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: portworx-operator
subjects:
- kind: ServiceAccount
  name: portworx-operator
  namespace: kube-system
roleRef:
  kind: ClusterRole
  name: portworx-operator
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: portworx-operator
  namespace: kube-system
spec:
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
    type: RollingUpdate
  replicas: 1
  selector:
    matchLabels:
      name: portworx-operator
  template:
    metadata:
      labels:
        name: portworx-operator
    spec:
      containers:
      - name: portworx-operator
        imagePullPolicy: Always
        image: portworx/px-operator:1.7.0
        command:
        - /operator
        - --verbose
        - --driver=portworx
        - --leader-elect=true
        env:
        - name: OPERATOR_NAME
          value: portworx-operator
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: "name"
                    operator: In
                    values:
                    - portworx-operator
              topologyKey: "kubernetes.io/hostname"
      serviceAccountName: portworx-operator
%{endif}
EOF
}

data "template_file" "storage_classes" {
  template = <<EOF
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: portworx-shared-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "1"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  priority_io: "high"
  sharedv4: "true"
allowVolumeExpansion: true
volumeBindingMode: Immediate
reclaimPolicy: Retain
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: portworx-couchdb-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  priority_io: "high"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: portworx-elastic-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  priority_io: "high"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: portworx-solr-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  priority_io: "high"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: portworx-cassandra-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  priority_io: "high"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: portworx-kafka-sc
provisioner: kubernetes.io/portworx-volume
parameters:
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  priority_io: "high"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-metastoredb-sc
parameters:
  priority_io: high
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-shared-gp
parameters:
  priority_io: high
  repl: "1"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  sharedv4: "true"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-shared-premium-lrs
parameters:
  priority_io: high
  repl: "2"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  sharedv4: "true"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-shared-gp3
parameters:
  priority_io: high
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  sharedv4: "true"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-db-gp
parameters:
  repl: "1"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-db-gp3
parameters:
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-nonshared-gp
parameters:
  priority_io: high
  repl: "1"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-nonshared-premium-lrs
parameters:
  priority_io: high
  repl: "2"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-gp3-sc
parameters:
  priority_io: high
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-shared-gp-allow
parameters:
  priority_io: high
  repl: "2"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  sharedv4: "true"
  io_profile: "cms"
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-db2-rwx-sc
parameters:
  block_size: 4096b
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  sharedv4: "true"
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-db2-rwo-sc
parameters:
  priority_io: high
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  sharedv4: "false"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-dv-shared-gp
parameters:
  priority_io: high 
  repl: "1"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  shared: "true"
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-assistant
parameters:
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  priority_io: "high"
  block_size: "64k"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
allowVolumeExpansion: true
provisioner: kubernetes.io/portworx-volume
reclaimPolicy: Retain
volumeBindingMode: Immediate
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: portworx-db2-fci-sc
provisioner: kubernetes.io/portworx-volume
allowVolumeExpansion: true
reclaimPolicy: Retain
volumeBindingMode: Immediate
parameters:
  block_size: 512b
  priority_io: high
  repl: "3"%{if local.px_enterprise && var.portworx_config.enable_encryption}${indent(2, "\nsecure: \"true\"")}%{endif}
  sharedv4: "false"
  io_profile: "db_remote"
  disable_io_profile_protection: "1"
EOF
}