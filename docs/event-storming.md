# Reto Antiventaja — Event Storming (lite)

> Estado: **Fase 2 — Modelado funcional**. Centro del diseño: deriva en `domain-model.md`, `contracts/`, `use-cases.md` y `tasks.md`.
> Fecha: 2026-05-29
> Alcance: el flujo de dominio del MVP (ver `mvp-scope.md`). Single-tenant, canal-agnóstico (hexagonal).

## Leyenda (Event Storming lite)

| Símbolo | Categoría | Qué es |
|---|---|---|
| 🟧 | **Evento de dominio** | algo relevante que ocurrió (en pasado). Va al event log. |
| 🟦 | **Comando** | intención de que algo pase (en imperativo). Lo dispara un actor o una policy. |
| 🟨 | **Actor** | quién dispara el comando. |
| 🟪 | **Policy / política de negocio** | regla reactiva: *"cuando ocurre 🟧, entonces 🟦"*. |
| 🟥 | **Hotspot / riesgo / duda** | lo que NO está resuelto. Decisión pendiente. |
| 🩷 | **Sistema externo** | vive afuera del core, detrás de un puerto. |
| 📦 | **Agregado** | a quién pertenece la consistencia (dónde se aplican las reglas). |

Actores 🟨: **Participante**, **Ops**, **Organizador**, **Scheduler** (reloj del sistema), **Agente IA** (automático, guarded — Bloque H).
Sistemas externos 🩷 (detrás de un puerto): **Automatizador de grupos WhatsApp** (`MessagingPort`), **Host de video** (`VideoTrackingPort`), **Procesador de pago / PSP** (`PaymentPort`), **Motor de IA conversacional** (`AIAgentPort` — GHL Conversation AI o LLM propio, Q58), **STT / transcripción** (notas de voz, futuro — Q57).
Agregados 📦: **Participante** (su estado), **Cohorte**, **AcciónDeSalida** (la cola).

> **Notas de clasificación:**
> - El **Impulsor** NO es actor activo en el MVP (no dispara comandos): la invitación ocurre fuera del sistema (comparte un link). Es un **rol/entidad del grafo de atribución** — aparece como dato en `AtribuciónCapturada` y como destino de `AtribuciónResuelta`.
> - El **Formulario** propio NO es sistema externo: es un **adaptador primario (driving)** que escribe directo al core; no vive detrás de un puerto.

> ⚠️ **Distinción de dominio clave: Cohorte ≠ Grupo de WhatsApp.**
> - **Cohorte** = la membresía lógica al programa (la edición del reto). Se ingresa por **aceptación de Ops** tras verificar el formulario → es un *gate humano*. Es un agregado del core.
> - **Grupo de WhatsApp** = solo el **canal** de comunicación (vive detrás del `MessagingPort`, no es agregado). El alta al grupo es *consecuencia* de la aceptación en la cohorte, no la misma cosa.
> Un participante primero es **aceptado en la cohorte** y recién después se lo **agrega a un grupo**.

---

## Línea de tiempo (comando → evento → policy)

### Bloque A — Registro, verificación (gate humano) y alta al grupo

> Recordar: **aceptación en cohorte** (paso de Ops) y **alta al grupo** (canal) son dos cosas distintas.

- 🟨 Participante → 🟦 `RegistrarParticipante` (con datos + "quién me invitó", vía el link→formulario)
  → 🟧 **ParticipanteRegistrado** + 🟧 **AtribuciónCapturada** (texto crudo del referente)
  → 🟪 *Cuando ParticipanteRegistrado: generar `token` único y persistir; queda en estado `PENDIENTE_VERIFICACIÓN`.*
- 🟨 **Ops** → 🟦 `VerificarRegistro` (revisa las respuestas del formulario)
  - acepta → 🟧 **ParticipanteAceptadoEnCohorte** *(gate humano que da la membresía a la cohorte)*
  - rechaza → 🟧 **ParticipanteRechazado**
  → 🟪 *Cuando ParticipanteAceptadoEnCohorte: encolar acción `alta_grupo` (gestión de grupo vía `MessagingPort`, NO un mensaje).* → 🟧 **AcciónEncolada(alta_grupo)**
