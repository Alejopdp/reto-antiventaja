# Brief de handoff — BeZy / Reto Antiventaja

> **Para:** Ale (Alejopdp), dev del Reto Antiventaja
> **De:** Chief of Staff de Max
> **Fecha:** 2026-06-24
> **Asunto:** Cierre de tus open-questions con lo salido de la call del 4-jun (Kley revisando TUS wireframes) + reconciliación con tu diseño actual.

Asumo que ya tienes en la cabeza tu discovery, domain-model, event-storming, ADRs, mvp-scope y wireframes (tras la call fundacional del 3-jun). Esto NO repite eso. El valor está en traerte lo que dijo Kley el 4-jun sobre tu trabajo y en cerrar (o acotar) tus preguntas abiertas. Todo está trazado a una call con fecha o a un archivo de tu repo. Donde no hay dato, digo `[pendiente]` — no invento.

---

## 1. TL;DR

- **Q1 resuelta a medias (la mitad buena):** confirmado el híbrido que ya proponías — el GRUPO de WhatsApp = comunidad + prueba social; el **1:1 por WhatsApp = el motor de conversión** (el 1:1 manual ya subió la conversión de ~20% a ~40%). Pero **H3 sigue abierto** (cómo medir por persona quién vio el replay) → ver §6. *(Kley 4-jun + 11-may)*
- **Dos ambigüedades de arquitectura ABIERTAS, no decididas:** (a) **stack** — las calls fijan 11ty+Wistia+Kapso+Zoom API frente a tu cerebro Next.js+Drizzle+Postgres; (b) **GHL** entra como "sistema base" frente a tu event log propio. Ninguna call desambigua. Son decisión de Max/Jesús/Kley, no tuya. → §3 y §6.
- **Kapso/Capstone es la herramienta elegida para el 1:1** (vía oficial), con modelo de coste real (primer mensaje = plantilla Meta; botón abre ventana "utility" más barata). Pero su **Groups API sigue en waitlist (Q48)** → el grupo no está resuelto técnicamente. *(Ale 3-jun + Kley 4-jun)*
- **Escala real ≈ 100/grupo, no 300+.** Reduce dimensionamiento de cola/throttling/capacidad. → §3. *(Kley 4-jun + 01-CONTEXTO-BEZY.md)*
- **Requisitos nuevos para "ahora":** bot con persona humana, conversación 1:1 con IA (no solo cola fija), reprogramación a mitad de reto, alertas por inacción, captura estructurada de prueba social (cantidades tipadas + adjuntos), mini-dashboard PÚBLICO, contenido editable por el equipo, grabación del directo vía Zoom API. → §5.
- **Lo grande de la visión NO es build ahora:** Skool/gamificación, comisiones multinivel 40%, inmobiliario/trading, Etikax, "producto para miles de comunidades". → §5 (visión). **Ojo:** escalar el 1:1 dentro de BeZy SÍ es ahora; el SaaS multi-comunidad NO.
- **Sigue abierto y es de Max/Jesús/Kley (no lo inventes):** H3/medición por persona, stack vs cerebro, GHL, cadencia/copy de follow-ups, 7 vs 60 días, moneda P60. → §6.

---

## 2. Tus preguntas que quedan RESPONDIDAS (lo más valioso)

> Lectura honesta: varias respuestas son **parciales**. La columna "respuesta" dice qué cierra y qué NO cierra. No trates como cerrado lo que apunta a §6.

