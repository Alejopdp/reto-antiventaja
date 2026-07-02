# Reto Antiventaja — Dudas abiertas y puntos muertos

> Propósito: registro vivo de **lo que NO está decidido**. Dos tipos:
> - **[CLIENTE]** — decisión de negocio/operativa que NO podemos tomar nosotros; va a la reunión con el cliente.
> - **[DISEÑO]** — decisión técnica/de producto que podemos tomar internamente, con un default propuesto, pero que conviene confirmar.
>
> Cada ítem tiene impacto y, donde aplica, un default propuesto. Los `Hn` cruzan con `event-storming.md`.
> Fecha: 2026-05-29

---

## 🔴 CRÍTICO — resolver antes de cualquier cosa técnica

### Q1 [CLIENTE] — ¿El contenido y el replay se envían al GRUPO (broadcast) o 1:1 (DM con link tokenizado)?
**Por qué es crítico:** si el contenido/replay va al grupo como broadcast, **no se puede trackear por persona** → se cae el motor de follow-up segmentado (no_vio / parcial / completo), que es el corazón del producto. El tracking por persona (H3, H4) **exige** entrega 1:1 con link tokenizado.
**Impacto:** define si el "cerebro" tiene señal de comportamiento o no. Afecta `VideoTrackingPort`, las policies de follow-up y casi todo el valor del MVP.
**Probable resolución:** híbrido — comunidad/dinámicas al grupo; replay y CTAs 1:1 tokenizados.

### Q2 [PARCIAL] — Política de baja / opt-out (derecho a no recibir más mensajes).
**Por qué es crítico:** legal y de reputación. Sin baja, riesgo de spam/baneo (agravado por canal no oficial).
**Impacto:** estado `BAJA` + chequeo antes de encolar cualquier acción.
- ✅ **DECIDIDO:** Ops puede dar de baja desde el **panel** (botón en el detalle del participante, ya en el proto) → `DarDeBaja`.
- 🔴 **PARA EL CLIENTE:** ¿damos además a los **usuarios** la opción de baja por WhatsApp (palabra clave tipo "BAJA")?

---

## Registro y atribución

### Q3 [CLIENTE] — ¿Qué campos pide el formulario y cuáles son obligatorios?
Aún no definido. Define validaciones y qué datos persistimos. (Mín. probable: nombre, WhatsApp, "quién te invitó".)

### Q4 [CLIENTE] — Reglas de atribución ambigua / "quién te invitó" en texto libre.
Homónimos, typos, nombre que no matchea a ningún participante, o referido a alguien que aún no se registró. ¿Texto libre, o se elige de una lista de impulsores conocidos? **Impacto fuerte en la calidad del grafo de atribución.**
**Default propuesto:** capturar texto crudo siempre; resolución diferida (bandeja Ops) — ya contemplado en `AtribuciónResuelta`.

### Q5 [DISEÑO] — Auto-invitación / referido circular.
Alguien se pone a sí mismo como su impulsor, o A→B y B→A.
**Default propuesto:** validar que `referido ≠ self`; ciclos se permiten pero se detectan en reporting.

### Q6 [DISEÑO] — Re-registro / duplicados (mismo WhatsApp o email).
La misma persona llena el formulario dos veces.
**Default propuesto:** deduplicar por WhatsApp normalizado (E.164) dentro de la misma cohorte; el segundo registro actualiza, no crea.

### Q7 [CLIENTE] — Participante recurrente entre cohortes.
Alguien que estuvo en una cohorte anterior y vuelve. ¿Es el mismo participante con historial, o uno nuevo por cohorte? **Impacto en el modelo de datos** (identidad global de persona vs. por cohorte).
**Default propuesto MVP:** identidad por cohorte (simple); persona global queda como evolución futura.

---

## Verificación (Ops) y alta al grupo

### Q8 [CLIENTE] — Criterios de aceptación/rechazo del formulario.
¿Qué hace que Ops rechace a alguien? Sin criterio, el gate humano es arbitrario.

### Q9 [CLIENTE] — ¿Qué pasa con un rechazado? ¿Se le notifica? ¿Puede re-aplicar?

### Q10 [CLIENTE] — SLA de verificación y qué ve la persona mientras espera.
Entre registro y aceptación puede pasar tiempo; a 300+/cohorte puede ser horas. ¿Mensaje de "estamos revisando"?

