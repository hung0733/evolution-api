# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Evolution API is a REST API for WhatsApp communication supporting multiple providers:
- **Baileys** (WhatsApp Web) - Open-source WhatsApp Web client
- **Meta Business API** - Official WhatsApp Business API
- **Evolution Channel** - Custom WhatsApp integration

Built with Node.js 20+, TypeScript 5+, and Express.js. Multi-tenant architecture with support for chatbots, CRM systems, and messaging platforms.

## Common Development Commands

### Build and Run
```bash
# Development
npm run dev:server    # Run in development with hot reload (tsx watch)

# Production
npm run build        # TypeScript check + tsup build
npm run start:prod   # Run production build

# Direct execution
npm start           # Run with tsx
```

### Code Quality
```bash
npm run lint        # ESLint with auto-fix
npm run lint:check  # ESLint check only
npm run commit      # Interactive commit with commitizen
```

### Database Management

All database commands require `DATABASE_PROVIDER` environment variable to be set:

```bash
export DATABASE_PROVIDER=postgresql  # or mysql

# Generate Prisma client
npm run db:generate

# Deploy migrations (production)
npm run db:deploy

# Development migrations
npm run db:migrate:dev

# Open Prisma Studio
npm run db:studio
```

### Testing

```bash
npm test    # Run tests with watch mode
```

Note: The project has minimal formal testing infrastructure. Test files can be placed in `test/` directory as `*.test.ts`.

## Architecture Overview

### Core Patterns

- **Multi-tenant SaaS**: Complete instance isolation with per-tenant authentication
- **Multi-provider database**: PostgreSQL and MySQL via Prisma ORM with provider-specific schemas
- **Event-driven**: EventEmitter2 for internal events + WebSocket, RabbitMQ, SQS, NATS, Pusher for external
- **RouterBroker pattern**: Routes extend `RouterBroker` and use `dataValidate()` for input validation
- **Service layer**: Business logic in service classes, thin controllers

### Directory Structure

```
src/
├── api/
│   ├── controllers/     # HTTP route handlers (thin layer)
│   ├── services/        # Business logic (core functionality)
│   ├── repository/      # Data access layer (Prisma)
│   ├── dto/            # Data Transfer Objects (plain classes, no decorators)
│   ├── guards/         # Authentication/authorization middleware
│   ├── integrations/   # External service integrations
│   │   ├── channel/    # WhatsApp providers (Baileys, Business API, Evolution)
│   │   ├── chatbot/    # AI/Bot integrations (OpenAI, Dify, Typebot, Chatwoot)
│   │   ├── event/      # Event systems (WebSocket, RabbitMQ, SQS, NATS, Pusher)
│   │   └── storage/    # File storage (S3, MinIO)
│   ├── routes/         # Express route definitions (RouterBroker pattern)
│   └── types/          # TypeScript type definitions
├── config/             # Environment configuration (env.config.ts)
├── cache/             # Redis and local cache
├── exceptions/        # Custom HTTP exception classes
├── utils/            # Shared utilities
└── validate/         # JSONSchema7 validation schemas
```

### Key Integration Points

**Channel Integrations** (`src/api/integrations/channel/`):
- **Baileys**: WhatsApp Web client with QR code authentication
- **Business API**: Official Meta WhatsApp Business API
- **Evolution Channel**: Custom WhatsApp integration
- Connection lifecycle managed per instance with automatic reconnection

**Chatbot Integrations** (`src/api/integrations/chatbot/`):
- EvolutionBot, Chatwoot, Typebot, OpenAI, Dify, Flowise, N8N, EvoAI

**Event Integrations** (`src/api/integrations/event/`):
- WebSocket (Socket.io), RabbitMQ, Amazon SQS, NATS, Pusher, Kafka

**Storage Integrations** (`src/api/integrations/storage/`):
- AWS S3, MinIO for media file storage

### Database Schema Management

- Separate schema files: `postgresql-schema.prisma`, `mysql-schema.prisma`, `psql_bouncer-schema.prisma`
- `DATABASE_PROVIDER` env variable determines active database
- Migrations are provider-specific and auto-selected during deployment
- Use database-specific types (`@db.JsonB` vs `@db.Json`)

### Authentication & Security

- API key-based authentication via `apikey` header (global or per-instance)
- Instance-specific tokens for WhatsApp connection authentication
- Guards system for route protection (`authGuard`, `instanceExistsGuard`, `instanceLoggedGuard`)
- Input validation using JSONSchema7 with RouterBroker `dataValidate()`
- Rate limiting and webhook signature validation

## Important Implementation Details

### WhatsApp Instance Management

- Each WhatsApp connection is an "instance" with a unique name
- Instance data stored in the database with connection state
- Session persistence in database or file system (configurable)
- Access instances via `waMonitor.waInstances[instanceName]`

### Validation Pattern

- Use JSONSchema7 schemas in `src/validate/` for input validation
- DTOs are plain classes without decorators (no class-validator)
- Routes use `this.dataValidate<T>({ request, schema, ClassRef, execute })` from RouterBroker

### Event System

- Internal events via EventEmitter2 (events defined in `src/api/types/event.type.ts`)
- External events via WebSocket, RabbitMQ, SQS, NATS, Pusher, or Kafka
- Configure per-instance which events to emit

### Multi-tenancy

- Instance isolation at database level
- Separate webhook configurations per instance
- Independent integration settings per instance

## Environment Configuration

Key environment variables (see `.env.example` for full list):

- `DATABASE_PROVIDER`: `postgresql` | `mysql` | `psql_bouncer`
- `DATABASE_CONNECTION_URI`: Database connection string
- `AUTHENTICATION_API_KEY`: Global API authentication key
- `REDIS_ENABLED`: Enable Redis cache
- `RABBITMQ_ENABLED`/`SQS_ENABLED`: Message queue options
- `LOG_LEVEL`: Comma-separated list of log levels

## Development Guidelines

### Code Standards (from `.cursor/rules/`)

- **TypeScript strict mode** with full type coverage
- **JSONSchema7** for input validation (not class-validator)
- **Conventional Commits** enforced by commitlint (use `npm run commit` for guided commits)
- **Service Object pattern** for business logic
- **RouterBroker pattern** for route handling with `dataValidate()`

### Patterns

- Services extend base classes like `ChannelStartupService` or `BaseChatbotService`
- Controllers use constructor injection with `private readonly` dependencies
- Routes extend `RouterBroker` and use `this.routerPath()` for path naming
- Use `new Logger('ClassName')` for logging (not console.log)
- Return `null` on error in service `find()` methods (Evolution pattern)

### Communication Standards

- User communication: Portuguese (PT-BR)
- Code/comments: English
- API responses: English
- Error messages: Portuguese for user-facing errors

## Testing Approach

The project has minimal formal testing infrastructure:
- Manual testing is the primary approach
- Integration testing in development environment
- No unit test suite currently implemented
- Test files can be placed in `test/` directory as `*.test.ts`
- Run `npm test` for watch mode testing

## Deployment

- Docker support with `Dockerfile` and `docker-compose.yaml`
- Graceful shutdown handling for connections
- Health check endpoints for monitoring
- Sentry integration for error tracking
- Prometheus metrics support (optional, configurable via env vars)