- 🩷 Automatizador → 🟦 `RegistrarAltaAlGrupo` (el número efectivamente se unió al grupo)
  → 🟧 **ParticipanteUnidoAlGrupo**
  → 🟪 *Cuando ParticipanteUnidoAlGrupo: matchear número↔participante y encolar Bienvenida.*
- 🟪 → 🟦 `EncolarAcciónDeSalida(bienvenida)` → 🟧 **AcciónEncolada(bienvenida)**
- 🩷 Automatizador → 🟦 `ConfirmarAcciónEnviada(ack)` → 🟧 **AcciónResuelta** `{ status: enviada | fallida, reason? }`

### Bloque B — Precalentamiento y Reto de 7 días

- 🟪 *Cuando ParticipanteUnidoAlGrupo: programar contenido relativo (día 0 precalentamiento … día 7).*
- 🟨 Scheduler → 🟦 `EvaluarContenidoDelDía(participante)` por cada participante activo
  → si corresponde el día N → 🟧 **AcciónEncolada(contenido_día_N)** (idempotente por `dedupe_key = participante:díaN`)
- 🟨 Participante → 🟦 `RegistrarRespuestaEncuesta` → 🟧 **EncuestaRespondida** *(se almacena como evento; SIN cálculo/segmentación en MVP — ver H10)*

### Bloque C — Presentación P60 y replay

- 🟨 Organizador → 🟦 `MarcarPresentaciónRealizada(cohorte, domingo)` → 🟧 **PresentaciónP60Realizada**
  → 🟪 *Cuando PresentaciónP60Realizada: encolar Replay+paso-a-paso a quienes no asistieron (y/o a todos).*
- 🩷 Host de video → 🟦 `RegistrarVideoVisto(token, % visto)` → 🟧 **VideoVisto**

### Bloque D — Follow-up segmentado (el motor)

- 🟪 *Cuando VideoVisto: segmentar comportamiento.*
  → 🟧 **ComportamientoSegmentado(no_vio | parcial<80% | completo>80%)**
- 🟪 según segmento:
  - no_vio → 🟦 `EncolarAcciónDeSalida(followup_1)`
  - parcial → 🟦 `EncolarAcciónDeSalida(followup_2)`
  - completo → 🟦 `EncolarAcciónDeSalida(cta_final)`
  → 🟧 **AcciónEncolada(...)** (idempotente por `dedupe_key = participante:segmento`)
- 🟨 Scheduler → 🟦 `EvaluarTimeoutReplay(participante)`
  → 🟪 *Si no hubo `VideoVisto` en X horas tras el envío del replay: emitir `ComportamientoSegmentado(no_vio)` y encolar followup_1.* (timeout)

### Bloque E — Conversión y atribución

- 🩷 PSP → 🟦 `RegistrarPagoP60(referencia)` → 🟧 **PagoP60Recibido**
  → 🟪 *Cuando PagoP60Recibido: matchear pago↔participante, marcar convertido.*
  → 🟧 **ParticipanteConvertido**
  → 🟪 *Cuando ParticipanteConvertido: resolver atribución (linkear impulsor).* → 🟧 **AtribuciónResuelta**
  → 🟪 *(FUERA DE MVP) Cuando AtribuciónResuelta: calcular comisión.*
- 🩷 PSP → 🟦 `RegistrarReembolso(referencia)` → 🟧 **ReembolsoP60Recibido**
  → 🟪 *Cuando ReembolsoP60Recibido: revertir el estado del participante a no-convertido.* → 🟧 **ParticipanteRevertido** *(sin lógica de comisión — fuera de MVP)*

### Bloque F — Experiencia / cierre

- 🟨 Participante → 🟦 `RegistrarExperiencia` → 🟧 **ExperienciaCompletada**
- (Analítica: read models del embudo y de atribución se actualizan con cada 🟧.)

### Bloque G — Operación interna (Ops / Organizador) — *surgido de los wireframes (ui-audit.md)*

> El event-storming original modelaba solo el ciclo de vida del participante. El panel interno destapó comandos de **operación** ejecutados por Ops y Organizador. Esto confirma a ambos como **actores activos** del core.

