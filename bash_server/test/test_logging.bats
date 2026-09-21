#!/usr/bin/env bats
# =============================================================================
# test/test_logging.bats - Unit tests for src/lib/logging.sh
# =============================================================================

# Cargar helpers comunes
load test_helper/common

setup() {
  common_setup
  
  # Source the logging functions
  source "${LIB_DIR}/logging.sh"
}

teardown() {
  common_teardown
}

# =============================================================================
# Tests for log()
# =============================================================================

@test "log() writes INFO message when LOG_LEVEL >= 1" {
  LOG_LEVEL=1
  run log "Test message"
  
  assert_success
  assert_output --regexp '\[INFO\].*Test message'
}

@test "log() does not write when LOG_LEVEL < 1" {
  LOG_LEVEL=0
  run log "Test message"
  
  assert_success
  assert_output ""
}

@test "log() writes to log file" {
  LOG_LEVEL=1
  log "Test message" >/dev/null
  
  assert_file_exists "$LOG_FILE"
  run cat "$LOG_FILE"
  assert_output --partial "Test message"
}

@test "log() includes timestamp in correct format" {
  LOG_LEVEL=1
  run log "Test message"
  
  assert_output --regexp '\[[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}\]'
}

# =============================================================================
# Tests for debug()
# =============================================================================

@test "debug() writes DEBUG message when LOG_LEVEL >= 2" {
  LOG_LEVEL=2
  run debug "Debug message"
  
  assert_success
  assert_output --regexp '\[DEBUG\].*Debug message'
}

@test "debug() does not write when LOG_LEVEL < 2" {
  LOG_LEVEL=1
  run debug "Debug message"
  
  assert_success
  assert_output ""
}

@test "debug() writes to log file" {
  LOG_LEVEL=2
  debug "Debug message" >/dev/null
  
  assert_file_exists "$LOG_FILE"
  run cat "$LOG_FILE"
  assert_output --partial "Debug message"
}

# =============================================================================
# Tests for ok()
# =============================================================================

@test "ok() writes success message with green color" {
  run ok "Success message"
  
  assert_success
  assert_output --regexp '\[ OK \].*Success message'
}

@test "ok() writes to log file" {
  ok "Success message" >/dev/null
  
  assert_file_exists "$LOG_FILE"
  run cat "$LOG_FILE"
  assert_output --partial "Success message"
}

@test "ok() always outputs regardless of LOG_LEVEL" {
  LOG_LEVEL=0
  run ok "Success message"
  
  assert_success
  assert_output --partial "Success message"
}

# =============================================================================
# Tests for warn()
# =============================================================================

@test "warn() writes warning message with yellow color" {
  run warn "Warning message"
  
  assert_success
  assert_output --regexp '\[WARN\].*Warning message'
}

@test "warn() writes to log file" {
  warn "Warning message" >/dev/null
  
  assert_file_exists "$LOG_FILE"
  run cat "$LOG_FILE"
  assert_output --partial "Warning message"
}

@test "warn() always outputs regardless of LOG_LEVEL" {
  LOG_LEVEL=0
  run warn "Warning message"
  
  assert_success
  assert_output --partial "Warning message"
}

# =============================================================================
# Tests for fail()
# =============================================================================

@test "fail() writes error message with red color" {
  run fail "Error message"
  
  assert_failure
  assert_output --regexp '\[FAIL\].*Error message'
}

@test "fail() exits with status 1" {
  run fail "Error message"
  
  assert_equal "$status" "1"
}

@test "fail() writes to log file before exiting" {
  run fail "Error message"
  
  assert_file_exists "$LOG_FILE"
  run cat "$LOG_FILE"
  assert_output --partial "Error message"
}

# =============================================================================
# Tests for run()
# =============================================================================

@test "run() executes command in normal mode" {
  DRY_RUN=false
  LOG_LEVEL=2
  
  run run echo "test command"
  
  assert_success
  assert_output --partial "test command"
}

@test "run() logs command in dry-run mode without executing" {
  DRY_RUN=true
  LOG_LEVEL=1
  
  run run rm -f /nonexistent/file
  
  assert_success
  assert_output --regexp '\[DRY-RUN\].*Would execute.*rm -f /nonexistent/file'
}

@test "run() logs debug message before execution" {
  DRY_RUN=false
  LOG_LEVEL=2
  
  run run true
  
  assert_output --regexp '\[DEBUG\].*Executing'
}

@test "run() shows success message on successful command" {
  DRY_RUN=false
  LOG_LEVEL=1
  
  run run true
  
  assert_success
  assert_output --regexp '\[ OK \]'
}

@test "run() shows fail message on failed command" {
  DRY_RUN=false
  LOG_LEVEL=1
  
  run run false
  
  assert_failure
  assert_output --regexp '\[FAIL\]'
}

@test "run() redirects command output to log file" {
  DRY_RUN=false
  LOG_LEVEL=2
  
  run run echo "output to log"
  
  assert_file_exists "$LOG_FILE"
  file_contains "$LOG_FILE" "output to log"
}

# =============================================================================
# Integration tests
# =============================================================================

@test "multiple log levels work together" {
  LOG_LEVEL=2
  
  log "Info message" >/dev/null
  debug "Debug message" >/dev/null
  ok "Success message" >/dev/null
  warn "Warning message" >/dev/null
  
  assert_file_exists "$LOG_FILE"
  
  run cat "$LOG_FILE"
  assert_output --partial "Info message"
  assert_output --partial "Debug message"
  assert_output --partial "Success message"
  assert_output --partial "Warning message"
}

@test "log file contains all messages in chronological order" {
  LOG_LEVEL=2
  
  log "First" >/dev/null
  sleep 0.1
  debug "Second" >/dev/null
  sleep 0.1
  ok "Third" >/dev/null
  
  # Verify all messages are in file
  run cat "$LOG_FILE"
  assert_output --partial "First"
  assert_output --partial "Second"
  assert_output --partial "Third"
}