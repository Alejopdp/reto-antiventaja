# Casos de uso — criterios de aceptación

> Cada caso: **actor**, **Given/When/Then** y notas. Cruza con `domain-model.md` (comandos/eventos) y `contracts/`. "(Q#)" remite a dudas abiertas.
> Estado: diseño (no implementado).

## Adquisición

### UC-01 — Registro (Participante)
- **Given** una persona con el link del reto **When** envía el formulario con datos válidos y consentimiento **Then** se crea el participante en `PENDIENTE_VERIFICACION`, se genera su `token` y se registran `ParticipanteRegistrado` + `AtribuciónCapturada` (texto crudo).
- *Edge:* móvil duplicado en la cohorte → no se crea otro; se actualiza (Q6). Sin consentimiento → no se envía (validación). Falta "quién te invitó" → ver Q39.

### UC-02 — Aceptar en cohorte (Ops)
- **Given** un registro en `PENDIENTE_VERIFICACION` **When** Ops lo acepta **Then** `ParticipanteAceptadoEnCohorte`, pasa a `ACEPTADO` y se encola `alta_grupo`.
- *Edge:* aceptación en lote → una transición por participante, idempotente.

### UC-03 — Rechazar registro (Ops)
- **Given** un registro pendiente **When** Ops lo rechaza con motivo **Then** `ParticipanteRechazado`, estado `RECHAZADO`; no se encola ninguna acción. (¿Notificación / re-aplicar? Q9.)

### UC-04 — Alta al grupo y bienvenida (Automatizador / policy)
- **Given** un participante `ACEPTADO` con `alta_grupo` encolada **When** el automatizador da el alta y confirma `group-join` **Then** `ParticipanteUnidoAlGrupo`, estado `EN_GRUPO`, se programa el contenido relativo y se encola `bienvenida`.
- *Edge:* aceptado que nunca entra → reintento N veces, luego `ALTA_PENDIENTE` para Ops (Q11).

## Activación

### UC-05 — Contenido diario relativo (Scheduler)
- **Given** un participante `EN_GRUPO` anclado en `joinedGroupAt` (Q31) **When** corresponde su día N (0..7) **Then** se encola `contenido_diario {day:N}` con `dedupeKey = participante:díaN` (no se reenvía).
- *Edge:* alta tardía → empieza en su día 1 relativo (Q14). Zona horaria (Q15).

### UC-06 — Respuesta a encuesta (Participante)
- **Given** una dinámica enviada **When** el participante responde **Then** `EncuestaRespondida` se persiste. Sin cálculo/segmentación en MVP (H10).

## Conversión

### UC-07 — Presentación P60 (Organizador)
- **Given** una cohorte activa **When** el organizador marca la presentación realizada **Then** `PresentaciónP60Realizada` y se encola el `replay` a los destinatarios.

### UC-08 — Visionado del replay y segmentación (Host de vídeo) ⚠️ Q1
- **Given** un replay entregado 1:1 con `token` **When** llega `VideoVisto{percentWatched}` **Then** `ComportamientoSegmentado` con `no_vio | parcial(<80%) | completo(>80%)` (umbral Q20).
- *Edge:* re-visionado que mejora el segmento → re-segmenta al máximo alcanzado y **cancela follow-ups encolados obsoletos** (Q17). Visionado con token ajeno → ruido aceptado (Q18).

### UC-09 — Follow-up por segmento (policy)
- **Given** un `ComportamientoSegmentado` **When** se evalúa **Then** se encola `followup_1` (no_vio) / `followup_2` (parcial) / `cta_final` (completo), idempotente por segmento.

### UC-10 — Timeout del replay (Scheduler)
- **Given** un replay enviado hace > X horas **When** no hubo `VideoVisto` **Then** se trata como `no_vio` y se encola `followup_1` (ventana Q20).

### UC-11 — Pago P60 y atribución (PSP / policy)
- **Given** un participante en el embudo **When** llega `PagoP60Recibido` y matchea (token o fallback) **Then** `ParticipanteConvertido` (estado `CONVERTIDO`) y `AtribuciónResuelta` al impulsor.
- *Edge:* pago sin participante (compra fuera del funnel) → bandeja Ops (Q21). Pago duplicado → idempotente por `reference` (Q23). Cuotas (Q22) / moneda (Q24).

### UC-12 — Reembolso (PSP / policy)
- **Given** un participante `CONVERTIDO` **When** llega `ReembolsoP60Recibido` **Then** `ParticipanteRevertido` a no-convertido. Sin lógica de comisión (fuera de MVP).

## Cierre

### UC-13 — Experiencia / testimonio (Participante)
- **Given** un participante al terminar el reto **When** completa el formulario **Then** `ExperienciaCompletada` (con consentimiento de uso, Q25). No bloquea el lifecycle.

## Operación interna (Ops / Organizador) — ver Bloque G