### Q11 [DISEÑO] — Aceptado que nunca entra al grupo.
La persona fue aceptada pero no hace clic / no se une al grupo.
**Default propuesto:** reintentar el `alta_grupo`/recordatorio N veces, luego marcar `ALTA_PENDIENTE` para Ops.

### Q12 [DISEÑO] — Persona que sale o es removida del grupo a mitad del reto.
**Default propuesto:** evento `ParticipanteSalióDelGrupo` → pausar secuencia de contenido; Ops decide.

### Q13 [PARCIAL] — Roles y permisos del panel.
✅ **DECIDIDO:** lo operan **varias personas** (multi-usuario). 🔴 **Pendiente:** ¿hace falta **roles/permisos granulares** (Ops vs Organizador ven cosas distintas) o todos ven todo en MVP?

---

## Reto, contenido y calendario

### Q14 [CLIENTE] — Alta tardía: alguien se suma en el "día 4" de la cohorte.
¿Empieza en su día 1 (relativo) o se sincroniza con la cohorte? (H8 definió contenido relativo, pero el alta tardía sigue siendo un caso a confirmar para la experiencia.)

### Q15 [CLIENTE] — Zona horaria y horario de envío del contenido diario.
¿TZ de la cohorte o del participante? ¿A qué hora se envía el contenido del día? (H4/H8 relacionados.)

### Q16 [DISEÑO] — Abandono a mitad del reto (deja de participar pero sigue en el grupo).
¿Se sigue enviando la secuencia? **Default:** sí hasta el final del reto, salvo baja explícita (Q2).

---

## Presentación, replay y follow-up

### Q17 [DISEÑO] — Cambio de segmento entre visionados (vio 50% → luego completa).
Si ya se encoló `followup_2` (parcial) y después completa, ¿se cancela y se manda `cta_final`?
**Por qué importa:** idempotencia + **cancelación** de acciones encoladas pero no enviadas. **Default propuesto:** re-segmentar con el máximo % alcanzado; cancelar acciones de follow-up pendientes que quedaron obsoletas.

### Q18 [DISEÑO] — Visionado con token de otra persona (link reenviado).
El % se atribuye al dueño del token, no a quien realmente miró. **Default:** se acepta el ruido en MVP; se documenta como limitación.

### Q19 [CLIENTE] — Cantidad y cadencia de follow-ups, y hasta cuándo insistir.
¿Solo followup_1/2 + cta, una vez? ¿Reintentos? ¿Ventana de corte?

### Q20 [CLIENTE] — Valor exacto del umbral de "completo" (hoy asumido 80%) y de la ventana de timeout del replay (hoy "X horas").

---

## Pago, conversión y reembolso

### Q21 [CLIENTE] — Compra fuera del funnel (paga sin haber hecho el reto / sin cohorte).
¿Se acepta? ¿Cómo se atribuye? **Default:** se registra el pago; queda "sin participante" en bandeja Ops si no matchea.

### Q22 [CLIENTE] — Pago en cuotas / pago parcial del P60.
¿El P60 se paga de una o admite cuotas? Cambia cuándo se considera "convertido".

### Q23 [DISEÑO] — Pago duplicado / webhook de pago repetido.
**Default:** idempotencia por referencia del PSP.

### Q24 [CLIENTE] — Moneda y país (60 USD).
¿Cobro en USD o conversión local? ¿Afecta el matching o el monto registrado?

---

## Experiencia y cierre

### Q25 [CLIENTE] — ¿La experiencia/testimonio es obligatoria? ¿Incentivada? ¿Consentimiento para uso público del testimonio?

---

## Transversales / operativos

### Q26 [DISEÑO] — Idempotencia de ingesta de webhooks (alta grupo, video, pago).
**Default:** todos los webhooks de entrada idempotentes por id de evento del proveedor.

### Q27 [DISEÑO] — Caída de la capa no-code / backlog de acciones.
Si el automatizador cae, las acciones se acumulan en la cola.
**Default:** la cola persiste y se drena al volver; throttling configurable (H11).

### Q28 [DISEÑO] — Política de reintentos y alertas de `AcciónResuelta(fallida)`.
¿Cuántos reintentos? ¿Cuándo se alerta a Ops? **Default:** N reintentos con backoff, luego a bandeja Ops.

