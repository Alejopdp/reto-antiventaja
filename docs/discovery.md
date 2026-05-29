# Reto Antiventaja — Discovery

> Estado: **Fase 1 — Entender (Research)**. Documento vivo. No hay decisiones de implementación tomadas todavía.
> Fecha: 2026-05-29

---

## 0. Qué es esto (en una frase)

Un embudo de educación financiera entregado por WhatsApp: un **reto gratuito de 7 días** que prepara y convierte participantes en clientes de un **plan de pago de 60 días (P60, 60 USD)**, con **atribución de referidos/comisiones** a quien invita ("impulsor") y **seguimiento automatizado por comportamiento** (qué contenido consume cada persona).

Modelo de negocio: adquisición por referidos + conversión free→paid + comisión al referente. Tiene rasgos de marketing de afiliación/comunidad. Esto tiene implicancias (ver §7).

---

## 1. Actores y Jobs To Be Done (JTBD)

El sistema tiene **4 actores** con trabajos distintos. Diseñar para uno solo es el error clásico.

### 1.1 Participante (end user — el corazón)
- **Funcional**: *"Cuando siento que no controlo mis finanzas y me abruma, quiero un sistema simple y guiado que me diga qué hacer cada día, para empezar a ordenar mis gastos sin frustrarme."*
- **Emocional**: *"Quiero sentir que avanzo y que pertenezco a una comunidad que me sostiene, no estar solo con mi desorden financiero."*
- **Social**: *"Quiero poder mostrar mi transformación / pertenecer a un grupo que progresa."*
- Lo que valora: claridad diaria, fricción cero, sensación de logro, no sentirse vendido (de ahí "anti-ventaja"/"antiventaja").
- Lo que lo hace abandonar: fricción para entrar, sentirse spameado, contenido genérico, no entender el siguiente paso.

### 1.2 Impulsor / Referente (quien invita)
- **JTBD**: *"Cuando invito gente al reto, quiero que se me atribuya correctamente cada referido que convierte, para cobrar mi comisión y saber a quién acompañar."*
- Lo que valora: atribución justa y transparente, visibilidad de su pipeline, cobro confiable.
- Dolor crítico: atribución que se pierde o es ambigua → desconfianza → deja de invitar. **La atribución es el activo de negocio.**

### 1.3 Equipo de operaciones (verifica formularios, da de alta, modera)
- **JTBD**: *"Quiero que el alta, la verificación y el envío de contenido sean lo más automáticos posible para no ser el cuello de botella cuando entren 50 personas el mismo día."*
- Dolor: hoy hay un paso manual (verificar formulario + añadir al grupo). No escala.

### 1.4 Organizador / Dueño del reto (el negocio)
- **JTBD**: *"Cuando lanzo una cohorte, quiero convertir el máximo de participantes gratuitos en clientes P60 sin seguimiento manual uno a uno, y entender qué funciona para mejorar cada cohorte."*
- Métricas que le importan: conversión free→paid, participación diaria, % de replays vistos, atribución/comisiones, retención.

---

## 2. Mapa del flujo (estados del participante)

El participante atraviesa una **máquina de estados**. Modelar esto bien es el 80% del producto.

```
INVITADO → REGISTRADO → ACCESO_SOLICITADO → EN_GRUPO (bienvenida)
   → PRECALENTAMIENTO → RETO_DIA_1..7 → PRESENTACION_P60 (en vivo / no asistió)
   → REPLAY (no_vio / parcial<80% / completo>80%) → [follow-up segmentado]
   → REGISTRADO_P60 (conversión) → comisión asignada al impulsor
   → EXPERIENCIA (testimonio)
```

Eventos que disparan transiciones: submit de formulario, alta al grupo, apertura/visionado de video (webhook de video), respuesta a encuesta, pago P60.

---

## 3. Casos de uso principales

1. Participante se registra vía link de un impulsor y queda atribuido a él.
2. Ops verifica y da de alta (idealmente semi-automático).
3. Sistema envía contenido diario del reto (7 días) y entrega el Excel.
4. Sistema detecta comportamiento en el replay y dispara el follow-up correcto.
5. Participante paga el P60 → se asigna comisión automáticamente al impulsor correcto.
6. Organizador ve un dashboard con embudo, conversión y atribución.

---

## 4. Edge cases (lo que rompe el sistema si no se piensa)

