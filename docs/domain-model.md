# Reto Antiventaja — Modelo de dominio

> Estado: **Fase 2 — Modelado**. Autoritativo para entidades, estados, eventos, comandos y reglas.
> Deriva de `event-storming.md` y `mvp-scope.md`. Decisiones clave en `adr/`.
> Fecha: 2026-05-29

---

## 1. Lenguaje ubicuo (glosario)

Términos que código, docs y conversación con el cliente deben usar igual:

| Término | Definición |
|---|---|
| **Cohorte** | Edición del reto. Membresía **lógica** al programa. Se ingresa por aceptación de Ops. NO es el grupo de WhatsApp. |
| **Grupo de WhatsApp** | **Canal** de comunicación de una cohorte. Vive detrás del `MessagingPort`. No es entidad del core. |
| **Participante** | Persona inscripta a una cohorte. Tiene un estado en el ciclo de vida. |
| **Impulsor** | Quien invitó a un participante. Rol/entidad del grafo de atribución; no es actor activo en MVP. |
| **Token** | Identificador único y opaco por participante. Viaja en links de contenido/video/pago para resolver identidad. |
| **Atribución** | Relación "X fue invitado por Y". Capturada como texto crudo y resuelta a un impulsor concreto. |
| **Acción de salida** | Operación que el core ordena y la capa no-code ejecuta sobre WhatsApp (mensaje o gestión de grupo). |
| **Segmento** | Clasificación del comportamiento frente al replay: `no_vio` / `parcial` / `completo`. Atributo, no estado. |
| **Evento (de dominio)** | Hecho ocurrido, append-only en el event log; es la fuente de verdad del estado. |
| **Gate de verificación** | Paso humano (Ops) que acepta/rechaza un registro y otorga la membresía a la cohorte. |
| **Conversión** | El participante pagó el P60. |

---

## 2. Agregados y límites de consistencia

Tres agregados (📦); cada uno es una frontera transaccional:

- **Cohorte** — `{ id, name, start_date, timezone, presentation_at, status }`. Raíz de configuración del programa.
- **Participante** — raíz del ciclo de vida y de la atribución. Toda transición de estado y la resolución de atribución se aplican acá. Contiene/referencia su historial de eventos.
- **AcciónDeSalida** — la cola. Cada acción es consistente por sí misma; idempotente por `dedupe_key`. No comparte transacción con el Participante (se encola como efecto, se confirma async por ack).

> **Event log** transversal (append-only): los eventos de dominio se persisten y son la fuente de verdad; el estado del Participante es una proyección derivable de sus eventos. No es event sourcing completo (mantenemos estado materializado para queries simples — ver ADR pendiente sobre persistencia).

---

## 3. Entidades, value objects y enums

### Cohorte
`id, name, start_date, timezone, presentation_at (fecha fija de la presentación P60), status ∈ {borrador, activa, cerrada}`

### Participante
```
id, cohort_id, full_name, whatsapp_number (E.164), email?, token (único),
referred_by_raw (texto del formulario), referred_by_participant_id (nullable),
state (ver §4), segment (nullable, ver §4), current_day (nullable, día relativo del reto),
conversation_mode (autopilot|humano, default autopilot), conversation_paused_until? (cooldown del takeover, §10),
accepted_at?, joined_group_at?, converted_p60_at?, reverted_at?, opted_out_at?,
created_at
```

### AcciónDeSalida
```
id, participant_id, action_type (enum), params (jsonb), dedupe_key (único),
status ∈ {pendiente, enviada, fallida}, attempts, scheduled_for, sent_at?, fail_reason?
```

### Evento (event log)
`id, participant_id?, cohort_id?, type (enum, §5), payload (jsonb), occurred_at, source (form|ops|automatizador|video|psp|scheduler)`

### Enums (value objects cerrados)
- **ParticipantState**: `PENDIENTE_VERIFICACION | RECHAZADO | ACEPTADO | EN_GRUPO | POST_PRESENTACION | CONVERTIDO | REVERTIDO | BAJA` *(BAJA provisional — depende de Q2)*
- **ActionType** — familia **mensajes**: `bienvenida | contenido_diario | followup_1 | followup_2 | cta_final | recordatorio | respuesta_ia`; familia **gestión**: `alta_grupo` (ADR-0001). *(`respuesta_ia` = respuesta generada por el agente IA, no plantilla fija — §10.)*
- **ActionStatus**: `pendiente | enviada | fallida`.
- **Segment**: `no_vio | parcial | completo`.
- **ConversationMode**: `autopilot | humano` (modo del 1:1; atributo, no estado — §10).

