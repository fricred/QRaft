# QRaft v2.0 Vision — Dynamic QR Platform

**Status:** Strategic vision document. Not executable roadmap.
**Created:** 2026-05-01 during v1.0 initialization
**Trigger to activate:** v1.0 GA + ~3-6 months of marketplace data + minimum installed base validated

---

## TL;DR

v2.0 transforms QRaft from "QR app + laser marketplace" into **the dynamic QR platform with the world's only physical wedge**. The strategic insight: every static QR engraved in v1.0 already routes through `qraft.link/{slug}` — converting them to dynamic (paid subscription unlock) is a UI flip, not a re-architecture. v1.0 monetizes the physical product. v2.0 unlocks recurring revenue from every customer the marketplace ever served.

---

## The Business Model Insight

The QR app market is a **subscription business disguised as a generator**. QR TIGER, Uniqode, ME-QR, Beaconstac all derive ~80% of revenue from dynamic QR subscriptions, NOT from the QR generator itself. The generator is the funnel; the redirect dashboard is the cash register.

QRaft has two assets that NO competitor in this space has:
1. **Physical permanence** — laser-engraved QRs cannot be replaced once shipped. The user is locked into the redirect we control. This is the strongest possible retention mechanic.
2. **Tattoo wedge** — irreversible commitment + emotional investment + decade-scale preservation need. Pure premium pricing power.

The combination is rare. SaaS QR competitors have neither. Etsy laser-sellers have neither. QRaft can own it.

---

## v1.0 → v2.0 Architecture Bridge

The single most important decision baked into v1.0 is that **every engraved QR points to `qraft.link/{slug}`, not the user's URL directly**. This means:

- v1.0 customer engraves a QR pointing to `qraft.link/abc123` → which currently redirects (statically) to `https://miempresa.com`
- v2.0 launches: same customer pays subscription → editing destination becomes "dynamic" with multi-destination, geo/time targeting, landing builder, deep analytics
- Same physical product, same QR slug, completely different software experience. **Zero customer migration friction.**

In v1.0, destination editing is **free** to:
1. Validate the value proposition without paywall friction
2. Build the largest possible installed base of pre-qualified leads
3. Avoid the worst-case UX (someone's tattoo redirect dies because they didn't pay)

In v2.0, monetization shifts to *advanced* features (multi-destination, landing builder, etc.) — the basic redirect always remains free. This is the **graceful degradation** principle: physical permanence requires perpetual functionality.

---

## v2.0 Feature Tiers

### Free (continues from v1.0)
- One redirect destination per QR
- Manual destination edits (unlimited but rate-limited if abuse emerges)
- Basic scan analytics (count, country, last scanned)
- All v1.0 features (QR generation, customization, scanner, marketplace)

### Pro Tier (v2.0 — paid monthly/annual)
- **Multi-destination redirect**: route by geo (Bogotá → mapa, Medellín → otro mapa), time (horario comercial → tienda, fuera → contacto), device (iOS → App Store, Android → Play Store)
- **Landing page builder lite**: drag-drop blocks (text, image, video, link list, map, contact form, RSVP) hosted at `qraft.link/{slug}` — Linktree pero contextual
- **Deep analytics**: scan timeline, geo heatmap, device breakdown, referrer, peak times, conversion tracking
- **Scheduled changes**: queue destination changes ("on Dec 24 switch to holiday landing")
- **Bulk QR management**: edit 100s of QRs at once
- **Priority support**

### Studio/Business Tier (v2.0)
- Custom domains (`tu-marca.qraft.link` or `qr.tu-marca.com`)
- Team accounts (multi-user with roles)
- API access + webhooks
- White-label: remove "Powered by QRaft"
- Higher rate limits
- SLA guarantees

### Tattoo Lifetime Plan (v2.0 — flagship product)
- **One-time payment** (~$X COP / ~$50-100 USD equivalent)
- Permanent dynamic capabilities for ONE specific QR (the tattooed one)
- "Forever" support guarantee with sustainability fund (long-tail uptime budget)
- Includes high-resolution stencil + transfer + Tattoo-Safe QR validation profile
- Marketing: "Your tattoo will never be outdated"

---

## Tattoo Line Evolution

| Phase | What's offered |
|---|---|
| **v1.0 (minimal)** | TAT-01..04 — stencil/transfer products in marketplace, tattoo-safe QR validation (15% logo cap, EC-H, larger modules), educational FAQ, partner waitlist |
| **v2.0 (flagship)** | Lifetime Plan as a SKU, tattoo studio partnerships (revenue share), white-label tools for tattoo artists, "preview your tattoo" AR feature, social proof (tatuajes de la comunidad gallery) |
| **v3.0 (platform)** | Marketplace de tattoo artists con QR especializados, training/certification program, B2B SaaS for studios |

