# Students API — Spring Boot en AWS ECS Fargate

API REST para gestionar estudiantes, contenerizada con Docker y desplegada en **Amazon ECS (Fargate)** con la imagen almacenada en **Amazon ECR**.

Actividad 4 — Herramientas de Software II, Universidad de La Salle (2026-2).

| | |
|---|---|
| Lenguaje | Java 21 (LTS) |
| Framework | Spring Boot 3.5 (Web, Validation, Actuator) |
| Build | Maven |
| Persistencia | En memoria (`ConcurrentHashMap`) detrás de la interfaz `StudentRepository` |
| Contenedor | Docker multi-stage (`maven` → `eclipse-temurin:21-jre-alpine`) |
| Nube | Amazon ECR + Amazon ECS sobre AWS Fargate (AWS Academy Learner Lab) |

## Arquitectura

```
Desarrollador ──docker push──▶ Amazon ECR (imagen students-api:1.0.0)
                                     │ pull
                                     ▼
Cliente (curl/Postman) ──HTTP:8080──▶ ECS Service ──▶ Tarea Fargate (contenedor Spring Boot)
                                       │                     │
                                Security Group          CloudWatch Logs
                                 (TCP 8080)             (/ecs/students-api)
```

## Endpoints

| Método | Ruta | Descripción | Éxito | Errores |
|---|---|---|---|---|
| `POST` | `/students` | Crear un estudiante | `201 Created` + header `Location` | `400` datos inválidos, `409` correo duplicado |
| `GET` | `/students/{id}` | Obtener un estudiante por id (UUID) | `200 OK` | `404` no existe, `400` id mal formado |
| `GET` | `/students` | Listar todos los estudiantes | `200 OK` (lista, vacía si no hay) | — |
| `GET` | `/actuator/health` | Estado de la aplicación (health check) | `200 {"status":"UP"}` | — |

**Request — `POST /students`**
```json
{ "nombre": "Ana", "apellido": "Gómez", "correo": "ana.gomez@unisalle.edu.co" }
```

**Response — `201 Created`**
```json
{
  "id": "3f6c1e2a-8b4d-4c9e-9a51-2d7f0b6e1c44",
  "nombre": "Ana",
  "apellido": "Gómez",
  "correo": "ana.gomez@unisalle.edu.co",
  "fechaCreacion": "2026-10-02T01:30:12.345Z"
}
```

**Response de error — `400 Bad Request`** (formato estándar RFC 9457 `ProblemDetail`)
```json
{
  "type": "about:blank",
  "title": "Datos inválidos",
  "status": 400,
  "detail": "Uno o más campos no son válidos",
  "instance": "/students",
  "errores": { "nombre": "El nombre es obligatorio", "correo": "El correo no tiene un formato válido" }
}
```

## Estructura del proyecto

```
src/main/java/com/nickbern/studentsapi/
├── controller/StudentController.java      # Endpoints HTTP
├── service/StudentService.java            # Reglas de negocio (id, normalización, correo único)
├── repository/StudentRepository.java      # Contrato de persistencia
├── repository/InMemoryStudentRepository.java
├── model/Student.java                     # Entidad (record)
├── dto/CreateStudentRequest.java          # Entrada validada
├── dto/StudentResponse.java               # Salida JSON
└── exception/                             # Excepciones + manejador global (ProblemDetail)
Dockerfile · ecs/task-definition.json · scripts/
```

---

## 1. Ejecución local sin Docker (opcional)

Requiere JDK 21 y Maven (o abrir el proyecto en IntelliJ).

```bash
mvn test              # 6 pruebas de integración con MockMvc
mvn spring-boot:run   # API en http://localhost:8080
```

## 2. Contenerización con Docker

```bash
# Construir la imagen (Maven corre dentro del contenedor de build; no hace falta tenerlo instalado)
docker build -t students-api:1.0.0 .

# Ver el tamaño final de la imagen
docker images students-api

# Ejecutar el contenedor: puerto 8080 del host → 8080 del contenedor
docker run -d --name students-api -p 8080:8080 students-api:1.0.0

# Ver logs (esperar "Started StudentsApiApplication")
docker logs -f students-api

# Estado del health check definido en el Dockerfile
docker ps
```

Probar la API:

```bash
./scripts/test-api.sh
```

O manualmente:

```bash
curl -i -X POST http://localhost:8080/students \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Ana","apellido":"Gómez","correo":"ana.gomez@unisalle.edu.co"}'

curl http://localhost:8080/students
curl http://localhost:8080/students/<id>
```

Detener y eliminar el contenedor:

```bash
docker stop students-api && docker rm students-api
```

> **Mac con chip Apple (M1/M2/M3):** Fargate corre por defecto en x86_64. La imagen que se sube a ECR debe construirse con `--platform linux/amd64` (el script `push-ecr.sh` ya lo hace). Si no, la tarea falla con `exec format error`.

## 3. Despliegue en AWS (Learner Lab)

### 3.1 Credenciales

1. Learner Lab → **Start Lab** → esperar el círculo verde.
2. **AWS Details** → **AWS CLI: Show** → copiar el bloque en `~/.aws/credentials` (incluye `aws_session_token`; caduca con la sesión).
3. Verificar:

```bash
aws sts get-caller-identity
aws configure set region us-east-1
```

### 3.2 Subir la imagen a ECR

```bash
./scripts/push-ecr.sh
```

Esto hace, en orden: crea el repositorio `students-api` en ECR → `docker login` contra ECR con `aws ecr get-login-password` → `docker build --platform linux/amd64` → `docker tag` → `docker push`. Al final imprime la **URI de la imagen**.

### 3.3 Desplegar en ECS Fargate — por consola (recomendado para el video)

**a) Cluster**
ECS → *Clusters* → *Create cluster* → nombre `students-cluster` → infraestructura **AWS Fargate (serverless)** → *Create*.

**b) Task definition**
ECS → *Task definitions* → *Create new task definition*:
- Family: `students-api`
- Launch type: **AWS Fargate** · OS/Arch: **Linux/X86_64**
- CPU **0.5 vCPU** · Memoria **1 GB** (Spring Boot necesita más de 512 MB)
- **Task role:** `LabRole` · **Task execution role:** `LabRole`
  ⚠️ No dejar "Create new role": el Learner Lab no permite crear roles IAM y el despliegue falla.
- Container: nombre `students-api`, imagen = URI de ECR, puerto **8080** TCP.
- Health check: comando `CMD-SHELL, wget -qO- http://localhost:8080/actuator/health || exit 1`, *start period* **60** s.
- Logs: dejar CloudWatch activado.

(Equivalente en JSON: `ecs/task-definition.json`.)

**c) Servicio**
Cluster `students-cluster` → *Services* → *Create*:
- Compute: **Launch type → FARGATE**
- Task definition: `students-api` (última revisión) · Service name: `students-api-service` · Desired tasks: **1**
- Networking: VPC por defecto, todas sus subnets, **Create new security group** con regla de entrada **Custom TCP 8080 desde 0.0.0.0/0** (Anywhere), **Public IP: ON**.
- *Create* y esperar a que la tarea pase a **RUNNING** (2–4 min).

**d) Obtener la IP pública**
Servicio → pestaña *Tasks* → clic en la tarea → *Configuration* → **Public IP**.

### 3.3 (alternativa) Desplegar por CLI

```bash
./scripts/deploy-ecs.sh
```

Crea el cluster, registra la task definition, crea el security group y el servicio, espera a que esté estable e imprime la URL.

### 3.4 Probar en la nube

```bash
./scripts/test-api.sh http://<IP-PUBLICA>:8080
```

Los logs de la aplicación se ven en ECS → tarea → pestaña *Logs*, o en CloudWatch → Log groups → `/ecs/students-api`.

### 3.5 Limpieza

```bash
./scripts/cleanup-aws.sh
```

---

## Decisiones de diseño

- **Persistencia en memoria:** permitida por el enunciado y suficiente para la demo. Limitación: los datos se pierden si la tarea se reinicia, y con más de 1 réplica cada contenedor tendría su propia lista. Por eso el servicio corre con **1 tarea**. La interfaz `StudentRepository` permite cambiar a DynamoDB o RDS sin tocar controlador ni servicio.
- **IP pública directa en lugar de Application Load Balancer:** más simple y barato para la actividad. En producción se usaría un ALB (IP/DNS estable, HTTPS, varias réplicas).
- **Dockerfile multi-stage:** la imagen final solo contiene el JRE y el `.jar`; no incluye JDK, Maven ni código fuente.
- **Usuario no-root y apagado limpio:** la JVM corre como `spring` y recibe el `SIGTERM` de ECS (`exec` + `server.shutdown: graceful`).