---

## 4. Statechart del Participante

```
        (RegistrarParticipante)
                 │
                 ▼
      ┌───────────────────────┐
      │ PENDIENTE_VERIFICACION │
      └───────────────────────┘
         │ aceptado        │ rechazado
         ▼                 ▼
    ┌──────────┐      ┌───────────┐
    │ ACEPTADO │      │ RECHAZADO │ (terminal; re-aplica → Q9)
    └──────────┘      └───────────┘
         │ ParticipanteUnidoAlGrupo
         │ (si nunca entra → sub-estado ALTA_PENDIENTE, Q11)
         ▼
    ┌──────────┐
    │ EN_GRUPO │  atributo current_day: 0(precalentamiento)…7   ──► recibe bienvenida + contenido diario
    └──────────┘
         │ PresentaciónP60Realizada (cohorte) + replay enviado
         ▼
   ┌────────────────────┐
   │ POST_PRESENTACION   │  atributo segment ← ComportamientoSegmentado  ──► recibe followup_1/2/cta
   └────────────────────┘
         │ ParticipanteConvertido            (también alcanzable desde EN_GRUPO: compra directa, Q21)
         ▼
   ┌────────────┐   ParticipanteRevertido (reembolso)   ┌────────────┐
   │ CONVERTIDO │ ─────────────────────────────────────►│ REVERTIDO  │
   └────────────┘                                        └────────────┘

   Transversal: desde cualquier estado activo, ParticipanteDadoDeBaja → BAJA (frena toda acción). [provisional, Q2]
```

**Decisiones de modelado tomadas acá:**
- **`segment` y `current_day` son atributos, NO estados.** El lifecycle no se multiplica por día ni por segmento (mismo criterio que ADR-0001 para acciones).
- **CONVERTIDO es alcanzable desde EN_GRUPO o POST_PRESENTACION** (no obliga a pasar por segmentación; soporta compra directa).
- **EXPERIENCIA no es un estado**: `ExperienciaCompletada` se registra como evento/atributo; no bloquea el lifecycle.

---

## 5. Catálogo de eventos (17)

| Evento | Disparado por | Datos clave |
|---|---|---|
| ParticipanteRegistrado | RegistrarParticipante | datos del formulario |
| AtribuciónCapturada | RegistrarParticipante | referred_by_raw |
| ParticipanteAceptadoEnCohorte | VerificarRegistro (acepta) | ops_id |
| ParticipanteRechazado | VerificarRegistro (rechaza) | motivo? (Q8) |
| ParticipanteUnidoAlGrupo | RegistrarAltaAlGrupo | whatsapp_number, grupo |
| AcciónEncolada | EncolarAcciónDeSalida | action_type, params, dedupe_key |
| AcciónResuelta | ConfirmarAcciónEnviada | status, reason? |
| EncuestaRespondida | RegistrarRespuestaEncuesta | respuestas (persistidas, sin cálculo) |
| PresentaciónP60Realizada | MarcarPresentaciónRealizada | cohort_id |
| VideoVisto | RegistrarVideoVisto | token, percent_watched |
| ComportamientoSegmentado | policy (VideoVisto / timeout) | segment |
| PagoP60Recibido | RegistrarPagoP60 | referencia PSP |
| ParticipanteConvertido | policy (match pago) | participant_id |
| AtribuciónResuelta | policy (post-conversión) | impulsor_id |
| ExperienciaCompletada | RegistrarExperiencia | testimonio |
| ReembolsoP60Recibido | RegistrarReembolso | referencia PSP |
| ParticipanteRevertido | policy (reembolso) | participant_id |

*(Pendiente Q2: `ParticipanteDadoDeBaja`.)*

---

## 6. Comandos (22)
**Ciclo de vida del participante:** RegistrarParticipante · VerificarRegistro · RegistrarAltaAlGrupo · EncolarAcciónDeSalida · ConfirmarAcciónEnviada · EvaluarContenidoDelDía · EvaluarTimeoutReplay · RegistrarRespuestaEncuesta · MarcarPresentaciónRealizada · RegistrarVideoVisto · RegistrarPagoP60 · ResolverAtribución · RegistrarExperiencia · RegistrarReembolso.
**Operación interna (Ops / Organizador — ver `ui-audit.md` y Bloque G del event-storming):** CrearCohorte · ActualizarCohorte · CambiarEstadoCohorte · ReintentarAcción · ReenviarAcceso · ResolverAtribuciónManual · MarcarSinInvitador · DarDeBaja.

