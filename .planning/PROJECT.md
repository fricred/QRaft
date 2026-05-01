# QRaft

## What This Is

QRaft es una app móvil (iOS + Android, Flutter) que permite a usuarios en Colombia crear códigos QR personalizados (con logos, colores, gradientes, frames con call-to-action y templates pre-diseñados), escanear QRs con historial, y comprar el QR grabado físicamente sobre madera, acrílico, metal, cuero, vidrio o piedra a través de un marketplace integrado que se conecta con una máquina XTool F1 Ultra para producción láser. El usuario final es retail (consumidores individuales) en mercado colombiano.

## Core Value

**Cerrar el loop digital→físico con un QR personalizado de calidad: que el usuario pueda diseñar un QR único y recibirlo grabado en su material favorito, sin fricción, pagado en pesos colombianos.** Si todo lo demás falla, este flujo end-to-end (crear → personalizar → comprar → recibir) debe funcionar.

## Requirements

### Validated

<!-- Inferred from existing codebase (.planning/codebase/) -->

- ✓ **Autenticación Firebase completa** — login, register, forgot password con deeplinks iOS+Android — existing
- ✓ **Splash screen profesional** — animaciones staged 8s, logo custom QRaft con elementos QR y láser — existing
- ✓ **GlassButton component library** — glassmorphism con BackdropFilter, multi-layer glow, variantes Primary/Secondary/Success — existing
- ✓ **Deeplinks iOS + Android** — method channel `qraft/deeplink`, scheme `qraft://`, dominio `qraft-e8a1d.firebaseapp.com` — existing
- ✓ **i18n base (es/en)** — existing
- ✓ **Supabase backend linkeado** — project ref configurado, migraciones aplicadas (001, 002, scan_history fix), buckets de avatars — existing
- ✓ **Test infrastructure base** — flutter_test + mocktail, 38+ tests en GlassButton/AuthController/AuthProvider/DeepLinkService — existing
- ✓ **AdMob integration inicial** — para usuarios free — existing (recently added, validar consent/privacy)
- ✓ **Cross-platform builds configurados** — iOS, Android, web, macOS, Windows, Linux — existing

### Active

<!-- v1.0 scope, agreed with user 2026-05-01 -->

#### QR Generation & Customization

- [ ] **QR-01**: Generación de QR para tipos URL, texto, vCard, WiFi, eventos, ubicación
- [ ] **QR-02**: Logo central con halo blanco/transparente, error correction nivel H para escaneabilidad garantizada
- [ ] **QR-03**: Personalización de colores y gradientes (lineales/radiales), paletas pre-definidas
- [ ] **QR-04**: Estilos de módulos y "eyes" (bordes redondeados, puntos circulares, formas custom para los 3 ojos de posición)
- [ ] **QR-05**: Frames con call-to-action ("Scan me", "Visit", etc.) alrededor del QR
- [ ] **QR-06**: Galería de templates de QR pre-diseñados (curados)
- [ ] **QR-07**: Bulk QR generation / import CSV (B2B-friendly)
- [ ] **QR-08**: Library del usuario con QRs guardados, edición y duplicación
- [ ] **QR-09**: Compartir QR (link, imagen exportada, redes sociales)
- [ ] **QR-10**: UI toggle explícito "Print-safe vs Digital-only" en el editor con validaciones distintas (engraving-safe blokea logo >20% y inversión, digital permite más libertad)

#### QR Digital-Only Features (no graban en marketplace)

- [ ] **QRD-01**: QRs animados con export GIF/MP4/Lottie (digital share, no marketplace)
- [ ] **QRD-02**: QRs estilizados con AI (Replicate/Stability API) con validación obligatoria de escaneabilidad antes de guardar
- [ ] **QRD-03**: Home screen widgets nativos — iOS WidgetKit + Android Glance, mostrar QRs favoritos del library siempre a un tap

#### QR Scanner

- [ ] **SCAN-01**: Resolver bloqueo de `mobile_scanner` en iOS (dependencia pendiente — ver `.planning/codebase/CONCERNS.md`)
- [ ] **SCAN-02**: Scanner full-screen con overlay verde estilo Carden Pro
- [ ] **SCAN-03**: Historial de escaneos persistente (Supabase `scan_history` ya existe)
- [ ] **SCAN-04**: Manejo por tipo de QR (URL → abrir, vCard → guardar contacto, WiFi → conectar, etc.)

#### Marketplace

