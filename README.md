# AlfaMail — cliente de correo para Windows

Cliente de correo empresarial nativo para Windows (Tauri 2 + Rust + WebView2) con interfaz
Flat UI basada en `Informe_Requerimientos_Cliente_Correo_Corporativo_Windows.pdf`.
Se conecta directamente a los servidores de la empresa por **IMAP/SMTP**, con varias cuentas a la vez.

> v0.5.0: destinatarios con chips (espacio/coma/Enter) y autocompletado, Directorio de contactos, grupos de correo con emoji y color, «Enviar a TODOS» con vista previa y cambio de cuenta activa al vuelo (§10). · v0.4.1 (corrige ventanas independientes en blanco y congelamientos durante la sincronización) · v0.4.0: etiquetas, búsqueda avanzada con exportación .mbox, paginación en todas las vistas, respuesta desplegable y envío en segundo plano. Arquitectura y fases en [`docs/ARQUITECTURA_v0.3.md`](docs/ARQUITECTURA_v0.3.md) (§8 para la v0.4).
> Fase 1 entregada: marca AlfaMail, datos en `%LOCALAPPDATA%\AlfaMail`, multicuenta + bandeja unificada,
> paginación de 50 (local y servidor), notificaciones por cuenta y temas de color.
> Fase 2 entregada: pestañas y ventanas independientes de lectura/redacción, borradores con
> autoguardado (local + carpeta Borradores del servidor) y retomar edición.
> Fase 3 entregada: carpetas locales (.mbox), mover entre servidor/local/cuentas, motor de reglas,
> exportación .mbox y compactación del almacenamiento.
> Fase 4 entregada: miniaturas y visor integrado (imágenes, PDF, Word, Excel, texto), imágenes remotas
> con remitentes de confianza e instalador Inno Setup (`AlfaMail_Setup_v0.5.0.exe`).

## Estructura

```
CorreoCorporativo/
├─ core/              Motor de correo en Rust (biblioteca, probada de extremo a extremo)
│  ├─ src/paths.rs    Rutas de datos (%LOCALAPPDATA%\AlfaMail) y migración desde la v0.2
│  ├─ src/verify.rs   Verificación de correo empresarial + autodetección de servidores
│  ├─ src/imapc.rs    Conexión IMAP (TLS implícito / STARTTLS) con rustls
│  ├─ src/sync.rs     Sincronización UID/UIDVALIDITY, banderas, eliminaciones, páginas de 50 hacia atrás
│  ├─ src/smtp.rs     MIME (mixed/related/alternative, cid:) y envío SMTP
│  ├─ src/parse.rs    Lectura de mensajes RFC 5322 / MIME y adjuntos
│  ├─ src/db.rs       Índice SQLite (WAL) con migraciones, hilos RFC 5322, seguimiento, búsqueda multicuenta
│  ├─ src/drafts.rs   Borradores: guardado local + APPEND \Draft con reemplazo de versiones, retomar
│  ├─ src/local.rs    Carpetas locales en archivos .mbox (mboxrd) · src/mbox.rs formato mbox
│  ├─ src/organize.rs Mover entre carpetas/cuentas, aplicar reglas, exportar · src/rules.rs motor de reglas
│  ├─ src/maintenance.rs Medición y compactación del almacenamiento
│  ├─ src/preview.rs  Vista previa (Word→HTML, hojas, texto, imágenes) y miniaturas
│  ├─ src/service.rs  API de alto nivel + bucle IMAP IDLE con reconexión
│  └─ tests/          greenmail.rs (servidor real) · dns.rs (DNS de internet)
├─ src-tauri/         App de escritorio: comandos, credenciales Windows, bandeja, notificaciones
├─ src/               Interfaz (HTML/CSS/JS). En un navegador corre en modo demostración.
├─ installer/         Instalador Inno Setup (AlfaMail.iss) y scripts de compilación
├─ tests-ui/          Pruebas de interfaz (Chromium sin cabeza)
├─ branding/          Logo de AlfaMail (SVG fuente de los íconos)
└─ docs/              Arquitectura v0.3 y plan por fases
```

## Qué hace

