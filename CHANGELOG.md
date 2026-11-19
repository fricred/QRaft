# Changelog

## [1.0.0] — 2026-05-01

### QRaft v1.0 — GA Launch

#### QR Generation
- Genera QRs para URL, texto, vCard, WiFi, eventos y ubicación
- Biblioteca personal con guardado, edición y duplicación
- Exporta y comparte como PNG o enlace
- Estilos con IA (Replicate API) con validación de escaneo obligatoria
- QRs animados: export GIF/MP4
- Widget de pantalla de inicio (iOS WidgetKit + Android Glance)
- Importación masiva CSV (separador `;`) para generación en bulk

#### Personalización
- Perfiles Print-Safe, Digital-Only y Tattoo-Safe
- Colores, gradientes, estilos de módulos y "eyes" curados
- Frames con call-to-action y quiet zone automático
- Galería de 8 templates curados
- Logo central con halo blanco (EC-H automático)

#### Marketplace
- Catálogo de productos grabados en madera, acrílico, metal, cuero, vidrio y piedra
- Preview en vivo del QR sobre el material seleccionado
- Carrito persistente con snapshot de personalización congelada
- Categoría Tattoo: stencils y tatuajes temporales con QR

#### Pagos y Cumplimiento Legal
- Pago vía Wompi (tarjetas, PSE, Nequi, Daviplata) en COP
- Webhooks seguros con verificación SHA256
- Cumplimiento Ley 1480 (retracto, garantía) y Ley 1581 (habeas data)
- Módulo PQRS desde el perfil

#### Órdenes y Notificaciones
- Timeline de estados en tiempo real vía Supabase Realtime
- Push notifications FCM en cada cambio de estado
- Dashboard de operador para gestión de órdenes

#### Premium (RevenueCat)
- QRs ilimitados, estilos IA ilimitados, importación masiva CSV
- Sin anuncios para suscriptores premium

#### Infraestructura
- Servicio de redirects `qraft.link/{slug}` — edición gratuita en v1
- Firebase Crashlytics + Analytics integrados
- Privacidad: Ley 1581 + consentimiento AdMob UMP
