<#
.SYNOPSIS
  Retorna seu IPv4 publico em formato CIDR /32 para usar em allow_ssh_cidrs no Terraform.
.EXAMPLE
  .\scripts\get-my-public-ip.ps1
#>
$ErrorActionPreference = "Stop"
$ip = (Invoke-WebRequest -Uri "https://api.ipify.org" -UseBasicParsing).Content.Trim()
if ($ip -match '^\d{1,3}(\.\d{1,3}){3}$') {
  Write-Host "$ip/32"
} else {
  Write-Error "Resposta inesperada ao consultar IP publico: $ip"
}