| Tu pregunta | Respuesta (qué cierra / qué NO) | Fuente |
|---|---|---|
| **Q1 [🔴 CRÍTICO]** ¿Contenido y replay al GRUPO (broadcast) o 1:1 (DM tokenizado)? | **CIERRA:** híbrido, como tu repo proponía. Grupo = comunidad + sensación de movimiento + canal de contenido diario; **1:1 = motor de seguimiento/conversión** ("el uno a uno es lo que convierte; el grupo da prueba social"); 1:1 subió conversión ~20%→~40%. **NO CIERRA:** H3 — cómo identificar y medir **por persona** quién vio el replay (→ §6). Resuelve solo la mitad de "follow-up 1:1". | Kley 4-jun + 11-may + `open-questions.md:Q1` / `client-questions.md §Bloque1 item1` + `01-CONTEXTO-BEZY.md` |
| **Q47** Mecanismo de alta al grupo / herramienta WhatsApp | **CIERRA:** herramienta = **Kapso/Capstone** (vía oficial); alta por **link de invitación** (Modelo 2, anti-spam), como ya forzaba tu research. Modelo de coste: 1er mensaje = tarifa Meta (plantilla), botón abre ventana "utility" más barata. **NO CIERRA:** Kapso se confirma para 1:1, **NO** su Groups API (sigue en waitlist, Q48 → §6). | Ale 3-jun + Kley 4-jun / `open-questions.md:Q47` |
| **Q46** Contenido diario: fuente y alcance (7 vs 60 días) | **CIERRA fuente:** el contenido (audios/vídeos/Excel) lo produce **Jesús/equipo**; nosotros solo orquestamos la entrega ("no generamos contenido"). Requisito duro: el equipo edita mensajes/documentos por sí mismo. **NO CIERRA alcance:** v1.0 cubre el **reto de 7 días hasta el directo dominical = la venta**; los **60 días del P60 NO se confirman dentro del MVP** (→ §6). | Kley 4-jun / `open-questions.md:Q46` / `client-questions.md §Bloque1 item4` |
| **H9** 1 cohorte = 1 grupo y capacidad | **CIERRA:** cohorte = **1 grupo de WhatsApp nuevo cada semana** (lunes→domingo); capacidad real **~100 personas/grupo** (hoy, manual). **OJO:** esto fuerza un CHANGE — tu repo dimensionó 300+/cohorte (→ §3). Overflow >100 = residuo abierto (→ §6). | Kley 4-jun + Ale 3-jun + `01-CONTEXTO-BEZY.md` / `open-questions.md:H9` |
| **Q8 / Q49** Criterios de aceptación/rechazo y bloqueo | **CIERRA criterio de fondo:** "**poner el listón alto, mirones no**"; si no hay acción / no comparten → sacar del grupo y dárselo a otros (criterio de rechazo + remoción; motiva Q49 bloqueo permanente). **NO CIERRA:** el **umbral exacto** de "no acción" (depende de la señal de participación, Q41). | Kley 11-may + 4-jun / `open-questions.md:Q8, Q49` |
| **Q42** ¿Portal del participante? (ya RESUELTO en repo) | **CONFIRMA y matiza:** sigue **WhatsApp-first, sin portal**. El **Excel v1 = recurso descargable de autodescubrimiento** (la persona ve sus falencias); NO se envía al equipo para análisis; "que no requiera descargar ni Google Forms". El mini-Excel dentro de producto propio = **v2 (visión)**. Coherente con sin captura financiera en MVP. | Kley 4-jun + 11-may / `open-questions.md:Q42 (RESUELTO)` |
| **Q19 / Q45** ¿Hay follow-ups por comportamientos distintos al replay? | **CIERRA alcance:** SÍ. Quieren seguimiento 1:1 ("Jesús manda audio + IA pregunta ¿cómo vas? ¿te ayudo?"), **alertas al equipo cuando alguien no toma acción** (intervención manual / "poner caña") y **reprogramación a mitad de camino** ("¿te gustaría otra oportunidad el próximo día?"). **NO CIERRA:** cadencia/horarios/copy/corte exactos (→ §6). | Kley 11-may + 4-jun / `open-questions.md:Q19, Q45` |
| **Q41** ¿Qué señal define "participación diaria"? / qué se trackea por persona | **CIERRA la lista de señales:** ¿vio el contenido?, ¿en qué punto del proceso está?, ¿descargó las herramientas?, ¿compartió la oportunidad?, ¿envió la factura? (dato real: de **~112-116 personas solo ~35 enviaron factura**). Eso define el KPI de participación. **NO CIERRA:** la parte de "cuánto vio del replay" sigue colgando de Q1/H3. | Kley 11-may + 4-jun / `open-questions.md:Q41` |
| **Setup-14** Herramientas actuales y CRM | **CIERRA:** hoy **NO hay CRM** — todo manual, solo un Excel de quién pagó; verificación de acceso manual. Stack v1.0 = **11ty + Wistia + Kapso + Zoom API**, todo consumible desde WhatsApp. **Se quiere usar GHL como CRM/sistema base** → colisiona con tu cerebro propio (→ §3 y §6). | Kley 4-jun + Ale 3-jun / `client-questions.md §Bloque4 item14` |

