# webapp-template

A production-ready TypeScript monorepo template for building web applications and APIs.

## Stack

| Layer | Technology |
|---|---|
| API | Fastify + TypeScript |
| Frontend | Next.js 14 (App Router) |
| Database | PostgreSQL + Prisma |
| IaC | Terraform (AWS ECS + RDS) |
| CI/CD | GitHub Actions |
| Containers | Docker + Docker Compose |
| Testing | Vitest + Playwright |
| Monorepo | Turborepo + npm workspaces |

## Getting started

### Prerequisites

- Node.js 20+
- Docker & Docker Compose
- (Optional) AWS CLI for deployment

### Local development

```bash
# First-time setup: installs deps, copies .env, starts DB, runs migrations
npm run setup

# Start all services with hot reload
npm run dev
```

The API will be available at http://localhost:3000 and the web app at http://localhost:3001.

### Testing

```bash
# Unit tests
npm test

# Integration tests (requires running DB)
npm run test:integration
```

### Project structure

```
├── apps/
│   ├── api/          # Fastify REST API
│   └── web/          # Next.js frontend
├── packages/
│   └── shared-types/ # Shared Zod schemas + TypeScript types
├── infra/            # Terraform IaC (AWS)
├── scripts/          # Operational scripts
├── docker/           # Docker Compose for local dev
└── .github/          # GitHub Actions workflows
```

## Deployment

See [infra/README.md](infra/README.md) for infrastructure setup and deployment instructions.