- [ ] **MKT-01**: Catálogo navegable (productos por material × tamaño × precio) con previews realistas y filtros
- [ ] **MKT-02**: Preview del QR del usuario aplicado sobre el material seleccionado
- [ ] **MKT-03**: Carrito persistente con cálculo de total (subtotal + IVA 19% + envío)
- [ ] **MKT-04**: Checkout con dirección de envío Colombia (departamento/ciudad/dirección)
- [ ] **MKT-05**: Integración Wompi (Bancolombia) — tarjetas, PSE, Nequi, Daviplata
- [ ] **MKT-06**: Webhooks de Wompi para confirmación de pagos
- [ ] **MKT-07**: Vista de órdenes del usuario (lista + detalle)
- [ ] **MKT-08**: Timeline de estados de orden (recibido → en producción → grabando → listo → enviado → entregado)
- [ ] **MKT-09**: Notificaciones push de cambios de estado (FCM)
- [ ] **MKT-10**: Cuentas premium / suscripciones (modelo freemium)
- [ ] **MKT-11**: Operator dashboard (Flutter Web o Supabase Studio + RPC) para gestión manual de órdenes — sin esto hay drift de status que rompe confianza
- [ ] **MKT-12**: Customization snapshot — cart/order guardan PNG pre-rasterizado 2160px + JSONB de customization para que ediciones futuras del library no afecten órdenes en vuelo

#### Compliance Colombia (legal blockers para v1.0)

- [ ] **LGL-01**: DIAN factura electrónica — integración con proveedor (Alegra/Siigo/Dataico) para emitir UBL 2.1 + CUFE en cada venta. **Sin esto no se puede operar legalmente**
- [ ] **LGL-02**: Disclaimer Ley 1480 Art. 47 — exhibir en checkout/post-orden que productos personalizados (grabados) están exentos del retracto 5 días
- [ ] **LGL-03**: Política de privacidad + habeas data Ley 1581 — flujo de consentimiento, derecho al olvido, registro RNBD si supera umbral
- [ ] **LGL-04**: Garantía 3 meses por defectos (Ley 1480) — flujo de reclamo separado del retracto
- [ ] **LGL-05**: PQRS module (Peticiones/Quejas/Reclamos/Sugerencias) — norma Colombia para apps consumer-facing

#### Optimización (cross-cutting)

- [ ] **OPT-01**: Performance — 60fps en Android low-end, splash sub-2s, scroll/transiciones sin jank
- [ ] **OPT-02**: Pulido visual completo Carden Pro — haptic feedback, glow animations, shimmer loading, microinteracciones, dark mode polish
- [ ] **OPT-03**: Observabilidad production-ready — Crashlytics, analytics, error tracking, monitoring de pagos, logging estructurado

### Out of Scope

<!-- v1.0 deliberadamente excluye: -->

- **Apps de escritorio (macOS/Windows/Linux) como targets primarios** — los builds existen pero v1.0 prioriza iOS+Android. Se mantienen funcionales pero sin polish específico
- **Internacionalización más allá de es/en** — solo Colombia en v1.0; portugués/francés/etc. se evalúa post-v1.0
- **Marketplace fuera de Colombia** — solo COP, envío nacional, Wompi colombiano. Multi-país queda para v2
- **Automatización IoT con la máquina XTool F1 Ultra** — la integración directa máquina-app (envío de archivos, telemetría, control remoto) queda para v2. La operación se hace manual a través del operator dashboard (MKT-11)
- **B2B wholesale / cuentas corporativas** — `QR-07` (bulk) está en v1.0 pero como feature de usuario individual; gestión de cuentas empresariales con descuentos/contratos queda fuera

## Context

