#!/usr/bin/env bash
# =============================================================================
# setup-project-structure.sh - Configura la estructura del proyecto con BATS
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(pwd)"
BATS_VERSION="${BATS_VERSION:-v1.11.0}"

echo "Setting up project structure for Bash + BATS..."
echo ""

# =============================================================================
# Crear estructura de directorios
# =============================================================================

echo "📁 Creating directory structure..."

mkdir -p src/lib
mkdir -p test/test_helper
mkdir -p bin
mkdir -p docs

echo "   ✓ src/lib/"
echo "   ✓ test/test_helper/"
echo "   ✓ bin/"
echo "   ✓ docs/"
echo ""

# =============================================================================
# Mover archivos existentes si existen
# =============================================================================

echo "📦 Organizing existing files..."

if [[ -f "logging.sh" ]]; then
  mv logging.sh src/lib/
  echo "   ✓ Moved logging.sh → src/lib/"
fi

if [[ -f "utils.sh" ]]; then
  mv utils.sh src/lib/
  echo "   ✓ Moved utils.sh → src/lib/"
fi

if [[ -f "test_logging.bats" ]]; then
  mv test_logging.bats test/
  echo "   ✓ Moved test_logging.bats → test/"
fi

if [[ -f "test_utils.bats" ]]; then
  mv test_utils.bats test/
  echo "   ✓ Moved test_utils.bats → test/"
fi

echo ""

# =============================================================================
# Instalar submódulos de BATS
# =============================================================================

echo "🔧 Installing BATS testing framework..."

if [[ ! -d "test/test_helper/bats-core" ]]; then
  git clone --depth 1 --branch "$BATS_VERSION" \
    https://github.com/bats-core/bats-core.git \
    test/test_helper/bats-core
  echo "   ✓ Installed bats-core"
else
  echo "   ℹ️  bats-core already installed"
fi

if [[ ! -d "test/test_helper/bats-support" ]]; then
  git clone --depth 1 \
    https://github.com/bats-core/bats-support.git \
    test/test_helper/bats-support
  echo "   ✓ Installed bats-support"
else
  echo "   ℹ️  bats-support already installed"
fi

if [[ ! -d "test/test_helper/bats-assert" ]]; then
  git clone --depth 1 \
    https://github.com/bats-core/bats-assert.git \
    test/test_helper/bats-assert
  echo "   ✓ Installed bats-assert"
else
  echo "   ℹ️  bats-assert already installed"
fi

if [[ ! -d "test/test_helper/bats-file" ]]; then
  git clone --depth 1 \
    https://github.com/bats-core/bats-file.git \
    test/test_helper/bats-file
  echo "   ✓ Installed bats-file"
else
  echo "   ℹ️  bats-file already installed"
fi

echo ""

# =============================================================================
# Crear archivo de helpers común
# =============================================================================

echo "📝 Creating test helper files..."

cat > test/test_helper/common.bash << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# test/test_helper/common.bash - Configuración común para todos los tests
# =============================================================================

# Cargar librerías de BATS
load 'bats-support/load'
load 'bats-assert/load'
load 'bats-file/load'

# Variables globales para tests
export PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
export SRC_DIR="${PROJECT_ROOT}/src"
export LIB_DIR="${SRC_DIR}/lib"

# Setup común para todos los tests
common_setup() {
  # Crear directorio temporal para cada test
  export TEST_TEMP_DIR="$(temp_make)"
  export LOG_FILE="${TEST_TEMP_DIR}/test.log"
  export STATE_FILE="${TEST_TEMP_DIR}/state.txt"
  
  # Configuración por defecto
  export LOG_LEVEL=2
  export DRY_RUN=false
  export EUID=0
}

# Teardown común para todos los tests
common_teardown() {
  # Limpiar directorio temporal
  temp_del "${TEST_TEMP_DIR}"
}

# Función helper para mockear comandos
mock_command() {
  local cmd="$1"
  local return_code="${2:-0}"
  local output="${3:-}"
  
  eval "${cmd}() { echo '${output}'; return ${return_code}; }"
}

# Función helper para verificar que un archivo contiene texto
file_contains() {
  local file="$1"
  local text="$2"
  
  grep -qF "${text}" "${file}"
}
EOF