**Eventos de operación interna:** CohorteCreada · CohorteActualizada · CohorteEstadoCambiado · AtribuciónDescartada · ParticipanteDadoDeBaja (→ estado `BAJA`; resuelve el evento provisional de Q2). `ReintentarAcción` y `ReenviarAcceso` re-emiten `AcciónEncolada`.

## 7. Policies (12) — el "cerebro"
generar token · al aceptar→encolar `alta_grupo` · al unirse→encolar bienvenida · al unirse→programar contenido relativo · día N→encolar contenido · presentación→encolar replay · VideoVisto→segmentar · segmento→encolar follow-up · timeout→no_vio · match pago→convertir · post-conversión→resolver atribución · reembolso→revertir.

---

## 8. Invariantes y reglas de negocio

1. **Idempotencia de acciones**: nunca dos `AcciónDeSalida` con el mismo `dedupe_key`.
2. **Idempotencia de ingesta**: webhooks de entrada deduplicados por id del proveedor (Q26).
3. **Token único y estable** por participante; no cambia durante su ciclo de vida.
4. **`current_day` es relativo** al anclaje del participante (Q31) y acotado a 0..7.
5. **No se encola ninguna acción** para un participante en estado `BAJA` (Q2) ni `RECHAZADO`.
6. **Conversión** requiere matchear el pago a un participante; si no matchea → bandeja Ops (Q21).
7. **Re-segmentación monótona**: el segmento puede mejorar (no_vio→parcial→completo) con nuevos `VideoVisto`; al mejorar, se cancelan follow-ups encolados obsoletos (Q17).
8. **Atribución**: `referred_by_participant_id ≠ self` (Q5); el texto crudo siempre se preserva aunque no resuelva.

---

## 9. Zonas grises detectadas al modelar (→ registradas en `open-questions.md`)

Nuevas, surgidas al formalizar el modelo (Q31–Q36):
- **Q31 [DISEÑO]** Anclaje del "día N": ¿`joined_group_at`, `accepted_at` o `start_date` de cohorte? *Default propuesto: `joined_group_at`.*
- **Q32 [DISEÑO]** Eventos fuera de orden / webhooks tardíos (ej. `VideoVisto` antes de registrar el envío del replay). *Default: el estado se computa por reglas tolerantes al orden; acciones idempotentes.*
- **Q33 [DISEÑO]** Alcance de unicidad del `token`: global vs por cohorte. *Default: global.*
- **Q34 [DISEÑO]** `segment`/`current_day` como atributo y no estado. *Decidido acá; documentado.*
- **Q35 [DISEÑO]** Conversión directa sin segmentación (compra fuera del funnel). *Statechart ya lo permite; matching → Q21.*
- **Q36 [DISEÑO]** ¿La cola `AcciónDeSalida` es agregado independiente del Participante? *Default: sí, consistencia por `dedupe_key`, ack async.*
- **Persistencia**: definir si event log materializa estado o se reproyecta (candidato a ADR-0002).

---

## 10. Extensión — Agente IA 1:1 (guarded agent) — 2026-07-01

> Surge del handoff (§5a), Q56 (nivel = autopiloto con red) y Q58 (motor + takeover). Convierte al **Participante** en interlocutor **bidireccional**, reusando la maquinaria existente (cola de acciones, event log, idempotencia — criterio de ADR-0001).

### Glosario (añadidos)
- **Conversación 1:1** — hilo de WhatsApp directo IA/equipo ↔ participante. El hilo vive **detrás del `MessagingPort`** (como el grupo); el core solo materializa su **modo** y los eventos relevantes.
- **Modo de conversación** — `autopilot` (responde la IA) | `humano` (un operador la tomó). Atributo, no estado del lifecycle.
- **Agente IA (guarded)** — motor que interpreta el mensaje entrante y responde **dentro de un allow-list** de acciones/temas derivado del dominio del reto. Vive detrás del `AIAgentPort`.
- **Mensaje entrante** — mensaje del participante (texto o, a futuro, voz→STT, Q57).

### Atributos añadidos al Participante
`conversation_mode ∈ {autopilot, humano}` (default `autopilot`) · `conversation_paused_until?` (cooldown del takeover).

