# Requirements: QRaft v1.0

**Defined:** 2026-05-01
**Core Value:** Cerrar el loop digital→físico con un QR personalizado de calidad: que el usuario pueda diseñar un QR único y recibirlo grabado en su material favorito, sin fricción, pagado en pesos colombianos.

## v1 Requirements

### QR Generation (Print-Safe)

- [x] **QR-01**: User puede generar QRs para tipos URL, texto, vCard, WiFi, eventos, ubicación ✓ Phase 2 plan 02-03
- [ ] **QR-02**: User puede embeber logo central con halo blanco/transparente — error correction nivel H obligatorio, cap ≤20% (≤15% para tattoo profile)
- [ ] **QR-03**: User puede personalizar colores y gradientes (lineales/radiales) con paletas pre-definidas
- [ ] **QR-04**: User puede elegir estilos de módulos y "eyes" desde galería curada (bordes redondeados, puntos circulares, formas validadas con scanner-matrix)
- [ ] **QR-05**: User puede agregar frames con call-to-action ("Scan me", "Visit", etc.) respetando quiet zone de 4 módulos
- [x] **QR-06**: User puede elegir templates de QR pre-diseñados desde galería curada (8-12 templates iniciales) ✓ 2026-05-03 (plan 05-05)
- [x] **QR-07**: User puede generar QRs en bulk importando un CSV (separador `;` para Excel-ES) ✓ 2026-05-03 (plan 05-05)
- [ ] **QR-08**: User puede guardar, editar y duplicar QRs en su library personal
- [ ] **QR-09**: User puede compartir/exportar QR (link, imagen PNG, redes sociales)
- [x] **QR-10**: User selecciona perfil "Print-safe / Digital-only / Tattoo-safe" en el editor con validaciones específicas por perfil ✓ 2026-05-01 (plan 05-01)

### QR Digital-Only (no graban en marketplace)

- [ ] **QRD-01**: User puede generar QRs animados con export GIF/MP4/Lottie (digital share)
- [ ] **QRD-02**: User puede estilizar QRs con AI (vía Replicate/Stability API) con validación obligatoria de escaneabilidad antes de guardar
- [ ] **QRD-03**: User puede agregar QRs de su library a home screen widgets nativos (iOS WidgetKit + Android Glance)

### QR Scanner

- [ ] **SCAN-01**: Resolver bloqueo de mobile_scanner en iOS — bump a 7.2.0 (Vision API en lugar de MLKit), confirmar Flutter SDK ≥3.29
- [ ] **SCAN-02**: Scanner full-screen con overlay verde Carden Pro, auto-detect, tap-to-focus
- [ ] **SCAN-03**: Historial de escaneos persistente (tabla scan_history ya migrada en Supabase)
- [ ] **SCAN-04**: Manejo type-aware de resultado de escaneo (URL → abrir, vCard → guardar contacto, WiFi → conectar, email/phone → acción)

### Marketplace

- [ ] **MKT-01**: User puede navegar catálogo de productos por material × tamaño × precio con filtros y previews
- [x] **MKT-02**: User puede ver preview compuesto de su QR aplicado sobre el material seleccionado (live render)
- [x] **MKT-03**: User puede mantener carrito persistente con cálculo de total (subtotal + IVA 19% + envío)
- [ ] **MKT-04**: User puede completar checkout con dirección Colombia (departamento/municipio/dirección) usando dataset DANE local
- [ ] **MKT-05**: User puede pagar vía Wompi (tarjetas, PSE, Nequi, Daviplata) en WebView Checkout
- [ ] **MKT-06**: Sistema valida y procesa webhooks de Wompi vía Supabase Edge Function con SHA256 X-Event-Checksum + idempotency lock
- [ ] **MKT-07**: User puede ver su lista de órdenes y detalle individual
- [ ] **MKT-08**: User puede ver timeline de estados de cada orden (recibido → en producción → grabando → listo → enviado → entregado) con server-authoritative state machine
- [ ] **MKT-09**: User recibe push notifications FCM de cambios de estado de orden
- [ ] **MKT-10**: User puede suscribirse a tier premium vía RevenueCat (modelo freemium — quita ads + features avanzados)
- [ ] **MKT-11**: Operator puede gestionar órdenes desde dashboard (Flutter Web o Supabase Studio) con transitions vía RPC
- [x] **MKT-12**: Sistema guarda customization snapshot (PNG 2160px + JSONB) en cart/order para que ediciones del library no afecten órdenes en vuelo

### Redirect Service (foundation v2)

- [ ] **RDR-01**: Dominio `qraft.link` (o equivalente) registrado y configurado en DNS
- [ ] **RDR-02**: Servicio de redirects implementado (Supabase Edge Function o Cloudflare Worker) con tabla `redirects`
- [ ] **RDR-03**: Cada orden de marketplace genera slug único (`qraft.link/abc123`) que el láser graba; default destination = URL ingresada por usuario
- [ ] **RDR-04**: User puede editar destination_url de sus QRs desde la app (gratis en v1.0)
- [ ] **RDR-05**: Sistema registra scan analytics básicos (count, last_scanned_at, last_country) por slug
- [ ] **RDR-06**: SLA monitoring + alertas de downtime configurados (uptime crítico para tatuajes y QRs grabados)