- 🟨 **Organizador** → 🟦 `CrearCohorte` → 🟧 **CohorteCreada**
- 🟨 **Organizador** → 🟦 `ActualizarCohorte` → 🟧 **CohorteActualizada**
- 🟨 **Organizador** → 🟦 `CambiarEstadoCohorte` (borrador→activa→cerrada) → 🟧 **CohorteEstadoCambiado**
- 🟨 **Ops** → 🟦 `ReintentarAcción` (sobre una `AcciónResuelta(fallida)`) → 🟧 **AcciónEncolada** (reintento; relaciona Q28)
- 🟨 **Ops** → 🟦 `ReenviarAcceso` → 🟧 **AcciónEncolada(alta_grupo/bienvenida)**
- 🟨 **Ops** → 🟦 `ResolverAtribuciónManual` (desde la bandeja de sin-atribuir) → 🟧 **AtribuciónResuelta**
- 🟨 **Ops** → 🟦 `MarcarSinInvitador` → 🟧 **AtribuciónDescartada**
- 🟨 **Ops/Participante** → 🟦 `DarDeBaja` → 🟧 **ParticipanteDadoDeBaja** (resuelve el evento provisional de Q2)
  → 🟪 *Cuando ParticipanteDadoDeBaja: no encolar ninguna acción futura (estado `BAJA`).*

### Bloque H — Conversación 1:1 con IA (guarded) + takeover — *surgido del handoff §5a / Q56 / Q58*

> Convierte al Participante en interlocutor **bidireccional**. Reusa la cola (`respuesta_ia`) y el event log. El motor concreto (GHL Conversation AI o LLM propio) vive detrás del `AIAgentPort` (Q58).

- 🟨 Participante → 🟦 `RegistrarMensajeEntrante` (webhook de mensajería 1:1) → 🟧 **MensajeEntranteDelParticipante**
  → 🟪 *Cuando MensajeEntranteDelParticipante y modo=autopilot y sin cooldown: `GenerarRespuestaIA` dentro del allow-list; si off-topic/baja confianza → fallback o escalar.*
- 🟨 **Agente IA** → 🟦 `GenerarRespuestaIA` → 🟧 **RespuestaIAGenerada** → 🟦 `EncolarAcciónDeSalida(respuesta_ia)` → 🟧 **AcciónEncolada(respuesta_ia)**
  → 🟪 *Antes de enviar: si modo=humano o hay un entrante más nuevo → cancelar la respuesta obsoleta (Q17).*
- 🟨 **Ops** → 🟦 `TomarConversación` → 🟧 **ConversaciónIntervenida** (modo=humano + cooldown)
  → 🟪 *pausa-al-intervenir: no se generan respuestas IA mientras modo=humano / cooldown activo.*
- 🟪 *IA con baja confianza / off-topic / "quiero una persona"* → 🟦 `EscalarAHumano` → 🟧 **ConversaciónEscaladaAHumano** (modo=humano + alerta a Ops)
- 🟨 **Ops** → 🟦 `DevolverConversaciónALaIA` → 🟧 **ConversaciónDevueltaALaIA** (modo=autopilot)

> 🟥 **Q58** (dónde corre la IA + superficie de takeover), **Q59/Q60** (Conversación atributo vs agregado; `AIAgentPort` 4º puerto + latencia push/pull) quedan abiertas.

### Bloque I — Prueba social (resultados tipados + moderación) — *handoff §3-C4 / §5a*

> Reemplaza el texto libre (con el que "la gente se liaba") por un form tipado + evidencia. La **captura y moderación** son del core; la **exhibición pública** es un read-model (Q61).

- 🟨 Participante → 🟦 `RegistrarResultado` (form tipado propio; evidencia por upload o WhatsApp) → 🟧 **ResultadoRegistrado** (estado `pendiente`)
- 🟨 **Ops** → 🟦 `AprobarResultado` → 🟧 **ResultadoAprobado** (pasa a público)
  - o 🟦 `RechazarResultado` → 🟧 **ResultadoRechazado**
- 🟨 **Ops** → 🟦 `OcultarResultado` (despublicar uno ya live) → 🟧 **ResultadoOcultado**
- 🟪 *Solo `aprobada` y no `oculta` alimenta el dashboard público (read-model); nada público sin moderación.*

> 🩷 Nuevo sistema externo: **Almacenamiento de objetos** (evidencia) — concreto en ADR-0004 (S3 vs Cloudflare R2). 🟥 **Q61** (dashboard público: mecánica + consentimiento), **Q62** (taxonomía de categorías) quedan abiertas.

### Bloque J — Inacción + reprogramación — *handoff §5a*

