# Roadmap — Quiz Show Palencia

Este roadmap organiza la evolución de la app para poder hacer concursos cada vez mejores sin romper la estabilidad de los eventos en vivo.

Principio rector: **primero confiabilidad, después espectacularidad**. Una feature bonita que falla delante del público no sirve.

## Estado de producto actual

- App Godot 4.6 con roles de presentador, pantalla y concursante.
- Sincronización MQTT en red local.
- Banco actual de 46 preguntas revisadas de Palencia.
- Modo actual: **partida libre** con preguntas aleatorias globales.
- El campo `ronda` existe como metadata, pero no gobierna la partida actual.
- Minijuegos existen en datos/código, pero no son foco inmediato.
- Pulsadores externos Tasmota/MQTT deseados para futuro.

## Reglas de decisión

1. Antes de un concurso real, solo entran cambios de bajo riesgo.
2. El presentador es la autoridad; display y concursantes renderizan estado.
3. La UI debe ser operable bajo presión, no solo bonita en desarrollo.
4. Toda mejora de show debe tener camino de recuperación si algo falla.
5. Hardware externo entra mediante adaptadores, no mezclado con la lógica del juego.

---

## Fase 0 — Pre-evento: congelar y asegurar

Objetivo: llegar al concurso con una app estable y conocida.

### Checklist operativo

- [ ] Instalar APK actualizado en todos los dispositivos.
- [ ] Probar broker MQTT en la red real.
- [ ] Probar rol Presentador.
- [ ] Probar rol Pantalla en proyector/TV real.
- [ ] Probar tablets de concursantes.
- [ ] Verificar número de equipos configurados.
- [ ] Lanzar 3-5 preguntas de prueba.
- [ ] Probar respuesta correcta, incorrecta y ajuste manual de puntos.
- [ ] Probar recuperación básica si una tablet se cierra y vuelve a entrar.

### Cambios permitidos antes de evento

- [ ] Confirmación para reset completo.
- [ ] Botón de reenviar estado actual.
- [ ] Texto claro de modo actual: `Partida libre`.
- [ ] Correcciones visuales pequeñas de bajo riesgo.

### Cambios prohibidos antes de evento

- [ ] Integrar Tasmota.
- [ ] Rediseñar flujo de partida.
- [ ] Cambiar scoring completo.
- [ ] Reescribir MQTT.
- [ ] Añadir modos complejos.

---

## Fase 1 — Robustez de evento

Objetivo: que el sistema aguante desconexiones, errores humanos y presión de directo.

### MQTT y sincronización

- [ ] Detectar publish fallido cuando MQTT está desconectado.
- [ ] Mantener snapshot pendiente si no se pudo publicar.
- [ ] Reenviar estado automáticamente al reconectar.
- [ ] Añadir botón visible: `Reenviar estado actual`.
- [ ] Mostrar estado de conexión MQTT en presentador, pantalla y concursante.
- [ ] Mostrar última hora de sincronización.

### Recuperación en directo

- [ ] Panel de emergencia del presentador.
- [ ] Acción: liberar bloqueos sin cambiar puntuaciones.
- [ ] Acción: reiniciar pregunta actual.
- [ ] Acción: reenviar estado.
- [ ] Acción: reset marcador con confirmación.
- [ ] Acción: reset partida completa con confirmación fuerte.

### Seguridad contra errores humanos

- [ ] Confirmar `Nueva partida`.
- [ ] Confirmar `Reset completo`.
- [ ] Separar acciones frecuentes de acciones destructivas.
- [ ] Añadir `Deshacer último cambio de puntos`.

---

## Fase 2 — UX del presentador

Objetivo: que operar el concurso sea simple, rápido y claro.

### Reorganización visual

- [ ] Separar pantalla del presentador en bloques:
  - Pregunta actual.
  - Control de turno/pulsador.
  - Marcador.
  - Sistema/emergencia.