### Atribución (el más crítico para el negocio)
- Persona entra al grupo por un link compartido libremente, **sin pasar por el formulario** → no hay a quién atribuir ni cómo trackear.
- Dos impulsores dicen haber invitado a la misma persona / nadie la invitó.
- La persona pone mal "quién me invitó" (texto libre, typos, homónimos).
- Reembolso del P60 → ¿se revierte la comisión?
- ¿Es **un solo nivel** (A invita a B, A cobra) o **multinivel** (A invita a B, B invita a C, A cobra de ambos)? Cambia radicalmente el modelo de datos y el riesgo legal.

### Identidad
- El número de WhatsApp es el ID natural, pero el del formulario puede no coincidir con el que escribe al grupo.
- La persona cambia de número / usa otro para el grupo.

### Tracking de video
- ¿"80%" es del largo del video o del tiempo de sesión? ¿Cuenta si lo ve en 2 sesiones / 2 dispositivos?
- Replay descargado o reenviado: no se trackea.

### Mensajería / WhatsApp
- Límites y plantillas de la WhatsApp Cloud API; ventana de 24h para mensajes de sesión.
- Riesgo de baneo con automatización no oficial sobre grupos.
- Idempotencia: no mandar el mismo follow-up dos veces; no duplicar al reprocesar un webhook.
- Zona horaria para "contenido diario", "domingo" y recordatorios.

### Operación
- Varias cohortes corriendo en paralelo (el reto es recurrente) → un participante pertenece a una cohorte; los días son relativos a SU fecha de inicio.
- Persona que se registra al formulario pero nunca entra al grupo (fuga silenciosa).

---

## 5. La pregunta de producto que define el MVP: **build vs buy**

Casi todo el flujo del mapa **ya se puede hacer con no-code** (Make + WhatsApp API + Airtable + Wistia + ElevenLabs + ChatGPT). Por eso la decisión central no es "cómo lo programamos" sino **qué construimos nosotros vs. qué dejamos en herramientas existentes**.

Dónde el software propio **agrega valor real** (el "cerebro"):
- **Atribución de referidos y comisiones** — el corazón del negocio; los no-code lo resuelven mal/frágil.
- **Estado del participante (single source of truth)** a lo largo del embudo.
- **Motor de segmentación de follow-up** (no vio / parcial / completo → mensaje correcto, idempotente).
- **Dashboard analítico** del embudo.

Dónde **no** conviene construir en MVP (usar lo existente):
- Hosting + tracking de video → Wistia/Vimeo (ya resuelto, mandan webhooks).
- Audios IA → ElevenLabs. Copy → ChatGPT manual.
- Envío de WhatsApp → WhatsApp Cloud API / proveedor (BSP).

> **Hipótesis de MVP**: construir el "cerebro" (datos + atribución + segmentación + dashboard + formulario de registro propio), e **integrar** lo demás. No reconstruir video/IA/mensajería.

### Opciones de alcance (a decidir con el usuario)
- **A — Solo el cerebro + integraciones** *(recomendado)*: formulario propio, DB de estado/atribución, motor de follow-up, dashboard; WhatsApp/video/IA vía herramientas externas.
- **B — App end-to-end propia**: además construir envío de WhatsApp, tracking propio, etc. (más caro, más control, más riesgo).
- **C — 100% no-code**: nosotros solo orquestamos Make/Airtable. (rápido, pero techo bajo y atribución frágil).
- **D — Slice mínimo**: solo formulario de registro + DB de atribución, para validar el activo más crítico primero.

---

## 6. Stack candidato (si vamos por opción A, alineado al stack del usuario)

- **Front + API**: Next.js 15 (App Router) — formulario público de registro + dashboard interno. Coincide con `leia-app`.
- **DB**: PostgreSQL + Drizzle (RDS o Vercel Marketplace/Neon). Modela cohorte, participante, estado, evento, atribución, comisión.
- **Mensajería**: WhatsApp Cloud API (oficial) con plantillas, o BSP. *(a definir — ver §7)*
- **Tracking de video**: webhooks de Wistia/Vimeo → endpoint propio → eventos.
- **Jobs/scheduling**: contenido diario y follow-ups → cron + cola (Vercel Cron / Queues, o similar). Idempotencia obligatoria.
- **Hosting**: Vercel o AWS, según preferencia.

Esto es **candidato**, no decidido. Se ajusta tras las respuestas de §8.

---

## 7. Riesgos / compliance a decidir (no técnicos, pero condicionan todo)