> Amplía las alertas: hoy solo se avisa por acción **fallida** (Q28); ahora también por **inacción del participante**. Umbrales/reglas = negocio (Q45/Q41).

- 🟨 Scheduler → 🟦 `EvaluarInacción(participante)` → si lo esperado no se cumplió al umbral (Q45/Q41) → 🟧 **InacciónDetectada** `{tipo}`
  → 🟪 *Cuando InacciónDetectada: `AlertarInacción` (bandeja Ops y/o agente IA "poner caña") y, según regla, `OfrecerReprogramación`.*
- 🟨 **Ops / Agente IA** → 🟦 `OfrecerReprogramación` → 🟧 **ReprogramaciónOfrecida**
- 🟨 Participante → 🟦 `RegistrarRespuestaReprogramación` → 🟧 **ReprogramaciónResuelta** `{aceptada|rechazada}`
  → 🟪 *Si aceptada: re-encolar el paso perdido y correr el día relativo del participante (la presentación fija de la cohorte no se mueve).*

---

## Resumen de elementos

**Eventos de dominio 🟧 (22):** ParticipanteRegistrado, AtribuciónCapturada, ParticipanteAceptadoEnCohorte, ParticipanteRechazado, ParticipanteUnidoAlGrupo, **AcciónEncolada** `{ action_type, params, dedupe_key }`, **AcciónResuelta** `{ status: enviada \| fallida, reason? }`, EncuestaRespondida, PresentaciónP60Realizada, VideoVisto, ComportamientoSegmentado, PagoP60Recibido, ParticipanteConvertido, AtribuciónResuelta, ExperienciaCompletada, ReembolsoP60Recibido, ParticipanteRevertido, **CohorteCreada**, **CohorteActualizada**, **CohorteEstadoCambiado**, **AtribuciónDescartada**, **ParticipanteDadoDeBaja** *(+ operación interna, Bloque G)*.

> **Acciones de salida = evento abstracto tipado** (ver ADR-0001). `action_type` tiene dos familias: **mensajes** `{ bienvenida, contenido_diario, followup_1, followup_2, cta_final, [recordatorio] }` y **gestión de grupo** `{ alta_grupo }` — ambas reusan la misma cola/maquinaria (idempotencia, throttling, retry, ack). El día va en `params: { day: N }`, NO en el tipo de evento. No se modelan eventos por tipo (`BienvenidaEnviada`, etc.).

**Comandos 🟦 (22):** RegistrarParticipante, VerificarRegistro (aceptar/rechazar), RegistrarAltaAlGrupo, EncolarAcciónDeSalida, ConfirmarAcciónEnviada, EvaluarContenidoDelDía, EvaluarTimeoutReplay, RegistrarRespuestaEncuesta, MarcarPresentaciónRealizada, RegistrarVideoVisto, RegistrarPagoP60, ResolverAtribución, RegistrarExperiencia, RegistrarReembolso, **CrearCohorte**, **ActualizarCohorte**, **CambiarEstadoCohorte**, **ReintentarAcción**, **ReenviarAcceso**, **ResolverAtribuciónManual**, **MarcarSinInvitador**, **DarDeBaja**.

**Policies 🟪 (el "cerebro") (12):** generar token; **al aceptar en cohorte → encolar `alta_grupo`**; matchear alta y encolar bienvenida; programar contenido relativo; encolar contenido del día N; **al realizarse la presentación → encolar replay**; segmentar por video; encolar follow-up por segmento; timeout→no_vio; matchear pago y convertir; resolver atribución; **al recibir reembolso → revertir estado**.

**+ Bloque H — Agente IA 1:1 (2026-07-01):** eventos `MensajeEntranteDelParticipante`, `RespuestaIAGenerada`, `ConversaciónIntervenida`, `ConversaciónEscaladaAHumano`, `ConversaciónDevueltaALaIA`; comandos `RegistrarMensajeEntrante`, `GenerarRespuestaIA`, `TomarConversación`, `DevolverConversaciónALaIA`, `EscalarAHumano`; `ActionType` suma `respuesta_ia`; puerto `AIAgentPort` (4º). Detalle en `domain-model.md §10`.

