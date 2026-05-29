# Reto Antiventaja

Producto de **educación financiera por WhatsApp**: un reto gratuito de 7 días que convierte participantes en clientes de un plan de pago (P60, 60 €), con seguimiento automatizado por comportamiento y atribución de referidos. Mercado: **España**.

> **Estado:** fase de **discovery + diseño**. Este repo contiene la documentación de producto/arquitectura y prototipos de wireframes. **Todavía no hay código de la aplicación.**

---

## 🧭 Cómo revisar este trabajo con Claude

Este repo está preparado para iniciar una sesión de **Claude Code** dentro de la carpeta y tener todo el contexto cargado automáticamente (ver [`CLAUDE.md`](./CLAUDE.md)). Buenos primeros prompts:

- *"Resumime el estado del proyecto y las decisiones tomadas leyendo `docs/`."*
- *"Repasá `open-questions.md`: ¿qué hay que cerrar con el cliente y qué podemos decidir nosotros?"*
- *"Cuestioná los supuestos del `domain-model.md`."*
- *"Mostrame los wireframes y cómo se relacionan con el modelo de dominio."*

## 🖼️ Ver los wireframes

Prototipos HTML autocontenidos (requieren conexión para cargar estilos/fuentes por CDN).

```bash
# opción servidor local (recomendado)
python3 -m http.server 8080
# abrir http://localhost:8080/wireframes/
```
O abrir directamente `wireframes/index.html` en el navegador. Para compartir online, se puede activar **GitHub Pages**.

9 pantallas: registro público, aceptado→grupo, estados secundarios, y el panel interno (embudo, verificación, lista, detalle de participante con timeline de eventos, atribución, cohortes).

## 📚 Documentación (`docs/`)

| Documento | Contenido |
|---|---|
| [`discovery.md`](./docs/discovery.md) | JTBD, actores, edge cases, decisiones iniciales |
| [`mvp-scope.md`](./docs/mvp-scope.md) | Alcance, modelo de datos, integración, criterio no-regret, roadmap |
| [`event-storming.md`](./docs/event-storming.md) | Eventos, comandos, policies, sistemas externos, hotspots |
| [`domain-model.md`](./docs/domain-model.md) | Entidades, statechart, glosario ubicuo, invariantes |
| [`contracts/`](./docs/contracts/) | Interfaces de los 3 puertos + frontera HTTP + `openapi.yaml` |
| [`schema.sql`](./docs/schema.sql) | DDL de referencia (PostgreSQL) |
| [`use-cases.md`](./docs/use-cases.md) | Casos de uso con criterios Given/When/Then |
| [`test-plan.md`](./docs/test-plan.md) | UC → tipos de test + definition of done (backlog TDD) |
| [`tasks.md`](./docs/tasks.md) | Desglose en waves + DAG (plan de ejecución) |
| [`engineering-guidelines.md`](./docs/engineering-guidelines.md) | Capas, DI, estrategia de tests (TDD), convenciones |
| [`nfr-and-security.md`](./docs/nfr-and-security.md) | No funcionales, GDPR/PII, ToS WhatsApp, seguridad |
| [`integration-research.md`](./docs/integration-research.md) | Candidatos de plataforma (WhatsApp/vídeo/pagos): límites, precios, riesgos |
| [`ui-audit.md`](./docs/ui-audit.md) | Inventario de controles UI ↔ comandos de dominio |
| [`open-questions.md`](./docs/open-questions.md) | ⭐ Dudas abiertas vivas (para el cliente y de diseño) |
| [`wireframe-brief.md`](./docs/wireframe-brief.md) | Brief que originó los prototipos |
| [`adr/`](./docs/adr/) | Architecture Decision Records |

## 🏛️ En una línea

Cerebro **agnóstico del canal** (arquitectura hexagonal, event log) que orquesta el embudo del reto e indica *qué* mensaje enviar; la capa no-code de WhatsApp ejecuta el *cómo*. Single-tenant, preparado para 300+ por cohorte.

## ⚠️ Decisiones aún abiertas (ver `open-questions.md`)

Las más importantes para el cliente: **Q1** (contenido/replay ¿broadcast al grupo o 1:1 con tracking por persona?) y **Q2** (baja/opt-out). La elección de PSP, host de vídeo y herramienta de WhatsApp está deliberadamente diferida (aislada tras puertos).
