# Sistema de Autenticación - Banco Pichincha Fuerza de Ventas

## Descripción General
La app implementa un sistema de autenticación multicapa que se conecta con Supabase con fallback automático a modo demo.

## Flujo de Autenticación

### 1️⃣ Intento de Login
El usuario ingresa email y contraseña en la pantalla de login.

### 2️⃣ Validación en Cascada
```
1. Credenciales demo explícitas (demo@pichincha.com / pichincha123)
   ↓
2. Supabase Auth (SignInWithPassword)
   ↓
3. SQL Query a tabla officers
   ↓
4. Fallback a Demo Mode (si todos fallan)
```

## Componentes

### 📝 AuthService (lib/services/auth_service.dart)
- Maneja la lógica de login con fallback
- Persiste sesión en SharedPreferences
- Indicador de modo demo: `AuthService.isDemoLogin`

### 🔐 AuthRepository (lib/repositories/auth_repository.dart)
- Integración con Supabase Auth
- Consulta tabla `asesores_negocio`
- Valida si el asesor está activo

### 🎯 AuthNotifier (lib/providers/auth_notifier.dart)
- State management con Riverpod
- Gestiona estados: initial, loading, authenticated, unauthenticated, error

### 🖥️ LoginScreen (lib/screens/login_screen.dart)
- UI moderna con Banco Pichincha branding
- Botón "Modo Demo" para inicio rápido
- Muestra credenciales de demo

### 🏠 HomeShell (lib/screens/home_shell.dart)
- Pantalla principal después del login
- **Banner amarillo** si está en modo demo
- Logout disponible en la esquina superior derecha

## Credenciales de Demo

```
Email:    demo@pichincha.com
Password: pichincha123
```

Cuando se usan estas credenciales, aparece un banner amarillo en la app que indica "Modo de Demostración".

## Tabla Supabase Requerida: asesores_negocio

```sql
CREATE TABLE asesores_negocio (
  id UUID PRIMARY KEY,
  codigo_empleado VARCHAR(20),
  nombres VARCHAR(100),
  apellidos VARCHAR(100),
  agencia_id VARCHAR(10),
  perfil VARCHAR(100),
  activo BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

## Configuración Supabase

En `lib/services/supabase_config.dart`:
```dart
const String supabaseUrl = '...tu URL...';
const String supabaseAnonKey = '...tu anon key...';
```

Inicializado en `main.dart`:
```dart
await Supabase.initialize(
  url: supabaseUrl,
  anonKey: supabaseAnonKey
);
```

## Flujo de Recuperación de Sesión

Al iniciar la app:
1. Busca sesión en `asesores_negocio` table (si está autenticado con Supabase)
2. Busca sesión demo guardada localmente
3. Si ambas fallan, redirige a LoginScreen

## Estados de Autenticación

- **initial**: Cargando sesión anterior
- **loading**: Procesando login
- **authenticated**: Usuario autenticado ✅
- **unauthenticated**: Sin sesión activa
- **error**: Error en autenticación ❌

## Mensajes de Error

- "Credenciales inválidas" → Usuario/contraseña incorrectos
- "El asesor de negocio no está activo" → Usuario bloqueado
- "Perfil de asesor no encontrado" → Usuario existe pero sin perfil

## Modo Demo vs Producción

### Modo Demo
- ✅ Acceso sin credenciales válidas en Supabase
- ✅ Pruebas sin conexión (offline)
- ⚠️ Banner amarillo visible en toda la app
- ❌ No accede a datos reales de Supabase

### Modo Producción
- ✅ Autenticación con Supabase Auth
- ✅ Datos reales de asesores_negocio
- ❌ Requiere credenciales válidas
- ❌ Requiere conexión a internet

## Logout

El logout:
- Limpia sesión local
- Firma fuera de Supabase Auth
- Redirige a LoginScreen

## Seguridad

- ✅ Contraseña no se guarda (solo en sesión HTTP)
- ✅ Token de Supabase se maneja automáticamente
- ✅ SharedPreferences solo guarda datos públicos
- ✅ No hay hardcoding de secretos en producción
