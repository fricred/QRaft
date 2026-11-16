// Pure rendering for the public scanqraft.app/<slug> response: no I/O, fully unit-tested.
// Content is stored as { payload: <exact string a static QR of that type would encode> },
// so parsing here mirrors lib/features/qr_generator/domain/entities/qr_data_models.dart.

export type ContentType = "url" | "text" | "vcard" | "vevent" | "geo" | "wifi" | "email";
export type Status = "pending_payment" | "active" | "paused" | "revoked" | "blocked";
export type Lang = "es" | "en";

export interface RedirectRow {
  id: string;
  slug: string;
  status: Status;
  content_type: ContentType | null;
  content: { payload?: string } | null;
}

export interface Outcome {
  status: number;
  headers: Record<string, string>;
  body: string | null;
  /** Count this hit as a scan (only a real view of an active code). */
  countScan: boolean;
}

const BASE_HEADERS: Record<string, string> = {
  "Cache-Control": "no-store",
  "X-Robots-Tag": "noindex, nofollow",
  "Referrer-Policy": "no-referrer",
  "X-Content-Type-Options": "nosniff",
};

export function pickLang(acceptLanguage: string | null): Lang {
  return (acceptLanguage ?? "").trim().toLowerCase().startsWith("es") ? "es" : "en";
}