**+ Bloque I — Prueba social (2026-07-01):** eventos `ResultadoRegistrado`, `ResultadoAprobado`, `ResultadoRechazado`, `ResultadoOcultado`; comandos `RegistrarResultado`, `AprobarResultado`, `RechazarResultado`, `OcultarResultado`; nuevo agregado `Resultado`; sistema externo **Almacenamiento de objetos**. Detalle en `domain-model.md §11`.

**+ Bloque J — Inacción + reprogramación (2026-07-01):** eventos `InacciónDetectada`, `AlertaInacciónEmitida`, `ReprogramaciónOfrecida`, `ReprogramaciónResuelta`; comandos `EvaluarInacción`, `AlertarInacción`, `OfrecerReprogramación`, `RegistrarRespuestaReprogramación`; enum `TipoInaccion`. Detalle en `domain-model.md §12`.

---

## 🟥 Hotspots / Riesgos / Dudas abiertas (lo que decidimos juntos)

> Estas son las decisiones que aún NO tomé. Cada una propone un default razonable para no frenar; marcá las que quieras cambiar.

**H1 — Identidad: número del formulario ↔ número que se une al grupo.**
Default propuesto: normalizar a E.164 y matchear por número; si no matchea, queda en bandeja "sin resolver" para Ops. *¿OK?*

**H2 — Entrada al grupo SIN formulario previo (link compartido libre).** 🔴 **ABIERTO → PARA EL CLIENTE.**
Opciones: permitir como "fantasma" / bloquear hasta registrarse / permitir sin trackear. No se decide internamente; va al doc de dudas para el cliente.

**H3 — Asociación VideoVisto ↔ participante.**
Default: el replay se entrega con URL que lleva el `token`; el webhook del host devuelve ese token. *¿El host elegido (Wistia/Vimeo) soporta pasar y devolver un identificador propio?*

**H4 — Semántica del "80%".**
Default: % del **largo total** del video, **acumulado** entre sesiones (máximo alcanzado). *¿Coincide con cómo reporta el host?*

**H5 — Matching Pago P60 ↔ participante.**
El PSP (a definir) debe devolver algo que linkee al participante (email/teléfono, o un `token` que pasemos en el checkout). Default: pasar el `token` como metadata en el link de pago. *¿Viable con el PSP que elijan?*

**H6 — Reembolso del P60.** ✅ **RESUELTO (default adoptado).**
Registramos `ReembolsoP60Recibido` (vía PSP) y revertimos el estado del participante a no-convertido (`ParticipanteRevertido`); sin lógica de comisión (fuera de MVP). *(Confirmar con el cliente que el PSP notifica reembolsos por webhook — anotado en H5/open-questions.)*

**H7 — Verificación / aceptación en cohorte.** ✅ **RESUELTO.**
Hay un **gate humano**: Ops verifica las respuestas del formulario y **acepta al participante en la cohorte** (`VerificarRegistro`). El **alta al grupo** de WhatsApp es un paso posterior y distinto, que ejecuta la capa no-code. Cohorte ≠ Grupo. (Riesgo a futuro: a 300+ la verificación manual puede ser cuello de botella → eventual semi-automación por reglas, fuera de MVP.)

**H8 — "Domingo / Presentación P60": fijo por cohorte o relativo.** ✅ **RESUELTO.**
Contenido diario **relativo** al inicio de cada persona; presentación P60 = evento **fijo por cohorte**.

**H9 — Una cohorte = ¿un grupo de WhatsApp? Límite de grupo.**
Default: 1 cohorte = 1 grupo; si supera el límite de WhatsApp, se parte en sub-grupos de la misma cohorte. *¿Cómo lo maneja hoy el cliente?*

**H10 — Encuestas/dinámicas: ¿tracking en MVP o solo contenido?** ✅ **RESUELTO.**
**Sí registramos** las respuestas como eventos (`EncuestaRespondida`), pero **sin cálculo ni segmentación** sobre ellas todavía (solo persistencia para uso futuro).

**H11 — Rate limits / ventana del automatizador no oficial a 300+.**
Riesgo operativo. Default: la cola de acciones soporta throttling configurable para no superar el ritmo seguro del canal. *(diseño, no bloquea — solo confirmar que lo prevemos.)*

**H12 — Tono "anti-ventaja".**
¿El posicionamiento "no te estamos vendiendo" debe reflejarse como restricción de diseño en los mensajes automáticos (ej: evitar lenguaje de venta agresivo en los follow-up)? *Impacta el diseño del contenido, no el código.*