### Enum / puerto añadidos
- **ConversationMode**: `autopilot | humano`.
- **ActionType** suma `respuesta_ia` (familia mensajes): respuesta generada por el agente, **no** plantilla; reusa cola/idempotencia/ack.
- **`AIAgentPort` (4º puerto)**: el core pide *"dado el contexto del participante (día N, segmento, tareas, eventos) + el allow-list, generá una respuesta o escalá"*. Adaptador = **GHL Conversation AI** o **LLM propio** (Q58). Desacopla Q58 del dominio.

### Eventos (añadidos)
| Evento | Disparado por | Datos clave |
|---|---|---|
| MensajeEntranteDelParticipante | RegistrarMensajeEntrante (webhook 1:1) | texto, occurred_at |
| RespuestaIAGenerada | GenerarRespuestaIA (agente) | → AcciónEncolada(respuesta_ia) |
| ConversaciónIntervenida | TomarConversación (Ops) | modo=humano, paused_until |
| ConversaciónEscaladaAHumano | policy (baja confianza/off-topic/pedido) | motivo |
| ConversaciónDevueltaALaIA | DevolverConversaciónALaIA (Ops) | modo=autopilot |

### Comandos (añadidos)
RegistrarMensajeEntrante · GenerarRespuestaIA · TomarConversación · DevolverConversaciónALaIA · EscalarAHumano.

### Policies (añadidas) — el cerebro conversacional
- *MensajeEntranteDelParticipante + modo=autopilot + sin cooldown → GenerarRespuestaIA (dentro del allow-list); si off-topic/baja confianza → fallback o EscalarAHumano.*
- *Humano toma/envía en la conversación → modo=humano + cooldown (**pausa-al-intervenir**).*
- *Antes de enviar una `respuesta_ia` encolada: si el modo pasó a humano o llegó un entrante más nuevo → **cancelar la respuesta obsoleta*** (reusa la cancelación monótona de Q17).
- *Cooldown vencido → volver a autopilot* (default; ver Q59).

### Invariantes (añadidas)
- **Allow-list:** el agente solo emite acciones/temas del allow-list; nada fuera del menú del reto.
- **No responde** en `BAJA` / `RECHAZADO` / cooldown activo (extiende el invariante 5).
- **Pausa-al-intervenir:** una intervención humana suprime la IA en esa conversación hasta reanudar.
- **Cancelación de respuesta obsoleta:** una `respuesta_ia` encolada se cancela si el estado de la conversación la superó (modo o mensaje más nuevo).

### Zonas grises (→ `open-questions.md` Q59/Q60)
- **Q59 [DISEÑO]** Conversación como atributos del Participante (default, lean) vs agregado propio (si el agente crece: historial/múltiples hilos); y si el cooldown auto-reanuda a autopilot o requiere acción humana.
- **Q60 [DISEÑO]** `AIAgentPort` como 4º puerto y **latencia**: la cola actual es *pull* (`GET /actions/pending`); el chat quiere baja latencia → `respuesta_ia` por camino **push/inmediato**, o (si Q58=GHL) GHL envía y no pasa por nuestra cola.

---

## 11. Extensión — Prueba social (resultados tipados + evidencia) — 2026-07-01

> Surge del handoff §3-C4 / §5a (Kley 4-jun): reemplaza el **texto libre** (con el que "la gente se liaba") por un **form tipado** + **evidencia archivada**. Se modelan **captura** y **moderación**; la **exhibición pública** (dashboard) es una superficie aparte (Q61) que se alimenta de un read-model.

### Glosario (añadidos)
- **Resultado (prueba social)** — logro monetario auto-reportado por un participante (ahorro/generado), con monto **tipado** + evidencia. Un participante puede tener varios.
- **Evidencia** — adjunto (factura/captura) que respalda un resultado. Vive en **almacenamiento de objetos** (concreto → ADR-0004: S3 vs **Cloudflare R2**) o, si llegó por WhatsApp, en GHL (referenciado, no duplicado).
- **Moderación** — gate de Ops: un resultado no es público hasta ser **aprobado**; puede **ocultarse/despublicarse** aun estando live.

### Entidad `Resultado` (nuevo agregado)
```
id, participant_id, categoria (enum), monto, moneda, tipo (recuperado|ganado),
descripcion?, evidencias[] (refs a objetos/GHL),
estado (pendiente|aprobada|rechazada|oculta),
source (form|whatsapp|agente), captured_at, moderated_by?, moderated_at?
```

