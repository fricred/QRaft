import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { validateContent } from "./dynamic_qr.ts";

Deno.test("validateContent per type", () => {
  assertEquals(validateContent("url", "https://cafe.co/menu"), { ok: true });
  assertEquals(validateContent("url", "https://bit.ly/x"), { ok: false, error: "shortener_not_allowed" });
  assertEquals(validateContent("url", "https://www.scanqraft.app/abc"), { ok: false, error: "own_domain_not_allowed" });
  assertEquals(validateContent("url", "javascript:alert(1)"), { ok: false, error: "invalid_url" });
  assertEquals(validateContent("bogus", "x"), { ok: false, error: "invalid_type" });
  assertEquals(validateContent("text", "   "), { ok: false, error: "empty_content" });
  assertEquals(validateContent("text", "x".repeat(4001)), { ok: false, error: "content_too_long" });
  assertEquals(validateContent("vcard", "BEGIN:VCARD\nFN:Ana\nEND:VCARD"), { ok: true });
  assertEquals(validateContent("vcard", "hola"), { ok: false, error: "invalid_vcard" });
  assertEquals(validateContent("vevent", "BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:x\nDTSTART:20261120T190000\nEND:VEVENT\nEND:VCALENDAR"), { ok: true });
  assertEquals(validateContent("vevent", "BEGIN:VEVENT\nSUMMARY:x\nEND:VEVENT"), { ok: false, error: "invalid_event" });
  assertEquals(validateContent("geo", "geo:4.6,-74.1"), { ok: true });
  assertEquals(validateContent("wifi", "WIFI:T:WPA;S:Casa;P:x;;"), { ok: true });
  assertEquals(validateContent("wifi", "WIFI:T:WPA;P:x;;"), { ok: false, error: "invalid_wifi" });
  assertEquals(validateContent("email", "mailto:a@b.co"), { ok: true });
});
