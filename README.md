# 🏥 MedFind

> Aplicación móvil Flutter para gestión inteligente de medicamentos con análisis de recetas médicas mediante IA.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![n8n](https://img.shields.io/badge/n8n-Automation-EA4B71?logo=n8n)
![Supabase](https://img.shields.io/badge/Supabase-Backend-3ECF8E?logo=supabase)
![License](https://img.shields.io/badge/License-MIT-green)

---

## 📱 Capturas de Pantalla

| Login | Ficha Médica | Inicio | Análisis IA | Carrito |
|-------|-------------|--------|-------------|---------|
| Autenticación segura | Perfil de salud | Búsqueda + Receta | OCR con OpenAI | Pedido y pago |

---

## 🚀 Características

- **Autenticación** con correo y contraseña vía Supabase Auth
- **Ficha médica** personalizada con condiciones crónicas y alergias
- **Búsqueda de medicamentos** en tiempo real contra catálogo Supabase
- **Análisis de recetas con IA** — fotografía tu receta y OpenAI Vision extrae los medicamentos automáticamente
- **Recomendaciones personalizadas** según el perfil de salud del usuario
- **Carrito de compras** con opción de recogida en tienda o domicilio

---

## 🏗️ Arquitectura

```
Flutter App
     │
     ├─── Supabase Auth         → Autenticación de usuarios
     ├─── Supabase DB           → Catálogo de medicamentos, perfiles, pedidos
     │
     └─── n8n Webhook ──────────→ Recibe imagen de receta (base64)
                │
                ├── OpenAI Vision API  → Extrae medicamentos del texto
                ├── Supabase Query     → Verifica stock en catálogo
                └── Response JSON      → Devuelve lista de medicamentos a Flutter
```

---

## 📁 Estructura del Proyecto

```
medfind/
├── lib/
│   ├── main.dart                    # Entry point + ThemeData + rutas
│   └── screens/
│       ├── login_screen.dart        # Autenticación
│       ├── registro_salud_screen.dart  # Ficha médica / chips de condiciones
│       ├── inicio_screen.dart       # Home: búsqueda + banner receta + recomendados
│       ├── analisis_receta_screen.dart # Loading IA + animación rotación
│       └── carrito_screen.dart      # Carrito + método entrega + pago
├── n8n/
│   └── medfind_flow.json            # Flujo n8n exportado (importar en tu instancia)
├── supabase/
│   └── schema.sql                   # Esquema de tablas PostgreSQL
├── pubspec.yaml
└── README.md
```

---

## ⚙️ Instalación y Configuración

### Requisitos Previos

- Flutter SDK `>=3.0.0`
- Dart SDK `>=3.0.0`
- Cuenta en [Supabase](https://supabase.com) (gratuita)
- Cuenta en [OpenAI](https://platform.openai.com) (para Vision API)
- Instancia de [n8n](https://n8n.io) (self-hosted o cloud)

### 1. Clonar el repositorio

```bash
git clone https://github.com/tu-usuario/medfind.git
cd medfind
flutter pub get
```

### 2. Configurar Supabase

Crea un proyecto en Supabase y ejecuta el esquema:

```bash
# En el SQL Editor de Supabase, ejecuta:
supabase/schema.sql
```

Crea un archivo `lib/config/supabase_config.dart`:

```dart
const String supabaseUrl = 'https://TU_PROYECTO.supabase.co';
const String supabaseAnonKey = 'TU_ANON_KEY';
```

### 3. Configurar n8n

1. Abre tu instancia de n8n
2. Ve a **Settings → Import Workflow**
3. Importa `n8n/medfind_flow.json`
4. Configura las credenciales:
   - **OpenAI API Key** en el nodo de OpenAI
   - **Supabase URL + Key** en el nodo de Supabase
5. Activa el workflow y copia la **Webhook URL**

### 4. Conectar Flutter con n8n

En `lib/services/receta_service.dart`, reemplaza la URL del webhook:

```dart
const String n8nWebhookUrl = 'https://tu-n8n.com/webhook/analizar-receta';
```

### 5. Ejecutar la app

```bash
flutter run
```

---

## 🗄️ Esquema de Base de Datos (Supabase)

```sql
-- Usuarios (manejado por Supabase Auth)

-- Perfiles de salud
CREATE TABLE perfiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id),
  edad INTEGER,
  alergias TEXT[],
  condiciones TEXT[],
  created_at TIMESTAMPTZ DEFAULT NOW()
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
  total NUMERIC(10,2),
  estado TEXT DEFAULT 'pendiente',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## 🔄 Flujo n8n — Análisis de Receta con IA

El flujo recibe la imagen de la receta desde Flutter, la procesa con OpenAI Vision y devuelve los medicamentos encontrados con su disponibilidad en stock.

**Nodos del flujo:**

1. **Webhook** — Recibe `{ image_base64, user_id }`
2. **OpenAI Vision** — Extrae nombres de medicamentos del texto de la receta
3. **Parse JSON** — Limpia y estructura la respuesta de OpenAI
4. **Supabase Query** — Busca cada medicamento en el catálogo y verifica stock
5. **Merge Results** — Combina medicamentos encontrados/no encontrados
6. **Respond to Webhook** — Devuelve JSON con la lista final a Flutter

Importa `n8n/medfind_flow.json` directamente en tu instancia de n8n.

---

## 📦 Dependencias Flutter

```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0      # Backend + Auth
  http: ^1.1.0                   # Llamadas al webhook n8n
  image_picker: ^1.0.4           # Cámara para fotografiar receta
  cached_network_image: ^3.3.0   # Imágenes de medicamentos con caché
  flutter_dotenv: ^5.1.0         # Variables de entorno
```

---

## 🤝 Contribuir

1. Fork del repositorio
2. Crea una rama: `git checkout -b feature/nueva-funcionalidad`
3. Commit: `git commit -m 'feat: descripción del cambio'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Abre un Pull Request

---

## 📄 Licencia

MIT © 2026 MedFind Team
