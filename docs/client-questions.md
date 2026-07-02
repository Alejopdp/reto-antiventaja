# Preguntas para el cliente — agenda de reunión

> Versión en lenguaje claro de lo que necesitamos definir para construir el MVP. Ordenado por prioridad: lo de arriba **bloquea** el desarrollo. Donde tenemos una recomendación, la marcamos para que decidir sea rápido.
> (Las referencias `Q##` son para nuestro seguimiento interno — ver `open-questions.md`.)

---

## 🔴 Bloque 1 — Lo que más nos traba (decidir primero)

**1. ¿El contenido y el replay se ven en el grupo o de forma individual?** `(Q1, H3)`
Si todo se manda al grupo (todos juntos), no podemos saber **quién vio qué** ni hacer seguimiento personalizado. El seguimiento automático por comportamiento **solo funciona si el replay se entrega de forma individual** a cada persona (con un enlace propio).
→ *Recomendación: comunidad/dinámicas en el grupo, pero replay y videos clave individuales.*
> **Lo que más nos preocupa resolver:** cómo **identificamos a la persona que abrió el replay** y cómo **medimos cuánto vio**.
> ✅ **Ya lo resolvimos (técnico):** entregamos el replay en una **página propia con enlace único por persona** y **medimos nosotros** el visionado (con los eventos del reproductor) → sabemos quién vio y cuánto, sin depender del host. Así Wistia **deja de ser necesario** (ver punto 21). Queda de ustedes solo lo del punto 1 (grupo vs individual), que ya recomendamos.

**2. WhatsApp: ¿para qué usamos el grupo, con qué herramienta y cómo se suma la gente?** `(Q47, Q48, Q50)`
- **Primero, definir el rol del grupo:** ¿es solo comunidad / sensación de movimiento, o también canal por donde se entrega contenido? De esto depende qué necesitamos de la herramienta. *(Nuestra opción ideal es Kapso, pero antes de cerrar con ellos tenemos que tener clarísimo para qué y cómo usamos los grupos.)*
- Tenemos a **Kapso (somos partners)**, vía **oficial** (sin riesgo de baneo, mejor para la ley de datos). Su función de **grupos está por lanzarse** → hay que **hablar con Kapso** (acceso anticipado + qué hace su API de grupos). Alternativa no oficial (Whapi) ya hace grupos pero **arriesga el baneo**.
- Técnicamente **no se puede agregar a un número desconocido a un grupo** → la gente se suma con un **enlace de invitación**. ¿Lo aceptan así?
- **Herramienta del 1:1 vs grupo:** GHL ya hace WhatsApp 1:1 por la vía **oficial**, así que Kapso quedaría **solo para los grupos** (su API de grupos está por salir; en el MVP el grupo puede manejarse **a mano**). Falta definir: ¿usamos **un número** (con limitaciones) o **dos** (uno para el grupo, uno para el 1:1 oficial)? `(Q51, Q52)`

**3. Baja / dejar de recibir mensajes.** `(Q2)`
Ya está definido que **Ops puede dar de baja a alguien desde el panel**. La pregunta para ustedes: ¿damos además a los **propios usuarios** la opción de baja por WhatsApp (palabra clave "BAJA")? *(En España es obligatorio que exista un mecanismo de baja.)*

**4. El contenido del reto: ¿quién lo produce y qué alcance tiene?** `(Q46)`
- Los videos/audios/textos de los 7 días, ¿los hacen ustedes? (Nosotros **no generamos contenido**, solo lo entregamos.) ¿Está listo?
- **Importante:** el sistema, ¿maneja solo el **reto gratis de 7 días** (hasta que la persona paga), o también los **60 días del plan pago (P60)**? Hoy diseñamos hasta el pago; los 60 días serían una etapa aparte.

**5. Reglas del seguimiento automático.** `(Q45)`
¿Cuántos mensajes de seguimiento mandamos, con qué frecuencia y hasta cuándo insistir? ¿Hay seguimiento también para quien no entró al grupo o no participó? ¿Quién escribe esos mensajes?

---

## 🟠 Bloque 2 — Decisiones del reto

**6. "¿Quién te invitó?" e impulsores.** `(Q43, Q4)`
Hoy es un campo de texto libre → el ranking de quién trae gente no agrupa bien (errores, apodos). ¿Tienen una **lista de impulsores** conocidos para asignar correctamente? ¿El que invita es siempre otro participante o puede ser alguien externo?

**7. Verificación de inscriptos.** `(Q8, Q9, Q49)`
El alta la decide el operario (como en el prototipo). A definir con ustedes:
- ¿Al rechazado se le avisa y puede volver a intentar? *(Nuestra propuesta: sí, se le avisa y puede reintentar.)*
- ¿Quieren que el operario pueda **bloquear para siempre** a un número/usuario (que no pueda volver a registrarse nunca)? *(Es factible; definir si lo quieren y con qué criterio.)*
- ¿Cuánto tardan en verificar? (para decirle a la persona qué esperar)