| Función | Detalle |
|---|---|
| Inicio de sesión | Correo + contraseña; autodetección de servidores (SRV, MX de Microsoft 365/Google/Zoho, sondeo de puertos); configuración manual; diagnóstico DNS → TLS → IMAP → SMTP |
| Varias cuentas | Agregar/quitar cuentas, bandeja unificada, búsqueda y seguimiento entre cuentas, selector «De» al redactar, firmas por cuenta |
| Verificación empresarial | Rechaza proveedores personales (Gmail, Hotmail, Outlook.com, Yahoo…), exige registros MX y admite lista blanca de dominios (`policy.json`) |
| Seguridad | Contraseña en el Administrador de credenciales de Windows; TLS obligatorio con validación de certificados (incluye CA internas del almacén de Windows); HTML aislado en iframe sin scripts; imágenes remotas bloqueadas; alertas SPF/DKIM/DMARC |
| Recibir | Todas las carpetas; últimos 90 días (máx. 1500 por carpeta) en la primera sincronización y el resto bajo demanda en páginas de 50 al llegar al final de la lista; correo nuevo al instante por IMAP IDLE; reconexión automática |
| Apariencia | Modo sistema/claro/oscuro y 8 paletas de color o color personalizado, en tiempo real y con contraste WCAG AA |
| Enviar | Nuevo, responder, responder a todos, reenviar (con adjuntos originales), CC/CCO, adjuntos del disco (máx. 25 MB), firma con logotipo incrustado; copia en Enviados |
| Pestañas y ventanas | Varias conversaciones y redacciones abiertas a la vez en pestañas (cada una conserva su estado) o en ventanas independientes; se restauran al reiniciar |
| Borradores | Autoguardado cada 30 s y Ctrl+S, en este equipo y en la carpeta Borradores del servidor; «Continuar edición», también de borradores creados en otros equipos o clientes |
| Organizar | Hilos por Message-ID/In-Reply-To/References, leído/no leído, archivar, papelera, eliminar definitivamente, búsqueda con operadores; selección múltiple (Ctrl/Mayús+clic) y arrastrar a carpetas; «Mover a…» cualquier carpeta del servidor, de otra cuenta o local |
| Carpetas locales | Correo guardado en este equipo (fuera del servidor) en archivos .mbox; crear, anidar, renombrar, eliminar |
| Reglas | Para el correo que llega: remitente, destinatarios, asunto, cuerpo, adjuntos, tamaño (contiene, igual, empieza, termina, expresión regular) → mover a carpeta local o del servidor, marcar leído, destacar, papelera, sin notificación; probar y ejecutar ahora |
| Respaldo y mantenimiento | Exportar carpetas, conversaciones o selecciones a .mbox; compactar (purga física de lo borrado, copias huérfanas, caché y VACUUM) con medición del espacio |
| Seguimiento | «Esperar respuesta en 24h/48h/fecha», vistas Esperando respuesta y SLA, detección automática de la respuesta + notificación |
| Archivos | Todos los adjuntos con filtros, tabla o galería con miniaturas; abrir con la app de Windows, guardar |
| Vista previa integrada | Sin salir de AlfaMail (clic en el adjunto, en la fila de archivos o en lo que se está adjuntando): imágenes (también TIFF/BMP), PDF (PDF.js, con respaldo del visor de WebView2), Word (.docx), ODT, Excel/ODS/CSV, PowerPoint (.pptx, texto), ZIP (contenido), correos .eml, HTML, RTF y texto; zoom, páginas, hojas, ← → entre adjuntos |
| Imágenes en el correo | Incrustadas (cid:) siempre; remotas bajo demanda, siempre para remitentes/dominios de confianza o siempre para todos |
| Firmas | Varias firmas, reglas por cuenta (nuevos vs. respuestas), editor visual/HTML, simulador claro/oscuro con control de contraste |

## Política corporativa (opcional)

