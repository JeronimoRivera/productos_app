# Taller Integrador 2 + 3: Persistencia y sincronización

Desarrollo Móvil

## Integrantes

- Jerónimo Rivera Murillo
- Samuel Meneses Montoya

## Instrucciones de ejecución

### Requisitos previos

- Flutter 3.47.0 (canal stable) con Dart 3.13.0, o una versión compatible con la restricción `sdk: ^3.11.5` de `pubspec.yaml`.
- Dependencias declaradas en el proyecto: `http ^1.6.0`, `path_provider ^2.1.6`, `path ^1.9.1`, `drift ^2.34.0`, `firebase_core ^4.15.0`, `cloud_firestore ^6.10.0`, `cupertino_icons ^1.0.8`, `drift_dev ^2.34.0`, `build_runner ^2.4.15` y `flutter_lints ^6.0.0`.
- JDK 17 o 21, acorde con la configuración de compilación Java y Kotlin 17 del proyecto. Si Flutter detecta otro JDK, se puede indicar la ruta correcta con `flutter config --jdk-dir="<ruta del JDK>"`.
- Android SDK instalado, por ejemplo con Android Studio, con Platform-Tools, Command-line Tools y el NDK 28.2.13676358. Para instalar el NDK, abrir Android Studio > SDK Manager > SDK Tools, activar "Show Package Details" y seleccionar esa versión en "NDK (Side by side)".
- Un dispositivo Android: emulador (recomendado API 34, con almacenamiento interno de 4 GB y gráficos en modo Software si el equipo tiene poca RAM) o celular físico con depuración por USB activada. La aplicación tiene `minSdk` 24.
- En Windows, Modo de desarrollador activado, necesario para compilar proyectos con plugins.
- Conexión a internet estable: el catálogo se consume desde `https://dummyjson.com/products` y Gradle descarga dependencias durante la primera compilación.
- Un proyecto de Firebase con Firestore Database creado en modo de prueba para probar la sincronización.

### Pasos

1. Descomprimir el archivo `.zip` y abrir una terminal en la carpeta del proyecto.

   ```powershell
   Set-Location "<ruta de la carpeta del proyecto>"
   ```

2. Verificar el entorno. La sección Android toolchain de `flutter doctor` debe estar sin errores; Chrome y Visual Studio no son necesarios.

   ```powershell
   flutter doctor
   ```

3. Instalar las dependencias del proyecto.

   ```powershell
   flutter pub get
   ```

4. Generar el código de Drift. El archivo `lib/local/app_database.g.dart` ya existe en el proyecto, pero se recomienda ejecutar el generador para mantenerlo actualizado.

   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```

5. Configurar Firebase. Instalar las herramientas, iniciar sesión, activar FlutterFire CLI y ejecutar la configuración para el proyecto y la plataforma Android. Esto genera `lib/firebase_options.dart` y `android/app/google-services.json`.

   ```powershell
   npm install -g firebase-tools
   firebase login
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Actualmente `lib/firebase_options.dart` es un esqueleto que lanza `UnsupportedError` y no existe `android/app/google-services.json`. Sin esta configuración, la aplicación funciona en modo solo local y los registros permanecen como pendientes.

6. Abrir el emulador o conectar el celular y comprobar que Flutter lo detecta.

   ```powershell
   flutter devices
   ```

7. Ejecutar la aplicación. Reemplazar `emulator-5554` por el ID que muestre `flutter devices`. La primera compilación puede tardar varios minutos.

   ```powershell
   flutter run -d emulator-5554
   ```

### Solución de problemas frecuentes

- "Building with plugins requires symlink support": activar el Modo de desarrollador de Windows con `start ms-settings:developers`.
- "Java/Gradle incompatibility": configurar un JDK 17 o 21 con `flutter config --jdk-dir="<ruta del JDK>"` y, si `JAVA_HOME` apunta a otra versión, corregir esa variable de entorno.
- "Android SDK not found" o licencias sin aceptar: instalar el SDK con Android Studio y apuntar Flutter con `flutter config --android-sdk "<ruta del SDK>"`; aceptar las licencias pendientes en SDK Manager o ejecutar `flutter doctor --android-licenses`.
- "NDK not found" / "did not install NDK 28.2.13676358": instalar exactamente esa versión desde SDK Manager, en SDK Tools con "Show Package Details" activado.
- "Not enough space to create userdata partition": reducir el almacenamiento interno del emulador a 4 GB o liberar espacio en disco.
- "No supported devices connected": abrir el emulador o conectar el celular y comprobar que `adb` lo detecte; después, repetir `flutter devices`.
- "Read timed out" durante la compilación de Gradle: suele indicar un problema de conexión; repetir `flutter run` sin ejecutar `flutter clean`, para continuar usando las dependencias ya descargadas.
- "this and base files have different roots" (Kotlin): puede ocurrir cuando el proyecto y la caché de Pub están en discos distintos. El proyecto ya incluye `kotlin.incremental=false` en `android/gradle.properties`; como alternativa, mover el proyecto al mismo disco que la caché de Pub.

## Preguntas

### 1. ¿Para qué sirve pendingSync?

Es una marca que nos dice si una nota ya se envió a Firebase o todavía no. Cuando vale true, la nota está guardada solo en el celular y falta subirla. Cuando vale false, ya está en Firebase. Así la app sabe cuáles notas mostrar como "Pendiente" o "Sincronizado" y cuáles enviar cuando se pulsa el botón "Sincronizar pendientes".

### 2. ¿Por qué se guarda primero en Drift?

Porque Drift guarda los datos dentro del celular y siempre funciona, aunque no haya internet. Si primero intentáramos guardar en Firebase y fallara la conexión, el usuario perdería lo que escribió. Guardando primero en Drift, la información queda segura, y después se intenta subir a Firebase.

### 3. ¿Qué función cumple el Repository?

Es como un intermediario entre las pantallas y los lugares donde se guardan los datos (Drift y Firebase). Las pantallas solo le piden cosas al Repository, como guardar una nota o sincronizar, y él se encarga de hablar con Drift y Firebase. Así la pantalla no tiene que saber cómo funciona cada uno y el código queda más ordenado.

### 4. ¿Qué ocurre si Firebase falla?

No pasa nada grave: la nota ya quedó guardada en Drift y se conserva en el celular. Como no se pudo enviar, el registro sigue como "Pendiente" (pendingSync = true). Después, cuando haya internet, se puede pulsar "Sincronizar pendientes" y la nota se envía sin tener que escribirla otra vez.
