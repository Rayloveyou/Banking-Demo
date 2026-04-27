{{- /*
Unified Microservice Service Template
Usage: include "banking-demo.microservice.service" (dict "root" . "svcName" "auth-service")
*/ -}}
{{- define "banking-demo.microservice.service" -}}
{{- $root := .root -}}
{{- $svcName := .svcName -}}
{{- $svc := index $root.Values $svcName -}}
{{- if $svc.enabled }}
apiVersion: v1
kind: Service
metadata:
  name: {{ $svcName }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    app: {{ $svcName }}
    app.kubernetes.io/name: {{ include "banking-demo.chart" $root }}
    app.kubernetes.io/instance: {{ $root.Release.Name }}
    app.kubernetes.io/component: {{ $svcName }}
spec:
  {{- if eq $svc.service.type "ClusterIP" }}
  type: ClusterIP
  {{- else if eq $svc.service.type "ExternalName" }}
  type: ExternalName
  externalName: {{ $svc.service.externalName }}
  {{- else }}
  type: {{ $svc.service.type | default "ClusterIP" }}
  {{- end }}
  selector:
    app: {{ $svcName }}
  ports:
    - port: {{ $svc.service.port }}
      targetPort: {{ $svc.service.targetPort | default $svc.service.port }}
      name: {{ $svc.service.portName | default "http" }}
      protocol: TCP
{{- end }}
{{- end }}
