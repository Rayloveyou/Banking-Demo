# Phase 1 → Phase 2 Migration Guide

Migration từ Kubernetes manifests (Phase 1) lên Helm Charts (Phase 2)

## 📋 What's New

### Images Updated
- `registry.gitlab.com/...` → `datnxdevops/banking-demo-*:v1` (public Docker Hub)
- No need for ImagePullSecrets

### WebSocket Fixed
- Kong route `/ws`: `strip_path: false` (preserves path for WebSocket)
- Notification service: accepts WebSocket before validating session

### Configuration
- All Phase 1 settings migrated to `values-phase1.yaml`
- Security contexts, resource limits, health checks included
- Kong CORS properly configured

## 🚀 Deployment

### Option 1: Fresh Install
```bash
helm install banking-demo ./banking-demo \
  -f banking-demo/values-phase1.yaml \
  -n banking --create-namespace
```

### Option 2: Upgrade Existing
```bash
helm upgrade --install banking-demo ./banking-demo \
  -f banking-demo/values-phase1.yaml \
  -n banking --create-namespace
```

### Option 3: Dry Run (Preview)
```bash
helm template banking-demo ./banking-demo \
  -f banking-demo/values-phase1.yaml \
  -n banking > generated-manifests.yaml

# Review generated-manifests.yaml, then:
kubectl apply -f generated-manifests.yaml
```

## 📝 Configuration Files

### Main Values
- **`values-phase1.yaml`** - Phase 1 settings
  - Images: datnxdevops registry
  - Kong: WebSocket fix (strip_path: false)
  - Services: auth, account, transfer, notification, frontend
  - Infra: PostgreSQL, Redis, Kong
  - Ingress: npd-banking.co

### Chart Structure
```
banking-demo/
├── Chart.yaml              # Chart metadata
├── values.yaml             # Default values (empty)
├── values-phase1.yaml      # Phase 1 migration config ← USE THIS
├── values-phase8.yaml      # Phase 8 config (RabbitMQ variant)
├── templates/              # Helm templates (shared)
│   ├── *-deployment.yaml   # Service deployments
│   ├── *-service.yaml      # Kubernetes services
│   ├── kong-configmap.yaml # Kong configuration
│   ├── ingress.yaml        # Ingress routing
│   └── ...
└── charts/                 # Sub-charts (service-specific values)
    ├── auth-service/
    ├── notification-service/
    └── ...
```

## ✅ Verification

After deployment:

```bash
# Check releases
helm list -n banking

# Check pods
kubectl get pods -n banking

# Check services
kubectl get svc -n banking

# Check Kong config
kubectl get configmap -n banking kong-config -o yaml | grep -A 5 "notification-ws"

# Verify WebSocket route
# Should show: strip_path: false
```

## 🔍 Customization

To customize deployment:

```bash
# Create custom values file
cp values-phase1.yaml values-custom.yaml

# Edit as needed
nano values-custom.yaml

# Deploy with custom values
helm install banking-demo ./banking-demo \
  -f values-custom.yaml \
  -n banking --create-namespace
```

### Common Customizations

**Change image tag:**
```yaml
auth-service:
  image:
    tag: v2  # instead of v1
```

**Change replicas:**
```yaml
auth-service:
  replicas: 3
```

**Change resources:**
```yaml
auth-service:
  resources:
    requests:
      memory: "256Mi"
      cpu: "200m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

## 🐛 Troubleshooting

### WebSocket 403 Error
- Check Kong config: `strip_path: false` for notification-ws-route
- Verify: `kubectl get configmap kong-config -n banking -o yaml | grep notification-ws-route -A 5`
- If not showing `strip_path: false`, restart Kong pod:
  ```bash
  kubectl rollout restart deployment/kong -n banking
  ```

### Services Not Ready
```bash
# Check logs
kubectl logs -n banking -l app=auth-service --tail=50

# Check events
kubectl describe pod <pod-name> -n banking

# Check readiness probes
kubectl get pods -n banking -o jsonpath='{.items[].status.conditions[]}'
```

### Helm Template Errors
```bash
# Validate chart
helm lint ./banking-demo -f banking-demo/values-phase1.yaml

# Debug template rendering
helm template --debug banking-demo ./banking-demo \
  -f banking-demo/values-phase1.yaml -n banking
```

## 📚 References

- Phase 1 manifests: `/phase1-docker-to-k8s/`
- Helm Chart: `/phase2-helm-chart/banking-demo/`
- Values file: `/phase2-helm-chart/banking-demo/values-phase1.yaml`

## 🎯 Next Steps

1. Deploy Phase 2 Helm chart
2. Verify all pods running: `kubectl get pods -n banking`
3. Test WebSocket: Access app at `http://npd-banking.co:8080/` (with port-forward)
4. Check logs for issues: `kubectl logs -n banking -f <pod-name>`
5. Customize as needed via values files
