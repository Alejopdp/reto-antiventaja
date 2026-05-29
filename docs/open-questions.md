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

### Q2 [CLIENTE] — Política de baja / opt-out (derecho a no recibir más mensajes).
**Por qué es crítico:** legal y de reputación. Sin un mecanismo de baja, riesgo de spam/baneo (agravado por usar canal no oficial).
**Impacto:** estado `BAJA` del participante + chequeo antes de encolar cualquier acción.
**Default propuesto:** palabra clave de baja (ej. "BAJA") detectada por la capa no-code → evento `ParticipanteDadoDeBaja` → se frena toda acción futura.

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

### Q13 [CLIENTE] — Roles y permisos: ¿quién es "Ops"? ¿una o varias personas? ¿qué ve cada rol en el dashboard?

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

## Hotspots del event-storming que siguen para el CLIENTE
(referencia cruzada; no se decidieron internamente)

- **H1** identidad número formulario↔grupo (default E.164 + bandeja Ops — confirmar).
- **H2** entrada al grupo sin formulario previo (permitir/bloquear/no-trackear). 🔴 abierto.
- **H3** el host de video soporta pasar/devolver nuestro `token` (depende de Q1).
- **H4** semántica del "80%" según el host elegido.
- **H5** el PSP devuelve algo que linkee al participante + notifica reembolsos (relaciona Q21–Q24, H6).
- **H9** 1 cohorte = 1 grupo y límite de capacidad del grupo.
- **H11** rate limits del automatizador no oficial a 300+.
- **H12** tono "anti-ventaja" como restricción de diseño de los mensajes.