- **Modelo de comisiones**: afiliación de un nivel vs. multinivel. El multinivel tiene exposición legal según jurisdicción y complica el modelo de datos. **Decidir explícitamente.**
- **WhatsApp**: API oficial (Cloud API, cumple ToS, plantillas aprobadas, más fricción) vs. automatización no oficial sobre grupos (como sugiere el mapa con Marychat — más flexible, riesgo de baneo). Trade-off real.
- **Datos personales/financieros**: consentimiento, almacenamiento, baja. Si hay usuarios en la UE, GDPR.
- **Promesas financieras**: publicidad de resultados económicos está regulada en varias jurisdicciones. Lenguaje del contenido.

No hace falta resolverlos hoy, pero el dueño debe elegir postura porque cambian el diseño.

---

## 7.bis Decisiones tomadas (iteración 1 — 2026-05-29)

- **Alcance**: Opción **A — Solo el "cerebro" + integraciones**. Construimos formulario propio + DB de estado/atribución + motor de follow-up + dashboard. WhatsApp / video / audios IA quedan en herramientas externas.
- **WhatsApp**: **Automatización de grupos (no oficial)**, tipo Marychat sobre grupos. Nuestro app NO envía WhatsApp directo: emite *acciones de salida* que la capa no-code ejecuta.
- **Comisiones**: **Sin liquidación por ahora**. Igual capturamos el grafo de atribución "quién invitó a quién" (activo a futuro), pero sin lógica de cálculo/cobro en el MVP.
- **Escala**: **Recurrente, volumen alto (300+/cohorte)**. La automatización del alta y del follow-up es obligatoria, no opcional. Modelar cohorte + días relativos al inicio de cada persona.

### ⚠️ Tensión a vigilar (no bloquea, pero hay que monitorearla)
La combinación **volumen alto (300+) + automatización NO oficial sobre grupos** es la de mayor riesgo de **baneo del número y límites de rate**. Es viable, pero conviene: (a) tener plan B (migrar a API oficial si crece), (b) diseñar el motor de follow-up para que sea *agnóstico del canal* (emitir "acción de salida" abstracta), de modo que cambiar de capa de mensajería no toque el cerebro.

### Decisiones (iteración 2 — 2026-05-29)
- **Excel**: solo se **entrega como archivo** (link de descarga). El app NO captura ni analiza datos financieros del participante. → menor alcance y sin manejo de datos sensibles.
- **Hipótesis a validar**: sin priorizar todavía. → el MVP construye la **columna vertebral completa pero lean** (alta + entrega del reto + tracking + follow-up + dashboard), sin sobre-invertir en conversión ni en operación por separado.
- **Dueño**: **cliente específico** (no multi-tenant, no white-label). → single-tenant. Aparece dependencia: el **setup existente del cliente** (herramienta de grupos, host de video, cómo cobra el P60, contenido, número/grupo, zona horaria).

### Implicación arquitectónica de estas decisiones
- **Nuestro app = fuente de verdad**: cohorte, participante, estado, eventos, grafo de atribución, analítica + formulario público.
- **Frontera de integración por webhooks/acciones**: la capa no-code (Make + automatizador de grupos) avisa a nuestro app (nuevo miembro, respuesta, video visto vía webhook de Wistia/Vimeo) y consume del app la *cola de acciones pendientes* (qué mensaje/contenido toca enviar).
- **El reto de identidad es el crux**: atar `número de WhatsApp ↔ submission del formulario ↔ visionado de video`. Propuesta: el formulario genera un **token único por participante**; todo link de contenido/video lo lleva; el alta al grupo se matchea por número de teléfono.

---

## 8. Preguntas abiertas para iterar (bloquean el plan)

1. **Alcance build-vs-buy**: ¿opción A/B/C/D de §5?
2. **WhatsApp**: ¿API oficial, automatización de grupos, o híbrido?
3. **Comisiones**: ¿un solo nivel o multinivel?
4. **Recurrencia**: ¿una cohorte piloto única, o producto recurrente con muchas cohortes? ¿Cuántas personas por cohorte se esperan (10? 500?)?
5. **Dueño/cliente**: ¿es producto propio de Novox, de un cliente, white-label?
6. **Qué validar primero**: ¿la hipótesis es *conversión* (¿la gente paga el P60?) u *operación* (¿podemos escalar el alta y el seguimiento sin equipo?)?
7. **Excel de control de gastos**: ¿es solo un archivo que se entrega, o el producto debería capturar/analizar esos datos financieros? (cambia mucho el alcance)

---

## 9. Próximos pasos

1. Responder §8 (iteración con el usuario).
2. Cerrar alcance del MVP y postura de compliance.
3. Pasar a **Fase 2 — Planificar**: modelo de datos, lista de casos de uso priorizada, descomposición en tareas atómicas y waves.