**8. Datos del formulario.** `(Q3)`
¿Qué piden exactamente? (nombre, WhatsApp, email, quién invitó…). Cuantos menos campos, más gente se anota.

**9. Personas que repiten.** `(Q7)`
Alguien que estuvo en una cohorte anterior y vuelve, ¿es la misma persona (con historial) o una nueva?

**10. Roles del panel interno.** `(Q13)`
Ya sabemos que lo usan **varias personas**. La pregunta: ¿todas ven y hacen todo, o hace falta separar roles/permisos (ej. Ops vs responsable del negocio)?

---

## 🟡 Bloque 3 — Pago y cierre

**11. Cobro del P60.** `(Q21–Q24)`
Recomendamos **Stripe con Bizum** (cobro local en España, ~60 €). ¿Es un pago único o admite cuotas? ¿Cómo manejamos reembolsos?

**12. ¿Y si alguien paga sin haber hecho el reto?** `(Q21)`
¿Se acepta? ¿Cómo lo registramos?

**13. Testimonio final.** `(Q25)`
¿Es obligatorio? ¿Pueden usar el testimonio públicamente (con nombre)?

---

## 🟢 Bloque 4 — Setup y estilo

**14. Herramientas actuales.** `(Q46, setup)`
¿Qué usan hoy para WhatsApp, para alojar los videos y para cobrar?

**15. Grupos y tamaño.** `(H9)`
¿Una cohorte = un grupo de WhatsApp? ¿Cuántas personas esperan por cohorte?

**16. Idioma, zona horaria y horarios.** `(Q15, Q29)`
Confirmamos España (es-ES). ¿A qué hora se manda el contenido diario?

**17. Tono "anti-ventaja".** `(Q12)`
¿Hay lineamientos de cómo deben sonar los mensajes (cercano, sin venta agresiva)? Impacta el contenido.

---

## 🔵 Bloque 5 — Plataforma, IA y nuevas capacidades (de la call del 4-jun)

**18. ¿Qué esperan que haga GHL exactamente?** `(Q53)`
Mencionaron usar **GHL como sistema base**. Para diseñar bien necesitamos saber **qué trabajo concreto** esperan de él: ¿CRM/contactos? ¿reaprovechar embudos ya montados en Lector Voraz? ¿la membresía del plan pago? Según eso, GHL entra como pieza central o solo de apoyo. *Nota: si fuera la GHL de Lector Voraz, hay que acordar el coste, porque BeZy es un negocio aparte.*

**19. El seguimiento 1:1 con IA.** `(Q56, Q58, Q57)`
Quieren un seguimiento personal con IA que pregunte "¿cómo vas?, ¿te ayudo?".
- *Recomendación: la IA responde sola, con un humano que supervisa y puede tomar la conversación en cualquier momento.* (Descartamos que un humano tenga que enviar cada mensaje: no escala.)
- Falta definir **dónde "vive" esa IA**: la propia de GHL (más fácil, menos flexible) o una nuestra (más potente, más trabajo). Se los explicamos con pros y contras.
- ¿Permitimos que manden **notas de voz**? (Habría que transcribirlas; lo dejaríamos para una segunda etapa.)

**20. El directo en vivo (Zoom).** `(Q54)`
Para saber **quién asistió en vivo y cuánto se quedó** (y así decidir a quién mandarle el replay), usaríamos **registro con enlace único por persona** en Zoom. ¿Con qué **plan de Zoom** cuentan? ¿El directo es una reunión o un webinar?

**21. El video del replay.** `(Q55)`
Como el visionado lo medimos nosotros, **no hace falta Wistia**: alcanza con guardar el video (que Zoom ya graba) y mostrarlo en una **página propia**. ¿De acuerdo en dejar Wistia de lado?

**22. Prueba social (los resultados con números).** `(Q62)`
En vez de pedirlo por texto libre (que se prestaba a confusión), usamos un **formulario con campos concretos** + evidencia (foto de la factura/captura). Proponemos estas **categorías**: *ahorro en suscripciones · generado con la factura de la luz · vendido en Wallapop · otro.* ¿Suman o sacan alguna?

**23. El dashboard público.** `(Q61)`
Pidieron una **página pública** con los logros de la comunidad y un **ranking con nombres**. Proponemos:
- Un **enlace** que se comparte al **cierre del reto** (y disponible en la web).
- Ranking **por semana** + un **total acumulado**, mostrando **nombre de pila** (quien no quiera, aparece anónimo).
- **Todo pasa por la aprobación de ustedes** antes de mostrarse (y pueden ocultar algo ya publicado).
¿Les cierra así?

---

## Nota legal a tener presente (no es pregunta, es un cuidado)
En España multaron con 70.000 € a una empresa por **añadir a alguien a un grupo de WhatsApp sin su consentimiento**. Por eso el formulario pide consentimiento explícito y habrá baja fácil. Conviene tenerlo claro con el cliente.
