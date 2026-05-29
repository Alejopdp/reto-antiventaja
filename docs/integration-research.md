# Investigación de integraciones (deep-research)

> Investigación multi-fuente con verificación adversarial (23 claims confirmados / 2 refutados, 23 fuentes). Mercado España, ~300+/cohorte. Precios verificados a **mayo 2026** — re-verificar antes de contratar.
> ⚠️ Contiene un hallazgo que **cambia un supuesto de diseño** (tracking de video, ver §2).

## TL;DR — recomendación por categoría
1. **WhatsApp:** evaluar **Kapso primero** (⭐ **somos partners**, **oficial** → sin ban-risk, mejor GDPR), pero su **Groups API está en waitlist** → confirmar capacidades y early access. **Whapi.Cloud** (no oficial) ya da grupos+1:1+webhooks, pero con **riesgo de baneo** y solo por **link de invitación** (no se añaden números desconocidos) → **fallback**. Cloud API oficial vía 360dialog (€49/nº/mes) no automatiza grupos.
2. **Video con tracking por persona:** **Wistia** es lo más cercano (webhook `percent_watched` a 25/50/75/100% + `visitor.id` persistente), **pero NO acepta un token propio en el webhook** → rompe nuestro supuesto de "token en la URL del replay". Hay workarounds (email-gate / mapeo `visitor.id`↔token) o evaluar **api.video** (session tokens).
3. **Pagos:** **Stripe + Bizum** (1,5% + €0,25, solo EUR, pago único) y **soporta metadata por token en el Checkout que vuelve en el webhook** → **confirma** nuestro matching pago↔participante (H5). Alternativa: **Mollie** (Bizum, sin cuota mensual).

---

## 1) WhatsApp

| Opción | Grupos (add/invite) | 1:1 + webhooks | Precio (may-2026) | ToS / baneo |
|---|---|---|---|---|
| **Whapi.Cloud** (no oficial) | ✅ add/remove + invite links | ✅ envío 1:1 + webhooks en tiempo real (mensajes, estados, **alta/baja de grupo**, llamadas) | ❌ **no confirmado** (la claim de ~$29/mes fue **refutada**; verificar en whapi.cloud/price) | ⚠️ **viola ToS, riesgo de baneo** (no cuantificado) |
| **Cloud API oficial vía 360dialog** | ❌ no automatiza grupos | ✅ 1:1 + plantillas, ventana 24h | €49/nº/mes, **sin markup** sobre tarifas Meta (pass-through) | ✅ oficial |

**Recomendación MVP:** seguir con el enfoque no-oficial que eligió el cliente (Whapi u equivalente), **distribuyendo link de invitación** (no altas directas), con el diseño **canal-agnóstico** ya previsto para migrar a oficial si crece o si hay baneo. **Verificar el precio real de Whapi** (lo refutado) y sus límites de envío antes de presupuestar.

**Banderas:** riesgo de baneo del número (material para un servicio de pago); no se pueden añadir números desconocidos → onboarding por **link de invitación**.

### Kapso — candidato preferente (⭐ somos partners)
*(Fuente: web/docs de Kapso — una sola fuente vendor; NO pasó la verificación adversarial del resto del research. Confirmar directamente, que para eso somos partners.)*

- **Qué es:** plataforma de WhatsApp para developers **sobre la Cloud API oficial de Meta** (Meta factura las conversaciones directo a tu WABA). Multi-tenant, almacenamiento de conversaciones, **funciones serverless (Cloudflare Workers)** para webhooks/lógica/workflows/agentes, workflow builder visual, SDK TypeScript.
- **Pricing (vendor):** Free 2K msgs/mes · Pro $25/mes 100K · Platform $299/mes 1M; tarifas de Meta aparte; no-plantilla gratis en ventana 24h.
- **Grupos:** **waitlist / "coming soon"** — la pieza central de nuestro funnel. **No disponible aún.**
- **Plus partnership:** potencial **early access** al Groups API + pricing/soporte preferente.

**Por qué importa:** al ser **oficial**, Kapso **elimina el ToS/ban-risk y mejora el cumplimiento GDPR** — justo la bandera roja más grande de Whapi. **Pero** el modelo oficial es 1:1 + plantillas; **el grupo depende del Groups API que aún no salió** → incertidumbre de capacidades y fecha. Para un MVP, depender de una API no liberada es un riesgo.

**Recomendación revisada (WhatsApp):** **evaluar Kapso primero** (aprovechando la partnership) — confirmar qué hace y cuándo su Groups API (add/invite, envío al grupo, webhooks de eventos de grupo) y si hay early access. Si llega a tiempo, es la opción **compliant** preferida. **Whapi queda como fallback** no-oficial si necesitamos grupos ya y Kapso no está listo. El diseño canal-agnóstico permite cambiar sin tocar el core.