**Tech stack** (de `.planning/codebase/STACK.md`):
- Flutter 3.6.2+ / Dart, Riverpod state management, go_router (planned)
- Firebase Auth (project `qraft-e8a1d`, bundle `io.gothcorp.qraft`) + Supabase (Postgres + Edge Functions + Storage)
- Diseño visual basado en Carden Pro adaptado: dark-first (#1A1A1A), neon accent #00FF88, glassmorphism

**Estado actual** (de `.planning/codebase/ARCHITECTURE.md`):
- Clean Architecture por feature (`data/`/`domain/`/`presentation/`)
- Auth completo, marketplace stub, QR generation/scanner pendientes
- AdMob recién agregado (`commit 528c62c`), service key Supabase removido (`ecbf781`)

**Concerns conocidos** (de `.planning/codebase/CONCERNS.md`):
- iOS dependency block en `mobile_scanner` — bloqueador para SCAN-01
- 5/13 tests de ForgotPasswordDialog fallan
- AdMob requires consent/privacy review
- env.json secret handling debe estar en gitignore (verificado)

**Máquina física**:
- XTool F1 Ultra (specs a investigar por research-agent)
- Materiales objetivo: madera, acrílico, metal, cuero, vidrio, piedra
- Operación manual — el catálogo del marketplace debe diseñarse alrededor de las capacidades reales de la máquina (área grabable, materiales certificados, tiempos)

**Mercado y monetización**:
- Solo Colombia v1.0 — moneda COP, IVA 19%, envío nacional
- Monetización: AdMob (usuarios free) + comisión sobre ventas marketplace + suscripciones premium (MKT-10)

## Constraints

- **Tech stack**: Flutter (cross-platform) — locked, codebase ya construido sobre esto
- **Backend**: Firebase Auth + Supabase — locked, ya configurados con datos
- **Pagos**: Wompi (Bancolombia) — decisión del usuario, soporta PSE/Nequi/Daviplata/tarjetas que dominan el mercado colombiano
- **Geografía**: Solo Colombia v1.0 — driver de moneda, payment processor, regulación
- **Timeline**: 4-6 meses para v1.0 completo (scope amplio > velocidad ASAP)
- **Plataformas primarias**: iOS + Android — desktop builds se mantienen funcionales pero sin polish
- **Producción láser**: manual (no automatización máquina-app en v1.0)
- **Compliance**: regulación financiera Colombia (Wompi maneja PCI), privacy (Ley 1581 + AdMob consent)

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Wompi como payment processor | Mejor cobertura de medios de pago colombianos (PSE/Nequi/tarjetas/Daviplata) vs Stripe que requiere LLC US o MercadoPago menos integrado con bancos locales | — Pending |
| Solo Colombia en v1.0 | Reduce complejidad de multi-currency/i18n/regulación, permite enfocarse en cerrar el loop digital→físico bien antes de escalar | — Pending |
| Scope amplio + 4-6 meses (rechazo de ASAP estricto) | Usuario explícitamente prefiere shipear feature-complete sobre shipear MVP rápido. Define la estructura del roadmap en fases más grandes | ⚠️ Revisit — si emerge presión de mercado, considerar partir v1.0 en alpha/beta/GA |
| Roadmapper decide orden de fases por dependencias técnicas | Usuario sin preferencia fuerte, prefiere optimización lógica sobre prioridad por valor de negocio | — Pending |
| Test coverage / code quality NO es eje de "optimización" | Usuario priorizó performance + visual + observabilidad. Sin embargo, app maneja pagos reales — los tests del flujo de checkout son críticos y se mantendrán como subtareas implícitas en cada fase de marketplace | ⚠️ Revisit — proponer tests de checkout en review de plan, aunque el usuario no los marcó como prioridad |
| Operación de la máquina XTool F1 Ultra es manual en v1.0 | Reduce scope técnico (no IoT, no API máquina) y permite validar el modelo de negocio antes de invertir en automatización | — Pending |
| UI bifurcada print-safe vs digital-only en el editor | Permite ofrecer QRs animados + AI + widgets como diferenciadores digitales sin contaminar el flujo del marketplace donde la escaneabilidad post-grabado es crítica. Toggle explícito > detección automática (más predecible para usuario) | — Pending |
| Logo cap 20% con error correction H (no 25%) | Backed por ISO/IEC 18004 + research de pitfalls. Margen de 30% recovery menos buffer para wear/tear de grabado láser. Hard-coded en validaciones de print-safe | — Pending |
| QR siempre exportado dark-on-light para marketplace, ignorando theme de la app | Inversión (light-on-dark) silenciosamente falla en iOS Camera y muchos scanners nativos. Hard-code en export para evitar bugs de escaneabilidad | — Pending |
| DIAN factura electrónica vía proveedor (Alegra/Siigo/Dataico TBD) | Construir factura DIAN-compliant in-house es prohibitivo. Decisión de proveedor específico se difiere a research del marketplace phase | — Pending |
| Operator dashboard como Flutter Web build separado vs Supabase Studio | Decisión técnica diferida — depende de quién opera (developer-only → Studio basta; staff no-técnico → Flutter Web). Surfacear durante el roadmap | — Pending |
| Wompi vía REST + Web Checkout en webview_flutter (no SDK Flutter) | El community SDK `wompi_payment_colombia` está stale (21 meses). REST con WebView reduce PCI scope y mantiene UI controlada | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-01 after initialization*