---

## Anti-features for v2 (don't build these unless data demands)

- **Free tier with destination edits behind subscription wall** — kills physical permanence promise; reputational suicide
- **Aggressive ads on free tier landing pages** — ruins UX, content moderation nightmare
- **Crypto/NFT integration** — chasing hype, no real product fit
- **Generic URL shortener (compete with bit.ly)** — different market, different unit economics, no QRaft moat
- **Self-serve laser machine API** — v3+ at earliest, requires hardware partnership

---

## Compliance & Risk Surfaces

The redirect service introduces non-trivial obligations:

1. **Content moderation**: users WILL try to redirect to spam, malware, phishing, illegal content. Need:
   - Automated URL safety check (Google Safe Browsing API, custom ML)
   - User-report mechanism
   - Takedown SLA
   - Terms with explicit prohibited content list
   
2. **Uptime SLA**: tattoo plan promises "forever" — operationally:
   - Multi-region redirect serving (Cloudflare Workers ideal)
   - Database backup + replication strategy
   - Sustainability fund for "free" lifetime plans
   - Communication strategy if downtime happens

3. **Privacy / GDPR-equivalent**: scan analytics include geo + device data
   - Need explicit consent flow
   - Anonymous mode option
   - Data retention policy
   - Right to deletion (but redirect itself stays alive even if analytics deleted)

4. **Legal entity for global expansion**: when v2 expands beyond Colombia, need:
   - International payment processing
   - Multi-currency
   - Country-specific legal compliance (GDPR EU, CCPA California, etc.)

---

## Open Strategic Questions

To resolve before activating v2.0 roadmap:

1. **Domain choice**: `qraft.link` available? Alternative options? (`qrf.co` short but unclear, `qraft.app` taken?)
2. **Subscription pricing**: $X/month for Pro in COP — research what Colombian users will pay for SaaS subscriptions
3. **Landing page builder vs simple redirect**: full builder is heavy. Maybe v2.0 ships only multi-destination + analytics, landing builder waits for v2.1
4. **Tattoo Lifetime Plan economics**: what's the long-tail cost of maintaining a redirect "forever"? Sustainability fund sizing
5. **B2B angle for tattoo studios**: revenue share model? Partnership tier? Wholesale stencil bulk pricing?
6. **AI features placement**: AI-stylized QRs are in v1.0 (digital-only) — does v2.0 add AI-generated landing pages? AI-suggested destinations?
7. **International expansion**: Colombia → LATAM → US → Global. Sequence and timing?
8. **Custom domain implementation**: DNS-level subdomain ON `tu-marca.qraft.link` is trivial; full custom apex domain (`qr.tu-marca.com`) requires more infrastructure

---

## Activation Triggers

v2.0 should be considered ready to plan when:

- ✅ v1.0 has shipped to production
- ✅ At least 200-500 marketplace orders fulfilled (validates the loop works)
- ✅ At least 50+ tattoo-line orders (validates the wedge)
- ✅ Average destination edit frequency measured per user (informs pricing tiers)
- ✅ Domain `qraft.link` (or chosen alternative) registered and operational from v1.0
- ✅ Operator dashboard (MKT-11) operational without major drift issues
- ✅ DIAN factura integration stable
- ⚠️ User research conducted with 20+ v1.0 customers about willingness to pay for dynamic features

---

## Rough Phasing for v2.0 (when activated)

These phases will be scoped properly via `/gsd-new-milestone v2.0` when triggered. Sketch only:

| Phase (v2) | Theme |
|---|---|
| v2.A | Subscription billing infrastructure (RevenueCat → Stripe / Wompi recurring) |
| v2.B | Pro tier — multi-destination + scheduled changes |
| v2.C | Pro tier — deep analytics dashboard |
| v2.D | Landing page builder lite |
| v2.E | Tattoo Lifetime Plan launch + studio partnerships |
| v2.F | Studio/Business tier — custom domains + team accounts |
| v2.G | API + webhooks |

---

## Key Decisions Already Locked (during v1.0)

These v1.0 architectural decisions enable v2.0:

- ✓ Every engraved QR points to `qraft.link/{slug}` (RDR-03)
- ✓ Free destination editing in v1.0 (no monetization friction during base-building)
- ✓ Tattoo line minimal product in v1.0 (validates segment without full feature build)
- ✓ Operator dashboard required v1.0 (foundation for B2B operations later)
- ✓ Print-safe vs digital-only vs tattoo-safe profiles (architecture supports tier-aware validation)
- ✓ Customization snapshot pattern (v2 multi-destination won't break in-flight orders)

---

*This document is a living strategic artifact. Update as v1.0 ships and learnings emerge. Do not implement v2 features until activation triggers met.*