- [ ] Convertir controles avanzados en sección plegable.
- [ ] Evitar iconos sin texto en acciones críticas.
- [ ] Añadir textos de ayuda cortos donde haya ambigüedad.

### Preview privada

- [ ] Mostrar respuesta correcta claramente.
- [ ] Mostrar dificultad.
- [ ] Mostrar dato curioso.
- [ ] Mostrar puntos sugeridos.
- [ ] Mostrar si la pregunta ya fue usada.

### Flujo de pregunta

- [ ] Botón primario: `Lanzar pregunta`.
- [ ] Botón primario: `Abrir respuestas` o `Abrir pulsador`.
- [ ] Botón primario: `Revelar respuesta`.
- [ ] Botón secundario: `Saltar pregunta`.
- [ ] Botón secundario: `Marcar como no usada`.

---

## Fase 3 — Pantalla y concursantes más show-ready

Objetivo: que la experiencia parezca un concurso real.

### Pantalla pública

- [ ] Mejorar pantalla de espera.
- [ ] Añadir banner de pregunta entrante.
- [ ] Mejorar reveal de respuesta correcta.
- [ ] Añadir pantalla clara de acierto/error.
- [ ] Mostrar `Dato desbloqueado` tras revelar.
- [ ] Añadir variante visual para `Rebote` o segunda oportunidad.
- [ ] Adaptar layout si las opciones son largas.

### Concursantes

- [ ] Mensajes más humanos y menos técnicos.
- [ ] Botones de respuesta con área táctil grande.
- [ ] Feedback fuerte al enviar respuesta.
- [ ] Estado claro cuando el equipo está bloqueado.
- [ ] Estado claro cuando otro equipo tiene turno.
- [ ] Diagnóstico MQTT discreto, no invasivo.

### Accesibilidad

- [ ] Tamaño mínimo táctil aproximado de 48px.
- [ ] Contraste alto en todos los estados.
- [ ] Navegación por teclado/gamepad donde aplique.
- [ ] Textos escalables o tamaños revisados para tablet/proyector.

---

## Fase 4 — Modos de partida

Objetivo: permitir concursos más variados sin obligar a usar rondas siempre.

### Modo 1: Partida libre

Estado actual.

- [ ] Preguntas aleatorias de todo el banco.
- [ ] Rondas ignoradas a nivel de gameplay.
- [ ] Mostrar explícitamente `Modo partida libre`.

### Modo 2: Partida por rondas

Futuro.

- [ ] Activar selector de ronda solo en este modo.
- [ ] Random filtrado por ronda.
- [ ] Contador de usadas/restantes por ronda.
- [ ] Banner visual de ronda.
- [ ] Configurar orden de rondas.

### Modo 3: Guion de concurso

Futuro avanzado.

- [ ] Secuencia predefinida de bloques.
- [ ] Preguntas y minijuegos ordenados.
- [ ] El presentador solo avanza paso a paso.
- [ ] Ideal para eventos grandes o repetibles.

---

## Fase 5 — Scoring y tensión de juego

Objetivo: aumentar emoción sin complicar demasiado al presentador.

### Puntuación

- [ ] Puntos por dificultad:
  - Dificultad 1: 50.
  - Dificultad 2: 100.
  - Dificultad 3: 150.
  - Dificultad 4: 200.
- [ ] Permitir override manual por pregunta.
- [ ] Mostrar puntos posibles antes de lanzar.

### Mecánicas

- [ ] Rachas de aciertos.
- [ ] Bonus por velocidad.
- [ ] Rebote visible.
- [ ] Ronda final doble.
- [ ] Pregunta de desempate.

### Tradeoff

Estas mejoras dan espectáculo, pero aumentan reglas. Deben introducirse una a una y con UI muy clara.

---

## Fase 6 — Pulsadores externos Tasmota

Objetivo: integrar pulsadores físicos sin ensuciar la lógica central.

### Arquitectura propuesta