### Q29 [CLIENTE] — Idioma(s). ¿Solo español? Afecta plantillas y formulario.

### Q30 [DISEÑO] — Cohortes solapadas: una persona activa en dos cohortes a la vez.
**Default MVP:** se permite (identidad por cohorte, Q7); sin dedup cross-cohorte.

---

## Surgidas al modelar el dominio (domain-model.md §9)

### Q31 [DISEÑO] — Anclaje del "día N" del reto.
¿Relativo a `joined_group_at`, `accepted_at` o al `start_date` de la cohorte? **Default propuesto:** `joined_group_at` (empieza cuando realmente entra). Relaciona Q14 (alta tardía) y Q15 (TZ).

### Q32 [DISEÑO] — Eventos fuera de orden / webhooks tardíos.
Ej.: llega `VideoVisto` antes de que registremos el envío del replay; o el pago antes de poder matchear. **Default:** el estado se computa por reglas tolerantes al orden y las acciones son idempotentes; ningún handler asume orden estricto.

### Q33 [DISEÑO] — Alcance de unicidad del `token`.
Global (una persona = un token de por vida) vs por cohorte. **Default:** global. Relaciona Q7 (recurrente entre cohortes).

### Q34 [DISEÑO] — `segment` y `current_day` como atributo, no estado. ✅ decidido en domain-model; sin lifecycle por día/segmento.

### Q35 [DISEÑO] — Conversión directa sin segmentación. El statechart la permite (CONVERTIDO desde EN_GRUPO); el matching del pago cae en Q21 si no hay participante.

### Q36 [DISEÑO] — `AcciónDeSalida` como agregado independiente del Participante.
**Default:** sí; consistencia por `dedupe_key`, confirmación async por ack (no comparte transacción con el Participante).

### Q37 [DISEÑO] — Persistencia: ¿event log materializa estado o se reproyecta?
Candidato a **ADR-0002**. **Default:** estado materializado + event log append-only (no event sourcing completo).

## Surgidas al revisar los wireframes

### Q41 [CLIENTE/DISEÑO] — ¿Qué señal define la "participación diaria"?
El dashboard muestra un KPI de participación diaria, pero no está definido qué la mide (¿respuestas a encuestas? ¿clics en contenido? ¿actividad en el grupo?). **Depende de Q1**: con contenido en broadcast al grupo NO hay señal por persona. Definir qué medimos y con qué dato.

> ⚠️ **Nota transversal de los dashboards (P2.1, P2.4):** están diseñados asumiendo **Q1 = tracking 1:1 tokenizado** (replay visto, segmentos, timeline de video por persona). Si Q1 resuelve "broadcast al grupo", estas vistas pierden esos datos. Revisar tras decidir Q1.

### Q42 [CLIENTE] ✅ **RESUELTO (MVP = WhatsApp-first, sin portal)** — ¿Existe un PORTAL del participante?
**Decisión:** sin portal. El participante vive en WhatsApp; el Excel solo se entrega; sin login ni captura de datos financieros. El **portal del participante** (carga de Excel, revisar cuenta) queda como **expansión futura / decisión del cliente** (implicaría auth + datos financieros + Q7). Superficies de participante que SÍ se construyen: **experiencia/testimonio** y, condicionales, baja (Q2) y landing de replay (Q1).
**Supuesto descartado para MVP:** NO. El participante vive en WhatsApp; el Excel **solo se entrega** (sin subida ni captura de datos financieros — decisión de scope); no hay login de participante.
**Lo que el cliente podría querer (expansión):** un portal donde el participante suba su Excel/reporte avances y revise su cuenta. Implica **auth**, **captura de datos financieros** (hoy descartada) e identidad de persona entre cohortes (Q7). Decisión de producto, no olvido.
**Superficies de participante que SÍ están en scope hoy y faltan diseñar:** formulario de **experiencia/testimonio** (`ExperienciaCompletada`, lo menciona el mapa original) y, condicional, página de **baja** (Q2) y **landing del replay** tokenizado (Q1).



