{{- /*
Unified Microservice Deployment Template
Usage: include "banking-demo.microservice.deployment" (dict "root" . "svcName" "auth-service")
*/ -}}
{{- define "banking-demo.microservice.deployment" -}}
{{- $root := .root -}}
{{- $svcName := .svcName -}}
{{- $svc := index $root.Values $svcName -}}
{{- if $svc.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ $svcName }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    app: {{ $svcName }}
    app.kubernetes.io/name: {{ include "banking-demo.chart" $root }}
    app.kubernetes.io/instance: {{ $root.Release.Name }}
    app.kubernetes.io/component: {{ $svcName }}
spec:
  replicas: {{ $svc.replicas }}
  selector:
    matchLabels:
      app: {{ $svcName }}
  template:
    metadata:
      labels:
        app: {{ $svcName }}
    spec:
      {{- with $svc.securityContext.pod }}
      securityContext:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if $svc.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml $svc.imagePullSecrets | nindent 8 }}
      {{- end }}
      containers:
        - name: {{ $svcName }}
          image: "{{ $svc.image.repository }}:{{ $svc.image.tag }}"
          imagePullPolicy: {{ $svc.image.pullPolicy }}
          {{- with $svc.securityContext.container }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          ports:
            - containerPort: {{ $svc.service.port }}
              name: {{ $svc.service.portName | default "http" }}
          resources:
            {{- toYaml $svc.resources | nindent 12 }}
          env:
            {{- if $svc.secretRef }}
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: {{ $svc.secretRef.name }}
                  key: {{ $svc.secretRef.keys.databaseUrl }}
            - name: REDIS_URL
              valueFrom:
                secretKeyRef:
                  name: {{ $svc.secretRef.name }}
                  key: {{ $svc.secretRef.keys.redisUrl }}
            {{- end }}
            {{- if $svc.rabbitmqSecretRef }}
            - name: RABBITMQ_URL
              valueFrom:
                secretKeyRef:
                  name: {{ $svc.rabbitmqSecretRef.name }}
                  key: {{ $svc.rabbitmqSecretRef.key }}
            {{- end }}
            {{- if $svc.corsOrigins }}
            - name: CORS_ORIGINS
              value: {{ $svc.corsOrigins | quote }}
            {{- end }}
            {{- range $k, $v := $svc.extraEnv }}
            - name: {{ $k }}
              value: {{ $v | quote }}
            {{- end }}
          {{- if $svc.readinessProbe.enabled }}
          readinessProbe:
            httpGet:
              path: {{ $svc.readinessProbe.path }}
              port: {{ $svc.readinessProbe.port }}
            initialDelaySeconds: {{ $svc.readinessProbe.initialDelaySeconds }}
            periodSeconds: {{ $svc.readinessProbe.periodSeconds }}
            {{- if $svc.readinessProbe.timeoutSeconds }}
            timeoutSeconds: {{ $svc.readinessProbe.timeoutSeconds }}
            {{- end }}
          {{- end }}
{{- end }}
{{- end }}
