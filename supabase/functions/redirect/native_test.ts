import { assert, assertEquals, assertStringIncludes } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  androidContactIntent,
  androidEventIntent,
  appleMapsUrl,
  detectPlatform,
  googleCalendarUrl,
  parseEvent,
  parseVCard,
  type Platform,
  type RedirectRow,
  respond,
  wifiAppIntent,
} from "./render.ts";

const now = new Date("2026-11-16T12:00:00Z");
const o = (platform: Platform, extra: Record<string, unknown> = {}) => ({ lang: "es" as const, dl: null, nonce: "n0nce", now, platform, ...extra });
const row = (over: Partial<RedirectRow>): RedirectRow => ({
  id: "r1", slug: "abc12345", status: "active", content_type: "url", content: { payload: "https://example.com" }, ...over,
});
const VCARD = "BEGIN:VCARD\nVERSION:3.0\nN:Restrepo;María;;;\nFN:María Restrepo\nORG:Estudio; Norte\nTITLE:Diseñadora\nTEL:+57 300 123 4567\nEMAIL:maria@norte.co\nEND:VCARD";
const EVENT = "BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:Lanzamiento; otoño\nDTSTART:20261122T190000Z\nDTEND:20261122T220000Z\nLOCATION:Galería Norte\nEND:VEVENT\nEND:VCALENDAR";

Deno.test("platform detection", () => {
  assertEquals(detectPlatform("Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 Chrome/130 Mobile Safari/537.36"), "android");
  assertEquals(detectPlatform("Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 Version/18.0 Mobile/15E148 Safari/604.1"), "ios");
  assertEquals(detectPlatform("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 Version/18.0 Safari/605.1.15"), "other");
  assertEquals(detectPlatform(null), "other");
});

Deno.test("iPhone: contact and event are the files themselves (native sheet), counted once", () => {
  const c = respond("abc12345", row({ content_type: "vcard", content: { payload: VCARD } }), o("ios"));
  assertEquals(c.status, 200);
  assertEquals(c.headers["Content-Type"], "text/vcard; charset=utf-8");
  assertStringIncludes(c.headers["Content-Disposition"], "inline");
  assertEquals(c.countScan, true);
  const ev = respond("abc12345", row({ content_type: "vevent", content: { payload: EVENT } }), o("ios"));
  assertEquals(ev.headers["Content-Type"], "text/calendar; charset=utf-8");
  assertEquals(ev.countScan, true);
  // ?view=page forces the page.
  assertEquals(respond("abc12345", row({ content_type: "vcard", content: { payload: VCARD } }), o("ios", { view: "page" })).headers["Content-Type"], "text/html; charset=utf-8");
});

Deno.test("iPhone location → Apple Maps; Android → Google Maps", () => {
  const geo = row({ content_type: "geo", content: { payload: "geo:4.65,-74.05" } });
  assertEquals(respond("x", geo, o("ios")).headers.Location, "https://maps.apple.com/?ll=4.65,-74.05&q=4.65,-74.05");
  assertStringIncludes(respond("x", geo, o("android")).headers.Location, "google.com/maps");
  assertEquals(appleMapsUrl("geo:99,0"), null);
});

Deno.test("Android contact page: Contacts insert intent, encoded, with .vcf fallback", () => {
  const out = respond("abc12345", row({ content_type: "vcard", content: { payload: VCARD } }), o("android"));
  assertEquals(out.countScan, true);
  assertStringIncludes(out.body!, "Guardar en Contactos");
  const i = androidContactIntent(parseVCard(VCARD), "https://scanqraft.app/abc12345?dl=vcf");
  assert(i.startsWith("intent:#Intent;action=android.intent.action.INSERT;type=vnd.android.cursor.dir/raw_contact;"));
  assertStringIncludes(i, "S.name=Mar%C3%ADa%20Restrepo;");
  assertStringIncludes(i, "S.phone=%2B57%20300%20123%204567;");
  assertStringIncludes(i, "S.browser_fallback_url=https%3A%2F%2Fscanqraft.app%2Fabc12345%3Fdl%3Dvcf;");
  assert(i.endsWith(";end"));
});