### Q38 [CLIENTE] ✅ **RESUELTO (MVP = Modelo A)** — Modelo de invitación/atribución: link único vs link por impulsor.
**Decisión:** MVP usa **Modelo A** (link único compartido + texto auto-reportado, editable; atribución resuelta en bandeja Ops). **Modelo B** (link por impulsor) queda como **evolución futura** y/o validación con el cliente (sinergia con Q1). El prototipo se alineó a A.
- **Modelo A (el del mapa original)**: un único enlace compartido por todos + campo "¿quién te invitó?" auto-reportado (texto). Atribución sucia → resolución en bandeja Ops (Q4). Sin scope extra.
- **Modelo B**: cada impulsor genera su propio link de referido (con token); el invitador queda identificado automáticamente. Atribución limpia, **pero suma scope**: entidad `Invitación`/`LinkReferido`, comando `GenerarLinkDeInvitación`, evento nuevo (no existe hoy), Impulsor pasa a **actor activo**, y una **pantalla nueva** para que el impulsor obtenga/comparta su link. **Sinergia**: el mismo token alimenta el tracking 1:1 de video (Q1/H3).
**Impacto:** calidad de atribución + scope del MVP + existencia de nuevos eventos/entidades + si Impulsor es actor. **Decisión de fondo.** El prototipo actual mezcló ambos (incoherente).

### Q39 [DISEÑO] ✅ **RESUELTO** — Coherencia del campo "¿quién te invitó?".
Como quedó Modelo A (Q38): campo **vacío y editable** (única fuente). *(Pendiente menor: ¿es obligatorio? Hoy el prototipo lo marca obligatorio; revisar el caso de quien llega sin un invitador claro — relaciona H2/Q4.)*

### Q40 [DISEÑO] — Indicación de obligatoriedad y validación del formulario. ✅ criterio decidido.
Marcar lo opcional + nota "todos obligatorios salvo los marcados"; **validar on-blur** (no solo al submit) con mensajes inline. Best practice; se aplica al ajustar el form.

---

## Surgidas al pulir el prototipo (interactividad)

### Q43 [DISEÑO/CLIENTE] 🔴 — Impulsor tipado (para que el ranking de atribución funcione).
Con Modelo A la atribución es **texto libre** → el ranking de impulsores no agrupa bien (typos/variantes). **Propuesta:** un registro **tipado de impulsores**; Ops resuelve el texto libre asignándolo a un impulsor existente o creando uno nuevo (la pantalla "Asignar impulsor" es ese mecanismo). El ranking agrupa por `impulsorId`, no por texto.
**A decidir:** ¿el impulsor es (a) otro participante, (b) un promotor externo que no necesariamente participa, o (c) su propia entidad `Impulsor`? Afecta el modelo de datos (`referred_by_participant_id` asume (a)). Relaciona Q38 (Modelo B reusaría esto) y Q4.

### Q44 [DISEÑO] — Navegación/alcance por cohorte en el panel interno.
El breadcrumb "Cohortes › Mayo 2026" era engañoso. **Decisión de diseño adoptada (prototipo):** un **selector de cohorte global** define el alcance de todo el panel (embudo, verificación, participantes, atribución), con opción **"Todas las cohortes"**; en vistas cross-cohorte se muestra la columna Cohorte. *Confirmar que es el modelo deseado vs. filtros por pantalla.*

### Q47 [CLIENTE] 🔴 — Mecanismo de alta al grupo de WhatsApp (¿añadir o invitar?).
Define la semántica de la acción `alta_grupo` y si la pantalla web "aceptado" tiene sentido.
- **Modelo 1 — el equipo/automatizador AÑADE el número** (lo que dice el mapa: "lo añade al grupo"): la persona queda dentro sin hacer nada → NO hay acción de "unirse"; un CTA web "Unirme al grupo" es contradictorio.
- **Modelo 2 — se envía un LINK DE INVITACIÓN** que la persona clickea: el link **llega por WhatsApp**, no por web → la pantalla web sería redundante/respaldo.
- **Realidad técnica — CONFIRMADA (research):** los automatizadores no-oficiales (Whapi) **no pueden añadir números desconocidos/no guardados** (anti-spam de WhatsApp) → **se fuerza el Modelo 2 (link de invitación)**. Ver `integration-research.md §1`. ⇒ `alta_grupo` debería significar **"enviar link de invitación"**, no "añadir número".
- **Implicación de diseño:** la pantalla `aceptado.html` se reformuló a "te sumamos al grupo" (Modelo 1); con el Modelo 2 confirmado convendría ajustarla a "**unite con este link**" (que igual llega por WhatsApp). Relaciona Q42 y P1.3.
- **GDPR (research):** añadir a alguien a un grupo sin consentimiento fue **multado con 70.000 €** en España → el alta exige consentimiento explícito (ya está el checkbox).

