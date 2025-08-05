#!/bin/bash

set -e

echo "🛠️  Setting up Collaborative Code Editor development environment..."

# Check for required tools
echo "🔍 Checking for required tools..."

check_tool() {
    if ! command -v $1 &> /dev/null; then
        echo "❌ $1 is not installed. Please install it first."
        return 1
    else
        echo "✅ $1 is installed"
        return 0
    fi
}

MISSING_TOOLS=()

check_tool "node" || MISSING_TOOLS+=("node")
check_tool "npm" || MISSING_TOOLS+=("npm")
check_tool "docker" || MISSING_TOOLS+=("docker")
check_tool "docker-compose" || MISSING_TOOLS+=("docker-compose")

# Check for Elixir/Erlang
if ! command -v elixir &> /dev/null; then
    echo "❌ Elixir is not installed"
    echo "   Install with: https://elixir-lang.org/install.html"
    MISSING_TOOLS+=("elixir")
else
    echo "✅ Elixir is installed ($(elixir --version | head -n1))"
fi

if ! command -v mix &> /dev/null; then
    echo "❌ Mix is not installed"
    MISSING_TOOLS+=("mix")
else
    echo "✅ Mix is installed"
fi

if [ ${#MISSING_TOOLS[@]} -ne 0 ]; then
    echo ""
    echo "❌ Please install the missing tools and try again:"
    printf '   - %s\n' "${MISSING_TOOLS[@]}"
    exit 1
fi

# Check versions
echo ""
echo "📋 Installed versions:"
echo "   Node.js: $(node --version)"
echo "   npm: $(npm --version)"
echo "   Docker: $(docker --version)"
echo "   Docker Compose: $(docker-compose --version)"
echo "   Elixir: $(elixir --version | head -n1)"

# Install root dependencies
echo ""
echo "📦 Installing root dependencies..."
npm install

# Install frontend dependencies
echo ""
echo "🎨 Installing frontend dependencies..."
cd packages/frontend
npm install
cd ../..

# Install backend dependencies
echo ""
echo "⚙️  Installing backend dependencies..."
cd packages/backend
mix local.hex --force
mix local.rebar --force
mix deps.get
cd ../..

# Start database services
echo ""
echo "🗄️  Starting database services..."
docker-compose up -d postgres redis

# Wait for databases to be ready
echo "⏳ Waiting for databases to start..."
sleep 10

# Check if databases are running
if docker-compose ps postgres | grep -q "Up"; then
    echo "✅ PostgreSQL is running"
else
    echo "❌ PostgreSQL failed to start"
    docker-compose logs postgres
    exit 1
fi

if docker-compose ps redis | grep -q "Up"; then
    echo "✅ Redis is running"
else
    echo "❌ Redis failed to start"
    docker-compose logs redis
    exit 1
fi

# Setup backend database
echo ""
echo "🗄️  Setting up backend database..."
cd packages/backend
mix ecto.create
mix ecto.migrate
cd ../..

# Generate development certificates (optional)
echo ""
echo "🔐 Setting up development certificates..."
if [ ! -f "certs/localhost.crt" ]; then
    mkdir -p certs
    openssl req -x509 -newkey rsa:4096 -keyout certs/localhost.key -out certs/localhost.crt -days 365 -nodes -subj "/CN=localhost" 2>/dev/null || echo "⚠️  OpenSSL not available, skipping certificate generation"
fi

# Create environment files
echo ""
echo "⚙️  Creating environment files..."

if [ ! -f "packages/frontend/.env.local" ]; then
    cat > packages/frontend/.env.local << EOF
VITE_API_URL=http://localhost:4000
VITE_WS_URL=ws://localhost:4000/socket
VITE_ENVIRONMENT=development
EOF
    echo "✅ Created frontend/.env.local"
fi

if [ ! -f "packages/backend/.env" ]; then
    cat > packages/backend/.env << EOF
DATABASE_URL=ecto://postgres:postgres@localhost:5432/collaborative_editor_dev
REDIS_URL=redis://localhost:6379
SECRET_KEY_BASE=your_secret_key_base_here_make_it_long_and_random
JWT_SECRET=your_jwt_secret_here
MIX_ENV=dev
PORT=4000
PHX_HOST=localhost
EOF
    echo "✅ Created backend/.env"
fi

# Build frontend for development
echo ""
echo "🔨 Building frontend for development..."
cd packages/frontend
npm run build
cd ../..

echo ""
echo "🎉 Development environment setup complete!"
echo ""
echo "🚀 To start the development servers:"
echo "   npm run dev"
echo ""
echo "   Or start them individually:"
echo "   Backend:  cd packages/backend && mix phx.server"
echo "   Frontend: cd packages/frontend && npm run dev"
echo ""
echo "📍 Access points:"
echo "   Frontend: http://localhost:3000"
echo "   Backend:  http://localhost:4000"
echo "   Phoenix LiveDashboard: http://localhost:4000/dashboard"
echo ""
echo "🛠️  Useful commands:"
echo "   npm run test       - Run all tests"
echo "   npm run lint       - Lint all code"
echo "   npm run type-check - TypeScript type checking"
echo "   npm run clean      - Clean build artifacts"
echo ""
echo "🐳 Docker services:"
echo "   docker-compose up   - Start services"
echo "   docker-compose down - Stop services"
echo "   docker-compose logs - View logs"