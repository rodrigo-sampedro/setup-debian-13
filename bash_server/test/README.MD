# Instalar BATS si no lo tienes
git clone https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh /usr/local

# Ejecutar tests individuales
bats test_logging.bats
bats test_utils.bats

# Ejecutar todos los tests
bats test_*.bats

# Ejecutar con verbose
bats -t test_logging.bats