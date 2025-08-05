# Collaborative Code Editor

A production-grade, real-time collaborative code editor built with TypeScript, React, Monaco Editor, Elixir Phoenix, and Yjs CRDT.

## Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │    Backend      │    │  Infrastructure │
│                 │    │                 │    │                 │
│ • React + TS    │◄──►│ • Phoenix       │◄──►│ • PostgreSQL    │
│ • Monaco Editor │    │ • Channels      │    │ • Redis         │
│ • Yjs CRDT      │    │ • GenServer     │    │ • Kubernetes    │
│ • WebSocket     │    │ • OTP           │    │ • Terraform     │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

### Prerequisites

- Node.js 18+ and npm
- Elixir 1.14+ and Phoenix 1.7+
- PostgreSQL 14+
- Redis 6+
- Docker and Docker Compose
- kubectl and Terraform (for deployment)

### Development Setup

1. **Clone and install dependencies:**
```bash
git clone <repository-url>
cd collaborative-code-editor
npm install
```

2. **Start development services:**
```bash
# Start PostgreSQL and Redis
docker-compose up -d postgres redis

# Start Phoenix backend
cd packages/backend
mix deps.get
mix ecto.setup
mix phx.server

# Start React frontend (new terminal)
cd packages/frontend
npm run dev
```

3. **Access the application:**
- Frontend: http://localhost:3000
- Backend API: http://localhost:4000
- Phoenix LiveDashboard: http://localhost:4000/dashboard

### Production Deployment

1. **Build and deploy with Kubernetes:**
```bash
# Build Docker images
npm run docker:build

# Deploy to Kubernetes
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n collaborative-editor
```

2. **Infrastructure provisioning:**
```bash
cd terraform/
terraform init
terraform plan
terraform apply
```

## Project Structure

```
collaborative-code-editor/
├── packages/
│   ├── frontend/              # React TypeScript application
│   │   ├── src/
│   │   │   ├── components/    # React components
│   │   │   ├── hooks/         # Custom React hooks
│   │   │   ├── services/      # API and WebSocket services
│   │   │   ├── stores/        # State management
│   │   │   ├── types/         # TypeScript definitions
│   │   │   └── utils/         # Utility functions
│   │   ├── public/            # Static assets
│   │   └── tests/             # Frontend tests
│   │
│   ├── backend/               # Phoenix Elixir application
│   │   ├── lib/
│   │   │   ├── collaborative_editor/     # Core business logic
│   │   │   ├── collaborative_editor_web/ # Web layer (controllers, channels)
│   │   │   └── collaborative_editor/     # Application context
│   │   ├── priv/              # Database migrations, static files
│   │   └── test/              # Backend tests
│   │
│   └── shared/                # Shared TypeScript types and utilities
│       ├── types/             # Common type definitions
│       └── protocols/         # Communication protocols
│
├── docker/                    # Docker configurations
├── k8s/                      # Kubernetes manifests
├── terraform/                # Infrastructure as Code
├── .github/workflows/        # GitHub Actions CI/CD
├── scripts/                  # Build and deployment scripts
└── docs/                     # Additional documentation
```

## Development Commands

### Frontend (packages/frontend)
```bash
npm run dev          # Start development server
npm run build        # Build for production
npm run test         # Run unit tests
npm run test:e2e     # Run E2E tests
npm run lint         # Lint code
npm run type-check   # TypeScript type checking
```

### Backend (packages/backend)
```bash
mix phx.server       # Start Phoenix server
mix test             # Run tests
mix format           # Format code
mix credo            # Static code analysis
mix ecto.migrate     # Run database migrations
mix ecto.reset       # Reset database
```

### Monorepo Commands (root)
```bash
npm run dev          # Start all services
npm run test         # Run all tests
npm run build        # Build all packages
npm run docker:build # Build Docker images
npm run deploy       # Deploy to staging
npm run deploy:prod  # Deploy to production
```

## Testing Strategy

- **Unit Tests**: Jest (Frontend), ExUnit (Backend)
- **Integration Tests**: Phoenix channels, API endpoints
- **E2E Tests**: Playwright for user workflows
- **Performance Tests**: Load testing with k6
- **Security Tests**: OWASP ZAP integration

## Monitoring and Observability

- **Metrics**: Prometheus + Grafana
- **Logging**: Structured logging with ELK stack
- **Tracing**: OpenTelemetry integration
- **Health Checks**: Kubernetes probes
- **Alerting**: PagerDuty integration

## Security Considerations

- JWT-based authentication with refresh tokens
- Rate limiting and DDoS protection
- Input validation and sanitization
- CORS and CSP headers
- Secrets management with Kubernetes secrets
- Regular dependency updates and vulnerability scanning

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes with tests
4. Run the full test suite
5. Submit a pull request

## License

MIT License - see LICENSE file for details