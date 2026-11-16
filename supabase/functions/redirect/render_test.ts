import { assert, assertEquals, assertStringIncludes } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  escapeHtml,
  geoToMapsUrl,
  icsFile,
  parseEmail,
  parseEvent,
  parseVCard,
  parseWifi,
  pickLang,
  type RedirectRow,
  respond,
  safeHttpUrl,
} from "./render.ts";

const now = new Date("2026-11-16T12:00:00Z");
const opts = (dl: string | null = null) => ({ lang: "es" as const, dl, nonce: "n0nce", now });
const row = (over: Partial<RedirectRow>): RedirectRow => ({
  id: "r1", slug: "abc12345", status: "active", content_type: "url", content: { payload: "https://example.com" }, ...over,
});

Deno.test("status codes per state", () => {
  assertEquals(respond("zzz", null, opts()).status, 404);
  assertEquals(respond("x", row({ status: "revoked" }), opts()).status, 410);
  assertEquals(respond("x", row({ status: "blocked" }), opts()).status, 451);
  const paused = respond("x", row({ status: "paused" }), opts());
  assertEquals(paused.status, 200);
  assertEquals(paused.countScan, false);
  assertStringIncludes(paused.body!, "pausado");
  const pending = respond("x", row({ status: "pending_payment" }), opts());
  assertEquals(pending.status, 200);
  assertEquals(pending.countScan, false);
});

Deno.test("active url → 302 no-store, counted", () => {
  const o = respond("x", row({}), opts());
  assertEquals(o.status, 302);
  assertEquals(o.headers.Location, "https://example.com/");
  assertEquals(o.headers["Cache-Control"], "no-store");
  assertEquals(o.countScan, true);
});

Deno.test("unsafe urls are refused", () => {
  for (const p of ["javascript:alert(1)", "https://a b.com", "https://user:pw@evil.com", "ftp://x.com", ""]) {
    assertEquals(safeHttpUrl(p), null, p);
    assertEquals(respond("x", row({ content: { payload: p } }), opts()).status, 422, p);
  }
});

Deno.test("geo → maps 302", () => {
  assertEquals(geoToMapsUrl("geo:4.6,-74.08?q=4.6,-74.08(Caf%C3%A9)"), "https://www.google.com/maps/search/?api=1&query=4.6,-74.08");
  assertEquals(geoToMapsUrl("geo:200,1"), null);
  assertEquals(respond("x", row({ content_type: "geo", content: { payload: "geo:4.6,-74.08" } }), opts()).status, 302);
});

Deno.test("text page escapes html and counts", () => {
  const o = respond("x", row({ content_type: "text", content: { payload: "<script>alert(1)</script>" } }), opts());
  assertEquals(o.status, 200);
  assertEquals(o.countScan, true);
  assert(!o.body!.includes("<script>alert"));
  assertStringIncludes(o.body!, "&lt;script&gt;");
  assertStringIncludes(o.headers["Content-Security-Policy"], "nonce-n0nce");
  assertEquals(o.headers["X-Robots-Tag"], "noindex, nofollow");
});

const VCARD = "BEGIN:VCARD\nVERSION:3.0\nFN:Ana Ruiz\nN:Ruiz;Ana;;;\nORG:Café Central\nTITLE:Gerente\nTEL:+57 300 123 4567\nEMAIL:ana@cafe.co\nURL:cafe.co\nADR:;;Cra 7 #45-10;;;;\nEND:VCARD";

Deno.test("vcard parse, page and download", () => {
  const c = parseVCard(VCARD);
  assertEquals(c.name, "Ana Ruiz");
  assertEquals(c.org, "Café Central");
  assertEquals(c.phones, ["+57 300 123 4567"]);
  assertEquals(c.url, "https://cafe.co/");
  assertEquals(c.address, "Cra 7 #45-10");
  const r = row({ content_type: "vcard", content: { payload: VCARD } });
  const page = respond("x", r, opts());
  assertStringIncludes(page.body!, "Guardar contacto");
  assertStringIncludes(page.body!, 'href="tel:+573001234567"');
  const dl = respond("x", r, opts("vcf"));
  assertEquals(dl.headers["Content-Type"], "text/vcard; charset=utf-8");
  assert(dl.body!.includes("\r\nFN:Ana Ruiz\r\n"));
  assertEquals(dl.countScan, false);
});

const EVENT = "BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:Lanzamiento\nDTSTART:20261120T190000\nLOCATION:Café Central\nEND:VEVENT\nEND:VCALENDAR";

Deno.test("event parse, page and ics", () => {
  const ev = parseEvent(EVENT);
  assertEquals(ev.title, "Lanzamiento");
  assertEquals(ev.start?.date.toISOString(), "2026-11-20T19:00:00.000Z");
  assertEquals(ev.start?.floating, true);
  const r = row({ content_type: "vevent", content: { payload: EVENT } });
  const page = respond("x", r, opts());
  assertStringIncludes(page.body!, "vie");
  assertStringIncludes(page.body!, "Agregar a Google Calendar");
  const ics = icsFile(EVENT, "abc12345", now);
  assertStringIncludes(ics, "PRODID:-//QRaft//scanqraft.app//ES\r\n");
  assertStringIncludes(ics, "UID:abc12345@scanqraft.app\r\n");
  assertStringIncludes(ics, "DTSTAMP:20261116T120000Z\r\n");
  assertEquals(respond("x", r, opts("ics")).headers["Content-Type"], "text/calendar; charset=utf-8");
  assertEquals(parseEvent("BEGIN:VEVENT\nSUMMARY:x\nDTSTART;VALUE=DATE:20261120\nEND:VEVENT").start?.allDay, true);
});

Deno.test("wifi parse with escapes", () => {
  const w = parseWifi('WIFI:T:WPA;S:Caf\\;e\\:5G;P:p\\\\a\\"ss;H:false;;');
  assertEquals(w, { ssid: "Caf;e:5G", password: 'p\\a"ss', security: "WPA", hidden: false });
  const page = respond("x", row({ content_type: "wifi", content: { payload: "WIFI:T:WPA;S:Home;P:secret;H:false;;" } }), { ...opts(), platform: "ios" });
  assertStringIncludes(page.body!, "Copiar contraseña");
  assertStringIncludes(page.body!, '<strong id="v2" class="mono">secret</strong>');
  assertStringIncludes(page.body!, 'data-copy="v2"');
});

Deno.test("email parse rejects junk", () => {
  assertEquals(parseEmail("mailto:ana@cafe.co?subject=Hola%20ya")?.subject, "Hola ya");
  assertEquals(parseEmail("mailto:not-an-email"), null);
  assertEquals(parseEmail("javascript:x"), null);
});

Deno.test("helpers", () => {
  assertEquals(pickLang("es-CO,es;q=0.9"), "es");
  assertEquals(pickLang(null), "en");
  assertEquals(escapeHtml(`<a href="x">'&`), "&lt;a href=&quot;x&quot;&gt;&#39;&amp;");
});
