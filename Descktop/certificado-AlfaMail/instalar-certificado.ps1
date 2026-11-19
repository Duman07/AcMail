<#
.SYNOPSIS
  Instala (o quita) el certificado de firma interno de AlfaMail en este equipo.

.DESCRIPTION
  Añade AlfaMail-firma.cer a los almacenes del EQUIPO:
    - Entidades de certificación raíz de confianza (Root)
    - Editores de confianza (TrustedPublisher)
  Así Windows muestra «Editor verificado: AlfaMail» al instalar y ejecutar AlfaMail.
  Solo contiene la parte PÚBLICA del certificado; no permite firmar nada.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File instalar-certificado.ps1
  powershell -ExecutionPolicy Bypass -File instalar-certificado.ps1 -Quitar
#>
#Requires -RunAsAdministrator
param(
  [string]$Certificado = (Join-Path $PSScriptRoot 'AlfaMail-firma.cer'),
  [switch]$Quitar
)
$ErrorActionPreference = 'Stop'
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $Certificado
Write-Host "Certificado: $($cert.Subject)  (huella $($cert.Thumbprint), vence $($cert.NotAfter.ToString('yyyy-MM-dd')))"

foreach ($almacen in 'Root', 'TrustedPublisher') {
  $store = New-Object System.Security.Cryptography.X509Certificates.X509Store $almacen, 'LocalMachine'
  $store.Open('ReadWrite')
  try {
    if ($Quitar) {
      $store.Remove($cert); Write-Host "  quitado de $almacen"
    } else {
      $store.Add($cert);    Write-Host "  instalado en $almacen"
    }
  } finally { $store.Close() }
}
Write-Host 'Listo.' -ForegroundColor Green