---

## 3. Lo que CAMBIA respecto a tu diseño actual

> Patrón: de→a + qué queda por decidir. **Dos de estos NO están resueltos** (stack y GHL): los marco como cambios que ABREN pregunta, no como decisión cerrada. No inventes la resolución.

| # | Qué cambia | De → A | Qué queda por decidir | Fuente |
|---|---|---|---|---|
| C1 | **Stack de aplicación** `[ABIERTO]` | `ADR-0003` (Next.js 15 + Drizzle + Postgres = cerebro completo: form + dashboard + HTTP + event log) → calls "stack v1.0 = **11ty + Wistia + Kapso + Zoom API**". 11ty es un generador de sitios **estáticos**: no puede sostener solo el event-log/dashboard con estado que diseñaste. | ¿11ty es **solo la capa de contenido** consumible por WhatsApp y **coexiste** con el cerebro Next.js/Postgres, o estás **replanteando** la arquitectura? Las calls no lo desambiguan. → §6. | Ale 3-jun vs `adr/0003-stack-y-capas.md` |
| C2 | **CRM / sistema base** `[ABIERTO]` | `ADR-0002/0003` (event log propio append-only = fuente de verdad) → calls "hoy no hay CRM (solo Excel), **aprovechar GHL como CRM/sistema base**". GHL choca con / duplica tu cerebro. | ¿GHL **reemplaza** la DB de estado o se sienta **al lado** para comms? Y línea roja de coste: ¿es la **GHL de LV** (requiere acuerdo de coste; **BeZy ≠ LV**) o una **instancia nueva** de BeZy? → §6. | Kley 4-jun vs `adr/0002`, `adr/0003`, `01-CONTEXTO-BEZY.md` (regla de coste) |
| C3 | **Escala por cohorte** | NFR repo "~300+ participantes/cohorte; throttling configurable (sin tasa fijada)" → realidad "**grupos de ~100 máximo**". Reduce dimensionamiento (cola, throttling, capacidad). | Si una cohorte supera ~100, ¿se parte en sub-grupos y cómo se mantiene 1 cohorte ↔ varios grupos? (residuo H9 → §6). | Kley 4-jun + `01-CONTEXTO-BEZY.md` vs `nfr-and-security.md` / `open-questions.md:H9` |
| C4 | **Captura de prueba social** | Tu repo solo modela eventos de comportamiento + entrega del Excel (no captura resultados monetarios) → calls: probaron **texto libre por WhatsApp y la gente se liaba** → ahora **form con campos tipados** (ahorro en suscripciones, generado con factura de la luz, vendido por Wallapop…) + **archivado de adjuntos** (facturas/capturas) como evidencia. Alimenta el mini-dashboard público. | Modelo de datos nuevo de resultados monetarios por participante (no el Excel-solo-entrega). Implementación es tuya; el qué está cerrado. | Kley 4-jun |
| C5 | **Herramienta WhatsApp 1:1 con coste** | `integration-research §1` (evaluar Kapso primero, Whapi fallback, ambos sin cerrar) → calls "**Kapso/Capstone elegida** para 1:1; 1er mensaje = tarifa Meta plantilla, botón abre ventana utility". | El **grupo** (Groups API en waitlist, Q48) queda sin resolver → §6. | Ale 3-jun + Kley 4-jun vs `integration-research.md §1` |
| C6 | **Atribución — coherencia Modelo A/B** `[HIPÓTESIS, confirmar contigo]` | `Q38 RESUELTO = Modelo A` (link único compartido + texto auto-reportado) → calls reintroducen "**links únicos por usuario** para tracking" junto al campo "quién te invitó". | **Interpretación más probable:** "links únicos por usuario" = el **token opaco por participante** (compatible con Modelo A, sirve para tracking 1:1), **NO** links por impulsor (eso sería Modelo B y reabriría Q38/Q43). **Confírmalo tú** para no reabrir Modelo B por accidente. | Ale 3-jun + Kley 4-jun vs `open-questions.md:Q38` |

---

## 4. Lo que se CONFIRMA (validado — no lo toques)

