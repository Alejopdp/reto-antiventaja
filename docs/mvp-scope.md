# Reto Antiventaja — Alcance del MVP

> Estado: **Fase 2 — Planificar (borrador)**. Deriva de `discovery.md`. No implementar hasta validar §6 (inputs del cliente) y aprobar.
> Fecha: 2026-05-29

---

## 1. Objetivo del MVP

Ser la **única fuente de verdad** del embudo del Reto Antiventaja: registrar participantes, atribuir quién invitó a quién, seguir el estado de cada uno a lo largo del reto, ingerir señales de comportamiento (video visto), y **emitir las acciones de mensajería** que la capa no-code ejecuta sobre WhatsApp — todo con un dashboard para el organizador. Lean, single-tenant, recurrente y preparado para 300+/cohorte.

**Principio rector**: el cerebro es *agnóstico del canal*. Decide *qué acción* corresponde; *cómo se envía* (grupo no oficial hoy, API oficial mañana) vive afuera. Cambiar de canal no debe tocar el core.

---

## 2. Dentro / Fuera de alcance

**Dentro (MVP):**
- Formulario público de registro (con token único + captura de "quién te invitó").
- Modelo de datos: cohorte, participante, log de eventos, grafo de atribución, cola de acciones de salida.
- Máquina de estados del participante.
- Ingesta de webhooks: alta al grupo, visionado de video, respuestas/encuestas.
- Motor de scheduling (contenido diario relativo al inicio) y de follow-up segmentado (no vio / parcial <80% / completo >80%), **idempotente**.
- Cola de acciones de salida + endpoint para que la capa no-code la consuma y confirme (ack).
- Dashboard del embudo (conteos por estado, conversión, vista de atribución por impulsor).

**Fuera (MVP):**
- Liquidación/cálculo de comisiones (solo guardamos el grafo de atribución).
- Captura/análisis de datos financieros (el Excel solo se entrega).
- Envío directo de WhatsApp / API oficial (lo hace la capa no-code).
- Hosting de video y generación de audios/copy con IA (Wistia/Vimeo, ElevenLabs, ChatGPT — externos).
- Multi-tenant / white-label.

---

## 3. Modelo de datos (borrador)

- **cohort**: `id, name, start_date, timezone, presentation_at (fecha fija de la presentación P60), status`.
- **participant**: `id, cohort_id, full_name, whatsapp_number (normalizado), email?, token (único), referred_by_raw (texto del formulario), referred_by_participant_id (nullable, resuelto), state, accepted_at?, joined_group_at?, converted_p60_at?, created_at`.
  - `cohort_id` = membresía lógica (gate humano). El grupo de WhatsApp es canal, no se modela como entidad propia en MVP (es atributo de la cohorte/config del `MessagingPort`).
- **event** (append-only, manda el estado): `id, participant_id, type, payload (jsonb), occurred_at`. Tipos: `registered`, `joined_group`, `video_view`, `survey_response`, `p60_registered`, …
- **outbound_action** (cola): `id, participant_id, type, status (pending/sent/failed), scheduled_for, dedupe_key (único, idempotencia), payload (recipiente + plantilla + vars), sent_at?`.
- **Atribución**: aristas `referred_by_participant_id` entre participantes (grafo). Sin lógica de comisión todavía.
- **Contenido del reto** (día → asset): probablemente **config estática** versionada, no tabla, en el MVP.

> Identidad (crux): el formulario genera `token`; todo link de contenido/video lo lleva; el webhook de video devuelve el `token`; el alta al grupo se matchea por `whatsapp_number` normalizado.

---

## 4. Frontera de integración (contrato con la capa no-code)

**Entra a nuestro app (webhooks):**
- Registro: el formulario propio escribe directo en la DB (no necesita webhook).
- `POST /webhooks/group-join` — número se unió al grupo → transición de estado + encolar bienvenida.
- `POST /webhooks/video` — `{ token, percent_watched, … }` desde Wistia/Vimeo → evento + segmentación.
- `POST /webhooks/survey` — respuestas de encuestas/dinámicas (opcional MVP).

