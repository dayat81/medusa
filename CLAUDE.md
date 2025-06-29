# CLAUDE.md - Medusa Development Guide

## Project Overview

Medusa is an open-source composable commerce platform built with JavaScript/TypeScript. It provides building blocks for digital commerce applications, allowing developers to build custom B2B/DTC ecommerce stores, marketplaces, PoS systems, and service businesses.

### Tech Stack
- **Language**: TypeScript/JavaScript
- **Runtime**: Node.js (v20+)
- **Package Manager**: Yarn (v3.2.1) with workspaces
- **Build Tool**: Turbo
- **Testing**: Jest
- **Linting**: ESLint
- **Code Formatting**: Prettier
- **Database**: PostgreSQL (via MikroORM)
- **Architecture**: Modular monorepo with independent commerce modules

## Project Structure

This is a monorepo organized as follows:

```
medusa/
├── packages/
│   ├── medusa/                 # Core Medusa package
│   ├── admin/                  # Admin UI packages
│   ├── cli/                    # CLI tools
│   ├── core/                   # Core framework packages
│   ├── modules/                # Commerce and infrastructure modules
│   ├── design-system/          # UI components and design system
│   └── ...
├── integration-tests/          # Integration test suites
├── www/                        # Documentation websites
├── scripts/                    # Build and utility scripts
└── turbo.json                  # Turbo build configuration
```

## Build Commands

### Install Dependencies
```bash
yarn install
```

### Build All Packages
```bash
yarn build
```

### Build Specific Package
```bash
# Navigate to package directory
cd packages/medusa
yarn build
```

## Lint Commands

### Lint Entire Codebase
```bash
yarn lint
```

### Lint Specific Path
```bash
yarn lint:path path/to/files
```

### Format Code
```bash
yarn prettier --write "**/*.{js,jsx,ts,tsx,md,yaml,yml}"
```

## Test Commands

### Run All Unit Tests
```bash
yarn test
```

### Run Unit Tests in Chunks (for CI)
```bash
yarn test:chunk
```

### Run Integration Tests

#### Fast Integration Tests
```bash
yarn test:integration:packages:fast
```

#### Slow Integration Tests
```bash
yarn test:integration:packages:slow
```

#### API Integration Tests
```bash
yarn test:integration:api
```

#### HTTP Integration Tests
```bash
yarn test:integration:http
```

#### Modules Integration Tests
```bash
yarn test:integration:modules
```

### Run Tests for Specific Package
```bash
# Navigate to package directory
cd packages/medusa
yarn test
```

## Development Commands

### Start Development Server
```bash
# For the main medusa package
cd packages/medusa
yarn build
yarn serve
```

### Watch Mode (Auto-rebuild)
```bash
cd packages/medusa
yarn watch
```

## High-Level Architecture

### 1. **Modular Architecture**
Medusa follows a modular architecture where functionality is split into independent modules that can be composed together:

- **Commerce Modules**: Product, Cart, Order, Customer, Pricing, Promotion, etc.
- **Infrastructure Modules**: Event Bus, Cache, File Storage, Notification, etc.
- **Provider Modules**: Payment providers, fulfillment providers, auth providers, etc.

### 2. **Core Components**

#### Medusa Application (`@medusajs/medusa`)
The main application that orchestrates all modules and provides:
- HTTP API server
- Admin UI integration
- Module loading and configuration
- Middleware system
- Event handling

#### Framework (`@medusajs/framework`)
Core framework providing:
- Dependency injection container
- Module system
- Database abstractions
- Common utilities

#### Workflows (`@medusajs/workflows-sdk`)
Workflow engine for complex business logic:
- Declarative workflow definitions
- Step-based execution
- Compensation/rollback support
- Parallel execution

#### Data Models
- Uses MikroORM for database operations
- PostgreSQL as the primary database
- Each module has its own data models
- Supports custom data model extensions

### 3. **Module System**

Modules are self-contained units with:
- **Models**: Database entities
- **Services**: Business logic
- **Repositories**: Data access layer
- **Migrations**: Database schema changes
- **Loaders**: Initialization logic
- **Subscribers**: Event handlers

### 4. **API Architecture**

#### Admin API
- RESTful API for admin operations
- Protected routes with authentication
- Comprehensive CRUD operations
- Batch operations support

#### Store API
- Customer-facing API
- Cart and checkout flows
- Product catalog
- Customer management

### 5. **Extension Points**

#### API Routes
Custom API routes can be added to extend functionality

#### Workflows
Custom workflows for complex business processes

#### Subscribers
Event-driven extensions using the event bus

#### Services
Custom services can be injected into the container

#### Data Models
Extend existing models or create new ones

### 6. **Admin UI**
- React-based admin dashboard
- Extensible with custom widgets and routes
- Plugin system for UI extensions
- Built with Vite

### 7. **Testing Architecture**
- Unit tests for individual components
- Integration tests for module interactions
- API tests for endpoint validation
- Test utilities for module testing

## Key Design Patterns

1. **Dependency Injection**: Uses Awilix for IoC container
2. **Repository Pattern**: Data access abstraction
3. **Service Layer**: Business logic encapsulation
4. **Event-Driven**: Pub/sub for loose coupling
5. **Workflow Pattern**: Complex operations as workflows
6. **Module Federation**: Independent, composable modules

## Development Guidelines

1. **Branch Strategy**:
   - `develop`: Main development branch for v2.0
   - `v1.x`: Maintenance branch for v1.x
   - Feature branches: `feat/`, `fix/`, `docs/`

2. **Commit Convention**:
   - Keep commits small and focused
   - Use changesets for version management

3. **Testing Requirements**:
   - Write unit tests for new features
   - Add integration tests for API changes
   - Ensure all tests pass before PR

4. **Code Style**:
   - Follow ESLint configuration
   - Use Prettier for formatting
   - Document with TSDoc comments

## Environment Variables

Key environment variables:
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection (optional)
- `JWT_SECRET`: Authentication secret
- `COOKIE_SECRET`: Session secret
- `ADMIN_CORS`: CORS configuration for admin
- `STORE_CORS`: CORS configuration for store

See `packages/medusa/src/utils/environment-variables.ts` for full list.

## Quick Start

1. Clone the repository
2. Install dependencies: `yarn install`
3. Build packages: `yarn build`
4. Set up PostgreSQL database
5. Configure environment variables
6. Run migrations
7. Start the application

## Additional Resources

- [Documentation](https://docs.medusajs.com)
- [Contributing Guide](CONTRIBUTING.md)
- [Discord Community](https://discord.gg/medusajs)
- [GitHub Discussions](https://github.com/medusajs/medusa/discussions)