### Tattoo Line

- [ ] **TAT-01**: Catálogo de marketplace incluye categoría "Tattoo Stencil/Transfer" — papel transfer/tatuaje temporal con QR
- [ ] **TAT-02**: Validación "Tattoo-safe QR" extra-conservadora (módulos grandes, EC level H, 15% logo cap, simulación de distorsión de piel) integrada al toggle de QR-10
- [ ] **TAT-03**: App incluye contenido educativo/FAQ sobre tatuar QRs (tamaño mínimo, ubicación corporal, healing)
- [ ] **TAT-04**: Landing/CTA "Próximamente: Tattoo Studios Partner" para validación de demanda B2B sin construir feature aún

### Compliance Colombia

- [ ] **LGL-02**: Disclaimer Ley 1480 Art. 47 visible en checkout y post-orden — productos personalizados (grabados) están exentos del retracto 5 días
- [ ] **LGL-03**: Política de privacidad en español + flujo de habeas data (Ley 1581) — consentimiento, derecho al olvido, in-app data export/deletion
- [ ] **LGL-04**: Garantía 3 meses por defectos (Ley 1480) — flujo de reclamo separado del retracto
- [ ] **LGL-05**: Módulo PQRS (Peticiones/Quejas/Reclamos/Sugerencias) accesible desde profile

### Optimización

- [ ] **OPT-01**: Performance — 60fps en Android low-end, splash sub-2s, scroll/transiciones sin jank, time-to-interactive aceptable
- [ ] **OPT-02**: Pulido visual completo Carden Pro — haptic feedback, glow animations, shimmer loading, microinteracciones, dark mode polish, accesibilidad
- [ ] **OPT-03**: Observabilidad production-ready — Firebase Crashlytics + Analytics + Performance, monitoring de pagos, logging estructurado, AdMob UMP consent

## v2 Requirements

Diferidos a v2.0. Tracked but not in current roadmap. Ver `.planning/v2-vision.md` para detalle estratégico.

### DIAN Compliance (debt arrastrada de v1.0)

- **DIAN-01**: Integración DIAN factura electrónica (in-house o provider TBD) — XML UBL 2.1, firma XAdES-BES, CUFE, eventos obligatorios
- **DIAN-02**: Plan de regularización fiscal histórica para transacciones v1.0 (asesoría tributaria + emisión retroactiva)
- **DIAN-03**: Habilitación DIAN previa + set de pruebas + resolución de numeración

### Dynamic QR Platform

- **DYN-01**: Multi-destination redirect (geo-based, time-based, device-based)
- **DYN-02**: Landing page builder lite (drag-drop blocks)
- **DYN-03**: Deep analytics dashboard (timeline, geo heatmap, device breakdown, conversion)
- **DYN-04**: Scheduled destination changes (queue cambios futuros)
- **DYN-05**: Bulk QR management (edit 100s a la vez)

### Subscription Monetization

- **SUB-01**: Subscription billing infrastructure (RevenueCat → Stripe/Wompi recurring)
- **SUB-02**: Pro tier feature gating (multi-destination, analytics, scheduled changes)
- **SUB-03**: Studio/Business tier (custom domains, team accounts, API)
- **SUB-04**: Tattoo Lifetime Plan (one-time payment para QRs tatuados)

### Tattoo Line Expansion

- **TAT2-01**: Tattoo studio partnerships con revenue share
- **TAT2-02**: Lifetime plan launch + sustainability fund
- **TAT2-03**: AR preview de tattoo QR antes de grabar
- **TAT2-04**: Gallery de tatuajes de la comunidad (social proof)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Apps de escritorio (macOS/Windows/Linux) como targets primarios | v1.0 prioriza iOS+Android. Builds existen pero sin polish |
| Internacionalización más allá de es/en | Solo Colombia v1.0; otros idiomas post-v1.0 |
| Marketplace fuera de Colombia (multi-currency, shipping internacional) | Scope locked a Colombia v1.0 — Wompi-Bancolombia + COP + envío nacional |
| Automatización IoT con XTool F1 Ultra (telemetría, control remoto) | Operación manual vía operator dashboard MKT-11. IoT queda para v2+ |
| Dynamic QR features completos (multi-destination, geo/time, landing builder, custom domains, deep analytics) | Diferidos a v2.0. v1.0 solo construye foundation (RDR-01..06). Ver `.planning/v2-vision.md` |
| Subscripción premium para dynamic QRs | v1.0 ofrece edición free. v2.0 introduce tiers premium |
| AI-stylized QRs en marketplace (grabado láser) | Failure rate ~10-15% post-engraving. Solo permitidos en QRD-02 (digital-only) |
| **DIAN factura electrónica en v1.0** | **Risk acceptance explícito.** v1.0 opera marketplace + Wompi sin DIAN, asumiendo exposure hasta 950 UVT (~$47M COP). v2.0 incluye DIAN + regularización histórica |
| B2B wholesale / cuentas corporativas | QR-07 bulk está en v1.0 como feature individual; gestión empresarial con descuentos/contratos queda fuera |
| AR product try-on / 3D rotatable preview | Complejidad ARKit/ARCore alta; v2+ |
| Multi-vendor seller onboarding | QRaft es single-seller en v1.0 |
| Real-time chat / colaboración entre usuarios | No core a la propuesta de valor digital→físico |