---

### Q49 [DISEÑO/CLIENTE] — Bloqueo permanente de un número/usuario.
Idea (de la verificación, Q7): que Ops pueda marcar un número/usuario como **bloqueado para siempre**, que **no pueda volver a registrarse**. **Factibilidad:** trivial con DB propia (lista de bloqueo / flag). **A confirmar con el cliente** si lo quiere y con qué criterio. Relaciona verificación/rechazo (Q8–Q9) y re-registro (Q6 dedup).

### Q50 [CLIENTE] 🔴 — ¿Para qué usamos exactamente el grupo de WhatsApp y cómo?
Antes de hablar con Kapso hay que **definir el rol del grupo**: ¿es solo comunidad/sensación de movimiento, o también canal de entrega de contenido? Esto determina qué necesitamos del Groups API de Kapso (Q48) y se cruza con Q1 (si el contenido va al grupo o 1:1). **Reflejar en la agenda con el cliente.**

### Q48 [ACCIÓN] 🔴 — Confirmar con Kapso (somos partners) su WhatsApp Groups API.
Kapso es oficial (Cloud API) → elimina ban-risk y mejora GDPR vs Whapi, y la partnership puede dar early access. Pero su **Groups API está en waitlist**. **Preguntar a Kapso:** ¿qué hace exactamente el Groups API (añadir/invitar miembros, enviar al grupo, webhooks de eventos de grupo)?, ¿fecha de disponibilidad?, ¿early access para partners?, ¿reemplaza de forma compliant la necesidad de Whapi? Relaciona Q47 (mecanismo de alta) y Q1 (grupo vs 1:1). Ver `integration-research.md §1`.

---

## Reglas de negocio y contenido (NO determinadas — del cliente)

### Q45 [CLIENTE] 🔴 — Reglas de follow-up (no solo la segmentación).
Tenemos el **motor**: segmentar por % visto del replay → `followup_1` (no vio) / `followup_2` (parcial) / `cta_final` (completo). **NO** tenemos las **reglas de negocio**:
- ¿Cuántos follow-ups por segmento y con qué **cadencia/horarios**? ¿Hasta cuándo insistir (corte)? (relaciona Q19)
- ¿Hay follow-ups por **otros comportamientos** además del replay? (no entró al grupo, no participó en el reto, no abrió el contenido diario, abandonó a mitad…)
- ¿Quién **escribe el copy** de cada mensaje y con qué tono? (relaciona Q12, Q20)
→ Es decisión de cliente + contenido. Nuestro motor ejecuta las reglas que definan; hoy están como supuesto mínimo.

### Q46 [CLIENTE] 🔴 — Contenido diario: fuente, destinatario y alcance (7 vs 60 días).
- **Fuente:** ¿quién produce los vídeos/audios/copy del reto? *Supuesto:* los produce el cliente/equipo con sus herramientas (ChatGPT, ElevenLabs, etc.); **nosotros solo orquestamos la entrega, no generamos contenido**. Confirmar.
- **Destinatario:** el contenido diario del **reto** (7 días) es para todos los participantes de la cohorte. ✔
- **⚠️ Alcance (importante):** ¿el MVP entrega/trackea **solo el reto gratuito de 7 días** (hasta la conversión al P60), o **también los 60 días del programa P60** (post-pago)? Hoy el diseño **termina en la conversión + experiencia**; la entrega del P60 NO está modelada. Si el cliente espera que el sistema corra también el programa de 60 días, es **una fase nueva** (más contenido, más estados, más tracking). → decisión de alcance.

---

## Surgidas al integrar GHL (2026-07-01) — ver ADR-0005

### Q51 [CLIENTE/ACCIÓN] 🔴 — Proveedor de WhatsApp para el 1:1: GHL vs Kapso.
GHL hace 1:1 con la **WhatsApp Business API oficial**; Kapso solo se justifica por los **grupos** (su Groups API está en waitlist, Q48). **Default propuesto MVP:** GHL para todo el 1:1 automático; grupo **manual**; Kapso diferido hasta que su Groups API exista. Relaciona Q47, Q48, Q50, Q52.