**Sale de nuestro app (acciones):**
- `GET /actions/pending` — Make/automatizador consulta la cola (recipiente + plantilla + variables).
- `POST /actions/{id}/ack` — confirma enviado/fallido (cierra el loop, evita reenvíos).

---

## 5. Máquina de estados + reglas de follow-up

Estados: `REGISTRADO/PENDIENTE_VERIFICACIÓN → {ACEPTADO_EN_COHORTE | RECHAZADO} → EN_GRUPO → EN_RETO(día N) → POST_PRESENTACIÓN → {NO_VIO | PARCIAL | COMPLETO} → CONVERTIDO_P60 → EXPERIENCIA`.

> **Cohorte ≠ Grupo de WhatsApp.** `ACEPTADO_EN_COHORTE` es un **gate humano** (Ops verifica el formulario). `EN_GRUPO` es posterior: la capa no-code agrega el número al grupo (canal) y nos avisa.

- **Contenido diario**: job evalúa, por participante, el día relativo a su `start_date`/`joined_group_at` y encola la acción del día N (con `dedupe_key = participant:day`).
- **Follow-up por video**: al llegar `video_view`, se segmenta y se encola `followup_1` (no vio), `followup_2` (parcial) o `cta_final` (completo), idempotente por `dedupe_key`.
- **Conversión**: al recibir `p60_registered`, marcar `converted_p60_at` y resolver la atribución.

---

## 6. Inputs que necesitamos del cliente (bloquean el inicio)

1. **Herramienta de automatización de grupos** que ya usa (¿Marychat? ¿otra?) y qué webhooks/API expone.
2. **Host de video** (Wistia o Vimeo) — define el formato del webhook de tracking y si soporta pasar nuestro `token`.
3. **Cómo se detecta el pago del P60**: ¿webhook de un procesador de pago? ¿formulario de registro P60? ¿marca manual de ops? (define cómo entra `p60_registered`).
4. **Contenido**: videos/audios/copy de los 7 días + presentación + Excel (no los generamos en MVP).
5. **Setup de WhatsApp**: número(s), estructura de grupo(s), una cohorte = ¿un grupo?
6. **Zona horaria** de la operación y cadencia esperada de cohortes.

---

## 7. Orden de construcción — cuando se apruebe

### Criterio no-regret (qué podemos avanzar YA sin riesgo)
Avanzamos solo lo que NO es costoso de cambiar después o está aislado tras un puerto:
- ✅ **Cerrado/seguro**: arquitectura hexagonal y los 3 puertos; event log append-only como fuente de verdad; single-tenant; modelo de dominio base (cohorte/participante/evento/acción); identidad por `token`; `AcciónDeSalida` abstracta tipada (ADR-0001); stack Next.js + Drizzle + Postgres.
- ⛔ **Bloqueado por el cliente** (NO hornear): elección de PSP / host de video / automatizador de grupos (aislados tras puertos), campos del formulario, calendario/horarios de contenido, y sobre todo **Q1** (broadcast vs 1:1) que condiciona el tracking.

### Fase de diseño (TO-DO, antes de meternos en lo técnico)
- [ ] **Wireframes / prototipos con claude-design** de las 2 superficies del MVP: (a) **formulario público de registro**, (b) **dashboard interno** (embudo + bandeja de verificación Ops + atribución). Validar UX/flujo antes de escribir UI.
- [ ] Reunión con el cliente para cerrar `open-questions.md` (al menos los 🔴 críticos Q1 y Q2).

### Waves técnicas (post-diseño y post-respuestas del cliente)
- **Wave 0 — Cimientos**: init repo (Next.js 15 + Drizzle + Postgres), schema, config. Formulario público de registro → participante + token + atribución.
- **Wave 1 — Alta automática**: webhook group-join → estado + encolar bienvenida; cola de acciones + endpoints pending/ack; dashboard v0 (lista + conteos por estado).
- **Wave 2 — Entrega del reto**: scheduler de contenido diario (días relativos), idempotente.
- **Wave 3 — Conversión**: webhook de video → segmentación → follow-ups; captura de `p60_registered` + resolución de atribución.
- **Wave 4 — Analítica**: dashboard de embudo + vista de atribución por impulsor + export.

Dentro de cada wave hay trabajo paralelizable; entre waves hay dependencia de datos.
