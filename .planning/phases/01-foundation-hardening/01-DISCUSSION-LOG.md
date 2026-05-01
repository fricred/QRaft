# Phase 1: Foundation Hardening - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-01
**Phase:** 1-Foundation Hardening
**Areas discussed:** Firebase reintroduction scope, AdMob UMP consent UX, ForgotPasswordDialog test fix approach, Verification depth bar

---

## Firebase Reintroduction Scope

### Q1: ¿Hasta dónde llega Phase 1 con Firebase?

| Option | Description | Selected |
|--------|-------------|----------|
| Mínimo: solo wiring base | Phase 1 instala firebase_core + las 3 packages, agrega google-services.json y GoogleService-Info.plist, llama Firebase.initializeApp() en main.dart. Las 3 services (FCM/Crashlytics/Analytics) NO se configuran end-to-end aquí — eso queda para Phase 10 (FCM), Phase 12 (Crashlytics+Analytics). Phase 1 solo garantiza que el build no rompa. | ✓ |
| Medio: wiring + Crashlytics activo | Igual que mínimo, más: integrar Crashlytics desde Phase 1 (capturar crashes desde dia 1 de desarrollo es alto valor). FCM y Analytics quedan para sus fases. Costo extra: dSYM upload setup en iOS. | |
| Completo: todo configurado E2E | Phase 1 configura las 3 services completamente: FCM con APNs cert + token registration plumbing, Crashlytics con dSYM upload + smoke test crash, Analytics con primer evento. Más scope en Phase 1, menos trabajo en Phases 10/12. | |
| Diferir Firebase enteramente | Phase 1 NO trae Firebase de vuelta. Las 3 packages se quitan de la lista milestone de Phase 1 y se reasignan: firebase_messaging → Phase 10, firebase_crashlytics+analytics → Phase 12. Phase 1 queda más limpia pero hay que actualizar ROADMAP.md. | |

**User's choice:** Mínimo: solo wiring base
**Notes:** Phase 1 stays operational; per-service activation deferred to the phases that actually consume each service. ROADMAP.md milestone package list remains intact — only the depth of activation is scoped down.

### Q2: ¿El proyecto Firebase qraft-e8a1d sigue activo o crear uno nuevo?

| Option | Description | Selected |
|--------|-------------|----------|
| Sigue activo, reutilizar | qraft-e8a1d existe en Firebase Console y tengo acceso. Phase 1 descarga google-services.json + GoogleService-Info.plist desde ahí, los agrega al repo y reutiliza el mismo project ID. | ✓ |
| Crear uno nuevo | Borrar referencias al viejo qraft-e8a1d, crear un nuevo Firebase project, descargar configs nuevos. Phase 1 incluye la creación del proyecto en Firebase Console como prerequisito. | |
| No sé / verificar después | Marcar como TODO de verificación al inicio de Phase 1 antes de proceder con package installation. | |

**User's choice:** Sigue activo, reutilizar
**Notes:** Saves a Firebase Console setup task and preserves continuity with prior auth references. Codebase scout confirms project ID still cited in CLAUDE.md and deeplink configuration (`qraft-e8a1d.firebaseapp.com`).

---

## AdMob UMP Consent UX

### Q1: ¿Cuándo se muestra el formulario de consentimiento UMP?

| Option | Description | Selected |
|--------|-------------|----------|
| Después del splash, antes de cualquier ad request | Splash corre normal. Después del splash, UMP evalúa region+ConsentInformation; si requiere consent muestra el form en pantalla dedicada; al completar, MobileAds.instance.initialize() se llama. Latencia ~1-2s extra solo en first launch. | ✓ |
| Pre-splash (más temprano) | UMP corre antes que el splash anime. Más purista pero degrada la UX de bienvenida. | |
| On-demand (al primer ad request) | El form aparece la primera vez que se intentaría mostrar un banner. Riesgo: violación de política si AdMob inicializa antes. | |

**User's choice:** Después del splash, antes de cualquier ad request

### Q2: ¿A quién se le muestra el form de UMP?

| Option | Description | Selected |
|--------|-------------|----------|
| A todos los usuarios globalmente | UMP detecta automáticamente region GDPR/EU/UK y aplica el formulario obligatorio. Para regiones no-GDPR, UMP muestra consent simplificado o lo skipea. Robusto a futuras regulaciones (LGPD, CCPA, Ley 1581). | ✓ |
| Solo a usuarios en regiones GDPR (geo-targeted) | Detectar region en cliente; si es EU/UK mostrar UMP. No cubre futuras regulaciones. | |
| A todos pero con UI custom adicional para Colombia | Además del UMP estándar, agregar consent específico Habeas Data Ley 1581 (LGL-03) que ya está en Phase 9. | |

**User's choice:** A todos los usuarios globalmente
**Notes:** Consent Habeas Data Ley 1581 sigue siendo Phase 9 (LGL-03), separado del UMP de Phase 1.

### Q3: Si el usuario deniega consent, ¿qué hace la app?