### Q52 [CLIENTE] 🔴 — Estrategia de número(s) de WhatsApp.
Un número en la API oficial (GHL) **no puede** correr además automatización **no oficial** de grupos. ⇒ o **dos números** (uno grupo manual, uno 1:1 oficial en GHL), o un número con *coexistence* (limitaciones por país). A confirmar con el cliente/Kapso. Relaciona Q51, Q47.

### Q53 [CLIENTE - Max] 🔴 — ¿Qué trabajo concreto se espera de GHL?
¿Solo CRM? ¿Reusar funnels ya montados en LV? ¿Membership del P60? Determina si GHL entra como **sistema base** o solo como **pieza detrás de un puerto**. **Línea roja:** BeZy ≠ Lector Voraz → si es la GHL de LV, requiere acuerdo de coste. Si Max no justifica un trabajo concreto, aplica el **plan B "espejo" sin GHL** (ADR-0005, alternativas). Cierra C1/C2 del handoff.

---

## Surgidas al definir la medición de vídeo (2026-07-01)

### Q54 [CLIENTE/DISEÑO] 🔴 — Medición de la asistencia al directo EN VIVO (Zoom).
Aparte del replay, el directo dominical en vivo es señal por persona: **quién asistió, cuánto se quedó, quién se fue** → define a quién mandarle el replay y qué follow-up. **Mecanismo propuesto:** registro por participante en Zoom (link de join único por WhatsApp) + webhooks `participant_joined/left` / Reports API → cerebro (atado al token/`registrant_id`). **A confirmar:** plan de Zoom (requiere Pro+ con registro) y si el directo es *Meeting* o *Webinar*. Es una **segunda superficie de tracking** además del replay; relaciona el requisito "grabación por Zoom API" del handoff, Q41 (señales de participación) y "alertas por inacción".

### Q55 [DISEÑO] — Host y reproductor del replay.
Como la analítica la calculamos nosotros (eventos JS del player en la página tokenizada), el host queda como **commodity** de entrega/seguridad/costo detrás del `VideoTrackingPort`. **Default propuesto:** **Cloudflare Stream** (HLS automático + CDN + playback firmado + bring-your-own-player) o, mínimo viable, **mp4 en S3 + HTML5 + CloudFront/URL firmada**. **Wistia se descarta** (innecesario; el cliente lo asumía → avisar). Mux queda para más adelante si se necesita DRM. **Resuelve H3** (medición atada a nuestro token, no al `visitor.id` del host) y **H4** (umbral propio, Q20).

## Surgidas al definir el agente IA 1:1 (2026-07-01)

### Q56 [CLIENTE] ✅ DECIDIDO (dev — validar con cliente): nivel = **(b) Autopiloto con red**.
Se **descarta (a) copiloto** por inescalable (un humano no puede enviar cada mensaje a ~100/grupo). La conversación 1:1 con IA (handoff §5a), 3 niveles evaluados — decisión de **negocio/riesgo → validar con cliente**:
- **(a) Copiloto:** IA sugiere, humano envía. Máximo control, no escala.
- **(b) Autopiloto con red:** IA responde sola + handoff a humano en casos complejos. Escala (es lo que subió conversión ~20→40%), más riesgo (mitigado por guardrails).
- **(c) Semilla ahora, IA después:** cola determinista + respuestas guiadas (botones/plantillas) en MVP; agente conversacional en fase 2.
Relaciona Q45 (reglas/copy), Q46 (contenido), Q41 (señales).

> **Nota de diseño (nuestra, independiente del nivel):** el agente opera SIEMPRE como **"guarded agent"** — allow-list de acciones derivadas del dominio del reto; contexto que lo aterriza (retos, tiempos/día N, tareas del participante, cosas a revisar, eventos a conocer/asistir/reaccionar: directo, replay, deadlines); clasificador on-topic + fallback ("esto no tiene que ver con el reto, probá de nuevo"); handoff a humano. Ese contexto/conocimiento sale de Q45/Q46/Q41. Cuando se decida el nivel → candidato a ADR.

