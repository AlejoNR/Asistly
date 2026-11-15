# Asistly

Aplicación móvil para **tomar asistencia en clase** en la Universidad de la Amazonia. El docente abre una sesión desde su celular y los estudiantes registran su asistencia escaneando un código QR que cambia cada 15 segundos, así no se puede compartir por foto ni marcar desde fuera del salón.

Hecha con **Flutter** y **Firebase** (Authentication, Firestore, Cloud Functions y Hosting).

## ¿Qué hace?

### Docente
- Crea cursos con sus horarios (pueden ser distintos para cada día de la semana, domingo incluido).
- Importa la lista oficial de matriculados desde un archivo `.xlsx` o `.csv`. Solo toma el código, el nombre y el correo institucional; las demás columnas nunca salen del celular (Ley 1581 de protección de datos).
- Comparte el curso con un código o un QR para que los estudiantes soliciten unirse, y acepta o rechaza las solicitudes.
- Abre una sesión de asistencia que muestra un QR rotativo, la cierra y puede marcar asistencia a mano.
- Consulta el historial de clases y el reporte de asistencia del curso.

### Estudiante
- Se une a cursos con el código o el QR del docente.
- Marca asistencia escaneando el QR de la sesión activa.
- Ve su historial y su porcentaje de asistencia por curso.

### Cuentas
- Registro e inicio de sesión solo con correo institucional (`@udla.edu.co`).
- Verificación de correo y recuperación de contraseña con correos propios enviados desde Cloud Functions.
- Cada cuenta de estudiante queda vinculada a un solo celular para evitar que alguien marque por otro.
  > **Nota (pruebas):** por ahora está **desactivado el bloqueo al iniciar sesión**: se puede entrar con la misma cuenta desde cualquier celular para probar la app. Lo que sigue exigiendo el celular vinculado es **marcar asistencia** (en la app y en las reglas de Firestore); desde otro celular el botón de escanear aparece desactivado.

## ¿Cómo funciona la asistencia?

1. Al abrir la sesión se genera un secreto. Cada 15 segundos se calcula un código nuevo con HMAC-SHA256 a partir de ese secreto (`lib/util/session_codes.dart`).
2. El QR contiene el id de la sesión y el código vigente.
3. Las reglas de Firestore (`firestore.rules`) comparan el código en el servidor (la app nunca lo puede leer) y solo aceptan el registro si está vigente, si llega dentro del tiempo de registro de la sesión y si viene del celular vinculado al estudiante.

> La búsqueda de la señal Bluetooth del docente todavía está **simulada** (`lib/services/bluetooth_service.dart`). Por ahora la validación real es el QR.

## Estructura del proyecto

| Carpeta | Contenido |
|---|---|
| `lib/models` | Modelos de datos (curso, sesión, asistencia, usuario...) |
| `lib/services` | Acceso a Firebase, Bluetooth, permisos, lectura de la lista oficial |
| `lib/viewmodels` | Lógica de cada pantalla (patrón MVVM con `provider`) |
| `lib/views` | Pantallas del docente, del estudiante y de cuentas |
| `lib/theme`, `lib/util` | Colores, tema, validadores y utilidades |
| `functions` | Cloud Functions para enviar los correos de verificación y recuperación |
| `hosting` | Página web y política de privacidad |
| `firestore_tests` | Pruebas de las reglas de Firestore en el emulador |
| `test` | Pruebas unitarias de Flutter |

## Cómo correrlo

Requisitos: Flutter (SDK de Dart `^3.13.1`) y un celular o emulador Android/iOS.

```bash
flutter pub get
```

```bash
flutter run
```

**Modo demo** (solo desarrollo): entra como docente o estudiante sin iniciar sesión.

```bash
flutter run -t lib/main_demo.dart
```

**Pruebas:**

```bash
flutter test
```

```bash
powershell -ExecutionPolicy Bypass -File firestore_tests\run.ps1
```

## Cuentas de prueba

<!-- Las cuentas de prueba se subirán pronto. Por ahora no se incluyen porque las credenciales contienen información sensible y este repositorio es público. -->

> **Pronto.** Las cuentas de prueba (docente y estudiante) se subirán más adelante. Por ahora no se publican porque las credenciales actuales contienen información sensible que no debe estar en un repositorio público.
