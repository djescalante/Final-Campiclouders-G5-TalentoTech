# Diagramas UML del proyecto

Este directorio contiene los diagramas en **PlantUML (`.puml`)** y sus imágenes renderizadas (`.png`).

Archivos
- Casos de uso: `docs/uml/usecase.puml`, `docs/uml/usecase.png`
- Secuencia: `docs/uml/sequence.puml`, `docs/uml/sequence.png`
- Componentes: `docs/uml/components.puml`, `docs/uml/components.png`
- Despliegue: `docs/uml/deployment.puml`, `docs/uml/deployment.png`
- Modelo de datos: `docs/uml/data_model.puml`, `docs/uml/data_model.png`

Visualización
- Abre directamente los `.png` para una vista rápida.
- Para editar/generar desde `.puml`, usa un plugin de PlantUML o la CLI `plantuml *.puml`.

Contexto
- Backend: `server.js` expone `POST /registro` y almacena en DynamoDB.
- Variables: `TABLE_NAME`, `CORS_ORIGIN`.