echo "   ✓ Created test/test_helper/common.bash"
echo ""

# =============================================================================
# Crear Makefile para facilitar el uso
# =============================================================================

echo "🛠️  Creating Makefile..."

cat > Makefile << 'EOF'
.PHONY: test test-verbose test-coverage clean install-bats help

# Variables
BATS := test/test_helper/bats-core/bin/bats
TEST_DIR := test
SRC_DIR := src

help: ## Muestra esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

install-bats: ## Instala BATS y sus dependencias
	@./setup-project-structure.sh

test: ## Ejecuta todos los tests
	@echo "Running all tests..."
	@$(BATS) $(TEST_DIR)/*.bats

test-verbose: ## Ejecuta tests con output verbose
	@echo "Running tests (verbose mode)..."
	@$(BATS) -t $(TEST_DIR)/*.bats

test-single: ## Ejecuta un test específico (use: make test-single FILE=test_utils.bats)
	@echo "Running single test: $(FILE)"
	@$(BATS) $(TEST_DIR)/$(FILE)

test-coverage: ## Ejecuta tests con timing
	@echo "Running tests with timing..."
	@$(BATS) --timing $(TEST_DIR)/*.bats

test-watch: ## Ejecuta tests continuamente (requiere entr)
	@echo "Watching for changes..."
	@ls $(TEST_DIR)/*.bats $(SRC_DIR)/lib/*.sh | entr -c make test

lint: ## Ejecuta shellcheck en todos los scripts
	@echo "Linting bash scripts..."
	@shellcheck $(SRC_DIR)/lib/*.sh
	@shellcheck bin/*.sh 2>/dev/null || true
	@echo "✓ Lint complete"

clean: ## Limpia archivos temporales
	@echo "Cleaning temporary files..."
	@rm -rf test/test_helper/bats-*
	@find . -type d -name "tmp" -exec rm -rf {} + 2>/dev/null || true
	@echo "✓ Clean complete"

format: ## Formatea código con shfmt (requiere shfmt)
	@echo "Formatting bash scripts..."
	@shfmt -i 2 -w $(SRC_DIR)/lib/*.sh
	@shfmt -i 2 -w bin/*.sh 2>/dev/null || true
	@echo "✓ Format complete"

.DEFAULT_GOAL := help
EOF

echo "   ✓ Created Makefile"
echo ""

# =============================================================================
# Crear .gitignore actualizado
# =============================================================================

echo "📄 Creating/updating .gitignore..."

cat > .gitignore << 'EOF'
# Test artifacts
test/test_helper/bats-core/
test/test_helper/bats-support/
test/test_helper/bats-assert/
test/test_helper/bats-file/
*.log
tmp/
.tmp/

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# OS files
.DS_Store
Thumbs.db

# Project specific
state.txt
*.backup
EOF

echo "   ✓ Created .gitignore"
echo ""

# =============================================================================
# Actualizar paths en los archivos de test
# =============================================================================

echo "🔄 Updating test file paths..."

for test_file in test/test_*.bats; do
  if [[ -f "$test_file" ]]; then
    # Actualizar la línea de source para usar la estructura correcta
    sed -i 's|load "../lib/|load "../src/lib/|g' "$test_file" 2>/dev/null || \
    sed -i '' 's|load "../lib/|load "../src/lib/|g' "$test_file" 2>/dev/null || true
    
    sed -i 's|source "../lib/|source "$LIB_DIR/|g' "$test_file" 2>/dev/null || \
    sed -i '' 's|source "../lib/|source "$LIB_DIR/|g' "$test_file" 2>/dev/null || true
    
    echo "   ✓ Updated $(basename "$test_file")"
  fi
done

echo ""

# =============================================================================
# Crear README con instrucciones
# =============================================================================

echo "📚 Creating documentation..."

cat > docs/TESTING.md << 'EOF'
# Testing Guide

## Running Tests

### All tests
```bash
make test
```

### Verbose output
```bash
make test-verbose
```

### Single test file
```bash
make test-single FILE=test_utils.bats
```

### Watch mode (auto-run on changes)
```bash
make test-watch
```

## Writing Tests

### Basic test structure
```bash
#!/usr/bin/env bats

# Load common helpers
load test_helper/common

setup() {
  common_setup
  # Your specific setup
}

teardown() {
  common_teardown
  # Your specific teardown
}

@test "description of test" {
  run your_function "arg1" "arg2"
  
  assert_success
  assert_output "expected output"
}
```

### Available assertions (from bats-assert)
- `assert_success` - Command succeeded (exit 0)
- `assert_failure` - Command failed (exit != 0)
- `assert_equal "expected" "actual"` - Values are equal
- `assert_output "text"` - Output matches exactly
- `assert_output --partial "text"` - Output contains text
- `assert_line "text"` - A line matches exactly
- `refute_output` - No output produced
- `assert_file_exists "path"` - File exists
- `assert_file_not_exists "path"` - File doesn't exist

### File operations (from bats-file)
- `temp_make` - Create temp directory
- `temp_del` - Delete temp directory
- `assert_file_exists`
- `assert_file_not_exists`
- `assert_file_contains`

## Project Structure

```
.
├── src/                    # Source code
│   └── lib/               # Library modules
│       ├── logging.sh
│       └── utils.sh
├── test/                   # Tests
│   ├── test_helper/       # Test helpers
│   │   ├── common.bash    # Common setup
│   │   ├── bats-core/     # BATS framework
│   │   ├── bats-support/  # Support library
│   │   ├── bats-assert/   # Assertions
│   │   └── bats-file/     # File helpers
│   ├── test_logging.bats
│   └── test_utils.bats
├── bin/                    # Executable scripts
├── Makefile               # Build automation
└── setup-project-structure.sh
```

## Continuous Integration

Example GitHub Actions workflow (`.github/workflows/test.yml`):

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup BATS
        run: ./setup-project-structure.sh
      - name: Run tests
        run: make test
      - name: Run linter
        run: make lint
```

## Tips

1. **Keep tests isolated** - Each test should be independent
2. **Use descriptive names** - Test names should clearly describe what they test
3. **Test one thing** - Each test should verify one specific behavior
4. **Use helpers** - Common setup goes in `test_helper/common.bash`
5. **Mock external dependencies** - Use the `mock_command` helper
EOF

echo "   ✓ Created docs/TESTING.md"
echo ""

# =============================================================================
# Crear script de ejemplo actualizado
# =============================================================================

echo "📝 Creating example main script..."

cat > bin/example.sh << 'EOF'
#!/usr/bin/env bash
# =============================================================================
# bin/example.sh - Script de ejemplo usando las librerías
# =============================================================================

set -euo pipefail

# Obtener el directorio raíz del proyecto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Cargar librerías
source "${PROJECT_ROOT}/src/lib/logging.sh"
source "${PROJECT_ROOT}/src/lib/utils.sh"

# Configuración
export LOG_FILE="${PROJECT_ROOT}/app.log"
export LOG_LEVEL=2
export DRY_RUN=false

# Función main
main() {
  log "Starting example script..."
  
  if command_exists "docker"; then
    ok "Docker is installed"
  else
    warn "Docker is not installed"
  fi
  
  log "Script completed successfully"
}

# Ejecutar main
main "$@"
EOF

chmod +x bin/example.sh
echo "   ✓ Created bin/example.sh"
echo ""

# =============================================================================
# Resumen final
# =============================================================================

cat << 'EOF'
✅ Project structure setup complete!

📁 Structure:
   src/lib/         - Your library modules (logging.sh, utils.sh)
   test/            - Test files (test_*.bats)
   test/test_helper/- BATS framework and helpers
   bin/             - Executable scripts
   docs/            - Documentation

🚀 Quick start:
   make test              - Run all tests
   make test-verbose      - Run tests with verbose output
   make test-single FILE=test_utils.bats
   make lint              - Run shellcheck
   make help              - See all commands

📖 Documentation:
   docs/TESTING.md        - Complete testing guide

💡 Tips:
   - Tests are in: test/
   - Source code is in: src/lib/
   - Use 'make test' to run all tests
   - Check docs/TESTING.md for detailed guide

EOF

echo "✨ Ready to test! Run: make test"