## 2) Video con tracking por persona  ⚠️ cambia un supuesto

| Opción | % visto por webhook | ¿Token propio en el webhook? | Notas |
|---|---|---|---|
| **Wistia** | ✅ `viewing_session.percent_watched` a 25/50/75/100% | ❌ **NO** — solo `visitor.id` (cookie, se rompe entre dispositivos / Privacy Mode) o email vía **Turnstile** en la misma sesión | lo más alineado, con caveats |
| **Mux** | ❌ **no por webhook** (solo Mux Data API/export, client-side) | (sí por persona, pero no por webhook) | no encaja con arquitectura por-webhook |
| **api.video** | a verificar | "private video session tokens" (a verificar) | **candidato a comparar** si necesitamos token propio |

**Hallazgo crítico:** nuestro diseño asumía (H3) *"el replay lleva el `token` en la URL y el webhook del host lo devuelve"*. **Wistia no soporta esto.** Opciones:
- (a) **Email-gate (Turnstile)**: el participante ingresa su email antes del video → Wistia lo ata a la vista. Suma fricción.
- (b) **Mapeo `visitor.id` ↔ token** vía Stats API (correlación posterior, no determinista entre dispositivos).
- (c) **Otro host** que acepte un token propio (evaluar **api.video** / Vimeo / Cloudflare Stream — no comparados a fondo en esta ronda).

→ **Afecta `VideoTrackingPort`, H3 y Q1.** Decisión de diseño + producto (ver `open-questions.md`).

## 3) Pagos (España, ~60 €)

| Opción | Bizum | Fee (may-2026) | Metadata/token en webhook | Webhooks pago/reembolso |
|---|---|---|---|---|
| **Stripe** | ✅ (solo EUR, pago único, no recurrente) | 1,5% + €0,25 (+2% si hay conversión) | ✅ metadata en Checkout Session → vuelve en `checkout.session.completed` | ✅ |
| **Mollie** | ✅ (ES, EUR, online) | "Acquirer Fees + 0,10% + 0,10€", **sin cuota mensual** | ✅ (Payments API) | ✅ refunds totales/parciales |

**Recomendación MVP:** **Stripe** — DX madura, metadata por token **confirmada** para el matching automático pago↔participante (H5), Bizum nativo. Mollie es alternativa válida (más barata por transacción, sin cuota) si se prefiere.
**Caveat:** la metadata del Checkout no se propaga al PaymentIntent/Charge salvo que se setee `payment_intent_data.metadata` también.

## 4) GDPR / compliance (España) — bandera transversal

- La **AEPD multó a WhatsApp y Facebook (300.000 € c/u)** por tratar datos sin consentimiento válido.
- Precedente directo: una empresa fue **multada con 70.000 €** por **añadir a una persona a un grupo de WhatsApp usando su número sin consentimiento**. → **Añadir a alguien al grupo exige consentimiento explícito, informado y revocable.** Refuerza el checkbox de consentimiento (ya en el wireframe) y el opt-out (Q2).
- La automatización no-oficial **agrava** el riesgo de cumplimiento.

## Preguntas abiertas que deja el research
1. Precio real y límites de envío de Whapi (o Marychat) antes de gatillar anti-spam/baneo a escala de 300+.
2. ¿Hay un modelo oficial (WhatsApp Communities/Channels o broadcast 1:1) que reemplace la automatización de grupos sin violar ToS?
3. Implementación concreta del consentimiento GDPR para el alta a grupo tras el registro.
4. Para video: ¿aceptamos el email-gate de Wistia, o comparamos formalmente api.video/Vimeo/Cloudflare para uno que acepte token propio en el webhook?

## Fuentes principales (primarias)
- WhatsApp/Whapi: whapi.cloud/whatsapp-groups-api, support.whapi.cloud (webhooks, add member), 360dialog.com/pricing
- Kapso (partners): kapso.ai/platform, kapso.ai/pricing, kapso.ai/whatsapp-groups (waitlist), docs.kapso.ai/docs/whatsapp/pricing-faq
- Video: docs.wistia.com/docs/webhooks, mux.com/docs/webhook-reference, docs.api.video (session tokens)
- Pagos: docs.stripe.com/payments/bizum, stripe.com/.../local-payment-methods, docs.stripe.com/metadata/use-cases, mollie.com/payments/bizum
- GDPR: aepd.es (nota de prensa sanción WhatsApp/Facebook), infobae (multa 70.000 € por alta a grupo sin consentimiento)

> Lagunas: no se compararon a fondo Twilio, Vimeo, api.video, Cloudflare Stream, Redsys ni PayPal con claims propias. El precio de Whapi quedó sin confirmar (refutado). Re-verificar precios antes de contratar.