- **Estructura de la cohorte:** reto de 1 semana en grupo WhatsApp nuevo cada semana, lunes→domingo con **directo en vivo de Jesús = la VENTA** (entrada a comunidad/formación 60 días). Coincide exacto con tu supuesto. *(Kley 4-jun + Ale 3-jun + `01-CONTEXTO-BEZY.md`)*
- **Modelo A de atribución** (link único + "quién te invitó" auto-reportado + panel de atribución/referral) = **default interno del MVP** (prototipo alineado), **NO ratificado por el cliente** → ver C6 antes de tratarlo como cerrado. *(Q38 `[CLIENTE] RESUELTO (MVP = Modelo A)`; Modelo B queda como evolución/validación futura con cliente, vs `open-questions.md:Q38`)*
- **Excel solo se entrega**, sin captura financiera del participante en MVP (Excel = autodescubrimiento, NO análisis del equipo). Confirma Q42. *(Kley 4-jun + 11-may)*
- **Alta al grupo por link de invitación** (no se añaden números). Coherente con tu research (Q47) y la nota legal de los **70.000 €** por añadir sin consentimiento. *(Ale 3-jun + `integration-research.md §1`)*
- **El sistema solo orquesta la entrega; el contenido lo produce el cliente.** Confirma el supuesto de Q46. *(Kley 4-jun)*

> *Lo de abajo ya es tuyo (decisiones tuyas del 3-jun / tu propio repo) — solo lo listo para que conste que una call posterior de Kley NO lo contradice; no re-narro tu trabajo: **Dashboard interno = tus 7 pantallas del `wireframe-brief.md`**; **Mercado España / es-ES** (`client-questions §Bloque4 item16`); **Wistia como host de vídeo on-demand** (`integration-research §2`).*

---

## 5. Requisitos NUEVOS

### 5a. Scope AHORA (build)

| Requisito | Por qué es nuevo respecto a tu repo | Fuente |
|---|---|---|
| **Bot con persona humana:** el 1:1 se presenta como un humano del equipo (p. ej. Kley); el participante cree que habla con una persona real, no con un robot. | Tu repo solo modela "acciones de salida" abstractas y neutras; no contempla la restricción de copy/UX. | Kley 11-may |
| **Conversación 1:1 generada por IA** (no solo secuencia fija): "Jesús manda audio + IA pregunta ¿cómo vas? ¿te ayudo?", con preguntas/respuestas para ubicar a cada persona en su punto del proceso. | Tu repo modela una **cola de mensajes tipados** (followup_1/2/cta), no un **agente conversacional bidireccional**. | Kley 4-jun + 11-may |
| **Reprogramación a mitad de camino:** si no vio/no hizo, recoger feedback ("no he podido / no tuve tiempo") y ofrecer "¿te gustaría otra oportunidad el próximo día?", redirigiendo a quien no actuó. | Política nueva no modelada en el repo. | Kley 4-jun |
| **Alertas al equipo por INACCIÓN del participante** (no solo por acción fallida), para intervención manual ("poner caña"). | Tu repo solo alerta a Ops por **acciones fallidas** (Q28), no por inacción del participante. | Kley 11-may |
| **Captura estructurada de prueba social** con cantidades tipadas (ahorro en suscripciones, generado con factura de la luz, vendido por Wallapop…) + **archivado de adjuntos** (facturas/capturas) como evidencia. | Modelo de datos nuevo de resultados monetarios por participante (≠ Excel-solo-entrega). | Kley 4-jun |
| **Mini-landing + mini-dashboard PÚBLICO** con cifras recuperado/ganado "gracias al Desafío", rankings por semana y TOTAL + nombre. | Superficie pública nueva; tu repo solo tiene dashboard interno + páginas públicas de form/aceptado/experiencia. | Kley 4-jun |
| **Contenido editable por el propio equipo** (mensajes y documentos), nada estático: requisito duro de Kley ("máquina de creación", iteran cada edición). | Implica un **editor/config de contenido** para el equipo, no solo seeds técnicos. | Kley 4-jun |
| **Grabación del directo dominical vía Zoom API** en mp4, servida on-demand (Wistia). | Pieza de integración nueva (Zoom API) que el repo no listaba. | Ale 3-jun + Kley 4-jun |
| **Foco en CIERRE / post-venta:** analizar qué pasó con los que no convirtieron; la info de los que NO tomaron acción = "oro" (si fue por ellos o por el producto). | Orienta qué read-models/analítica priorizar. | Kley 4-jun |

