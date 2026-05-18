# TravelPick Java Backend (Pure Java)

Framework-free HTTP API using `com.sun.net.httpserver.HttpServer` and JSON file storage.

## Requirements

- JDK 17+
- Maven 3.9+

## Run

```bash
cd backend-java
mvn -q package
java -jar target/travelpick-backend-1.0.0.jar
```

Server listens on **http://127.0.0.1:8000** (same port as the Python backend).

Data files are read/written from `../backend/data/` by default. Override with:

```bash
set TRAVELPICK_DATA_DIR=D:\path\to\data
```

## API Endpoints (Python-compatible)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Health message |
| GET | `/groups` | List all groups |
| POST | `/groups` | Create group |
| GET | `/groups/{id}` | Get group |
| GET | `/groups?id={id}` | Get group (query style) |
| POST | `/users` | Create user |
| GET | `/users/{id}` | Get user |
| GET | `/destinations/catalog` | Wikipedia catalog search |
| GET | `/destinations/{groupId}` | List destinations in group |
| GET | `/destinations?groupId={id}` | List destinations (query style) |
| POST | `/destinations` | Add destination |
| POST | `/votes` | Submit/update vote |
| POST | `/votes/batch` | Submit multiple votes |
| GET | `/votes/{groupId}` | List votes for group |
| GET | `/results/{groupId}` | Weighted voting summary |

## JSON data files

Each file is a **JSON array** of objects:

- `groups.json`
- `users.json`
- `destinations.json`
- `votes.json`

See `../backend/data/` for live examples.

## Tests

```bash
mvn test
```
