# Reto Antiventaja — Brief de wireframes

> Input para generar wireframes/prototipos (claude-design). Cubre las 2 superficies web del MVP.
> No incluye el canal de WhatsApp (lo ejecuta la capa no-code). Deriva de `domain-model.md` y `mvp-scope.md`.
> Fecha: 2026-05-29

---

## Principios de diseño (transversales)

1. **Mobile-first en lo público**: el participante llega desde un link de WhatsApp, casi siempre en el teléfono. El formulario debe ser impecable en mobile.
2. **Tono "anti-ventaja" (Q12)**: copy cálido, honesto, sin lenguaje de venta agresivo. Transmitir acompañamiento, no presión. Aplica a TODO el texto de cara al participante.
3. **Fricción mínima en el registro**: lo justo y necesario. Cada campo extra cuesta conversión.
4. **Dashboard denso pero escaneable**: Ops necesita procesar 300+/cohorte; priorizar acciones rápidas (aceptar/rechazar) y lectura veloz del embudo.
5. **Idioma**: **español de España (es-ES)** — el producto se lanza para España. Tuteo ("tú"), vocabulario peninsular ("dinero", "móvil", +34). Tono cercano pero no rioplatense.
6. **Stack de UI sugerido**: Next.js (App Router) + Tailwind + **shadcn/ui** (alineado al ecosistema del usuario). Componentes accesibles por defecto.
7. **Estados siempre cubiertos**: loading, vacío, error y éxito en cada pantalla. No diseñar solo el "happy path".

---

## SUPERFICIE 1 — Formulario público de registro

Público: el **participante** (probablemente con poca alfabetización financiera, llega curioso/escéptico). Objetivo: registrarse con fricción mínima y entender que hay un paso de verificación.

### P1.1 — Formulario de registro
- **Propósito**: capturar datos + atribución y generar el `token`.
- **Elementos**:
  - Encabezado con identidad del reto + 1 línea de propuesta de valor (tono anti-ventaja).
  - Campos (provisional, depende de **Q3**): `Nombre completo` (req), `WhatsApp` (req, con selector de país / formato E.164), `Email` (opcional).
  - Campo **"¿Quién te invitó al reto?"** (depende de **Q4**): provisional = texto libre con autocompletado suave si hay match; si el link trae el token del impulsor, **viene pre-cargado y bloqueado/confirmable**.
  - Consentimiento de datos (checkbox) — necesario por datos personales.
  - CTA primario claro.
  - Señales de confianza (qué va a pasar después, cuánto tarda).
- **Validación**: inline, no agresiva. WhatsApp válido obligatorio.
- **Variante de entrada por link de impulsor**: misma pantalla con "Te invitó **{nombre}**" visible.

### P1.2 — Post-submit: "Estamos verificando" (Q10)
- **Propósito**: explicar el gate humano sin generar abandono.
- **Elementos**: confirmación de recepción, expectativa de tiempo, qué hacer mientras tanto (ej. botón a WhatsApp), tono tranquilizador. Sin prometer aceptación.

### P1.3 — Aceptado: instrucciones para unirse al grupo
- **Propósito**: llevar al participante aceptado al grupo de WhatsApp.
- **Elementos**: mensaje de bienvenida, **botón/link para unirse al grupo**, próximos pasos del reto. (Este estado puede llegarle también por WhatsApp; la pantalla es respaldo.)

### P1.4 — Estados secundarios
- **Rechazado (Q9)**: si se decide mostrarlo — mensaje respetuoso, ¿opción de re-aplicar?
- **Ya registrado / duplicado (Q6)**: "ya te tenemos registrado".
- **Error de envío**: reintento claro.

### P1.5 — Experiencia / testimonio (al terminar el reto)
- **Propósito**: capturar `ExperienciaCompletada` (el mapa original lo menciona como "formulario Excel/Online").
- **Elementos**: experiencia (texto), cambio percibido en el manejo del dinero (radio), aprendizaje (opcional), ¿recomendarías? y **consentimiento para uso del testimonio (Q25)** — público con nombre de pila vs anónimo/interno. Tokenizado, sin login.

