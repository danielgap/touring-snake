# Quiz Show Palencia

Aplicación de concurso interactivo construida con **Godot 4.6** y **MQTT** para funcionar en red local, sin depender de internet durante el evento.

El proyecto está pensado para montar concursos tipo show con tres roles dentro de la misma app:

- **Presentador**: controla la partida, lanza preguntas, habilita respuestas, arbitra y modifica puntos.
- **Pantalla**: vista pública para proyector/TV con pregunta, opciones, marcador y feedback visual.
- **Concursante**: tablet asignada a un equipo para pulsar/responder cuando el presentador habilita el turno.

La prioridad actual es que el sistema sea **estable para eventos en vivo**. Las rondas, minijuegos y pulsadores físicos están contemplados como evolución, pero la partida actual funciona como **partida libre**: preguntas aleatorias de todo el banco.

## Estado actual

- App Godot multimodo con selector de rol.
- Sincronización por MQTT en red local.
- Presentador como autoridad del sistema.
- Contestantes como clientes simples que obedecen el estado publicado.
- Banco de **46 preguntas revisadas de Palencia** en `godot/data/preguntas.json`.
- Preguntas con `ronda` como metadata futura, pero actualmente el modo de juego usa selección aleatoria global.
- Configuración local en `godot/data/show_config.json`.
- Persistencia de sesión del presentador en `user://presenter_session.json`.
- Soporte para 2 equipos por defecto, configurable.
- Modo minijuego implementado en la app, pero no es el foco actual del concurso inmediato.
- APK debug exportable para Android.

## Flujo recomendado de concurso actual

1. Arrancar broker MQTT local.
2. Abrir la app en el dispositivo del presentador y elegir **Presentador**.
3. Abrir la app en proyector/TV y elegir **Pantalla**.
4. Abrir tablets de equipos y elegir **Concursante**.
5. Verificar conexión y equipo asignado.
6. Lanzar preguntas aleatorias desde el presentador.
7. Habilitar turno/pulsador según dinámica elegida.
8. Revelar respuesta y ajustar puntos si hace falta.

## Estructura principal

```text
quiz/
├── README.md
├── ROADMAP.md
├── prd.md
└── godot/
    ├── project.godot
    ├── main.tscn
    ├── addons/mqtt/
    ├── autoload/
    │   ├── app_state.gd
    │   ├── content_repo.gd
    │   ├── game_service.gd
    │   ├── mqtt_bus.gd
    │   └── show_config.gd
    ├── data/
    │   ├── preguntas.json
    │   ├── minijuegos.json
    │   └── show_config.json
    ├── scenes/
    │   ├── bootstrap/
    │   ├── contestant/
    │   ├── display/
    │   ├── presenter/
    │   └── settings/
    └── scripts/
```

## Stack

- **Godot 4.6**
- **MQTT / Mosquitto**
- **JSON local** para contenido y configuración
- **Android debug export** para tablets/proyector Android

## Arquitectura resumida

- `AppState`: rol activo y estado general de la app.
- `ContentRepo`: carga preguntas y minijuegos desde JSON.
- `GameService`: lógica de juego, arbitraje, estado compartido, persistencia y sincronización.
- `MqttBus`: wrapper del addon MQTT.
- `ShowConfig`: configuración de equipos, MQTT, visuales y comportamiento.

Regla central: **el presentador manda**. Pantalla y concursantes no deciden la partida; escuchan y renderizan.

## Requisitos

- Godot 4.6 para desarrollo/export.
- Broker MQTT accesible en red local.
- Android SDK configurado si se quiere exportar APK.

Ejemplo local típico:

```text
host: 127.0.0.1
puerto: 1883
```

En Windows, con Mosquitto instalado en `C:\Program Files\mosquitto`:

```powershell
& "C:\Program Files\mosquitto\mosquitto.exe" -p 1883 -v
```

## Abrir el proyecto

1. Abrí **Godot 4.6**.
2. Importá:

```text
quiz/godot/project.godot
```

3. Ejecutá `main.tscn`.
4. Elegí rol:
   - Presentador
   - Pantalla
   - Concursante

## Exportar APK debug

Comando usado para generar el APK actual:

```powershell
& "C:\Users\Dani\Downloads\Godot\Godot_v4.6-stable_win64_console.exe" --headless --path "C:\Users\Dani\dev\quiz\godot" --export-debug "Android" "C:\Users\Dani\dev\quiz\build\quiz-debug.apk"
```

Salida esperada:

```text
C:\Users\Dani\dev\quiz\build\quiz-debug.apk
```

> Nota: el export release no está configurado porque falta keystore de release. Para pruebas/eventos se usa APK debug.

## Datos

Banco de preguntas:

```text
godot/data/preguntas.json
```

Estado actual del banco:

- 46 preguntas.
- Todas con 4 opciones.
- Respuesta correcta en formato `A`, `B`, `C` o `D`.
- Preguntas `[IMAGEN]`, `[DESAFÍO]` y `[DESAFÍO RETO]` eliminadas porque dependían de contexto visual o acciones externas.
- IDs secuenciales.

Banco de minijuegos:

```text
godot/data/minijuegos.json
```

Los minijuegos siguen disponibles como capacidad futura, aunque no son prioritarios para el concurso inmediato.

## Decisiones actuales de producto

- El modo actual es **partida libre**, no partida por rondas.
- El campo `ronda` se mantiene como metadata para una futura mejora.
- Los pulsadores físicos con Tasmota/MQTT se dejan para una fase posterior.
- Antes de eventos, se prioriza estabilidad sobre features nuevas.
- Las animaciones de UI en nodos dentro de `Container` deben evitar `scale` y `position`; usar `modulate` para fades/feedback.

## Roadmap

El plan de evolución está documentado en:

```text
ROADMAP.md
```

Resumen de fases:

1. Estabilidad pre-evento.
2. Robustez MQTT y recuperación.
3. UX del presentador.
4. Mejoras visuales de pantalla/concursante.
5. Modos de partida y rondas opcionales.
6. Pulsadores externos Tasmota.
7. Gestión avanzada de contenido.
8. Métricas, logs y calidad profesional.

## Documentos relacionados

- `prd.md`: visión funcional original del producto.
- `ROADMAP.md`: plan actualizado y priorizado.
