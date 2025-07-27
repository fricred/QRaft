# App QR

# Resumen del Proyecto: Aplicación QR con Marketplace de Grabado

## 1. Visión General

Una aplicación móvil que permite a usuarios crear, personalizar y gestionar códigos QR para compartir información personal y diversos tipos de contenido. Además, incluye un marketplace para grabar físicamente estos QR en diferentes materiales utilizando la máquina láser XTool F1 Ultra.

## 2. Propuesta de Valor

- **Creación personalizada de QR**: Generación de códigos QR para múltiples usos y con opciones de personalización visual.
- **Marketplace integrado**: Servicio de grabado láser en diversos materiales utilizando la máquina XTool F1 Ultra.
- **Todo en una sola plataforma**: Desde la creación digital hasta el producto físico en una única aplicación.

## 3. Tecnologías

- **Frontend**: FlutterFlow (desarrollo visual con generación de código Flutter)
- **Autenticación**: Firebase Authentication
- **Backend**: Supabase (PostgreSQL, funciones edge, almacenamiento)
- **Infraestructura**: Combinación de servicios Firebase y Supabase

## 4. Funcionalidades Principales

### Generación de QR

- Creación de códigos QR para:
    - Información personal y contacto
    - Enlaces/URLs
    - Texto libre
    - vCard
    - Email
    - WiFi
    - Ubicación geográfica
    - Eventos
- Personalización visual (colores, logo, diseño)
- Biblioteca de plantillas predefinidas
- Almacenamiento y organización de QR creados

### Escáner QR

- Lectura de códigos QR mediante cámara
- Visualización de contenido escaneado
- Historial de escaneos
- Opciones según tipo de QR escaneado

### Marketplace "Graba tu QR"

- Catálogo de productos/materiales disponibles:
    - Madera
    - Acrílico
    - Metal
    - Cuero
    - Vidrio
    - Piedra
- Personalización del grabado
- Carrito de compra y proceso de checkout
- Seguimiento de pedidos
- Historial de compras

## 5. Lista de Pantallas

### Autenticación y Perfil

1. Splash Screen
2. Login/Registro
3. Perfil de Usuario
4. Editar Perfil

### Dashboard Principal

1. Dashboard
2. Menú de Navegación

### Generación de QR

1. Creador de QR
2. Selección de Tipo de QR
3. Formularios específicos por tipo de QR
4. Personalización Visual
5. Vista Previa
6. Guardar QR

### Gestión de QR

1. Biblioteca de QR
2. Detalle de QR
3. Editar QR
4. Compartir QR

### Plantillas

1. Biblioteca de Plantillas
2. Usar Plantilla

### Escáner

1. Escáner
2. Resultado de Escaneo
3. Historial de Escaneos

### Marketplace "Graba tu QR"

1. Catálogo de Productos
2. Detalle de Producto
3. Seleccionar QR para grabar
4. Personalización de Grabado
5. Carrito de Compra
6. Checkout (Envío y Pago)
7. Seguimiento de Pedido
8. Historial de Pedidos

### Configuración

1. Ajustes Generales
2. Notificaciones
3. Ayuda y Soporte

## 6. Flujos de Usuario Principales

### Crear y Compartir QR

1. Usuario ingresa a la aplicación
2. Selecciona "Crear QR"
3. Elige tipo de QR (ej. información personal)
4. Completa formulario con datos
5. Personaliza apariencia del QR
6. Guarda QR en biblioteca
7. Comparte QR por redes sociales o mensajería

### Ordenar Grabado de QR

1. Usuario accede al marketplace
2. Explora opciones de materiales
3. Selecciona producto deseado
4. Elige QR de su biblioteca para grabar
5. Personaliza opciones de grabado
6. Añade al carrito
7. Completa información de envío
8. Realiza pago
9. Recibe actualizaciones de estado del pedido

## 7. Detalles del Marketplace "Graba tu QR"