Deno.test("Android event page: calendar insert intent; ';' in title can't break the intent", () => {
  const ev = parseEvent(EVENT);
  const i = androidEventIntent(ev, "https://cal")!;
  assertStringIncludes(i, "S.title=Lanzamiento%3B%20oto%C3%B1o;");
  assertStringIncludes(i, `l.beginTime=${Date.UTC(2026, 10, 22, 19)};`);
  assertStringIncludes(i, `l.endTime=${Date.UTC(2026, 10, 22, 22)};`);
  const page = respond("abc12345", row({ content_type: "vevent", content: { payload: EVENT } }), o("android"));
  assertStringIncludes(page.body!, "Agregar al calendario");
  // HTML-escaped inside href (& → &amp;) but still an intent.
  assertStringIncludes(page.body!, 'href="intent:#Intent;action=android.intent.action.INSERT;type=vnd.android.cursor.dir/event;');
});

Deno.test("Google Calendar link: UTC, all-day, TZID, default end", () => {
  assertStringIncludes(googleCalendarUrl(parseEvent(EVENT))!, "dates=20261122T190000Z/20261122T220000Z");
  const allDay = parseEvent("BEGIN:VEVENT\nSUMMARY:Feria\nDTSTART;VALUE=DATE:20261120\nEND:VEVENT");
  assertStringIncludes(googleCalendarUrl(allDay)!, "dates=20261120/20261121");
  const tz = parseEvent("BEGIN:VEVENT\nSUMMARY:x\nDTSTART;TZID=America/Bogota:20261120T190000\nEND:VEVENT");
  const g = googleCalendarUrl(tz)!;
  assertStringIncludes(g, "dates=20261120T190000/20261120T200000");
  assertStringIncludes(g, "ctz=America%2FBogota");
  // Bogotá is UTC-5: 19:00 there = 00:00Z next day.
  assertStringIncludes(androidEventIntent(tz, "x")!, `l.beginTime=${Date.UTC(2026, 10, 21, 0)};`);
});

Deno.test("Android WiFi: app intent with Play fallback, settings button; iPhone: steps", () => {
  const w = { ssid: "Café Wi;Fi", password: "p&ss", security: "WPA", hidden: false };
  const i = wifiAppIntent(w);
  assert(i.startsWith("intent://wifi?ssid=Caf%C3%A9+Wi%3BFi&pw=p%26ss&sec=WPA&hidden=false#Intent;scheme=qraft;package=io.gothcorp.qraft;"));
  assertStringIncludes(i, "S.browser_fallback_url=https%3A%2F%2Fplay.google.com");
  const payload = "WIFI:T:WPA;S:BLUEFI;P:K2c!709665;H:false;;";
  const a = respond("x", row({ content_type: "wifi", content: { payload } }), o("android"));
  assertStringIncludes(a.body!, "Conectar con un toque");
  assertStringIncludes(a.body!, "android.settings.WIFI_SETTINGS");
  const ios = respond("x", row({ content_type: "wifi", content: { payload } }), o("ios"));
  assertStringIncludes(ios.body!, "Ajustes → Wi-Fi");
  assert(!ios.body!.includes("intent:"));
});

Deno.test("Email: phones go straight to the mail app (302 mailto:), desktop/?view=page get the page", () => {
  const r = row({ content_type: "email", content: { payload: "mailto:hola@norte.co?subject=Cotizaci%C3%B3n" } });
  const a = respond("x", r, o("android"));
  assertEquals(a.status, 302);
  assertEquals(a.headers.Location, "mailto:hola@norte.co?subject=Cotizaci%C3%B3n");
  assertEquals(a.countScan, true);
  assertEquals(respond("x", r, o("ios")).status, 302);
  assertStringIncludes(respond("x", r, o("other")).body!, "Abrir en mi correo");
  assertEquals(respond("x", r, o("android", { view: "page" })).status, 200);
});

Deno.test("page layout: footer pinned to the bottom, dark mode, copy buttons, everything escaped", () => {
  const evil = "BEGIN:VCARD\nVERSION:3.0\nFN:<img src=x onerror=alert(1)>\nTEL:\"><script>x</script>\nEND:VCARD";
  const out = respond("x", row({ content_type: "vcard", content: { payload: evil } }), o("android"));
  assert(!out.body!.includes("<img src=x"));
  assert(!out.body!.includes("<script>x"));
  assertStringIncludes(out.body!, "footer{margin-top:auto");
  assertStringIncludes(out.body!, "min-height:100dvh");
  assertStringIncludes(out.body!, "prefers-color-scheme:dark");
  assertStringIncludes(out.body!, 'data-copy="v');
  assertEquals(out.headers.Vary, "User-Agent, Accept-Language");
});
