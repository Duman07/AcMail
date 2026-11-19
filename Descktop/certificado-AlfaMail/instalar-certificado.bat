@echo off
rem Doble clic: instala el certificado de AlfaMail (pide permisos de administrador).
powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell -Verb RunAs -Wait -ArgumentList -NoProfile -ExecutionPolicy Bypass -File \"%~dp0instalar-certificado.ps1\"; pause"