export function escapeHtml(s: string): string {
  return s
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

/** http(s) URL without whitespace or credentials, else null. */
export function safeHttpUrl(raw: string | undefined | null): string | null {
  if (!raw) return null;
  const v = raw.trim();
  if (/\s/.test(v)) return null;
  try {
    const u = new URL(v);
    if (u.protocol !== "http:" && u.protocol !== "https:") return null;
    if (u.username || u.password) return null;
    return u.toString();
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Payload parsers
// ---------------------------------------------------------------------------

/** Unfolded `NAME[;params]:value` lines of a vCard / iCalendar payload. */
function contentLines(payload: string): { name: string; params: string; value: string }[] {
  const unfolded = payload.replace(/\r\n/g, "\n").replace(/\n[ \t]/g, "");
  const out: { name: string; params: string; value: string }[] = [];
  for (const line of unfolded.split("\n")) {
    const colon = line.indexOf(":");
    if (colon <= 0) continue;
    const head = line.slice(0, colon);
    const semi = head.indexOf(";");
    out.push({
      name: (semi < 0 ? head : head.slice(0, semi)).toUpperCase(),
      params: semi < 0 ? "" : head.slice(semi + 1),
      value: line.slice(colon + 1),
    });
  }
  return out;
}

function unescapeText(v: string): string {
  return v.replace(/\\n/gi, "\n").replace(/\\([,;\\:"])/g, "$1");
}

export interface VCard {
  name: string;
  org: string;
  title: string;
  phones: string[];
  emails: string[];
  url: string | null;
  address: string;
  note: string;
}

export function parseVCard(payload: string): VCard {
  const card: VCard = { name: "", org: "", title: "", phones: [], emails: [], url: null, address: "", note: "" };
  for (const l of contentLines(payload)) {
    const v = unescapeText(l.value).trim();
    if (!v) continue;
    switch (l.name) {
      case "FN": card.name = v; break;
      case "ORG": card.org = v.replace(/;+$/, "").replaceAll(";", " · "); break;
      case "TITLE": card.title = v; break;
      case "TEL": card.phones.push(v); break;
      case "EMAIL": card.emails.push(v); break;
      case "URL": card.url = safeHttpUrl(v.startsWith("http") ? v : `https://${v}`); break;
      case "ADR": card.address = v.split(";").map((p) => p.trim()).filter(Boolean).join(", "); break;
      case "NOTE": card.note = v; break;
    }
  }
  if (!card.name) {
    const n = contentLines(payload).find((l) => l.name === "N");
    if (n) card.name = unescapeText(n.value).split(";").slice(0, 2).reverse().join(" ").trim();
  }
  return card;
}

export interface CalTime { date: Date; allDay: boolean; floating: boolean; tzid: string | null }

export interface CalEvent {
  title: string;
  start: CalTime | null;
  end: CalTime | null;
  location: string;
  description: string;
}

function parseIcsDate(value: string, params: string): CalTime | null {
  const m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$/.exec(value.trim());
  if (!m) return null;
  const [, y, mo, d, h, mi, s, z] = m;
  const allDay = !h || /VALUE=DATE(?!-)/i.test(params);
  const parts = [Number(y), Number(mo) - 1, Number(d), Number(h ?? 0), Number(mi ?? 0), Number(s ?? 0)] as const;
  // Floating / TZID times are shown as written (wall-clock), so build them in UTC and format in UTC.
  const date = new Date(Date.UTC(...parts));
  const tz = /TZID=([^;:]+)/i.exec(params)?.[1]?.replace(/^"|"$/g, "") ?? null;
  return { date, allDay, floating: !z, tzid: z ? null : tz };
}

export function parseEvent(payload: string): CalEvent {
  const ev: CalEvent = { title: "", start: null, end: null, location: "", description: "" };
  for (const l of contentLines(payload)) {
    switch (l.name) {
      case "SUMMARY": ev.title = unescapeText(l.value).trim(); break;
      case "DTSTART": ev.start = parseIcsDate(l.value, l.params); break;
      case "DTEND": ev.end = parseIcsDate(l.value, l.params); break;
      case "LOCATION": ev.location = unescapeText(l.value).trim(); break;
      case "DESCRIPTION": ev.description = unescapeText(l.value).trim(); break;
    }
  }
  return ev;
}

export interface Wifi { ssid: string; password: string; security: string; hidden: boolean }

/** WIFI:T:WPA;S:name;P:pass;H:false;; with \ escapes for \ ; , : " */
export function parseWifi(payload: string): Wifi {
  const body = payload.replace(/^WIFI:/i, "");
  const fields: Record<string, string> = {};
  let key = "";
  let val = "";
  let inKey = true;
  for (let i = 0; i < body.length; i++) {
    const c = body[i];
    if (c === "\\" && i + 1 < body.length) {
      if (inKey) key += body[++i]; else val += body[++i];
      continue;
    }
    if (inKey && c === ":") { inKey = false; continue; }
    if (!inKey && c === ";") {
      fields[key.toUpperCase()] = val;
      key = ""; val = ""; inKey = true;
      continue;
    }
    if (inKey) key += c; else val += c;
  }
  return {
    ssid: fields.S ?? "",
    password: fields.P ?? "",
    security: fields.T ?? "",
    hidden: (fields.H ?? "").toLowerCase() === "true",
  };
}

/** Google Maps URL for a geo: payload, else null. */
export function geoToMapsUrl(payload: string): string | null {
  const m = /^geo:\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)/i.exec(payload.trim());
  if (!m) return null;
  const lat = Number(m[1]);
  const lng = Number(m[2]);
  if (Math.abs(lat) > 90 || Math.abs(lng) > 180) return null;
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lng}`;
}

export interface Email { to: string; subject: string; body: string; href: string }

export function parseEmail(payload: string): Email | null {
  const m = /^mailto:([^?\s]+)(?:\?(.*))?$/i.exec(payload.trim());
  if (!m) return null;
  const to = decodeURIComponent(m[1]);
  if (!/^[^@\s<>"]+@[^@\s<>"]+\.[^@\s<>"]+$/.test(to)) return null;
  const q = new URLSearchParams(m[2] ?? "");
  const subject = q.get("subject") ?? "";
  const body = q.get("body") ?? "";
  const params: string[] = [];
  if (subject) params.push(`subject=${encodeURIComponent(subject)}`);
  if (body) params.push(`body=${encodeURIComponent(body)}`);
  return { to, subject, body, href: `mailto:${encodeURIComponent(to).replace("%40", "@")}${params.length ? `?${params.join("&")}` : ""}` };
}

// ---------------------------------------------------------------------------
// Downloads
// ---------------------------------------------------------------------------

function crlf(s: string): string {
  return s.replace(/\r\n/g, "\n").replace(/\n/g, "\r\n");
}

export function vcfFile(payload: string): string {
  return crlf(payload.trim()) + "\r\n";
}

/** The stored VCALENDAR, completed with the fields calendar apps require (PRODID, UID, DTSTAMP). */
export function icsFile(payload: string, slug: string, now: Date): string {
  let s = payload.trim().replace(/\r\n/g, "\n");
  if (!/^BEGIN:VCALENDAR/m.test(s)) s = `BEGIN:VCALENDAR\nVERSION:2.0\n${s}\nEND:VCALENDAR`;
  if (!/^PRODID:/m.test(s)) s = s.replace(/^VERSION:2\.0$/m, "VERSION:2.0\nPRODID:-//QRaft//scanqraft.app//ES");
  const stamp = now.toISOString().replace(/[-:]/g, "").replace(/\.\d{3}/, "");
  if (!/^UID:/m.test(s)) s = s.replace(/^BEGIN:VEVENT$/m, `BEGIN:VEVENT\nUID:${slug}@scanqraft.app`);
  if (!/^DTSTAMP:/m.test(s)) s = s.replace(/^BEGIN:VEVENT$/m, `BEGIN:VEVENT\nDTSTAMP:${stamp}`);
  return crlf(s) + "\r\n";
}

// ---------------------------------------------------------------------------
// Native handoff: platform + deep links (pure builders, unit-tested)
// ---------------------------------------------------------------------------

export type Platform = "ios" | "android" | "other";

export function detectPlatform(ua: string | null): Platform {
  const u = ua ?? "";
  if (/android/i.test(u)) return "android";
  if (/iphone|ipad|ipod/i.test(u) || (/macintosh/i.test(u) && /mobile/i.test(u))) return "ios";
  return "other";
}

export const PLAY_URL = "https://play.google.com/store/apps/details?id=io.gothcorp.qraft&referrer=utm_source%3Dscanqraft%26utm_medium%3Dwifi";
export const PUBLIC_ORIGIN = "https://scanqraft.app";

/** Apple Maps (opens the Maps app on iOS) for a geo: payload. */
export function appleMapsUrl(payload: string): string | null {
  const m = /^geo:\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)/i.exec(payload.trim());
  if (!m || !geoToMapsUrl(payload)) return null;
  return `https://maps.apple.com/?ll=${Number(m[1])},${Number(m[2])}&q=${Number(m[1])},${Number(m[2])}`;
}

const pad = (n: number) => String(n).padStart(2, "0");
function ymd(d: Date): string {
  return `${d.getUTCFullYear()}${pad(d.getUTCMonth() + 1)}${pad(d.getUTCDate())}`;
}
function ymdhms(d: Date): string {
  return `${ymd(d)}T${pad(d.getUTCHours())}${pad(d.getUTCMinutes())}${pad(d.getUTCSeconds())}`;
}

/** Event end: DTEND, else +1 day (all-day) or +1 hour. */
export function eventEnd(ev: CalEvent): CalTime | null {
  if (!ev.start) return null;
  if (ev.end && ev.end.date > ev.start.date) return ev.end;
  const ms = ev.start.allDay ? 86_400_000 : 3_600_000;
  return { ...ev.start, date: new Date(ev.start.date.getTime() + ms) };
}

/** Offset (ms) of [tz] at [wallClockUtc] (a wall-clock time stored as UTC), via Intl. */
function tzOffsetMs(tz: string, wallClockUtc: Date): number | null {
  try {
    const f = new Intl.DateTimeFormat("en-US", {
      timeZone: tz, hourCycle: "h23", year: "numeric", month: "2-digit", day: "2-digit", hour: "2-digit", minute: "2-digit", second: "2-digit",
    });
    const parts = Object.fromEntries(f.formatToParts(wallClockUtc).map((p) => [p.type, p.value]));
    const asUtc = Date.UTC(+parts.year, +parts.month - 1, +parts.day, +parts.hour, +parts.minute, +parts.second);
    return asUtc - wallClockUtc.getTime();
  } catch {
    return null;
  }
}

/** Absolute epoch ms of a CalTime; null for floating times (only the device knows its zone). */
export function absoluteMs(t: CalTime): number | null {
  if (t.allDay) return t.date.getTime();
  if (!t.floating) return t.date.getTime();
  if (t.tzid) {
    const off = tzOffsetMs(t.tzid, t.date);
    return off === null ? null : t.date.getTime() - off;
  }
  return null;
}

/** Google Calendar "create event" link, pre-filled. */
export function googleCalendarUrl(ev: CalEvent): string | null {
  if (!ev.start) return null;
  const end = eventEnd(ev)!;
  let dates: string;
  let ctz = "";
  if (ev.start.allDay) {
    dates = `${ymd(ev.start.date)}/${ymd(end.date)}`;
  } else if (!ev.start.floating) {
    dates = `${ymdhms(ev.start.date)}Z/${ymdhms(end.date)}Z`;
  } else {
    dates = `${ymdhms(ev.start.date)}/${ymdhms(end.date)}`;
    if (ev.start.tzid) ctz = `&ctz=${encodeURIComponent(ev.start.tzid)}`;
  }
  const q = [`action=TEMPLATE`, `text=${encodeURIComponent(ev.title)}`, `dates=${dates}`];
  if (ev.location) q.push(`location=${encodeURIComponent(ev.location)}`);
  if (ev.description) q.push(`details=${encodeURIComponent(ev.description)}`);
  return `https://calendar.google.com/calendar/render?${q.join("&")}${ctz}`;
}

function extra(kind: "S" | "l" | "B", key: string, value: string | number | boolean): string {
  return `${kind}.${key}=${encodeURIComponent(String(value))};`;
}

/**
 * Android "new event" screen of the default calendar app. Floating times carry their
 * wall-clock in data-* attributes; the page script recomputes beginTime/endTime on the device.
 */
export function androidEventIntent(ev: CalEvent, fallback: string): string | null {
  if (!ev.start) return null;
  const end = eventEnd(ev)!;
  const b = absoluteMs(ev.start) ?? ev.start.date.getTime();
  const e = absoluteMs(end) ?? end.date.getTime();
  let x = "action=android.intent.action.INSERT;type=vnd.android.cursor.dir/event;";
  if (ev.title) x += extra("S", "title", ev.title);
  if (ev.location) x += extra("S", "eventLocation", ev.location);
  if (ev.description) x += extra("S", "description", ev.description);
  x += extra("l", "beginTime", b) + extra("l", "endTime", e);
  if (ev.start.allDay) x += extra("B", "allDay", true);
  x += extra("S", "browser_fallback_url", fallback);
  return `intent:#Intent;${x}end`;
}

/** Android "new contact" screen, pre-filled (ContactsContract.Intents.Insert keys). */
export function androidContactIntent(c: VCard, fallback: string): string {
  let x = "action=android.intent.action.INSERT;type=vnd.android.cursor.dir/raw_contact;";
  if (c.name) x += extra("S", "name", c.name);
  const phones = ["phone", "secondary_phone", "tertiary_phone"];
  c.phones.slice(0, 3).forEach((v, i) => { x += extra("S", phones[i]!, v); });
  const emails = ["email", "secondary_email", "tertiary_email"];
  c.emails.slice(0, 3).forEach((v, i) => { x += extra("S", emails[i]!, v); });
  if (c.org) x += extra("S", "company", c.org);
  if (c.title) x += extra("S", "job_title", c.title);
  if (c.address) x += extra("S", "postal", c.address);
  if (c.note) x += extra("S", "notes", c.note);
  x += extra("S", "browser_fallback_url", fallback);
  return `intent:#Intent;${x}end`;
}

/** Opens the QRaft app's WiFi join screen; without the app, Chrome goes to Google Play. */
export function wifiAppIntent(w: Wifi, playUrl = PLAY_URL): string {
  const q = new URLSearchParams({ ssid: w.ssid, pw: w.password, sec: w.security || "WPA", hidden: String(w.hidden) });
  return `intent://wifi?${q.toString()}#Intent;scheme=qraft;package=io.gothcorp.qraft;${extra("S", "browser_fallback_url", playUrl)}end`;
}

export const WIFI_SETTINGS_INTENT = "intent:#Intent;action=android.settings.WIFI_SETTINGS;end";

// ---------------------------------------------------------------------------
// Pages
// ---------------------------------------------------------------------------

const T = {
  es: {
    madeWith: "Hecho con QRaft", createOwn: "crea el tuyo gratis", report: "Reportar este código",
    privacy: "Escaneos anónimos", privacyLink: "Privacidad",
    copy: "Copiar", copied: "Copiado", copiedToast: "Copiado al portapapeles",
    message: "Mensaje", copyText: "Copiar texto",
    contact: "Contacto", saveContacts: "Guardar en Contactos", saveContactsNote: "Abre Contactos con todo lleno",
    saveContact: "Guardar contacto", call: "Llamar", write: "Escribir", phone: "Teléfono", email: "Email", website: "Sitio web", address: "Dirección",
    event: "Evento", addCalendar: "Agregar al calendario", addCalendarNote: "Abre tu calendario con el evento listo",
    googleCalendar: "Agregar a Google Calendar", downloadIcs: "Descargar evento (.ics)",
    directions: "Cómo llegar", when: "Cuándo", where: "Dónde", allDay: "todo el día",
    wifi: "Red WiFi", wifiTitle: "Conéctate al WiFi", network: "Red", password: "Contraseña", noPassword: "Red abierta, sin contraseña",
    connect: "Conectar con un toque", connectNote: "Abre la app QRaft · si no la tienes, te lleva a Google Play",
    wifiSettings: "Abrir ajustes de WiFi", copyPassword: "Copiar contraseña",
    wifiNoApp: "Sin la app: copia la contraseña, abre ajustes, elige la red y pégala.",
    iosStep1: "Abre <b>Ajustes → Wi-Fi</b>", iosStep2: "Toca la red <b>%s</b>", iosStep3: "Mantén pulsado el campo y elige <b>Pegar</b>",
    otherWifi: "Abre los ajustes de WiFi de tu dispositivo, elige la red y pega la contraseña.",
    mail: "Correo", writeTo: "Escribir a %s", to: "Para", subject: "Asunto", openMail: "Abrir en mi correo", openMailNote: "Si no se abrió solo, toca aquí o copia los datos",
    pausedTitle: "Este código está pausado", pausedBody: "Su dueño lo pausó por un momento. Vuelve a escanearlo más tarde.",
    pendingTitle: "Este código aún no está activo", pendingBody: "Se activará en cuanto se confirme el pago. Vuelve a escanearlo más tarde.",
    missingTitle: "Este código no existe", missingBody: "Puede que esté mal impreso o que nunca se haya creado. Pide un código nuevo a quien te lo dio.",
    goneTitle: "Este código ya no está disponible", goneBody: "Su dueño lo eliminó. Pide un código nuevo a quien te lo dio.",
    blockedTitle: "Código bloqueado", blockedBody: "Bloqueamos este código porque recibimos reportes de que su contenido podría ser dañino.",
    errorTitle: "Algo salió mal", errorBody: "No pudimos abrir este código. Inténtalo de nuevo en unos segundos.",
    badTitle: "No pudimos mostrar este contenido", badBody: "El contenido de este código no es válido. Avísale a su dueño.",
  },
  en: {
    madeWith: "Made with QRaft", createOwn: "create yours for free", report: "Report this code",
    privacy: "Anonymous scans", privacyLink: "Privacy",
    copy: "Copy", copied: "Copied", copiedToast: "Copied to clipboard",
    message: "Message", copyText: "Copy text",
    contact: "Contact", saveContacts: "Save to Contacts", saveContactsNote: "Opens Contacts with everything filled in",
    saveContact: "Save contact", call: "Call", write: "Email", phone: "Phone", email: "Email", website: "Website", address: "Address",
    event: "Event", addCalendar: "Add to calendar", addCalendarNote: "Opens your calendar with the event ready",
    googleCalendar: "Add to Google Calendar", downloadIcs: "Download event (.ics)",
    directions: "Directions", when: "When", where: "Where", allDay: "all day",
    wifi: "WiFi network", wifiTitle: "Join the WiFi", network: "Network", password: "Password", noPassword: "Open network, no password",
    connect: "Connect in one tap", connectNote: "Opens the QRaft app · without it, takes you to Google Play",
    wifiSettings: "Open WiFi settings", copyPassword: "Copy password",
    wifiNoApp: "Without the app: copy the password, open settings, pick the network and paste it.",
    iosStep1: "Open <b>Settings → Wi-Fi</b>", iosStep2: "Tap the <b>%s</b> network", iosStep3: "Long-press the field and choose <b>Paste</b>",
    otherWifi: "Open your device's WiFi settings, pick the network and paste the password.",
    mail: "Email", writeTo: "Write to %s", to: "To", subject: "Subject", openMail: "Open in my email app", openMailNote: "If it didn't open by itself, tap here or copy the details",
    pausedTitle: "This code is paused", pausedBody: "Its owner paused it for a moment. Scan it again later.",
    pendingTitle: "This code isn't active yet", pendingBody: "It will turn on as soon as the payment is confirmed. Scan it again later.",
    missingTitle: "This code doesn't exist", missingBody: "It may be misprinted or was never created. Ask whoever gave it to you for a new one.",
    goneTitle: "This code is no longer available", goneBody: "Its owner deleted it. Ask whoever gave it to you for a new one.",
    blockedTitle: "Code blocked", blockedBody: "We blocked this code after reports that its content may be harmful.",
    errorTitle: "Something went wrong", errorBody: "We couldn't open this code. Try again in a few seconds.",
    badTitle: "We couldn't show this content", badBody: "This code's content isn't valid. Let its owner know.",
  },
} as const;

type Strings = { [K in keyof typeof T.es]: string };

const CSS = `:root{--bg:#F3F5F7;--card:#FFFFFF;--ink:#0B1220;--sub:#4B5563;--field:#F3F5F7;--line:#E2E6EA;--btn:#0B1220;--btn-ink:#FFFFFF;--pill:#E5E9ED;--pill-ink:#0B1220;--foot:#5B6470;--ok:#00A85A;--ok-ink:#FFFFFF;--toast:#0B1220;--toast-ink:#FFFFFF;color-scheme:light dark}
@media (prefers-color-scheme:dark){:root{--bg:#111315;--card:#1C1F22;--ink:#F2F5F8;--sub:#AEB6C0;--field:#26292D;--line:#33383D;--btn:#00FF88;--btn-ink:#04140D;--pill:#2E3337;--pill-ink:#F2F5F8;--foot:#9AA4B0;--ok:#00FF88;--ok-ink:#04140D;--toast:#F2F5F8;--toast-ink:#0B1220}}
*{box-sizing:border-box}html,body{height:100%}
body{margin:0;min-height:100vh;min-height:100dvh;display:flex;flex-direction:column;background:var(--bg);color:var(--ink);font-family:Inter,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-text-size-adjust:100%}
main{width:100%;max-width:480px;margin:0 auto;padding:20px 20px 24px}
.card{background:var(--card);border-radius:24px;padding:20px;display:flex;flex-direction:column;gap:14px;box-shadow:0 1px 3px rgba(11,18,32,.08)}
.center{align-items:center;text-align:center}
.chip{display:flex;align-items:center;gap:10px}.chip i{width:40px;height:40px;border-radius:12px;display:flex;align-items:center;justify-content:center;flex-shrink:0}
.chip span{font-size:13px;font-weight:700;letter-spacing:.04em;text-transform:uppercase;color:var(--sub)}
h1{margin:0;font-size:26px;line-height:1.2;font-weight:700;overflow-wrap:anywhere}
p{margin:0;font-size:14px;line-height:1.5;color:var(--sub);overflow-wrap:anywhere}p b,ol b{color:var(--ink)}
.text{white-space:pre-wrap;font-size:18px;line-height:1.55;color:var(--ink)}
.f{display:flex;align-items:center;gap:10px;padding:12px 12px 12px 16px;border-radius:16px;background:var(--field)}
.f div{flex:1;min-width:0;display:flex;flex-direction:column;gap:2px}.f small{font-size:12px;font-weight:600;color:var(--sub)}
.f strong{font-size:16px;font-weight:600;overflow-wrap:anywhere;white-space:pre-wrap}.f.big strong{font-size:20px;font-weight:700}
.mono{font-family:ui-monospace,SFMono-Regular,Menlo,Consolas,monospace;letter-spacing:.02em}
.cp{display:inline-flex;align-items:center;gap:6px;min-height:44px;padding:0 14px;border-radius:999px;border:0;background:var(--pill);color:var(--pill-ink);font-size:13px;font-weight:600;font-family:inherit;cursor:pointer;flex-shrink:0}
.cp.ok{background:var(--ok);color:var(--ok-ink)}
.btn{display:flex;align-items:center;justify-content:center;gap:10px;min-height:56px;padding:0 16px;border-radius:16px;border:0;background:var(--btn);color:var(--btn-ink);font-size:17px;font-weight:700;text-decoration:none;width:100%;font-family:inherit;cursor:pointer;text-align:center}
.btn2{display:flex;align-items:center;justify-content:center;gap:8px;min-height:52px;padding:0 14px;border-radius:14px;border:1px solid var(--line);background:var(--card);color:var(--ink);font-size:15px;font-weight:600;text-decoration:none;width:100%;font-family:inherit;cursor:pointer;text-align:center}
.note{font-size:12px;color:var(--sub);text-align:center;margin-top:-6px}
.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(120px,1fr));gap:8px}
.avatar{width:84px;height:84px;border-radius:42px;background:#D1FAE5;color:#065F46;font-size:28px;font-weight:700;display:flex;align-items:center;justify-content:center}
.icon{width:64px;height:64px;border-radius:32px;background:var(--pill);display:flex;align-items:center;justify-content:center;color:var(--ink)}
ol{margin:0;padding-left:20px;display:flex;flex-direction:column;gap:6px;font-size:14px;line-height:1.5;color:var(--sub)}
footer{margin-top:auto;width:100%;border-top:1px solid var(--line);padding:16px 20px calc(24px + env(safe-area-inset-bottom));display:flex;flex-direction:column;align-items:center;gap:6px;text-align:center}
footer .brand{display:inline-flex;align-items:center;gap:8px;min-height:44px;color:var(--ink);text-decoration:none;font-size:14px;font-weight:600}
footer .brand u{font-weight:600}.mark{width:22px;height:22px;border-radius:6px;background:#0B1220;border:1px solid #00FF88;display:inline-flex;align-items:center;justify-content:center}.mark:after{content:"";width:8px;height:8px;border-radius:2px;background:#00FF88}
footer .links{display:flex;flex-wrap:wrap;justify-content:center;gap:4px 14px;font-size:12px;color:var(--foot)}footer .links a{color:var(--foot);min-height:32px;display:inline-flex;align-items:center}
#toast{position:fixed;left:50%;bottom:calc(110px + env(safe-area-inset-bottom));transform:translateX(-50%);padding:10px 16px;border-radius:999px;background:var(--toast);color:var(--toast-ink);font-size:14px;font-weight:600;box-shadow:0 6px 20px rgba(0,0,0,.18);opacity:0;transition:opacity .2s;pointer-events:none}
#toast.on{opacity:1}
@media (prefers-reduced-motion:reduce){#toast{transition:none}}`;

const P = {
  copy: '<path d="M9 9h10v10H9zM5 15V5h10"/>',
  wifi: '<path d="M5 12.5a10 10 0 0 1 14 0M8.5 16a5 5 0 0 1 7 0M12 19.5h.01M2 9a15 15 0 0 1 20 0"/>',
  user: '<path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM4 21a8 8 0 0 1 16 0"/>',
  cal: '<path d="M7 3v3M17 3v3M4 8h16M5 5h14v15H5z"/>',
  mail: '<path d="M4 6h16v12H4zM4 7l8 6 8-6"/>',
  text: '<path d="M4 6h16M4 12h16M4 18h10"/>',
  phone: '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L15 13l5 2v4a2 2 0 0 1-2 2A16 16 0 0 1 3 6a2 2 0 0 1 2-2"/>',
  gear: '<path d="M12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z"/><path d="M19 12a7 7 0 0 0-.1-1.2l2-1.6-2-3.4-2.4 1a7 7 0 0 0-2-1.2L14 3h-4l-.5 2.6a7 7 0 0 0-2 1.2l-2.4-1-2 3.4 2 1.6a7 7 0 0 0 0 2.4l-2 1.6 2 3.4 2.4-1a7 7 0 0 0 2 1.2L10 21h4l.5-2.6a7 7 0 0 0 2-1.2l2.4 1 2-3.4-2-1.6c.1-.4.1-.8.1-1.2z"/>',
  map: '<path d="M12 21s-7-6.2-7-11.5A7 7 0 0 1 19 9.5C19 14.8 12 21 12 21z"/>',
  web: '<path d="M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18"/>',
  pause: '<path d="M9 6v12M15 6v12"/>',
  search: '<path d="M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4"/>',
  clock: '<path d="M12 7v5l3 2M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z"/>',
  alert: '<path d="M12 8v5M12 16h.01M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z"/>',
} as const;
type IconName = keyof typeof P;

function icon(name: IconName, size = 20, color = "currentColor"): string {
  return `<svg aria-hidden="true" width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="${color}" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${P[name]}</svg>`;
}

const e = escapeHtml;

class Ids { private n = 0; next(): string { return `v${++this.n}`; } }

function chip(name: IconName, color: string, label: string): string {
  return `<div class="chip"><i style="background:${color}">${icon(name, 20, "#fff")}</i><span>${e(label)}</span></div>`;
}

/** A labelled value with its own Copy button. */
function field(ids: Ids, s: Strings, label: string, value: string, opts: { big?: boolean; mono?: boolean } = {}): string {
  const id = ids.next();
  return `<div class="f${opts.big ? " big" : ""}"><div><small>${e(label)}</small><strong id="${id}"${opts.mono ? ' class="mono"' : ""}>${e(value)}</strong></div><button class="cp" type="button" data-copy="${id}" aria-label="${e(`${s.copy} ${label}`)}">${icon("copy", 16)}<span>${e(s.copy)}</span></button></div>`;
}

function btn(href: string, label: string, ic?: IconName, attrs = ""): string {
  return `<a class="btn" href="${e(href)}"${attrs}>${ic ? icon(ic, 20) : ""}${e(label)}</a>`;
}
function btn2(href: string, label: string, ic?: IconName, attrs = ""): string {
  return `<a class="btn2" href="${e(href)}"${attrs}>${ic ? icon(ic, 18) : ""}${e(label)}</a>`;
}
const note = (t: string) => `<p class="note">${e(t)}</p>`;

interface PageOpts { autoOpen?: string; floating?: boolean }

function page(lang: Lang, slug: string, title: string, inner: string, nonce: string, opts: PageOpts = {}): string {
  const s: Strings = T[lang];
  const report = `mailto:support@scanqraft.app?subject=${encodeURIComponent(`${lang === "es" ? "Reporte" : "Report"} scanqraft.app/${slug}`)}`;
  const site = lang === "es" ? "https://www.scanqraft.app/es" : "https://www.scanqraft.app";
  // Copy buttons + toast; optional one-shot auto-open (mailto); floating event times → device-local epoch.
  const js = `(function(){var t=document.getElementById('toast');function done(b){var l=b.querySelector('span');var o=l.textContent;b.classList.add('ok');l.textContent=${JSON.stringify(s.copied)};t.textContent=${JSON.stringify(s.copiedToast)};t.classList.add('on');setTimeout(function(){b.classList.remove('ok');l.textContent=o;t.classList.remove('on')},1800)}
function fallback(v){var a=document.createElement('textarea');a.value=v;a.setAttribute('readonly','');a.style.position='fixed';a.style.opacity='0';document.body.appendChild(a);a.select();try{document.execCommand('copy')}catch(e){}document.body.removeChild(a)}
document.querySelectorAll('[data-copy]').forEach(function(b){b.addEventListener('click',function(){var v=document.getElementById(b.getAttribute('data-copy')).textContent;if(navigator.clipboard&&window.isSecureContext){navigator.clipboard.writeText(v).then(function(){done(b)},function(){fallback(v);done(b)})}else{fallback(v);done(b)}})});
document.querySelectorAll('[data-fl]').forEach(function(a){var p=a.getAttribute('data-fl').split(',').map(Number);var b=new Date(p[0],p[1],p[2],p[3],p[4]).getTime();var e=new Date(p[5],p[6],p[7],p[8],p[9]).getTime();a.setAttribute('href',a.getAttribute('href').replace(/l\\.beginTime=\\d+/,'l.beginTime='+b).replace(/l\\.endTime=\\d+/,'l.endTime='+e))});
${opts.autoOpen ? `try{if(!sessionStorage.getItem('qa${slug}')){sessionStorage.setItem('qa${slug}','1');location.href=${JSON.stringify(opts.autoOpen)}}}catch(e){}` : ""}})();`;
  return `<!doctype html><html lang="${lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><meta name="robots" content="noindex,nofollow"><meta name="color-scheme" content="light dark"><meta name="theme-color" content="#F3F5F7" media="(prefers-color-scheme: light)"><meta name="theme-color" content="#111315" media="(prefers-color-scheme: dark)"><title>${e(title)} · QRaft</title><style>${CSS}</style></head><body><main>${inner}</main><footer><a class="brand" href="${site}"><span class="mark" aria-hidden="true"></span>${e(s.madeWith)} · <u>${e(s.createOwn)}</u></a><div class="links"><a href="${e(report)}">${e(s.report)}</a><span aria-hidden="true">·</span><span>${e(s.privacy)} · <a href="${site}/privacy">${e(s.privacyLink)}</a></span></div></footer><div id="toast" role="status" aria-live="polite"></div><script nonce="${nonce}">${js}</script></body></html>`;
}

function statePage(lang: Lang, slug: string, ic: IconName, title: string, body: string, nonce: string): string {
  return page(lang, slug, title, `<article class="card center" style="padding:28px 20px"><div class="icon">${icon(ic, 28)}</div><h1>${e(title)}</h1><p>${e(body)}</p></article>`, nonce);
}

function formatWhen(ev: CalEvent, lang: Lang, s: Strings): string {
  if (!ev.start) return "";
  const locale = lang === "es" ? "es-CO" : "en-US";
  const date = ev.start.date.toLocaleDateString(locale, { weekday: "short", day: "numeric", month: "short", year: "numeric", timeZone: "UTC" });
  if (ev.start.allDay) return `${date} · ${s.allDay}`;
  const opts: Intl.DateTimeFormatOptions = { hour: "numeric", minute: "2-digit", timeZone: "UTC" };
  if (!ev.start.floating) opts.timeZoneName = "short";
  const end = ev.end && ev.end.date > ev.start.date && ymd(ev.end.date) === ymd(ev.start.date)
    ? ` – ${ev.end.date.toLocaleTimeString(locale, { hour: "numeric", minute: "2-digit", timeZone: "UTC" })}`
    : "";
  return `${date} · ${ev.start.date.toLocaleTimeString(locale, opts)}${end}`;
}

function floatAttr(ev: CalEvent): string {
  if (!ev.start || ev.start.allDay || !ev.start.floating || ev.start.tzid) return "";
  const end = eventEnd(ev)!;
  const parts = (d: Date) => [d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate(), d.getUTCHours(), d.getUTCMinutes()];
  return ` data-fl="${[...parts(ev.start.date), ...parts(end.date)].join(",")}"`;
}

const mapsSearch = (q: string, platform: Platform) =>
  platform === "ios" ? `https://maps.apple.com/?q=${encodeURIComponent(q)}` : `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(q)}`;

/** HTML for an active type shown as a page, or null when the payload can't be shown. */
export function contentPage(row: RedirectRow, lang: Lang, nonce: string, now: Date, platform: Platform = "other"): string | null {
  const s: Strings = T[lang];
  const payload = row.content?.payload ?? "";
  const ids = new Ids();
  const self = `${PUBLIC_ORIGIN}/${row.slug}`;
  void now;
  switch (row.content_type) {
    case "text": {
      if (!payload.trim()) return null;
      const id = ids.next();
      return page(lang, row.slug, s.message, `<article class="card">${chip("text", "#64748B", s.message)}<p class="text" id="${id}">${e(payload)}</p><button class="btn" type="button" data-copy="${id}">${icon("copy", 20)}<span>${e(s.copyText)}</span></button></article>`, nonce);
    }
    case "vcard": {
      const c = parseVCard(payload);
      if (!c.name && !c.phones.length && !c.emails.length) return null;
      const initials = c.name.split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0]!.toUpperCase()).join("");
      const sub = [c.title, c.org].filter(Boolean).join(" · ");
      const save = platform === "android"
        ? `${btn(androidContactIntent(c, `${self}?dl=vcf`), s.saveContacts, "user")}${note(s.saveContactsNote)}`
        : btn(`?dl=vcf`, s.saveContact, "user");
      const quick: string[] = [];
      if (c.phones[0]) quick.push(btn2(`tel:${c.phones[0].replace(/[^\d+]/g, "")}`, s.call, "phone"));
      if (c.emails[0]) quick.push(btn2(`mailto:${c.emails[0]}`, s.write, "mail"));
      if (c.url) quick.push(btn2(c.url, s.website, "web", ' rel="noopener nofollow"'));
      const details = [
        ...c.phones.map((v) => field(ids, s, s.phone, v)),
        ...c.emails.map((v) => field(ids, s, s.email, v)),
        c.address ? field(ids, s, s.address, c.address) : "",
      ].join("");
      return page(lang, row.slug, c.name || s.contact, `<article class="card"><div class="center" style="display:flex;flex-direction:column;align-items:center;gap:8px"><div class="avatar" aria-hidden="true">${e(initials || "?")}</div><h1>${e(c.name)}</h1>${sub ? `<p>${e(sub)}</p>` : ""}</div>${save}${quick.length ? `<div class="grid">${quick.join("")}</div>` : ""}${details}${c.note ? `<p>${e(c.note)}</p>` : ""}</article>`, nonce);
    }
    case "vevent": {
      const ev = parseEvent(payload);
      if (!ev.title && !ev.start) return null;
      const when = formatWhen(ev, lang, s);
      const gcal = googleCalendarUrl(ev);
      let add = "";
      if (platform === "android" && ev.start) {
        add = `${btn(androidEventIntent(ev, gcal ?? `${self}?dl=ics`)!, s.addCalendar, "cal", floatAttr(ev))}${note(s.addCalendarNote)}`;
      } else if (platform === "ios") {
        add = btn(`?dl=ics`, s.addCalendar, "cal");
      } else {
        add = `${gcal ? btn(gcal, s.googleCalendar, "cal", ' rel="noopener"') : ""}${btn2(`?dl=ics`, s.downloadIcs, "cal")}`;
      }
      return page(lang, row.slug, ev.title || s.event, `<article class="card">${chip("cal", "#0891B2", s.event)}<h1>${e(ev.title)}</h1>${when ? field(ids, s, s.when, when) : ""}${ev.location ? field(ids, s, s.where, ev.location) : ""}${add}${ev.location ? btn2(mapsSearch(ev.location, platform), s.directions, "map", ' rel="noopener"') : ""}${ev.description ? `<p>${e(ev.description)}</p>` : ""}</article>`, nonce);
    }
    case "wifi": {
      const w = parseWifi(payload);
      if (!w.ssid) return null;
      const open = !w.password || w.security.toLowerCase() === "nopass";
      const net = field(ids, s, s.network, w.ssid, { big: true }); // v1
      const pw = open ? `<div class="f"><div><strong style="font-size:15px;font-weight:500">${e(s.noPassword)}</strong></div></div>` : field(ids, s, s.password, w.password, { big: true, mono: true });
      let actions: string;
      if (platform === "android") {
        actions = `${btn(wifiAppIntent(w), s.connect, "wifi")}${note(s.connectNote)}${btn2(WIFI_SETTINGS_INTENT, s.wifiSettings, "gear")}${open ? "" : `<p>${e(s.wifiNoApp)}</p>`}`;
      } else if (platform === "ios") {
        const pwId = open ? "" : `<button class="btn" type="button" data-copy="v2">${icon("copy", 20)}<span>${e(s.copyPassword)}</span></button>`;
        actions = `${pwId}<ol><li>${s.iosStep1}</li><li>${s.iosStep2.replace("%s", e(w.ssid))}</li>${open ? "" : `<li>${s.iosStep3}</li>`}</ol>`;
      } else {
        actions = `<p>${e(s.otherWifi)}</p>`;
      }
      return page(lang, row.slug, s.wifiTitle, `<article class="card">${chip("wifi", "#7C3AED", s.wifi)}<h1>${e(s.wifiTitle)}</h1>${net}${pw}${actions}</article>`, nonce);
    }
    case "email": {
      const m = parseEmail(payload);
      if (!m) return null;
      const title = s.writeTo.replace("%s", m.to);
      return page(lang, row.slug, title, `<article class="card">${chip("mail", "#D97706", s.mail)}<h1>${e(title)}</h1>${field(ids, s, s.to, m.to)}${m.subject ? field(ids, s, s.subject, m.subject) : ""}${m.body ? field(ids, s, s.message, m.body) : ""}${btn(m.href, s.openMail, "mail")}${note(s.openMailNote)}</article>`, nonce, { autoOpen: platform === "other" ? undefined : m.href });
    }
    default:
      return null;
  }
}

function html(status: number, body: string, nonce: string, extra: Record<string, string> = {}): Outcome {
  return {
    status,
    headers: {
      ...BASE_HEADERS,
      Vary: "User-Agent, Accept-Language",
      "Content-Type": "text/html; charset=utf-8",
      "Content-Security-Policy": `default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}'; img-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`,
      ...extra,
    },
    body,
    countScan: false,
  };
}

function redirect(location: string, countScan: boolean): Outcome {
  return { status: 302, headers: { ...BASE_HEADERS, Vary: "User-Agent", Location: location }, body: null, countScan };
}

function file(type: string, name: string, body: string, inline: boolean, countScan: boolean): Outcome {
  return {
    status: 200,
    headers: { ...BASE_HEADERS, Vary: "User-Agent", "Content-Type": `${type}; charset=utf-8`, "Content-Disposition": `${inline ? "inline" : "attachment"}; filename="${name}"` },
    body,
    countScan,
  };
}

/**
 * The whole public decision: status code, headers and body for a slug lookup.
 * [row] null = no such slug. [dl] = ?dl= value. [view] "page" forces the HTML page.
 * Native-first: iPhone gets contact/event files Safari opens as system sheets and Apple Maps;
 * Android gets pages whose main button opens the system app (intent:).
 */
export function respond(
  slug: string,
  row: RedirectRow | null,
  opts: { lang: Lang; dl: string | null; nonce: string; now: Date; platform?: Platform; view?: string | null },
): Outcome {
  const { lang, dl, nonce, now } = opts;
  const platform = opts.platform ?? "other";
  const forcePage = opts.view === "page";
  const s: Strings = T[lang];
  if (!row) return html(404, statePage(lang, slug, "search", s.missingTitle, s.missingBody, nonce), nonce);

  switch (row.status) {
    case "revoked": return html(410, statePage(lang, slug, "search", s.goneTitle, s.goneBody, nonce), nonce);
    case "blocked": return html(451, statePage(lang, slug, "alert", s.blockedTitle, s.blockedBody, nonce), nonce);
    case "paused": return html(200, statePage(lang, slug, "pause", s.pausedTitle, s.pausedBody, nonce), nonce);
    case "pending_payment": return html(200, statePage(lang, slug, "clock", s.pendingTitle, s.pendingBody, nonce), nonce);
  }

  const payload = row.content?.payload ?? "";
  const bad = () => html(422, statePage(lang, slug, "alert", s.badTitle, s.badBody, nonce), nonce);
  const ios = platform === "ios";

  // Explicit downloads (buttons on the page): never counted again.
  if (dl === "vcf" && row.content_type === "vcard" && payload) return file("text/vcard", `${slug}.vcf`, vcfFile(payload), ios, false);
  if (dl === "ics" && row.content_type === "vevent" && payload) return file("text/calendar", `${slug}.ics`, icsFile(payload, slug, now), ios, false);

  switch (row.content_type) {
    case "url": {
      const url = safeHttpUrl(payload);
      return url ? redirect(url, true) : bad();
    }
    case "geo": {
      const url = ios ? appleMapsUrl(payload) : geoToMapsUrl(payload);
      return url ? redirect(url, true) : bad();
    }
  }

  // iPhone: Safari shows the native "Create contact" / "Add to calendar" sheet for these.
  if (ios && !forcePage) {
    if (row.content_type === "vcard" && payload && parseVCard(payload).name) return file("text/vcard", `${slug}.vcf`, vcfFile(payload), true, true);
    if (row.content_type === "vevent" && payload && parseEvent(payload).start) return file("text/calendar", `${slug}.ics`, icsFile(payload, slug, now), true, true);
  }

  const body = contentPage(row, lang, nonce, now, platform);
  if (!body) return bad();
  const out = html(200, body, nonce);
  out.countScan = true;
  return out;
}

export function errorOutcome(lang: Lang, slug: string, nonce: string): Outcome {
  const s: Strings = T[lang];
  return html(503, statePage(lang, slug, "alert", s.errorTitle, s.errorBody, nonce), nonce, { "Retry-After": "30" });
}