### 5b. VISIÓN / fases siguientes — **NO es build ahora**

> Explícito: nada de esto se construye en el MVP. Sirve para que no tomes decisiones de arquitectura que lo bloqueen, no para implementarlo. **Distinción clave:** escalar el 1:1 dentro de BeZy = **ahora**; el producto multi-comunidad = **visión**.

- **Capa de IA de segmentación/recomendación** sobre data financiera (ingresos/gastos/ventas) — "si tienes esa info, tienes oro". Encima del mini-Excel v2. *(Kley 4-jun + 11-may)*
- **VSL grabado de 20-25 min** para sustituir el directo dominical en vivo (hoy el replay es la sesión simple). *(Kley 4-jun)*
- **Gamificación + comunidad tipo Skool + comisiones multinivel / referidos al 40%**, invitaciones por participante, "quién viene de quién" gamificado. Atado a Skool y a estructura inexistente hoy; el repo deja comisiones **explícitamente fuera de MVP**. *(Kley 4-jun + Jesús 8-may)*
- **Producto multi-comunidad (SaaS para miles de comunidades).** El repo es single-tenant por decisión. **NO confundir con escalar el 1:1 dentro de BeZy (eso es ahora).** *(Kley 4-jun)*
- **Mini-Excel v2 dentro del producto propio** con data 100% de BeZy (vs Excel v1 que solo se entrega). *(Kley 4-jun)*
- **Ads gestionados por participantes** (que inviertan en publicidad y cobren al 40%) + automatizar cohortes "sin límites". *(Kley 4-jun)*
- **Plus high-ticket** para quienes traen gente. *(Jesús 8-may)*
- **Productos de inversión inmobiliaria y trading** para perfiles con recursos. *(Jesús 11-may / 8-may)*
- **Etikax:** tokenización / inversión en IA desde 10€. **Fuera de scope build.** *(Jesús 8-may; call 7-jun fuera de scope)*

---

## 6. Lo que SIGUE abierto (decisiones de Max/Jesús/Kley — NO las inventes)

> Estas no son respuestas que yo proponga ni que tú debas adivinar. Son decisiones de negocio/arquitectura con dueño. Marco quién decide y por qué bloquea.

| Abierto | Por qué bloquea / quién decide |
|---|---|
| **Q1/H3 — medición por persona del replay** | Wistia NO acepta token propio en el webhook (solo `visitor.id` por cookie o email vía Turnstile). Hay que elegir entre **email-gate / mapeo `visitor.id`↔token / otro host (api.video)**. Sin esto, el follow-up segmentado por replay no tiene señal fiable. Decisión técnica + UX (fricción del email-gate). Ninguna call la cierra. **Es el crux del motor de segmentación.** |
| **¿Sobrevive el cerebro propio o lo reemplaza GHL?** | Decisión de arquitectura + coste/recursos (línea roja BeZy≠LV). Si GHL: ¿instancia de LV (requiere acuerdo de coste) o nueva de BeZy? ¿GHL como CRM/comms al lado de la DB, o como sistema de estado? **No es decisión de dev** → Max/Jesús/Kley. |
| **Rol de 11ty vs cerebro Next.js/Postgres** | ¿11ty solo capa de contenido coexistiendo con el brain, o replanteo de arquitectura? Define si los ADRs de stack siguen vigentes. Las calls no desambiguan. |
| **Kapso Groups API (Q48/Q50)** | Sigue en waitlist. Acción externa (confirmar con Kapso: qué hace, early access partners, reemplazo compliant a Whapi) + decisión de cliente (¿para qué se usa el grupo: solo comunidad o también entrega de contenido?). Las calls usan Kapso para 1:1, no confirman su API de grupos. |
| **Q45/Q19 — cadencia/horarios/copy de follow-ups y corte** | Las calls confirman QUÉ follow-ups se quieren, no las reglas. Decisión de negocio + contenido (Kley/Jesús), no de dev. |
| **Q46 — alcance 7 vs 60 días** | v1.0 = 7 días hasta la venta confirmado; **no se descarta** que el cliente espere los 60 días del P60. Abre/no abre una fase nueva entera. Lo cierra el cliente. |
| **Q7 — participante recurrente entre cohortes** | ¿Identidad global con historial o nuevo por cohorte? (default repo: por cohorte). Impacto en modelo de datos. No inventar desde el default → cliente. |
| **Q15/Q20 — hora/TZ de envío diario + umbral "completo"** | ¿80% o los umbrales 25/50/75/100 de Wistia (H4)? + ventana de timeout del replay. El default del repo ≠ respuesta del cliente. |
| **Q21/Q22/Q24 — pago del P60** | ¿Pago único o cuotas? Moneda (**60 USD vs ~60 € con Stripe/Bizum**) y compra fuera del funnel. Cambia cuándo se considera "convertido". Decisión financiera del cliente. **No elijas la moneda.** |
| **Q25 — testimonio/experiencia** | ¿Obligatorio? ¿Incentivado? ¿Consentimiento para uso público con nombre? Decisión de cliente + legal. |
| **Q2 (pendiente) — baja por WhatsApp con "BAJA"** | La baja desde panel por Ops ya está decidida; falta el mecanismo por WhatsApp (obligatorio en España). Cliente + legal. |
| **Q13 (pendiente) — roles/permisos en el panel** | Multi-usuario ya decidido; ¿granular Ops vs Organizador o todos ven todo? Cliente. |
| **H9 (residuo) — overflow >100 por cohorte** | ~100/grupo confirmado, pero no el manejo de sub-grupos (1 cohorte ↔ varios grupos). Operativa de cliente + diseño de cohorte. |