```text
Pulsador Tasmota
  ↓ MQTT
TasmotaInputAdapter
  ↓ evento normalizado
GameService.buzzer_pressed(team_id)
  ↓ estado global
Pantalla / Presentador / Concursantes
```

### Requisitos

- [ ] Definir topic MQTT por pulsador o payload con equipo.
- [ ] Mapping botón → equipo.
- [ ] Debounce software adicional.
- [ ] Ignorar pulsaciones fuera de ventana activa.
- [ ] Primer pulsador gana.
- [ ] Bloqueo inmediato del resto.
- [ ] Modo test de hardware.
- [ ] Pantalla de diagnóstico:
  - último mensaje recibido,
  - equipo detectado,
  - timestamp,
  - latencia aproximada.

### Flujo objetivo

1. Presentador pulsa `Abrir pulsadores`.
2. Pantalla muestra `¡PULSAD!`.
3. Tasmota publica evento MQTT.
4. Adapter normaliza el evento.
5. GameService asigna ganador.
6. Pantalla muestra equipo ganador.
7. Ese equipo responde.

---

## Fase 7 — Gestión de contenido

Objetivo: preparar concursos nuevos sin tocar código.

### Preguntas

- [ ] Validador de JSON integrado o script auxiliar.
- [ ] Detectar IDs duplicados.
- [ ] Detectar correctas inválidas.
- [ ] Detectar preguntas con etiquetas que requieren recursos externos.
- [ ] Detectar opciones demasiado largas.
- [ ] Campo opcional `source` o `verified_source`.
- [ ] Campo opcional `host_note`.
- [ ] Campo opcional `avoid_random`.

### Bancos por evento

- [ ] `palencia_general.json`.
- [ ] `instituto.json`.
- [ ] `fiestas.json`.
- [ ] `familia.json`.
- [ ] Selector de banco desde settings.

### Minijuegos

- [ ] Clasificar por material necesario.
- [ ] Marcar minijuegos aptos/no aptos según contexto.
- [ ] Añadir checklist del presentador.

---

## Fase 8 — Calidad profesional

Objetivo: convertir la app en herramienta reutilizable para muchos eventos.

### Observabilidad

- [ ] Log de eventos de partida.
- [ ] Exportar resultados.
- [ ] Historial de respuestas.
- [ ] Estadísticas por equipo.
- [ ] Preguntas más falladas.
- [ ] Tiempo medio de respuesta.

### Modo ensayo

- [ ] Simular equipos desde el presentador.
- [ ] Simular MQTT desconectado.
- [ ] Simular reconexión de pantalla/tablet.
- [ ] Demo mode sin broker externo.

### Testing

- [ ] Tests de lógica de scoring.
- [ ] Tests de bloqueo/turnos.
- [ ] Tests de parseo de preguntas.
- [ ] Tests de sincronización de estado.

---

## Backlog técnico detectado

- [ ] Revisar flujo de respuestas cuando `buzzer_mode_enabled = false`.
- [ ] Evitar pérdida silenciosa de publishes MQTT.
- [ ] Reenviar snapshot tras reconexión.
- [ ] Corregir/validar inserción de imágenes si se recuperan preguntas con imagen.
- [ ] Evitar animar `scale`/`position` en hijos de `Container`.
- [ ] Revisar `slice()` al recortar equipos en configuración.
- [ ] Hacer role select responsive.
- [ ] Aumentar touch targets en settings.
- [ ] Añadir confirmaciones a acciones destructivas.

## Orden recomendado realista

1. Fase 0 si hay evento cerca.
2. Fase 1 completa.
3. Fase 2 parcial: presenter más claro.
4. Fase 3 parcial: display/contestant más show.
5. Fase 6: Tasmota, cuando el core ya sea estable.
6. Fase 4 y 5 para concursos más ambiciosos.
7. Fase 7 y 8 cuando se quiera reutilizar profesionalmente.
