# SIEM-Plus API Reference

Complete API documentation for SIEM-Plus platform.

## Base URL
`https://api.siem-plus.io/api/v1`

## Authentication
All requests require JWT token in Authorization header:
```
Authorization: Bearer {your-token}
```

## Endpoints

### Authentication
- `POST /auth/login` - User login
- `POST /auth/register` - User registration
- `POST /auth/refresh` - Refresh token

### Agents
- `GET /agents` - List all agents
- `GET /agents/{id}` - Get agent details
- `POST /agents` - Register new agent
- `PUT /agents/{id}` - Update agent
- `DELETE /agents/{id}` - Delete agent
- `POST /agents/{id}/commands` - Send command to agent

### Alerts
- `GET /alerts` - List alerts (supports filtering)
- `GET /alerts/{id}` - Get alert details
- `PUT /alerts/{id}` - Update alert
- `POST /alerts/{id}/assign` - Assign alert
- `POST /alerts/{id}/resolve` - Resolve alert

### Rules
- `GET /rules` - List detection rules
- `GET /rules/{id}` - Get rule details
- `POST /rules` - Create rule
- `PUT /rules/{id}` - Update rule
- `DELETE /rules/{id}` - Delete rule
- `POST /rules/{id}/test` - Test rule

### Cases
- `GET /cases` - List cases
- `GET /cases/{id}` - Get case details
- `POST /cases` - Create case
- `PUT /cases/{id}` - Update case
- `POST /cases/{id}/alerts` - Add alert to case

### Dashboard
- `GET /dashboard/stats` - Get statistics
- `GET /dashboard/timeline` - Get alert timeline

### Events
- `POST /events` - Ingest events (bulk)

## Status Codes
- 200: Success
- 201: Created
- 400: Bad Request
- 401: Unauthorized
- 404: Not Found
- 500: Server Error