> **Impacto en el dominio (independiente del nivel):** los **mensajes entrantes del participante** pasan a ser ciudadanos de primera (evento nuevo, p.ej. `MensajeEntranteDelParticipante`) y la salida deja de ser solo plantillas fijas (`ActionType` cerrado) → puede ser generada por el agente dentro del allow-list. Afecta `domain-model.md` (event-storming, `ActionType`) — tratar al modelar el agente.

### Q57 [CLIENTE/DISEÑO] — Notas de voz del participante (STT).
¿Permitimos notas de voz entrantes? Requiere **transcripción (STT, p.ej. Whisper)** antes de que la IA interprete. Factible; probable **entrega futura**. Presentar al cliente. Relaciona Q56.

### Q58 [DISEÑO/CLIENTE] 🔴 — Motor de la IA 1:1 y superficie de intervención humana (takeover).
**Provenencia (importante):** el cliente pidió **GHL como sistema base** + una **conversación 1:1 con IA** — **NO** pidió que el motor de IA sea GHL. Usar la IA de GHL como motor fue una **opción propuesta por el dev** al investigar GHL, no un mandato del cliente.

Decidido el nivel (b, Q56), falta **quién GENERA** la respuesta (ver aclaración abajo) y **dónde interviene el humano**. **Verificado (GHL 2026):** GHL tiene Conversation AI + **Agent Studio** (builder visual multi-step, nodos condicionales, fallback), **Knowledge Base** (RAG: PDF/DOCX/CSV), **Custom Actions** (la IA llama POST a APIs externas —p.ej. nuestro cerebro— con auth/params dinámicos; **≤10 tools/agente**), guardrails por prompt, e inbox + takeover nativos.
- **Opción 1 — Agente en GHL (Conversation AI / Agent Studio):** takeover + inbox nativos, poco build, **editable por el equipo**; **puede ser domain-aware** llamando a nuestra API por Custom Actions (día N, segmento, tareas) — corrige la idea previa de "contexto pobre". Límites: ≤10 tools/agente, sin código arbitrario (solo nodos), es el LLM de GHL (menos control de modelo/prompt), lock-in + coste, y cada contexto es un round-trip webhook.
- **Opción 2 — Guarded agent propio (cerebro):** domain-aware total (día N, segmento, %replay, tareas) + allow-list de acciones; construimos takeover **y** pantalla de chat en vivo.
- **Opción 3 — Híbrido (recomendado):** conversación + takeover en GHL Conversation AI; el cerebro le **alimenta contexto** (custom fields) y **consume señales** (webhooks) para estado/acciones de dominio. Menos build; candidato fuerte de "trabajo para GHL" (Q53).

**Aclaración clave (generar ≠ entregar) — el eje real de Q58 es "¿quién GENERA?":**
- *Generar* (la inteligencia, qué decir): **nuestro agente** (contexto completo: día N, segmento, tareas, historial → respuestas ricas + allow-list de acciones) **vs la IA de GHL** (solo el contexto sincronizado a custom fields → más floja).
- *Entregar* (mandar el WhatsApp): GHL o Kapso; es lo de menos, no define la arquitectura.
- **Consecuencia:** si genera **GHL**, el takeover es **nativo** (pausar bot, ON/OFF, handoff) pero con **menos contexto**. Si genera **nuestro agente**, respuestas ricas pero el takeover nativo de GHL **no aplica** → lo implementamos nosotros (el modo IA/humano de `domain-model.md §10`). Instinto del dev (favorito): **genera nuestro agente, GHL/Kapso entrega**.

**Mecánica de takeover a preservar (cualquiera sea la opción):** modo por conversación (IA/humano), **pausa-al-intervenir**, **cancelar la respuesta IA encolada antes de enviar** (reusa el patrón de cancelación de acciones obsoletas, Q17), cooldown, y handoff iniciado por la IA (baja confianza / off-topic / "quiero una persona").

**GHL vs dashboard interno (aclaración):** con Opción 1/3, la **charla en vivo vive en GHL** (no construimos inbox); el **dashboard interno** queda solo para vistas de dominio (cohortes, embudo, verificación, dashboard público) que GHL no da. Con Opción 2, sumamos una pantalla de conversación propia.