### Enums (añadidos)
- **ResultadoEstado**: `pendiente | aprobada | rechazada | oculta`.
- **ResultadoTipo**: `recuperado | ganado` (para que el dashboard sume bien).
- **ResultadoCategoria**: [CLIENTE] taxonomía — seed `ahorro_suscripciones | factura_luz | venta_wallapop | otro` (Q62). Cada categoría mapea a un `tipo`.

### Eventos (añadidos)
| Evento | Disparado por | Datos |
|---|---|---|
| ResultadoRegistrado | RegistrarResultado (participante/form) | categoria, monto, evidencias |
| ResultadoAprobado | AprobarResultado (Ops) | moderated_by |
| ResultadoRechazado | RechazarResultado (Ops) | motivo? |
| ResultadoOcultado | OcultarResultado (Ops) | despublica uno live |

### Comandos (añadidos)
RegistrarResultado · AprobarResultado · RechazarResultado · OcultarResultado.

### Policies / invariantes (añadidas)
- **Moderación previa:** solo un resultado `aprobada` (y no `oculta`) alimenta el read-model del **dashboard público** (Q61). **Nada público sin aprobación.**
- **Consentimiento** para la exhibición pública (Q61, cruza Q25).
- **Evidencia** en almacenamiento de objetos abstracto (concreto → ADR-0004); adjuntos de WhatsApp quedan en GHL y se **referencian**.
- **Captura:** default **form propio** (link 1:1); a futuro, el **agente IA** (§10) puede capturarlo conversacionalmente.

### Zonas grises (→ `open-questions.md`)
- **Q61 [CLIENTE]** Dashboard público: mecánica de acceso/alcance + consentimiento (defaults-para-aprobar).
- **Q62 [CLIENTE]** Taxonomía de categorías (seed propuesto).

---

## 12. Extensión — Detección de inacción + reprogramación — 2026-07-01

> Surge del handoff §5a (Kley): alertar por **inacción** del participante (no solo por acción **fallida**, Q28) y **reprogramar** a quien no actuó. Los umbrales/reglas concretos son negocio (Q45/Q41); el motor ejecuta lo que definan.

### Glosario (añadidos)
- **Inacción** — el participante no hizo algo esperado para su día/deadline (no vio contenido, no asistió al directo, no vio el replay, no envió factura, no respondió). Se **deriva** de las señales existentes (Q41 + tracking Q54/Q55); no es un estado del lifecycle.
- **Reprogramación** — ofrecer otra oportunidad y re-enviar el paso perdido, **corriendo el día relativo** del participante sin mover la presentación fija de la cohorte.

### Enum (añadido)
- **TipoInaccion**: `no_vio_contenido | no_asistio_directo | no_vio_replay | no_envio_factura | no_respondio`.

### Eventos (añadidos)
| Evento | Disparado por | Datos |
|---|---|---|
| InacciónDetectada | EvaluarInacción (scheduler) | tipo, día |
| AlertaInacciónEmitida | policy (inacción) | destino (ops/agente) |
| ReprogramaciónOfrecida | OfrecerReprogramación | día objetivo |
| ReprogramaciónResuelta | RegistrarRespuestaReprogramación | aceptada\|rechazada |

### Comandos (añadidos)
EvaluarInacción (scheduler) · AlertarInacción · OfrecerReprogramación · RegistrarRespuestaReprogramación.

### Policies (añadidas)
- *Scheduler: `EvaluarInacción` por participante → si lo esperado no se cumplió al umbral (Q45/Q41) → `InacciónDetectada`.*
- *Cuando `InacciónDetectada` → `AlertarInacción` (bandeja Ops y/o agente IA "poner caña") y, según regla, `OfrecerReprogramación`.*
- *Cuando `ReprogramaciónResuelta(aceptada)` → re-encolar el paso perdido y correr el `current_day` del participante; la presentación de la cohorte NO se mueve.*
- **No** se evalúa inacción para `BAJA` / `RECHAZADO` (extiende el invariante 5).

### Zonas grises
- **[CLIENTE]** Umbrales/reglas de inacción y cadencia de re-intento = **Q45/Q41** (negocio).
- **[DISEÑO]** Reprogramar corre el `current_day` (relaciona Q31 anclaje). *Default adoptado.*
- **[DISEÑO]** Destino de alerta: Ops + opción agente. *Default adoptado.*