> **Alcance del participante (Q42 — RESUELTO): WhatsApp-first, SIN portal.** El participante NO tiene login ni área de cuenta ni carga de Excel (el Excel solo se entrega; no capturamos datos financieros). Superficies de participante en MVP: P1.1–P1.5 (+ condicionales: baja Q2, landing de replay Q1). Un portal con login/carga/cuenta sería expansión futura.

---

## SUPERFICIE 2 — Dashboard interno

Público: **Ops** (verifica y modera) y **Organizador** (mira resultados). Roles y permisos a definir (**Q13**) — por ahora diseñar como un dashboard con secciones, asumiendo que Ops ve todo.

### P2.1 — Overview / Embudo
- **Propósito**: estado del reto de un vistazo.
- **Elementos**:
  - Selector de **cohorte** (activa por defecto).
  - **Embudo** con conteos y tasas: Registrados → Aceptados → En grupo → Post-presentación → **Convertidos**.
  - KPIs: conversión free→paid, % replays vistos, participación.
  - Distribución por **segmento** (no_vio / parcial / completo).
  - Alertas operativas: nº en bandeja de verificación, acciones fallidas (link a P2.5).

### P2.2 — Bandeja de verificación (Ops) ⭐ pantalla más usada
- **Propósito**: aceptar/rechazar registros rápido, a escala (300+).
- **Elementos**:
  - Lista de participantes en `PENDIENTE_VERIFICACION` con: nombre, WhatsApp, "quién lo invitó" (resuelto o crudo), fecha de registro.
  - Acciones por fila: **Aceptar** / **Rechazar** (con motivo, Q8). 
  - **Acciones en lote** (aceptar varios) — clave para escalar.
  - Filtro/orden (más antiguos primero).
  - Indicador de atribución no resuelta (bandeja Q4).
- **Estados**: vacío ("nada por verificar"), procesando, error.

### P2.3 — Lista de participantes
- **Propósito**: explorar/filtrar toda la población.
- **Elementos**: tabla filtrable por estado, cohorte, segmento, impulsor; búsqueda por nombre/WhatsApp; paginación. Fila → P2.4.

### P2.4 — Detalle de participante
- **Propósito**: ver la historia completa de una persona.
- **Elementos**: datos + estado actual + `current_day`/`segment`; **timeline de eventos** (registro → aceptación → alta → contenidos → video → follow-ups → conversión); atribución (quién lo invitó); **acciones de salida** enviadas/fallidas; comportamiento de video (% visto).

### P2.5 — Salud operativa / cola de acciones (MVP-lite)
- **Propósito**: visibilidad de la mensajería (Q27, Q28).
- **Elementos**: acciones `pendiente`/`fallida`, reintentos, backlog, throttling actual. Acción: reintentar / a bandeja Ops.

### P2.6 — Atribución / impulsores
- **Propósito**: quién trae gente y quién convierte (sin liquidar comisiones — fuera de MVP).
- **Elementos**: ranking de impulsores por referidos y por conversiones atribuidas; detalle de un impulsor con su lista de referidos y estados.

### P2.7 — Cohortes (config)
- **Propósito**: crear/configurar una cohorte.
- **Elementos**: nombre, `start_date`, `timezone`, `presentation_at`, estado (borrador/activa/cerrada).

---

## Mapa de pantallas (resumen)

```
PÚBLICO (mobile-first)          INTERNO (desktop-first)
P1.1 Registro                   P2.1 Overview/Embudo
P1.2 Verificando                P2.2 Bandeja de verificación ⭐
P1.3 Aceptado→grupo             P2.3 Lista de participantes
P1.4 Estados 2rios              P2.4 Detalle de participante
                                P2.5 Salud operativa
                                P2.6 Atribución/impulsores
                                P2.7 Cohortes (config)
```

## Dudas que impactan estos wireframes (de open-questions.md)
- **Q3** campos exactos del formulario · **Q4** input de atribución (texto libre vs lista) · **Q9** mostrar rechazo y re-aplicación · **Q10** copy del estado "verificando" · **Q13** roles/permisos del dashboard.
- Para los wireframes se usan los **defaults provisionales** de arriba; se ajustan tras respuestas del cliente. **Q1 no bloquea** estas pantallas (son web, no el canal WhatsApp).