### Q59 [DISEÑO] — Conversación: ¿atributos del Participante o agregado propio?
**Default:** atributos en el Participante (`conversation_mode`, `conversation_paused_until`) + el hilo detrás del `MessagingPort` (lean, como el grupo). **Alternativa:** agregado `Conversación` propio si el agente crece (historial, múltiples hilos, métricas por conversación). Además: ¿el **cooldown** auto-reanuda a autopilot, o requiere acción humana explícita? *Default: auto-reanuda.* Ver `domain-model.md §10`.

### Q60 [DISEÑO] — `AIAgentPort` (4º puerto) y latencia de la respuesta IA.
El dominio ahora tiene 4 puertos (suma `AIAgentPort`). **Latencia:** la cola actual es *pull* (`GET /actions/pending`), pensada para el automatizador no-code; el chat 1:1 quiere baja latencia. **Opciones de ENTREGA** (aparte de quién genera, ver Q58): si **genera nuestro agente**, la `respuesta_ia` se entrega por un camino **push/inmediato** hacia GHL/Kapso (no espera el *pull* de la cola); si **genera la IA de GHL**, GHL entrega directo y ni pasa por nuestra cola. Depende de Q58. Ver `domain-model.md §10`.

---

## Surgidas al modelar prueba social / C4 (2026-07-01)

### Q61 [CLIENTE] 🔴 — Dashboard público de prueba social: mecánica de acceso y consentimiento.
**Provenencia:** pedido del cliente (handoff §5a, Kley 4-jun): *"mini-landing + mini-dashboard **público**, rankings por semana y TOTAL + nombre"*. **NO especificado:** cómo/cuándo se accede. **Defaults-para-aprobar** (facilitar la decisión del cliente):
- **Acceso:** link compartible enviado por WhatsApp al **cierre del reto** + disponible siempre en la landing.
- **Alcance:** ranking **por cohorte (semana)** + **TOTAL acumulado**; muestra montos recuperado/ganado agregados.
- **Consentimiento:** se muestra con **nombre de pila**; quien no quiera puede pedir **anonimato** (cruza Q25).
Solo se alimenta de resultados **aprobados** (moderados). La **exhibición** (esta superficie/landing) se construye **aparte** de la captura+moderación (C4, ya modelada en `domain-model.md §11`).

### Q62 [CLIENTE] — Taxonomía de categorías de resultado.
**Default-para-aprobar (seed):** `ahorro_suscripciones`, `factura_luz`, `venta_wallapop`, `otro`. Cada una mapea a `tipo` (`recuperado`|`ganado`) para sumar en el dashboard. ¿Suman/sacan categorías? Es contenido/negocio. Ver `domain-model.md §11`.

> **Nota de arquitectura (storage):** la evidencia (adjuntos) va a **almacenamiento de objetos**; el concreto (S3 vs **Cloudflare R2**) se decide en **ADR-0004** (Propuesto). Lean del dueño: evitar sobre-complejizar con AWS → evaluar Cloudflare (R2 pega con Cloudflare Stream del vídeo, Q55).

---

## Hotspots del event-storming que siguen para el CLIENTE
(referencia cruzada; no se decidieron internamente)

- **H1** identidad número formulario↔grupo (default E.164 + bandeja Ops — confirmar).
- **H2** entrada al grupo sin formulario previo (permitir/bloquear/no-trackear). 🔴 abierto.
- **H3** 🔴 **CAMBIÓ (research):** Wistia **NO** acepta un token propio en el webhook (solo `visitor.id` por cookie o email vía Turnstile). El supuesto "token en la URL del replay" no aplica → opciones: email-gate / mapeo visitor.id↔token / otro host (api.video). Ver `integration-research.md §2`. Depende de Q1.
- **H4** semántica del "80%": Wistia dispara a 25/50/75/100% (umbrales fijos), no un % continuo arbitrario. Ajustar el motor a esos umbrales.
- **H5** ✅ **CONFIRMADO (research):** Stripe permite pasar el `token` como metadata en el Checkout Session y vuelve en el webhook `checkout.session.completed` → matching pago↔participante determinista, sin email-gate. (Reembolsos: webhooks soportados.)
- **H9** 1 cohorte = 1 grupo y límite de capacidad del grupo.
- **H11** rate limits del automatizador no oficial a 300+: precio real de Whapi **sin confirmar** (claim refutada); riesgo de baneo no cuantificado. Ver research.
- **H12** tono "anti-ventaja" como restricción de diseño de los mensajes.
