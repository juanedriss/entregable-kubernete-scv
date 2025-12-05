resource "null_resource" "create_kind" {
  provisioner "local-exec" {
    command = <<EOT
      Write-Host "=== Creando directorios de datos ==="
      mkdir -Force "..\\data\\mariadb" | Out-Null
      mkdir -Force "..\\data\\matomo" | Out-Null

      Write-Host "=== Comprobando clusters kind existentes ==="
      $clusters = kind get clusters

      if ($clusters -eq $null -or $clusters -eq "" -or $clusters -match "No kind clusters found") {
        Write-Host "=== Creando cluster kind 'matomo-kind' ==="
        kind create cluster --name matomo-kind --config "..\\terraform\\kind-config.yaml" --wait 60s
      } else {
        Write-Host "Cluster matomo-kind ya existe"
      }

      Write-Host "=== Mostrando información del cluster ==="
      kubectl cluster-info --context kind-matomo-kind
    EOT
    interpreter = ["PowerShell", "-Command"]
  }
}