### UC-14 — Gestionar cohortes (Organizador)
- **When** crea / edita / cambia el estado de una cohorte **Then** `CohorteCreada` / `CohorteActualizada` / `CohorteEstadoCambiado` (borrador→activa→cerrada). El estado condiciona qué cohorte recibe altas y contenido.

### UC-15 — Reintentar acción fallida (Ops)
- **Given** una `AcciónResuelta(fallida)` **When** Ops reintenta **Then** se re-encola la misma acción (nuevo intento), respetando idempotencia de propósito (Q28).

### UC-16 — Reenviar acceso (Ops)
- **Given** un participante que no recibió/entró **When** Ops reenvía el acceso **Then** se encola `alta_grupo`/`bienvenida` de nuevo.

### UC-17 — Resolver atribución manual (Ops)
- **Given** un participante con atribución sin resolver **When** Ops asigna un impulsor **Then** `AtribuciónResuelta`; **o** la marca sin invitador **Then** `AtribuciónDescartada` (Q4).

### UC-18 — Baja / opt-out (Ops o Participante) ⚠️ Q2
- **Given** un participante activo **When** pide la baja (palabra clave por WhatsApp o acción de Ops) **Then** `ParticipanteDadoDeBaja`, estado `BAJA`; **no se encola ninguna acción futura**. (Mecanismo de detección desde WhatsApp: Q2.)

---

## Nuevos (surgidos de la call 4-jun / decisiones 2026-07-01)

### UC-19 — Conversación 1:1 con IA (Participante ↔ Agente)
- **Given** una conversación en modo `autopilot` **When** el participante envía un mensaje **Then** el agente (guarded) interpreta y responde **dentro del allow-list**; si off-topic/baja confianza → fallback o escala. (`domain-model §10`; motor por Q58.)

### UC-20 — Intervención humana / takeover (Ops)
- **Given** una conversación en `autopilot` **When** Ops la toma (o responde) **Then** modo `humano` + cooldown; la IA se pausa y se cancela la respuesta IA encolada obsoleta (Q17). **When** Ops la devuelve **Then** vuelve a `autopilot`.

### UC-21 — Registrar prueba social (Participante)
- **Given** un participante con un logro **When** completa el form tipado (categoría + monto + evidencia) **Then** `ResultadoRegistrado` en estado `pendiente` (§11). *Edge:* evidencia por WhatsApp → queda en GHL, referenciada.

### UC-22 — Moderar prueba social (Ops)
- **Given** un `Resultado` `pendiente` **When** Ops aprueba/rechaza **Then** `ResultadoAprobado`/`ResultadoRechazado`; **solo aprobados** alimentan el dashboard público. **When** Ops oculta uno live **Then** `ResultadoOcultado`.

### UC-23 — Alerta por inacción (Scheduler → Ops/Agente)
- **Given** un participante activo **When** no cumple lo esperado al umbral (Q45/Q41) **Then** `InacciónDetectada{tipo}` → alerta a Ops y/o al agente para intervenir ("poner caña").

### UC-24 — Reprogramación (Ops/Agente ↔ Participante)
- **Given** una inacción detectada **When** se ofrece otra oportunidad y el participante responde **Then** `ReprogramaciónResuelta{aceptada|rechazada}`; si acepta → re-encola el paso perdido y corre su día relativo (la presentación fija no se mueve).

### UC-25 — Medición de asistencia al directo en vivo (Zoom)
- **Given** un directo con registro por participante (link único) **When** entra/sale **Then** `LiveAttendance{joinedAt, leftAt, duración}` atado al token → alimenta la segmentación y decide a quién enviar el replay (ADR-0006, Q54).

### UC-26 — Ver el dashboard público (Visitante / Participante)
- **Given** resultados aprobados **When** alguien abre el dashboard público **Then** ve totales recuperado/ganado + ranking (nombre de pila / anónimo). *(Naturaleza —dashboard vs landing, con/sin login— y acceso: Q61.)*

---

## Cambios funcionales en UCs existentes (2026-07-01)
- **UC-01** además hace *upsert* del **contacto en GHL** (si va GHL, Q53).
- **UC-02/03** la verificación de Ops puede ocurrir **en GHL** (mover etapa → capturada por webhook → guardada en nuestra DB) o en **pantalla propia** (Q64).
- **UC-04** en MVP el **alta al grupo es manual** (Kapso diferido); el 1:1 de bienvenida sí automático.
- **UC-05** el contenido **al grupo** se publica **manual** (no hay API compliant de grupos): el sistema **compone** el mensaje del día y Ops lo pega (**botón copiar**; deep-link a grupo con texto no es viable — Q63). El contenido/seguimiento **1:1** sí automatizado.
- **UC-08** el visionado se mide con **nuestra página tokenizada** (no el webhook del host) y suma **asistencia al directo** (ADR-0006).
