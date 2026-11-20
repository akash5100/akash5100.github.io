# ==============================================================================
# Akash Blog Management Manual
# ==============================================================================
#
# USAGE GUIDE:
#
# 1. Setup & Environment:
#    just setup              - Build local Hugo Docker image
#
# 2. Server Management:
#    just up                 - Spin up local Hugo server with hot-reload (http://localhost:1313)
#    just down               - Stop and remove the blog container
#    just restart            - Rebuild & restart the blog container in 1 step
#    just logs               - Follow live container output
#
# 3. Static Site Generation:
#    just build              - Compile production static build into public/
#    just clean              - Remove public/ build artifacts and stop containers
#
# ==============================================================================

# Default recipe: list available recipes
default:
    @just --list --justfile {{justfile()}}

# Pre-flight check: ensure Docker daemon is running
_check-docker:
    @if ! docker info >/dev/null 2>&1; then \
        echo "Error: Docker daemon is not running. Please start Docker Desktop." >&2; \
        exit 1; \
    fi

# Build container image with Hugo, Dart-Sass, Go, and Git
setup: _check-docker
    @echo "⬢ Building blog container image..."
    @docker compose -f {{justfile_directory()}}/docker-compose.yml build

# Start local dev server with auto hot-reloading (Obsidian / browser sync)
up: _check-docker
    @echo "▶ Starting blog dev server..."
    @docker compose -f {{justfile_directory()}}/docker-compose.yml up -d
    @echo "✔ Blog is running at http://localhost:1313/"

# Stop local dev server
down: _check-docker
    @echo "■ Stopping blog dev server..."
    @docker compose -f {{justfile_directory()}}/docker-compose.yml down

# Rebuild and restart server in 1 step
restart: _check-docker
    @echo "↻ Rebuilding and restarting blog server..."
    @docker compose -f {{justfile_directory()}}/docker-compose.yml up -d --build --force-recreate
    @echo "✔ Blog is running at http://localhost:1313/"

# Stream live server logs
logs: _check-docker
    @docker compose -f {{justfile_directory()}}/docker-compose.yml logs -f

# Compile production static site to public/
build: _check-docker
    @echo "⬢ Compiling production static build into public/..."
    @docker compose -f {{justfile_directory()}}/docker-compose.yml run --rm blog build --minify

# Clean build artifacts and stop containers
clean: _check-docker
    @echo "⬡ Cleaning build artifacts and stopping containers..."
    @docker compose -f {{justfile_directory()}}/docker-compose.yml down --volumes --remove-orphans
    @rm -rf {{justfile_directory()}}/public {{justfile_directory()}}/.hugo_build.lock
    @echo "✔ Clean completed."
