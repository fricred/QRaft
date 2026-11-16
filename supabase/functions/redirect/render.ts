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

export interface CalEvent {
  title: string;
  start: { date: Date; allDay: boolean; floating: boolean } | null;
  location: string;
  description: string;
}

function parseIcsDate(value: string, params: string): CalEvent["start"] {
  const m = /^(\d{4})(\d{2})(\d{2})(?:T(\d{2})(\d{2})(\d{2})?(Z)?)?$/.exec(value.trim());
  if (!m) return null;
  const [, y, mo, d, h, mi, s, z] = m;
  const allDay = !h || /VALUE=DATE(?!-)/i.test(params);
  const parts = [Number(y), Number(mo) - 1, Number(d), Number(h ?? 0), Number(mi ?? 0), Number(s ?? 0)] as const;
  // Floating / TZID times are shown as written (wall-clock), so build them in UTC and format in UTC.
  const date = new Date(Date.UTC(...parts));
  return { date, allDay, floating: !z };
}

export function parseEvent(payload: string): CalEvent {
  const ev: CalEvent = { title: "", start: null, location: "", description: "" };
  for (const l of contentLines(payload)) {
    switch (l.name) {
      case "SUMMARY": ev.title = unescapeText(l.value).trim(); break;
      case "DTSTART": ev.start = parseIcsDate(l.value, l.params); break;
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
// Pages
// ---------------------------------------------------------------------------

const T = {
  es: {
    madeWith: "Creado con", createOwn: "Crea tu propio QR gratis", report: "Reportar este código",
    privacy: "QRaft cuenta los escaneos de forma anónima.", privacyLink: "Privacidad",
    message: "Mensaje", copyText: "Copiar texto", copied: "Copiado",
    saveContact: "Guardar contacto", call: "Llamar", phone: "Teléfono", email: "Email", website: "Sitio web",
    addCalendar: "Agregar al calendario", directions: "Cómo llegar", when: "Cuándo", where: "Dónde", allDay: "todo el día",
    wifiTitle: "Conéctate al WiFi", network: "Red", password: "Contraseña", noPassword: "Red abierta, sin contraseña",
    copyPassword: "Copiar contraseña",
    wifiHelp: "Abre los ajustes de WiFi de tu teléfono, elige la red y pega la contraseña.",
    writeEmail: "Escribir email", to: "Para", subject: "Asunto",
    pausedTitle: "Este código está pausado", pausedBody: "Su dueño lo pausó por ahora. Vuelve a escanearlo más tarde.",
    pendingTitle: "Este código aún no está activo", pendingBody: "Se activará en cuanto se confirme el pago. Vuelve a escanearlo más tarde.",
    missingTitle: "Este código no existe", missingBody: "Puede que esté mal impreso o que nunca se haya creado. Pide un código nuevo a quien te lo dio.",
    goneTitle: "Este código ya no está disponible", goneBody: "Su dueño lo eliminó. Pide un código nuevo a quien te lo dio.",
    blockedTitle: "Código bloqueado", blockedBody: "Bloqueamos este código porque recibimos reportes de que su contenido podría ser dañino.",
    errorTitle: "Algo salió mal", errorBody: "No pudimos abrir este código. Inténtalo de nuevo en unos segundos.",
    badTitle: "No pudimos mostrar este contenido", badBody: "El contenido de este código no es válido. Avísale a su dueño.",
  },
  en: {
    madeWith: "Made with", createOwn: "Create your own QR for free", report: "Report this code",
    privacy: "QRaft counts scans anonymously.", privacyLink: "Privacy",
    message: "Message", copyText: "Copy text", copied: "Copied",
    saveContact: "Save contact", call: "Call", phone: "Phone", email: "Email", website: "Website",
    addCalendar: "Add to calendar", directions: "Directions", when: "When", where: "Where", allDay: "all day",
    wifiTitle: "Join the WiFi", network: "Network", password: "Password", noPassword: "Open network, no password",
    copyPassword: "Copy password",
    wifiHelp: "Open your phone's WiFi settings, pick the network and paste the password.",
    writeEmail: "Write email", to: "To", subject: "Subject",
    pausedTitle: "This code is paused", pausedBody: "Its owner paused it for now. Scan it again later.",
    pendingTitle: "This code isn't active yet", pendingBody: "It will turn on as soon as the payment is confirmed. Scan it again later.",
    missingTitle: "This code doesn't exist", missingBody: "It may be misprinted or was never created. Ask whoever gave it to you for a new one.",
    goneTitle: "This code is no longer available", goneBody: "Its owner deleted it. Ask whoever gave it to you for a new one.",
    blockedTitle: "Code blocked", blockedBody: "We blocked this code after reports that its content may be harmful.",
    errorTitle: "Something went wrong", errorBody: "We couldn't open this code. Try again in a few seconds.",
    badTitle: "We couldn't show this content", badBody: "This code's content isn't valid. Let its owner know.",
  },
} as const;

type Strings = { [K in keyof typeof T.es]: string };

const CSS = `*{box-sizing:border-box}body{margin:0;background:#F4F6F8;color:#0B1220;font-family:Inter,system-ui,-apple-system,"Segoe UI",Roboto,sans-serif;-webkit-text-size-adjust:100%}
main{max-width:480px;margin:0 auto;padding:28px 20px 8px}
.card{background:#fff;border-radius:24px;padding:24px;display:flex;flex-direction:column;gap:14px;box-shadow:0 1px 3px rgba(11,18,32,.08)}
.center{align-items:center;text-align:center}
h1{margin:0;font-size:26px;line-height:1.2;font-weight:700;overflow-wrap:anywhere}
p{margin:0;font-size:16px;line-height:1.55;color:#1F2937;overflow-wrap:anywhere}
.muted{color:#4B5563;font-size:14px}.label{font-size:13px;font-weight:600;color:#4B5563}
.text{white-space:pre-wrap;font-size:17px}
.btn{display:flex;align-items:center;justify-content:center;min-height:56px;border-radius:16px;background:#0B1220;color:#fff;font-size:17px;font-weight:700;text-decoration:none;border:0;width:100%;font-family:inherit;cursor:pointer}
.btn2{display:flex;align-items:center;justify-content:center;min-height:52px;border-radius:14px;border:1px solid #9CA3AF;background:#fff;color:#0B1220;font-size:15px;font-weight:600;text-decoration:none;font-family:inherit;cursor:pointer;width:100%}
.row{display:grid;grid-template-columns:repeat(auto-fit,minmax(90px,1fr));gap:8px}
.field{padding:14px;border-radius:14px;background:#F4F6F8}.field dd{margin:4px 0 0;font-size:18px;font-weight:600;overflow-wrap:anywhere}
dl{margin:0;display:flex;flex-direction:column;gap:10px}dt{font-size:13px;color:#4B5563}
.icon{width:64px;height:64px;border-radius:32px;background:#E5E7EB;display:flex;align-items:center;justify-content:center}
footer{max-width:480px;margin:0 auto;padding:16px 20px 32px;display:flex;flex-direction:column;align-items:center;gap:4px;text-align:center}
footer a{color:#1A5FC4;font-size:13px;font-weight:600;min-height:44px;display:inline-flex;align-items:center;padding:0 8px}
footer .links{display:flex;flex-wrap:wrap;justify-content:center}footer small{font-size:12px;color:#4B5563}footer small a{font-size:12px;min-height:0;color:#4B5563;padding:0}`;

const ICON_PAUSE = `<svg aria-hidden="true" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2.2" stroke-linecap="round"><path d="M9 6v12M15 6v12"/></svg>`;
const ICON_SEARCH = `<svg aria-hidden="true" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2.2" stroke-linecap="round"><path d="M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4-4"/></svg>`;
const ICON_CLOCK = `<svg aria-hidden="true" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2.2" stroke-linecap="round"><path d="M12 7v5l3 2M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z"/></svg>`;
const ICON_ALERT = `<svg aria-hidden="true" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#374151" stroke-width="2.2" stroke-linecap="round"><path d="M12 8v5M12 16h.01M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18z"/></svg>`;

function page(lang: Lang, slug: string, title: string, inner: string, nonce: string, withCopy = false): string {
  const s: Strings = T[lang];
  const report = `mailto:support@scanqraft.app?subject=${encodeURIComponent(`${lang === "es" ? "Reporte" : "Report"} scanqraft.app/${slug}`)}`;
  const site = lang === "es" ? "https://www.scanqraft.app/es" : "https://www.scanqraft.app";
  const script = withCopy
    ? `<script nonce="${nonce}">document.querySelectorAll('[data-copy]').forEach(function(b){b.addEventListener('click',function(){var v=document.getElementById(b.getAttribute('data-copy')).textContent;var l=b.textContent;(navigator.clipboard?navigator.clipboard.writeText(v):Promise.reject()).then(function(){b.textContent=${JSON.stringify(s.copied)};setTimeout(function(){b.textContent=l},1600)}).catch(function(){})})})</script>`
    : "";
  return `<!doctype html><html lang="${lang}"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="robots" content="noindex,nofollow"><title>${escapeHtml(title)} · QRaft</title><style>${CSS}</style></head><body><main>${inner}</main><footer><span class="muted">${s.madeWith} <strong>QRaft</strong></span><div class="links"><a href="${site}">${s.createOwn}</a><a href="${escapeHtml(report)}">${s.report}</a></div><small>${s.privacy} <a href="${site}/privacy">${s.privacyLink}</a></small></footer>${script}</body></html>`;
}

function statePage(lang: Lang, slug: string, icon: string, title: string, body: string, nonce: string): string {
  return page(lang, slug, title, `<article class="card center"><div class="icon">${icon}</div><h1>${escapeHtml(title)}</h1><p class="muted">${escapeHtml(body)}</p></article>`, nonce);
}

function formatWhen(ev: CalEvent, lang: Lang, s: Strings): string {
  if (!ev.start) return "";
  const locale = lang === "es" ? "es-CO" : "en-US";
  const date = ev.start.date.toLocaleDateString(locale, { weekday: "long", day: "numeric", month: "long", year: "numeric", timeZone: "UTC" });
  if (ev.start.allDay) return `${date} · ${s.allDay}`;
  const opts: Intl.DateTimeFormatOptions = { hour: "numeric", minute: "2-digit", timeZone: "UTC" };
  if (!ev.start.floating) opts.timeZoneName = "short";
  return `${date}, ${ev.start.date.toLocaleTimeString(locale, opts)}`;
}

/** HTML for an active non-redirect type, or null when the payload can't be shown. */
export function contentPage(row: RedirectRow, lang: Lang, nonce: string, now: Date): string | null {
  const s: Strings = T[lang];
  const payload = row.content?.payload ?? "";
  const e = escapeHtml;
  switch (row.content_type) {
    case "text": {
      if (!payload.trim()) return null;
      return page(lang, row.slug, s.message, `<article class="card"><span class="label">${s.message}</span><p class="text" id="t">${e(payload)}</p><button class="btn2" type="button" data-copy="t">${s.copyText}</button></article>`, nonce, true);
    }
    case "vcard": {
      const c = parseVCard(payload);
      if (!c.name && !c.phones.length && !c.emails.length) return null;
      const initials = c.name.split(/\s+/).filter(Boolean).slice(0, 2).map((w) => w[0]!.toUpperCase()).join("");
      const sub = [c.title, c.org].filter(Boolean).join(" · ");
      const actions: string[] = [];
      if (c.phones[0]) actions.push(`<a class="btn2" href="tel:${e(c.phones[0].replace(/[^\d+]/g, ""))}">${s.call}</a>`);
      if (c.emails[0]) actions.push(`<a class="btn2" href="mailto:${e(c.emails[0])}">${s.email}</a>`);
      if (c.url) actions.push(`<a class="btn2" href="${e(c.url)}" rel="noopener nofollow">${s.website}</a>`);
      const details = [
        ...c.phones.map((v) => `<div class="field"><dt>${s.phone}</dt><dd>${e(v)}</dd></div>`),
        ...c.emails.map((v) => `<div class="field"><dt>${s.email}</dt><dd>${e(v)}</dd></div>`),
        c.address ? `<div class="field"><dt>${s.where}</dt><dd>${e(c.address)}</dd></div>` : "",
      ].join("");
      return page(lang, row.slug, c.name || s.saveContact, `<article class="card center"><div class="icon" aria-hidden="true" style="background:#FCE7F3;color:#9D174D;font-size:24px;font-weight:700;width:80px;height:80px;border-radius:40px">${e(initials || "?")}</div><h1>${e(c.name)}</h1>${sub ? `<p class="muted">${e(sub)}</p>` : ""}<a class="btn" href="?dl=vcf">${s.saveContact}</a>${actions.length ? `<div class="row" style="width:100%">${actions.join("")}</div>` : ""}${details ? `<dl style="width:100%;text-align:left">${details}</dl>` : ""}${c.note ? `<p class="muted">${e(c.note)}</p>` : ""}</article>`, nonce);
    }
    case "vevent": {
      const ev = parseEvent(payload);
      if (!ev.title && !ev.start) return null;
      const when = formatWhen(ev, lang, s);
      const maps = ev.location ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(ev.location)}` : null;
      return page(lang, row.slug, ev.title || s.addCalendar, `<article class="card"><h1>${e(ev.title)}</h1><dl>${when ? `<div><dt>${s.when}</dt><dd style="margin:2px 0 0;font-size:16px">${e(when)}</dd></div>` : ""}${ev.location ? `<div><dt>${s.where}</dt><dd style="margin:2px 0 0;font-size:16px">${e(ev.location)}</dd></div>` : ""}</dl>${ev.description ? `<p class="muted">${e(ev.description)}</p>` : ""}<a class="btn" href="?dl=ics">${s.addCalendar}</a>${maps ? `<a class="btn2" href="${e(maps)}" rel="noopener">${s.directions}</a>` : ""}</article>`, nonce);
    }
    case "wifi": {
      const w = parseWifi(payload);
      if (!w.ssid) return null;
      const open = !w.password || w.security.toLowerCase() === "nopass";
      return page(lang, row.slug, s.wifiTitle, `<article class="card"><h1>${s.wifiTitle}</h1><dl><div class="field"><dt>${s.network}</dt><dd>${e(w.ssid)}</dd></div>${open ? `<div class="field"><dd style="margin:0;font-size:15px;font-weight:500">${s.noPassword}</dd></div>` : `<div class="field"><dt>${s.password}</dt><dd id="pw">${e(w.password)}</dd></div>`}</dl>${open ? "" : `<button class="btn" type="button" data-copy="pw">${s.copyPassword}</button>`}<p class="muted">${s.wifiHelp}</p></article>`, nonce, !open);
    }
    case "email": {
      const m = parseEmail(payload);
      if (!m) return null;
      return page(lang, row.slug, s.writeEmail, `<article class="card"><h1>${s.writeEmail}</h1><dl><div class="field"><dt>${s.to}</dt><dd>${e(m.to)}</dd></div>${m.subject ? `<div class="field"><dt>${s.subject}</dt><dd>${e(m.subject)}</dd></div>` : ""}</dl>${m.body ? `<p class="text">${e(m.body)}</p>` : ""}<a class="btn" href="${e(m.href)}">${s.writeEmail}</a></article>`, nonce);
    }
    default:
      void now;
      return null;
  }
}

function html(status: number, body: string, nonce: string, extra: Record<string, string> = {}): Outcome {
  return {
    status,
    headers: {
      ...BASE_HEADERS,
      "Content-Type": "text/html; charset=utf-8",
      "Content-Security-Policy": `default-src 'none'; style-src 'unsafe-inline'; script-src 'nonce-${nonce}'; img-src data:; base-uri 'none'; form-action 'none'; frame-ancestors 'none'`,
      ...extra,
    },
    body,
    countScan: false,
  };
}

function redirect(location: string, countScan: boolean): Outcome {
  return { status: 302, headers: { ...BASE_HEADERS, Location: location }, body: null, countScan };
}

/**
 * The whole public decision: status code, headers and body for a slug lookup.
 * [row] null = no such slug. [dl] = ?dl= query value.
 */
export function respond(
  slug: string,
  row: RedirectRow | null,
  opts: { lang: Lang; dl: string | null; nonce: string; now: Date },
): Outcome {
  const { lang, dl, nonce, now } = opts;
  const s: Strings = T[lang];
  if (!row) return html(404, statePage(lang, slug, ICON_SEARCH, s.missingTitle, s.missingBody, nonce), nonce);

  switch (row.status) {
    case "revoked": return html(410, statePage(lang, slug, ICON_SEARCH, s.goneTitle, s.goneBody, nonce), nonce);
    case "blocked": return html(451, statePage(lang, slug, ICON_ALERT, s.blockedTitle, s.blockedBody, nonce), nonce);
    case "paused": return html(200, statePage(lang, slug, ICON_PAUSE, s.pausedTitle, s.pausedBody, nonce), nonce);
    case "pending_payment": return html(200, statePage(lang, slug, ICON_CLOCK, s.pendingTitle, s.pendingBody, nonce), nonce);
  }

  const payload = row.content?.payload ?? "";
  const bad = () => html(422, statePage(lang, slug, ICON_ALERT, s.badTitle, s.badBody, nonce), nonce);

  if (dl === "vcf" && row.content_type === "vcard" && payload) {
    return { status: 200, headers: { ...BASE_HEADERS, "Content-Type": "text/vcard; charset=utf-8", "Content-Disposition": `attachment; filename="${slug}.vcf"` }, body: vcfFile(payload), countScan: false };
  }
  if (dl === "ics" && row.content_type === "vevent" && payload) {
    return { status: 200, headers: { ...BASE_HEADERS, "Content-Type": "text/calendar; charset=utf-8", "Content-Disposition": `attachment; filename="${slug}.ics"` }, body: icsFile(payload, slug, now), countScan: false };
  }

  switch (row.content_type) {
    case "url": {
      const url = safeHttpUrl(payload);
      return url ? redirect(url, true) : bad();
    }
    case "geo": {
      const url = geoToMapsUrl(payload);
      return url ? redirect(url, true) : bad();
    }
    default: {
      const body = contentPage(row, lang, nonce, now);
      if (!body) return bad();
      const out = html(200, body, nonce);
      out.countScan = true;
      return out;
    }
  }
}

export function errorOutcome(lang: Lang, slug: string, nonce: string): Outcome {
  const s: Strings = T[lang];
  return html(503, statePage(lang, slug, ICON_ALERT, s.errorTitle, s.errorBody, nonce), nonce, { "Retry-After": "30" });
}