### Materiales Disponibles

- **Madera**: Diferentes tipos (roble, nogal, pino)
- **Acrílico**: Transparente y de colores
- **Metal**: Aluminio anodizado, acero inoxidable
- **Cuero**: Natural y sintético
- **Vidrio**: Transparente y tintado
- **Piedra**: Mármol, granito, pizarra

### Productos

- Llaveros
- Posavasos
- Placas decorativas
- Tarjetas de presentación
- Colgantes
- Señalética
- Artículos personalizados

### Proceso de Producción

1. Recepción del pedido
2. Preparación del material
3. Configuración del láser XTool F1 Ultra
4. Proceso de grabado
5. Control de calidad
6. Empaque
7. Envío

## 8. Consideraciones Técnicas

### Estructura de Base de Datos (Supabase)

- **users**: Información de usuarios
- **qr_codes**: Datos de QR generados
- **templates**: Plantillas predefinidas
- **scan_history**: Registro de escaneos
- **products**: Catálogo de productos para grabado
- **orders**: Pedidos y estado
- **order_items**: Items específicos en cada pedido

### Funciones Edge (Supabase)

- Generación de QR dinámicos
- Procesamiento de datos de QR
- Gestión de pedidos
- Integración con pasarelas de pago

### FlutterFlow

- Crear widgets personalizados para componentes recurrentes
- Implementar acciones personalizadas para lógica compleja
- Utilizar estado global para datos entre pantallas

## 9. Plan de Implementación

### Fase 1: MVP (2-3 meses)

- Autenticación básica
- Generador de QR con tipos principales
- Biblioteca de QR
- Escáner básico
- Catálogo simple del marketplace
- Proceso de compra básico

### Fase 2: Ampliación (3-4 meses)

- Más tipos de QR
- Personalización avanzada
- Plantillas predefinidas
- Ampliación del catálogo de productos
- Mejoras en el proceso de compra
- Seguimiento de pedidos

### Fase 3: Refinamiento (2-3 meses)

- Análisis y estadísticas de uso
- Funciones sociales y compartir
- Características premium
- Optimización de rendimiento
- Expansión de opciones de personalización

## 10. Modelo de Negocio Potencial

### Aplicación QR

- **Freemium**: Funciones básicas gratuitas, características avanzadas de pago
- **Suscripción Premium**: Acceso a plantillas exclusivas y personalización avanzada

### Marketplace "Graba tu QR"

- **Venta de productos**: Margen sobre materiales y servicio de grabado
- **Envío**: Costos de envío según ubicación
- **Productos personalizados**: Opción de diseños especiales con costo adicional

## 11. Aspectos Diferenciadores

1. **Integración completa**: Desde la creación digital hasta el producto físico
2. **Personalización**: Alto nivel de customización tanto digital como física
3. **Calidad de grabado**: Utilización de equipo láser profesional XTool F1 Ultra
4. **Variedad de materiales**: Múltiples opciones para diferentes gustos y presupuestos

![image.png](attachment:65dfc620-6e33-4e14-9589-d1ec170c2a1c:image.png)

### **🔵**

### **Opción 2: Azul Tecnológico + Acero**

- **Azul cobalto (#1A73E8)** – acento principal, transmite confianza e innovación
- **Gris grafito (#2E2E2E)** – base oscura para íconos o fondo
- **Blanco hielo (#F5F7FA)** – espacios en blanco o fondo alternativo

🟢 Refuerza el componente digital/tecnológico y la interfaz amigable.

[Base screens](https://www.notion.so/Base-screens-1e99fa839856806b80e3de80a38ab83f?pvs=21)

[Color pallete](https://www.notion.so/Color-pallete-1e99fa83985680fd8242c4d50d67f478?pvs=21)

[Database Password](https://www.notion.so/Database-Password-21a9fa839856801f8b83de4e659df026?pvs=21)