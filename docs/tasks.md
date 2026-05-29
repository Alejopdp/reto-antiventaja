# Tareas — desglose en waves + DAG

> Plan de ejecución del MVP. Cada tarea: objetivo, dependencias, criterios (refieren a `use-cases.md`) y si es paralelizable. **No empezar hasta aprobar** y cerrar los 🔴 de cliente.
> Estrategia: **walking skeleton primero** (una rebanada punta a punta en Wave 1) para probar la integración temprano; luego slices verticales. Stack: Next.js 15 + Drizzle + Postgres; UI según `wireframes/`.

## Gating por cliente (no bloquea todo, sí bloquea waves puntuales)
- **Q1** (broadcast vs 1:1) → bloquea la parte de **vídeo/segmentación** de Wave 3. El resto avanza.
- **Q2** (mecanismo de baja) → bloquea solo la *detección* de baja desde WhatsApp; el comando/estado se construye igual.
- Elección de **PSP / host de vídeo / automatizador** → no bloquea: se programan los puertos; el adaptador concreto se hace cuando se elija.

---

## Wave 0 — Cimientos  *(sin dependencias)*
- **T0.1** Init repo: Next.js 15 (App Router) + TS + Tailwind/shadcn + Drizzle + Postgres; lint/format. → *build pasa, app vacía corre.*
- **T0.2** Schema Drizzle: `cohort`, `participant`, `event` (append-only), `outbound_action`. Enums de `domain-model.md`. → *migración aplica; índices por `token`, `whatsapp_number`, `dedupe_key`.*
- **T0.3** Núcleo de dominio: máquina de estados del participante + reductor del event log (estado materializado). → *tests de transición (UC-01..UC-13).*
- **T0.4** Interfaces de puertos (`MessagingPort`, `VideoTrackingPort`, `PaymentPort`) según `contracts/`. → *compilan; adaptadores fake para tests.*
- **T0.5** Formulario público de registro + `POST /register` (token, dedup por móvil). UI: `wireframes/registro.html`. → *UC-01.*

*Paralelizable:* T0.2/T0.3/T0.4 tras T0.1; T0.5 tras T0.2.

## Wave 1 — Alta automática + walking skeleton  *(dep: Wave 0)*
- **T1.1** Cola de acciones: escribir `outbound_action` idempotente por `dedupeKey` + `MessagingPort` (adaptador = cola). → *no duplica por dedupeKey.*
- **T1.2** Endpoints salida: `GET /actions/pending` (throttling, `scheduledFor`) + `POST /actions/{id}/ack` → `AcciónResuelta`. → *http-boundary; idempotencia del ack.*
- **T1.3** Webhook `POST /webhooks/group-join` (match por E.164) → `ParticipanteUnidoAlGrupo` → encola `bienvenida`. → *UC-04; no resueltos → bandeja.*
- **T1.4** Bandeja de verificación (Ops): aceptar/rechazar individual y en lote → `VerificarRegistro`; aceptar encola `alta_grupo`. UI: `wireframes/dashboard-verificacion.html`. → *UC-02, UC-03.*
- **T1.5** Dashboard v0: embudo con conteos por estado. UI: `wireframes/dashboard-overview.html`. → *lee read model.*
- **🎯 Skeleton E2E:** registro → aceptar → `alta_grupo` encolada → `pending` → `ack` → `group-join` → `bienvenida`. *Prueba la integración con la capa no-code de punta a punta.*

*Paralelizable:* T1.1→T1.2; T1.3 y T1.4 en paralelo; T1.5 al final.

## Wave 2 — Entrega del reto  *(dep: Wave 1)*
- **T2.1** Config de contenido por día (0..7) versionada (no tabla en MVP). → *fuente única del calendario.*
- **T2.2** Scheduler de contenido relativo a `joinedGroupAt` (Q31) → encola `contenido_diario{day}` idempotente. → *UC-05; TZ Q15.*
- **T2.3** Webhook `POST /webhooks/survey` → `EncuestaRespondida` (persistir, sin cálculo). → *UC-06.*

## Wave 3 — Conversión  *(dep: Wave 1; vídeo bloqueado por Q1)*
- **T3.1** `MarcarPresentaciónRealizada` (Organizador) → encola `replay`. → *UC-07.*
- **T3.2** ⚠️Q1 Adaptador `VideoTrackingPort` + `POST /webhooks/video` → `VideoVisto`. → *normaliza host elegido.*
- **T3.3** ⚠️Q1 Motor de segmentación → `ComportamientoSegmentado`; re-segmentación monótona + **cancelación de follow-ups obsoletos** (Q17). → *UC-08.*
- **T3.4** ⚠️Q1 Policies de follow-up (1/2/cta) + timeout→no_vio (Scheduler). → *UC-09, UC-10.*
- **T3.5** `PaymentPort` + `POST /webhooks/payment` → `PagoP60Recibido`; matching (token/fallback) → `ParticipanteConvertido` + `AtribuciónResuelta`. → *UC-11; sin match → bandeja.*
- **T3.6** Reembolso → `ParticipanteRevertido`. → *UC-12.*

*Paralelizable:* T3.1, T3.5/T3.6 avanzan sin Q1; T3.2→T3.3→T3.4 esperan Q1.

## Wave 4 — Operación interna + analítica  *(dep: Waves 1–3)*
- **T4.1** CRUD de cohortes + estado (Organizador). UI: `wireframes/dashboard-cohortes.html`. → *UC-14.*
- **T4.2** Reintentar acción / reenviar acceso (Ops). UI: salud + detalle. → *UC-15, UC-16, Q28.*
- **T4.3** Resolución manual de atribución / sin invitador. UI: `wireframes/dashboard-atribucion.html`. → *UC-17.*
- **T4.4** Baja / opt-out → `ParticipanteDadoDeBaja`, estado `BAJA`, freno de acciones. Detección desde WhatsApp ⚠️Q2. → *UC-18.*
- **T4.5** Read models + pantallas restantes (lista, detalle con timeline, salud). UI: `wireframes/dashboard-participantes/participante/salud.html`. → *invariante: no encolar a `BAJA`/`RECHAZADO`.*
- **T4.6** Formulario de experiencia/testimonio + `ExperienciaCompletada`. UI: `wireframes/experiencia.html`. → *UC-13.*

---

## DAG (resumen)
```
W0 ──> W1(skeleton) ──> W2
                   └──> W3 ── (vídeo: espera Q1)
W1,W2,W3 ──────────> W4
```
Dentro de cada wave hay paralelismo; entre waves hay dependencia de datos. Las pantallas ya están prototipadas en `wireframes/` y sirven de especificación visual.

## Fuera de MVP (registrado)
Comisiones, captura de datos financieros / portal del participante (Q42), export CSV, API oficial de WhatsApp, multi-tenant, event sourcing completo.
