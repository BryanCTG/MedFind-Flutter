# 🏥 MedFind

> Aplicación móvil Flutter para gestión inteligente de medicamentos con carrito de compras y notificación automática de pedidos al administrador mediante n8n.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![n8n](https://img.shields.io/badge/n8n-Automation-EA4B71?logo=n8n)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📱 Pantallas Principales

| Login | Ficha Médica | Inicio | Carrito | Pedido confirmado |
|-------|-------------|--------|---------|------------------|
| <img width="436" height="875" alt="image" src="https://github.com/user-attachments/assets/b8706634-d0d2-4af2-8a4a-df7b84df7b9c" />
 | Perfil de salud | Búsqueda de medicamentos | Gestión del carrito | Código de pedido + email al admin |

---

## 🚀 Características

- **Autenticación** con correo y contraseña vía Supabase Auth
- **Ficha médica** personalizada con condiciones crónicas y alergias
- **Búsqueda de medicamentos** en tiempo real contra catálogo Supabase
- **Recomendaciones personalizadas** según el perfil de salud del usuario
- **Carrito de compras** con opción de recogida en tienda o domicilio
- **Integración con n8n**: al confirmar el pedido, se genera un código único y se envía un correo automático al administrador con el detalle del pedido

---

## 🏗️ Arquitectura

```
Flutter App
     │
     ├─── Supabase Auth         → Autenticación de usuarios
     ├─── Supabase DB           → Catálogo de medicamentos, perfiles, pedidos
     │
     └─── n8n Webhook ──────────→ Recibe pedido confirmado desde Flutter
                │
                ├── Code Generator    → Genera código único (MF-YYYYMMDD-XXXX)
                ├── Gmail Node        → Envía email al administrador con detalle
                └── Response JSON     → Devuelve orderCode a Flutter para mostrar
```

---

## 🔄 Flujo del Pedido (Semana 4 — Integración Completa)

```
Usuario llena carrito
        ↓
Selecciona método de entrega (tienda / domicilio)
        ↓
Toca "Confirmar Pedido"
        ↓
Flutter guarda pedido en Supabase (tabla pedidos)
        ↓
Flutter llama al Webhook de n8n (POST /medfind-order)
        ↓
n8n genera código de pedido único (ej. MF-20260416-4821)
        ↓
n8n envía email al administrador con:
  • Nombre del cliente
  • Lista de medicamentos y cantidades
  • Total en COP
  • Tipo de entrega + dirección (si aplica)
        ↓
n8n responde con { orderCode }
        ↓
Flutter muestra el código al usuario en pantalla de éxito
```

---

## 📁 Estructura del Proyecto

```
medfind/
├── lib/
│   ├── main.dart                      # Entry point + ThemeData
│   ├── screens/
│   │   ├── login_screen.dart          # Autenticación
│   │   ├── registro_perfil_screen.dart # Ficha médica
│   │   ├── inicio_screen.dart         # Home: búsqueda + catálogo
│   │   ├── carrito_screen.dart        # Carrito + integración n8n ← NUEVO
│   │   ├── notificaciones_screen.dart # Historial de notificaciones
│   │   └── receta_screen.dart         # (Legacy — no activo en flujo principal)
│   └── services/
│       └── notification_service.dart  # Notificaciones locales
├── n8n/
│   └── MedFind_Final.json            # Flujo n8n exportado (importar en tu instancia)
├── supabase/
│   └── schema.sql                    # Esquema de tablas PostgreSQL
├── .env                              # Variables de entorno (no commitear)
├── pubspec.yaml
└── README.md
```

---

## ⚙️ Instalación y Configuración

### Requisitos Previos

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Cuenta en [Supabase](https://supabase.com) (gratuita)
- Instancia de [n8n](https://n8n.io) (self-hosted o cloud)
- Cuenta de Gmail con OAuth2 configurada en n8n

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/medfind.git
cd medfind
flutter pub get
```

### 2. Configurar variables de entorno

Crea el archivo `.env` en la raíz del proyecto:

```env
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_ANON_KEY=TU_ANON_KEY
N8N_ORDER_WEBHOOK_URL=https://tu-n8n.com/webhook/medfind-order
```

> ⚠️ **Nunca subas el `.env` al repositorio.** Está incluido en `.gitignore`.

### 3. Configurar Supabase

Ejecuta el siguiente esquema en el SQL Editor de Supabase:

```sql
-- Perfiles de salud
CREATE TABLE perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  nombre TEXT,
  edad INTEGER,
  alergias TEXT[],
  condiciones TEXT[],
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Catálogo de medicamentos
CREATE TABLE medicamentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  precio NUMERIC(10,2),
  stock INTEGER DEFAULT 0,
  categoria TEXT,
  imagen_url TEXT
);

-- Pedidos
CREATE TABLE pedidos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  usuario_id UUID REFERENCES auth.users(id),
  items JSONB,
  metodo_entrega TEXT CHECK (metodo_entrega IN ('tienda', 'domicilio')),
  direccion TEXT,
  nombre_receptor TEXT,
  costo_envio NUMERIC(10,2) DEFAULT 0,
  subtotal NUMERIC(10,2),
  total NUMERIC(10,2),
  estado TEXT DEFAULT 'pendiente',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 4. Configurar n8n

1. Abre tu instancia de n8n
2. Ve a **Settings → Import Workflow**
3. Importa el archivo `n8n/MedFind_Final.json`
4. Configura las credenciales:
   - **Gmail OAuth2** en el nodo "Send Email" (destinatario: correo del admin)
5. Activa el workflow (`Active: ON`)
6. Copia la **Webhook URL** del nodo `Webhook1` y pégala en tu `.env` como `N8N_ORDER_WEBHOOK_URL`

### 5. Ejecutar la app

```bash
flutter run
```

---

## 📤 Payload enviado a n8n

Cuando el usuario confirma su pedido, Flutter envía el siguiente JSON al webhook:

```json
{
  "userName": "Nombre del usuario",
  "items": [
    { "id": "uuid", "nombre": "Metformina 850mg", "precio": 15000, "cantidad": 2 }
  ],
  "total": 38000,
  "type": "domicilio",
  "address": "Calle 30 #25-10, Cartagena",
  "recipientName": "María García"
}
```

## 📨 Respuesta de n8n

```json
{
  "orderCode": "MF-20260416-4821",
  "userName": "Nombre del usuario",
  "total": "38000",
  "type": "domicilio"
}
```

El `orderCode` se muestra al usuario en pantalla como confirmación del pedido.

---

## 📦 Dependencias Flutter

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.12.2    # Backend + Auth
  http: ^1.2.0                  # Llamadas al webhook n8n
  flutter_local_notifications: ^17.0.0
  intl: ^0.19.0                 # Formato de moneda COP
  cached_network_image: ^3.4.1
  flutter_dotenv: ^5.2.1        # Variables de entorno
  shared_preferences: ^2.5.5
  image_picker: ^1.2.1
```

---

## ✅ Checklist Técnico (Segundo Corte)

- [x] App Flutter corre sin errores en emulador/dispositivo
- [x] Webhook activo en n8n que retorna JSON con código de pedido
- [x] Flutter consume el Webhook usando el paquete `http`
- [x] El `orderCode` devuelto por n8n se muestra en la UI
- [x] Manejo de estado de carga (`CircularProgressIndicator`) y de error
- [x] Pedido guardado también en Supabase (tabla `pedidos`)
- [x] Email automático al administrador al confirmar pedido
- [x] Flujo n8n exportado como `.json` y subido al repositorio
- [x] Variables sensibles en `.env` (no en el código fuente)

---

## 🤝 Contribuir

1. Fork del repositorio
2. Crea una rama: `git checkout -b feature/nombre-funcionalidad`
3. Commit: `git commit -m 'feat: descripción del cambio'`
4. Push: `git push origin feature/nombre-funcionalidad`
5. Abre un Pull Request

---

## 📄 Licencia

MIT © 2026 MedFind Team
