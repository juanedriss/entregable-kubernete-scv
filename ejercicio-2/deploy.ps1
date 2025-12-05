<#
deploy.ps1
Script para desplegar Matomo + MariaDB en kind.
Versión autodetectada para Windows.
#>

param(
  [string] $ClusterName = "matomo-kind"
)

Write-Host "== deploy.ps1: Despliegue de Matomo + MariaDB en kind ($ClusterName) =="

# -----------------------------------------------------------
# 🔍 1) Detectar el contenedor control-plane AUTOMÁTICAMENTE
# -----------------------------------------------------------
$controlPlaneContainer = docker ps --format "{{.Names}}" | Where-Object { $_ -match "$ClusterName-control-plane" }

if (-not $controlPlaneContainer) {
    # Como fallback, buscar cualquier nodo control-plane
    $controlPlaneContainer = docker ps --format "{{.Names}}" | Where-Object { $_ -match "control-plane" }
}

if (-not $controlPlaneContainer) {
    Write-Error "ERROR: No se encontró ningún contenedor control-plane. Asegúrate de que el cluster kind está creado."
    exit 1
}

Write-Host "Nodo detectado correctamente: $controlPlaneContainer" -ForegroundColor Green

# -----------------------------------------------------------
# 2) Crear rutas de persistencia dentro del nodo kind
# -----------------------------------------------------------
Write-Host "`n== Creando carpetas de persistencia en el nodo =="
docker exec $controlPlaneContainer mkdir -p /kind/data/ejercicio-2/mariadb
docker exec $controlPlaneContainer mkdir -p /kind/data/ejercicio-2/matomo

docker exec $controlPlaneContainer chown -R 1000:1000 /kind/data/ejercicio-2/mariadb
docker exec $controlPlaneContainer chown -R 1000:1000 /kind/data/ejercicio-2/matomo

# -----------------------------------------------------------
# 3) Aplicar PV + PVC
# -----------------------------------------------------------
Write-Host "`n== Aplicando PVs y PVCs..."
kubectl apply -f ejercicio-2/k8s/pv-mariadb.yaml
kubectl apply -f ejercicio-2/k8s/pvc-mariadb.yaml
kubectl apply -f ejercicio-2/k8s/pv-matomo.yaml
kubectl apply -f ejercicio-2/k8s/pvc-matomo.yaml

# -----------------------------------------------------------
# 4) Desplegar MariaDB
# -----------------------------------------------------------
Write-Host "`n== Desplegando MariaDB..."
kubectl apply -f ejercicio-2/k8s/mariadb-deployment.yaml
kubectl apply -f ejercicio-2/k8s/mariadb-service.yaml

Write-Host "Esperando a que MariaDB esté lista..."
kubectl wait --for=condition=ready pod -l app=mariadb --timeout=180s

# -----------------------------------------------------------
# 5) Desplegar Matomo
# -----------------------------------------------------------
Write-Host "`n== Desplegando Matomo..."
kubectl apply -f ejercicio-2/k8s/matomo-deployment.yaml
kubectl apply -f ejercicio-2/k8s/matomo-service.yaml

Write-Host "Esperando a que Matomo esté listo..."
kubectl wait --for=condition=ready pod -l app=matomo --timeout=180s

# -----------------------------------------------------------
# 6) Mensaje final
# -----------------------------------------------------------
Write-Host "`n== DESPLIEGUE COMPLETADO ==" -ForegroundColor Cyan
Write-Host "Accede a Matomo en: http://localhost:8081"
Write-Host "`nComandos para validar dentro del pod:"
Write-Host "  kubectl get pods"
Write-Host "  kubectl exec -it <pod-matomo> -- cat /usr/local/etc/php/conf.d/zzz-matomo.ini"
Write-Host "  kubectl exec -it <pod-matomo> -- cat /usr/local/bin/matomo-build-info.txt (si lo añadiste)"