| Option | Description | Selected |
|--------|-------------|----------|
| Mostrar ads no-personalizados | Pasar npa=1 a AdMob; banners siguen apareciendo sin tracking. GDPR-compliant. Industry-standard. | ✓ |
| No mostrar ads | Si deniega, MobileAds NO se inicializa. Más respetuoso pero pierde revenue. | |
| Forzar a aceptar o suscribirse | Bloquear acceso hasta consent o premium. Posible violación de políticas Apple/Google. | |

**User's choice:** Mostrar ads no-personalizados

---

## ForgotPasswordDialog Test Strategy

### Q1: ¿Cómo abordamos los tests de ForgotPasswordDialog en Phase 1?

| Option | Description | Selected |
|--------|-------------|----------|
| Patch mínimo: arreglar lo que falla | Correr los 6 tests existentes, ajustar mocks/wait conditions/setup hasta que pase 6/6. NO refactor del dialog. | |
| Refactor + tests | Extraer la lógica de Riverpod async state del dialog a un controller separado, simplificar el widget a presentación pura, reescribir tests. | ✓ |
| Reconciliar primero, decidir después | Phase 1 incluye una primera tarea: correr tests, contar fallos reales, actualizar CONCERNS.md/CLAUDE.md. Decisión patch-vs-refactor con datos reales. | |
| Bajar prioridad: solo reconciliar números | Si los 6 tests pasan hoy, solo actualizar CONCERNS.md/CLAUDE.md. | |

**User's choice:** Refactor + tests
**Notes:** Address the fragility flagged in CONCERNS.md once and properly. Reconciliation of test counts (6 actual vs 13 documented) is part of the refactor's pre-step; not deferred.

### Q2: ¿Qué patrón debe seguir el controller extraído?

| Option | Description | Selected |
|--------|-------------|----------|
| Match existing AuthController | Replicar StateNotifier con AsyncValue, copyWith. Consistencia con resto del módulo auth. | |
| Riverpod 2.x AsyncNotifier (más moderno) | Más idóneo a futuro, pero introduce inconsistencia con AuthController. | |
| Lo decide el planner durante research | Surfacear como decisión abierta para el plan-phase. Planner revisa código y propone en PLAN.md. | ✓ |

**User's choice:** Lo decide el planner durante research
**Notes:** Explicit delegation to planner — must produce a research-backed comparison in PLAN.md.

---

## Verification Depth Bar

### Q1: ¿Qué nivel de verificación cierra Phase 1?

| Option | Description | Selected |
|--------|-------------|----------|
| Build + dry-run + tests verdes | Phase 1 done = pub upgrade --dry-run sin conflictos + flutter analyze clean + flutter test 100% verde + flutter run iOS+Android arranca en simulator. Sin device físico obligatorio. | ✓ |
| Build + smoke tests en device físico | Además: mobile_scanner escanea QR real en iOS device, AdMob UMP form aparece en device, banner ad se muestra post-consent. | |
| Bar máxima: + Firebase smoke | Todo lo anterior + Crashlytics test crash + FCM token + Analytics primer evento. Incompatible con wiring mínimo de Área 1. | |

**User's choice:** Build + dry-run + tests verdes
**Notes:** Functional smoke tests are deferred to the consuming feature phases (Phase 3 for scanner, Phase 10 for FCM, Phase 12 for Crashlytics/Analytics).

### Q2: Si mobile_scanner 7.2.0 falla en pub get/iOS pod install, ¿cuál es el fallback?

| Option | Description | Selected |
|--------|-------------|----------|
| Escalar a research-phase y bloquear | Si 7.2.0 no resuelve, Phase 1 se pausa y dispara /gsd-research-phase 1. NO downgrade a 7.x previa porque 4-6 también tienen breaking changes. | ✓ |
| Probar 7.x latest, si falla downgrade a 6.x | Riesgo: 6.x usa MLKit en iOS, el problema original. | |
| Stub temporal del scanner para Phase 1 | Comentar mobile_scanner del pubspec, dejar UI con placeholder, desbloquear el resto. Rompe SCAN-01. | |

**User's choice:** Escalar a research-phase y bloquear
**Notes:** Hard fail on 7.2.0 resolution → research handoff. Avoids reintroducing the iOS bug being fixed.

---

## Claude's Discretion

- Exact controller pattern for ForgotPasswordDialog refactor (StateNotifier vs AsyncNotifier vs hybrid).
- pubspec.yaml ordering / grouping of new packages.
- Whether to combine package installs into a single `pub add` or stage them.
- Naming of the new UMP consent screen widget and route.

## Deferred Ideas

- Functional scanner verification on iOS device → Phase 3 (SCAN-02).
- FCM end-to-end activation → Phase 10 (MKT-09).
- Crashlytics + Analytics activation → Phase 12 (OPT-03).
- Habeas Data Ley 1581 consent UI → Phase 9 (LGL-03).
- Migrating other Riverpod providers from StateNotifier to AsyncNotifier — depends on planner's controller-pattern choice.
- Splitting the 1500+ line UI screens flagged in CONCERNS.md — revisit during Phases 2/5/8.
- Reconciling pubspec/CLAUDE.md docs that still describe Firebase Auth as active — doc cleanup.
- CI pre-commit hook to verify env.json is never staged — backlog.
