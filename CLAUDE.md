# Reto Antiventaja — Contexto para Claude

> Este archivo lo carga Claude Code automáticamente al iniciar sesión en esta carpeta.
> Si estás leyendo esto como asistente: orientá tu trabajo con lo de abajo antes de actuar.

## Qué es este proyecto

**Reto Antiventaja** es un producto de **educación financiera entregado por WhatsApp**: un reto gratuito de 7 días que prepara y convierte participantes en clientes de un plan de pago de 60 días (**P60, 60 €**), con seguimiento automatizado según el comportamiento de cada persona y atribución de "quién invitó a quién".

- **Mercado: España.** Todo el copy de cara al usuario final va en **español de España (es-ES)** (tú, "dinero", móvil, +34). La comunicación de trabajo puede ser en el español del equipo.
- **Modelo de negocio:** adquisición por referidos + conversión free→paid. (Las comisiones están **fuera del MVP**; solo se captura el grafo de atribución.)

## Estado actual: Fase de DISCOVERY + DISEÑO (no hay código de la app todavía)

Lo que existe es **documentación de producto/arquitectura** y **prototipos de wireframes HTML** (throwaway, no la app real). **Todavía NO se construyó la aplicación.** No empieces a implementar la app salvo que el usuario lo pida explícitamente: seguimos en diseño.

## Cómo está organizado el repo

```
docs/                         ← documentación (fuente de verdad del diseño)
├── discovery.md              JTBD, actores, edge cases, decisiones iniciales
├── mvp-scope.md              alcance, modelo de datos, integración, criterio no-regret, roadmap
├── event-storming.md         eventos / comandos / policies / sistemas externos / hotspots
├── domain-model.md           entidades, statechart, glosario ubicuo, invariantes
├── contracts/                interfaces de los 3 puertos + frontera HTTP + openapi.yaml
├── schema.sql                DDL de referencia (PostgreSQL) alineado a ADR-0002
├── use-cases.md              casos de uso con criterios Given/When/Then
├── test-plan.md              UC → tipos de test + definition of done (backlog TDD)
├── tasks.md                  desglose en waves + DAG (plan de ejecución)
├── engineering-guidelines.md capas, DI, estrategia de tests (TDD), convenciones, anti-overeng.
├── nfr-and-security.md       escala, idempotencia, GDPR/PII, ToS WhatsApp, observabilidad
├── integration-research.md   candidatos (WhatsApp/video/PSP): rate limits, pricing, riesgos (deep-research)
├── ui-audit.md               inventario de controles UI ↔ comandos de dominio
├── open-questions.md         ⭐ DUDAS ABIERTAS vivas — [CLIENTE] vs [DISEÑO], algunas para el cliente
├── client-questions.md       las dudas en lenguaje no técnico, priorizadas (agenda de reunión)
├── wireframe-brief.md        brief que originó los prototipos
└── adr/                      ADRs: 0001 acciones, 0002 persistencia, 0003 stack, 0004 cloud (propuesto)
wireframes/                   ← prototipos HTML interactivos (abrir index.html)
```

**Orden de lectura recomendado:** `discovery.md` → `mvp-scope.md` → `event-storming.md` → `domain-model.md` → `contracts/` → `use-cases.md` → `tasks.md` → `open-questions.md` → `adr/`. Después abrir `wireframes/index.html`.

## Decisiones clave ya tomadas (no re-litigar sin motivo; ver docs para el "por qué")

- **Arquitectura hexagonal (puertos y adaptadores).** El "cerebro" es agnóstico del canal. 3 puertos: `MessagingPort` (WhatsApp), `VideoTrackingPort` (Wistia/Vimeo), `PaymentPort` (PSP). Las herramientas concretas se eligen detrás de cada puerto (aún sin decidir).
- **Event log append-only** como fuente de verdad; estado del participante materializado (no event sourcing completo).
- **Single-tenant** (es para un cliente específico, no multi-tenant).
- **Cohorte ≠ Grupo de WhatsApp.** Cohorte = membresía lógica (se entra por gate humano de Ops); el grupo es solo el canal.
- **Acciones de salida = evento abstracto tipado** (`AcciónEncolada{action_type,...}` + `AcciónResuelta{status}`), ver ADR-0001.
- **Atribución = Modelo A** (link único compartido + texto auto-reportado; resolución en bandeja Ops). El Modelo B (link por impulsor) es evolución futura. Ver `open-questions.md` Q38.
- **WhatsApp:** automatización no oficial de grupos (decisión del cliente); por eso el diseño aísla el canal.
- **Sin comisiones en MVP** (solo se guarda el grafo de atribución).

## Metodología usada (para que entiendas el enfoque)

Discovery con JTBD + design thinking → **Event Storming lite** (eventos/comandos/policies/hotspots) → **domain model** (DDD-lite, statechart, lenguaje ubicuo) → **ADRs** para decisiones que importan → wireframes con el plugin `frontend-design`. Las dudas se acumulan en `open-questions.md` en vez de decidirse a ciegas.

## Qué se puede hacer ahora (y qué NO)

**SÍ:**
- Revisar y cuestionar la documentación y los supuestos (está fomentado: ver `open-questions.md`).
- Ver e iterar los wireframes; refinar `open-questions.md`.
- Cuando se apruebe, **empezar a implementar siguiendo `tasks.md`** (Wave 0 → walking skeleton en Wave 1). El diseño (discovery, dominio, contratos, casos de uso, tareas) ya está completo.

**NO (sin pedirlo explícitamente):**
- Arrancar la implementación sin aprobación / elegir herramientas concretas de los puertos antes de las respuestas del cliente / commitear o pushear.
- Avanzar la parte de **vídeo/segmentación** (Wave 3) antes de cerrar **Q1**.

## Cómo trabajar en este repo

- **No implementar de más:** seguimos en diseño. Resolvé lo pedido, sin features especulativas.
- **Cuestioná supuestos** antes de darlos por buenos; registrá nuevas dudas en `open-questions.md`.
- **Git:** no commitear ni pushear sin autorización explícita. Commits en inglés.
- **Hotspots críticos abiertos para el cliente:** sobre todo **Q1** (contenido/replay ¿broadcast al grupo o 1:1 tokenizado? — define si existe el tracking por persona) y **Q2** (baja/opt-out). Muchos dashboards asumen Q1 = 1:1.

## Wireframes: cómo verlos e interactuar

Son HTML autocontenidos (Tailwind + Google Fonts por CDN — requieren conexión para que carguen los estilos/fuentes).

- **Rápido:** abrir `wireframes/index.html` en el navegador.
- **Recomendado (servidor local):** desde la carpeta del repo:
  ```bash
  python3 -m http.server 8080
  # luego abrir http://localhost:8080/wireframes/
  ```
- **Para compartir online:** se puede activar **GitHub Pages** apuntando a la raíz; los prototipos quedan navegables en `https://<usuario>.github.io/<repo>/wireframes/`.

## Buenos primeros prompts para revisar el trabajo

- "Resumime el estado del proyecto y las decisiones tomadas leyendo `docs/`."
- "Repasá `open-questions.md` y decime qué hay que cerrar con el cliente vs qué podemos decidir internamente."
- "Cuestioná los supuestos del `domain-model.md` y marcá lo que te haga ruido."
- "Mostrame los wireframes y explicame cómo el embudo refleja el statechart."
- "Avancemos con `contracts/` (interfaces de los puertos) — pero antes mostrame tu plan."