TI puede distribuir un `policy.json` junto al ejecutable (`C:\Program Files\AlfaMail`) o en `%ProgramData%\AlfaMail\`:

```json
{ "allowedDomains": ["miempresa.com"], "blockFreeProviders": true, "requireMx": true }
```

## Datos del usuario

Todo lo que cambia vive en `%LOCALAPPDATA%\AlfaMail\` (base de datos `alfamail.db`, copia local del
correo, carpetas locales y respaldos); las contraseñas, en el Administrador de credenciales de Windows
(servicio `AlfaMail`). Al actualizar desde «Correo Corporativo» 0.2 los datos y las contraseñas se
migran automáticamente en el primer arranque.

## Compilar en Windows 10/11

Requisitos: [Rust](https://rustup.rs) (toolchain MSVC), Node.js 18+, Visual Studio Build Tools
(«Desarrollo de escritorio con C++») e [Inno Setup 6](https://jrsoftware.org/isdl.php).

```powershell
npm install
npm run dev                                   # ejecutar en modo desarrollo
powershell -File installer\build-installer.ps1   # → installer\Output\AlfaMail_Setup_v0.5.0.exe
powershell -File installer\build-installer.ps1 -Sign   # ídem, firmando con signtool
```

Desde Linux (Docker): `./installer/build-installer.sh` compila para Windows y ejecuta Inno Setup bajo Wine;
`./installer/test-installer.sh` instala, actualiza y desinstala el instalador real en Wine 8 de 64 bits
y verifica Program Files, accesos directos, registro y «Agregar o quitar programas».

Firma de código: si existe `../claves-firma/alfamail-codesign.pfx`, `build-installer.sh` firma
`AlfaMail.exe`, el desinstalador y el instalador con el certificado interno. Para que los equipos lo
reconozcan hay que instalarles `installer/certificado/AlfaMail-firma.cer` (GPO, Intune o
`instalar-certificado.bat`); ver [docs/FIRMA_CODIGO.md](docs/FIRMA_CODIGO.md).

### Instalación

`AlfaMail_Setup_v0.5.0.exe` instala en `C:\Program Files\AlfaMail`, crea accesos directos en el menú
Inicio y el Escritorio, se registra en «Agregar o quitar programas» (desinstalador `unins000.exe`) e
instala Microsoft Edge WebView2 Runtime si falta. Desatendida:
`AlfaMail_Setup_v0.5.0.exe /VERYSILENT /SUPPRESSMSGBOXES /NORESTART [/SKIPWEBVIEW2=1]`.

## Pruebas

Interfaz (Chromium sin cabeza, modo demostración): ver [`tests-ui/README.md`](tests-ui/README.md).

```bash
# Servidor de prueba IMAP/SMTP
docker network create alfamail-test
docker run -d --name alfamail-gm --network alfamail-test \
  -e GREENMAIL_OPTS='-Dgreenmail.setup.test.all -Dgreenmail.hostname=0.0.0.0 -Dgreenmail.users=usuario:Secreta1@empresa.test,cliente:Secreta2@cliente.test,fase1a:Clave1@empresa.test,fase1b:Clave2@otra.test,fase2a:Clave3@empresa.test,fase2b:Clave4@otra.test,fase3a:Clave5@empresa.test,fase3b:Clave6@otra.test,fase4a:Clave7@empresa.test,fase5a:Clave8@empresa.test,fase5b:Clave9@otra.test,fase6a:Clave10@empresa.test,fase6b:Clave11@otra.test -Dgreenmail.users.login=email' \
  greenmail/standalone:2.0.1
# Pruebas unitarias (migración v0.2, borradores, mbox, reglas, carpetas locales, compactación y vista previa)
cargo test -p mail-core --lib
# Extremo a extremo: login, envío, recepción, hilos, seguimiento, IDLE + multicuenta, paginación, borradores, reglas y carpetas locales (v0.3)
# + v0.4: envío en segundo plano con conexión SMTP reutilizada, reglas con etiquetas, búsqueda avanzada y exportación
GM_HOST=alfamail-gm CORREO_DEV_INSECURE=1 cargo test -p mail-core --test greenmail -- --nocapture
# Verificación con DNS real
cargo test -p mail-core --test dns -- --ignored --nocapture
```

`CORREO_DEV_INSECURE=1` solo existe para pruebas (acepta certificados autofirmados); nunca en producción.

## Limitaciones conocidas

- **Microsoft 365 / Google Workspace:** requieren OAuth2. Con contraseña solo funcionan si el
  administrador habilita IMAP/SMTP con autenticación básica o contraseñas de aplicación.
- La búsqueda es sobre la copia local: el correo de más de 90 días se incluye cuando se descarga
  (desplazándose al final de la carpeta).
- No hay importación de .mbox (solo exportación). Sin vista previa de .doc antiguos ni presentaciones.
- La vista previa de PDF con fuentes CJK puede mostrar texto sustituido (no se incluyen los cMaps).
- Sin editor de texto enriquecido (negrita, listas) ni asociación `mailto:`.
- El instalador no está firmado digitalmente (Windows SmartScreen mostrará una advertencia).
# AlfaMail
# AcMail