## Traceability

Populated by gsd-roadmapper agent on 2026-05-01.

| Requirement | Phase | Status |
|-------------|-------|--------|
| QR-01 | Phase 2 | Complete ✓ |
| QR-02 | Phase 5 | Pending |
| QR-03 | Phase 5 | Pending |
| QR-04 | Phase 5 | Pending |
| QR-05 | Phase 5 | Pending |
| QR-06 | Phase 5 | Complete ✓ 2026-05-03 |
| QR-07 | Phase 5 | Complete ✓ 2026-05-03 |
| QR-08 | Phase 2 | Pending |
| QR-09 | Phase 2 | Pending |
| QR-10 | Phase 5 | Complete ✓ 2026-05-01 |
| QRD-01 | Phase 6 | Pending |
| QRD-02 | Phase 6 | Pending |
| QRD-03 | Phase 6 | Pending |
| SCAN-01 | Phase 1 | Pending |
| SCAN-02 | Phase 3 | Pending |
| SCAN-03 | Phase 3 | Pending |
| SCAN-04 | Phase 3 | Pending |
| MKT-01 | Phase 7 | In Progress (catalog+filter UI: 07-02 ✓; material preview: 07-03) |
| MKT-02 | Phase 7 | Complete (07-03 ✓ 2026-05-03) |
| MKT-03 | Phase 8 | Complete (08-04 ✓ 2026-05-03 — CartSummaryWidget + cartTotalsProvider RPC) |
| MKT-04 | Phase 9 | Pending |
| MKT-05 | Phase 9 | Pending |
| MKT-06 | Phase 9 | Pending |
| MKT-07 | Phase 10 | Pending |
| MKT-08 | Phase 10 | Pending |
| MKT-09 | Phase 10 | Pending |
| MKT-10 | Phase 12 | Pending |
| MKT-11 | Phase 11 | Pending |
| MKT-12 | Phase 8 | Complete (08-03 ✓ 2026-05-03 — CustomizationSnapshotService + unawaited PNG upload) |
| RDR-01 | Phase 4 | Pending |
| RDR-02 | Phase 4 | Pending |
| RDR-03 | Phase 4 | Pending |
| RDR-04 | Phase 4 | Pending |
| RDR-05 | Phase 4 | Pending |
| RDR-06 | Phase 4 | Pending |
| TAT-01 | Phase 11 | Pending |
| TAT-02 | Phase 11 | Pending |
| TAT-03 | Phase 11 | Pending |
| TAT-04 | Phase 11 | Pending |
| LGL-02 | Phase 9 | Pending |
| LGL-03 | Phase 9 | Pending |
| LGL-04 | Phase 9 | Pending |
| LGL-05 | Phase 9 | Pending |
| OPT-01 | Phase 12 | Pending |
| OPT-02 | Phase 12 | Pending |
| OPT-03 | Phase 12 | Pending |

**Coverage:**
- v1 requirements: 46 total
- Mapped to phases: 46 ✓
- Unmapped: 0

**Per-phase requirement count:**
- Phase 1: 1 (SCAN-01)
- Phase 2: 3 (QR-01, QR-08, QR-09)
- Phase 3: 3 (SCAN-02, SCAN-03, SCAN-04)
- Phase 4: 6 (RDR-01..06)
- Phase 5: 7 (QR-02, QR-03, QR-04, QR-05, QR-06, QR-07, QR-10)
- Phase 6: 3 (QRD-01, QRD-02, QRD-03)
- Phase 7: 2 (MKT-01, MKT-02)
- Phase 8: 2 (MKT-03, MKT-12)
- Phase 9: 7 (MKT-04, MKT-05, MKT-06, LGL-02, LGL-03, LGL-04, LGL-05)
- Phase 10: 3 (MKT-07, MKT-08, MKT-09)
- Phase 11: 5 (MKT-11, TAT-01, TAT-02, TAT-03, TAT-04)
- Phase 12: 4 (MKT-10, OPT-01, OPT-02, OPT-03)
- **Total: 46 ✓**

---
*Requirements defined: 2026-05-01*
*Last updated: 2026-05-01 — traceability populated by gsd-roadmapper*