---

## 7. Notas de negocio / contexto (breve)

**Números reales (todos trazados, no inventados):**

- De ~100 participantes, **~20 toman acción**; el ~80% restante es la mina de oro (descubrir por qué no actuaron y su interés real). *(`01-CONTEXTO-BEZY.md`)*
- El **seguimiento 1:1 manual** subió la conversión de **~20% a ~40%**. El 1:1 convierte; el grupo da prueba social. *(`01-CONTEXTO-BEZY.md` + Kley 4-jun)*
- Prueba social real: **Maribel, 526€ recuperados en una semana**. *(`01-CONTEXTO-BEZY.md`)*
- Señal de participación: de **~112-116 personas, solo ~35 enviaron factura** (por eso "envió la factura" es un KPI). *(Kley 11-may + 4-jun)*
- Grupos de **~100 máximo** (hoy, manual). *(`01-CONTEXTO-BEZY.md`)*
- **Coste Kapso 1:1:** primer mensaje paga tarifa Meta (plantilla); al tocar un botón abre ventana **"utility" mucho más barata**. Modelarlo importa para el coste a escala. *(Kley 4-jun)*
- **"300+/cohorte" es el supuesto VIEJO del repo** (el NFR no fija tasa de throttling, solo "configurable"), no un dato actual. La realidad operativa es ~100/grupo.

**Línea roja (no negociable):**

- **BeZy es el negocio PERSONAL de Jesús, SEPARADO de Lector Voraz.** El OS los trata en carpetas distintas a propósito. *(`01-CONTEXTO-BEZY.md`)*
- **Recursos de LV (equipo, GHL, funnels, audiencia) NO se usan para BeZy sin acuerdo explícito de coste.** Por eso la opción "GHL como sistema base" (C2) abre la pregunta de si es la GHL de LV (requiere acuerdo) o una instancia nueva de BeZy. `[regla a confirmar con Max]` *(`01-CONTEXTO-BEZY.md`)*
- Validar con la comunidad propia ANTES de escalar con ads (mismo principio que LV). *(`01-CONTEXTO-BEZY.md`)*

---

*Trazabilidad: cada afirmación apunta a una call con fecha (Ale 3-jun-2026, Kley 4-jun-2026, Kley 11-may-2026, Jesús 8-may/11-may-2026) o a un archivo (`01-CONTEXTO-BEZY.md` real del spoke; el resto — `open-questions.md`, `client-questions.md`, `adr/*`, `integration-research.md`, `nfr-and-security.md`, `wireframe-brief.md` — son rutas de tu propio repo reto-antiventaja). Huecos sin dato = `[pendiente]`.*
