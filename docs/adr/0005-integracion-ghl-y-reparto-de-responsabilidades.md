# ADR-0005 — Integración con GHL (GoHighLevel) y reparto de responsabilidades

- **Estado:** Propuesto — asume la integración con GHL (decisión de negocio en curso, ver Q53). Fija el reparto de responsabilidades y las fronteras. Pendientes: rol exacto de GHL (Q53), proveedor de WhatsApp (Q51), estrategia de número (Q52).
- **Fecha:** 2026-07-01
- **Origen:** call con Kley del 4-jun (PR #1 `docs/brief-kley-4jun`, handoff de Max), §3 C1/C2 y §6. Verificado contra la API/MCP real de GHL (ver Fundamento).

## Contexto

El handoff introdujo dos ideas en tensión con el diseño: (a) un stack "11ty + Wistia + Kapso + Zoom API" y (b) **GHL como "sistema base"**, frente a los ADR-0002/0003 (cerebro propio Next.js/Drizzle/Postgres + event log append-only como fuente de verdad). Ninguna call desambigua → decisión de negocio de Max/Jesús/Kley; el dev la enmarca.

Se decidió **integrar con GHL, no ser reemplazado por él**. GHL es un CRM contact-centric (contacto + campos custom + tags + pipelines + workflows) que es fuerte en comms 1:1 y edición por no-devs, y débil en lo diferencial de BeZy (cohortes, medición del replay por persona, dashboards a medida, grafo de atribución, event log).

## Decisión — quién es dueño de qué (system of record)

- **GHL = dueño del contacto (master data del participante) + comms 1:1 + adjuntos.** El hilo de conversación (mensajes enviados/recibidos, facturas/capturas que el usuario adjunta por WhatsApp) vive en GHL (Media Storage Center) y se consulta ahí; se recupera por API cuando haga falta.
- **Cerebro/DB propia = dueño del dominio:** la **cohorte** (entidad con estado borrador/activa/cerrada, capacidad, 1-grupo-semanal, ranking), el **vínculo** participante ↔ `ghlContactId`, el **event log** append-only (eventos de dominio: acciones enviadas por nosotros/automáticas, hitos del usuario), la **segmentación del replay**, el **grafo de atribución**, y los **dashboards** (interno + público).
- **Sincronización (evitar doble fuente de verdad):**
  - Principal, **una dirección**: el cerebro *empuja campos de display* a GHL (estado del reto, segmento, `% replay`, cohorte) vía **REST API v2** (custom fields), para que Ops trabaje en la card del contacto en GHL.
  - GHL → cerebro por **webhooks** (`ContactCreate`, `FormSubmitted`, `InboundMessage`, `OrderPlaced`, `ContactUpdate`…) cuando algo que pasa en GHL deba generar un evento de dominio / cálculo / métrica.
  - **No se duplica el texto de la conversación** (vive en GHL). Los adjuntos se recuperan por `GET message by ID` (el webhook *inbound* de WhatsApp **no** trae el adjunto; el GET sí).
- **Grupo de WhatsApp: fuera de GHL.** En MVP es **manual**. Kapso queda **diferido** hasta que su Groups API exista (Q48/Q51/Q52).

## Fundamento (verificado, no de memoria)

- **MCP oficial de GHL** (HTTP-based, *Private Integration token* + scopes): ~36 tools hoy (Contacts get/create/update/upsert + tags + tasks; Conversations search/get-messages/send; Opportunities; Calendars; Payments; Custom Fields **solo lectura** de definiciones). Escritura de campos → **REST API v2**. Roadmap 250+.
- **Cohorte:** GHL no tiene el concepto; lo más cercano es **custom field + Smart List** (vista dinámica filtrada). Sirve para *ver* los contactos de una cohorte, no para su lógica/estado/ranking → esa lógica queda en el cerebro.
- **Webhooks:** 50+ eventos, outbound e inbound. (Nota infra: `X-WH-Signature` se deprecia 2026-07-01 → verificar `X-GHL-Signature`, Ed25519.)
- **Adjuntos:** soportados (image|file|video) y guardados en el Media Storage Center; recuperables por API.
- **WhatsApp:** GHL 1:1 vía API oficial de Meta; **grupos no** (la Groups API oficial exige ~100k msgs/24h → impracticable). El número en la API oficial no puede además correr automatización no oficial de grupos.
- **Sin deadline duro** (input del dueño) → se prioriza control del núcleo diferencial sobre time-to-market.

## Consecuencias

- **Positivas:** no construimos CRM-UI ni bandeja de entrada 1:1; el equipo edita contenido/plantillas en GHL sin dev (cubre el requisito "máquina de creación" de Kley); el 1:1 usa canal oficial (menos ban-risk que Whapi).
- **Negativas / riesgos:** el contacto vive en dos lados (mitigado por sync unidireccional de display); dependencia de GHL (lock-in, coste recurrente, **línea roja BeZy≠LV**: la GHL de LV requiere acuerdo de coste — Q53); el proveedor de WhatsApp y la estrategia de número quedan por decidir (Q51/Q52).

## Alternativas descartadas

- **GHL como sistema de estado único:** no modela cohorte, segmentación del replay, dashboards a medida ni event log → insuficiente para el núcleo.
- **Cerebro puro sin GHL** (cerebro + Chatwoot/n8n para 1:1 + mini-editor de contenido): viable y sin lock-in, pero pierde la CRM-UI y la edición-por-equipo ya listas. Queda como **plan B "espejo"** si Max no justifica un trabajo concreto para GHL (Q53).

## Relación con otros ADRs

- **ADR-0002/0003 siguen vigentes** para el cerebro (event log + Next.js/TS/Drizzle/Postgres + hexagonal). GHL entra **detrás de un puerto** (mensajería/CRM), coherente con la arquitectura hexagonal.
- **11ty** queda, como mucho, como capa de landing estática; no reemplaza el cerebro.
