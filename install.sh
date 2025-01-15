#!/bin/bash

# Text colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
timestamp=$(date +%Y%m%d_%H%M%S)

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to generate random string
generate_random_string() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c "$1"
}

# Function to get user input with default value
get_user_input() {
    local prompt_message=$1
    local default_value=$2
    local user_input

    if [[ -n "$default_value" ]]; then
        read -p "$prompt_message [$default_value]: " user_input
        user_input=${user_input:-$default_value}
    else
        read -p "$prompt_message: " user_input
    fi

    echo "$user_input"
    return 0
}

# Function to validate protocol input
get_protocol_input() {
    local prompt_message=$1
    local default_value=$2
    local user_input

    while true; do
        if [[ -n "$default_value" ]]; then
            read -p "$prompt_message [$default_value]: " user_input
            user_input=${user_input:-$default_value}
        else
            read -p "$prompt_message: " user_input
        fi

        if [[ "$user_input" == "http" || "$user_input" == "https" ]]; then
            echo "$user_input"
            return 0
        else
            echo -e "${RED}Invalid input. Please enter 'http' or 'https'.${NC}"
        fi
    done
}

# Function to get yes/no confirmation
confirm() {
    local message="$1"
    local response

    while true; do
        echo -e -n "${YELLOW}$message${NC} [y/N]: "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY]) return 0 ;;
            [nN][oO]|[nN]|"") return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Function to backup existing env files
backup_env_files() {
    local backup_dir=".config_backup/${timestamp}"

    mkdir -p "$backup_dir" || { echo -e "${RED}Failed to create backup directory: $backup_dir${NC}"; exit 1; }

    for file in *.env; do
        if [[ -f "$file" ]]; then
            echo "Backing up $file..."
            mv "$file" "$backup_dir/" || { echo -e "${RED}Failed to backup $file${NC}"; exit 1; }
        fi
    done

    echo -e "${GREEN}Environment files backed up to: $backup_dir${NC}"
}

# Function to safely replace a line in a file
safe_replace() {
    local file="$1"
    local search="$2"
    local replace="$3"

    if [[ ! -w "$file" ]]; then
        echo -e "${RED}Error: File '$file' does not exist or is not writable.${NC}" >&2
        return 1
    fi

    # Escape special characters in replacement string
    local escaped_replace=$(printf '%s' "$replace" | sed 's/[&/]/\\&/g')
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' -e "s/^$search=.*/$search=$escaped_replace/" "$file" || { echo -e "${RED}Failed to update $file${NC}"; exit 1; }
    else
        sed -i "s/^$search=.*/$search=$escaped_replace/" "$file" || { echo -e "${RED}Failed to update $file${NC}"; exit 1; }
    fi
}

add_missing_variables() {
    local example_file="$1"
    local env_file="$2"

    while IFS='=' read -r key value; do
        # Skip lines that start with '#'
        if [[ $key == \#* || -z $key ]]; then
            continue
        fi
        if ! grep -q "^$key=" "$env_file"; then
            echo "$key=$value" >> "$env_file"
        fi
    done < "$example_file"
}

# Function to validate required example files
validate_example_files() {
    local example_files=("env_templates/app.env.example" "env_templates/db.env.example" "env_templates/minio.env.example" "env_templates/frontend.env.example" "env_templates/playwright.env.example" "env_templates/.env.example")

    for file in "${example_files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo -e "${RED}Missing required file: $file. Please ensure all example files are present.${NC}"
            exit 1
        fi
    done
}

# Function to validate environment files
validate_env_files() {
    local files=("app.env" "db.env" "frontend.env" "playwright.env")

    for file in "${files[@]}"; do
        if [[ ! -f "$file" ]]; then
            echo -e "${RED}Missing environment file: $file. Please check the setup.${NC}"
            exit 1
        fi
    done
}

# Parse command line arguments
REINSTALL=false
DEBUG=false
DB_FILE_EXISTS=$([ -f db.env ] && echo "true" || echo "false")
APP_FILE_EXISTS=$([ -f app.env ] && echo "true" || echo "false")
PLAYWRIGHT_FILE_EXISTS=$([ -f playwright.env ] && echo "true" || echo "false")

for arg in "$@"; do
    case $arg in
        --reinstall)
            REINSTALL=true
            ;;
        --debug)
            DEBUG=true
            ;;
    esac
done

# Enable debug mode
if [[ "$DEBUG" == true ]]; then
    set -x
fi

# Handle reinstall option
if [[ "$REINSTALL" == true ]]; then
    if [[ -f app.env || -f db.env || -f frontend.env ]]; then
        echo -e "${YELLOW}Existing environment files detected.${NC}"
        if confirm "Do you want to backup and remove existing environment files?"; then
            backup_env_files
        else
            echo "Installation cancelled."
            exit 1
        fi
    fi
fi

# Validate required example files
validate_example_files

# Check if Docker is installed
if ! command_exists docker; then
    echo -e "${RED}Docker is not installed. Please install Docker first.${NC}"
    echo "Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose && ! docker compose version >/dev/null 2>&1; then
    echo -e "${RED}Docker Compose is not installed. Please install Docker Compose first.${NC}"
    echo "Visit https://docs.docker.com/compose/install/ for installation instructions."
    exit 1
fi

# Get user input for configuration
WEBSITE_DOMAIN=$(get_user_input "Website Domain (e.g., example.com)" "localhost")
# STORAGE_DOMAIN=$(get_user_input "Storage Domain (e.g., storage.example.com)" "localhost:9000")
WEBSITE_PROTOCOL=$(get_protocol_input "Website Protocol" "http")
# STORAGE_PROTOCOL=$(get_protocol_input "Storage Protocol" "http")

WEBSITE_URL="${WEBSITE_PROTOCOL}://${WEBSITE_DOMAIN}"
# STORAGE_URL="${STORAGE_PROTOCOL}://${STORAGE_DOMAIN}"

# Copy and configure environment files
for env in app db frontend playwright; do
    if [[ -f "env_templates/${env}.env.example" && ! -f "${env}.env" ]]; then
        echo "Creating ${env}.env..."
        cp "env_templates/${env}.env.example" "${env}.env"
    else
        echo -e "${YELLOW}${env}.env already exists. checking for missing variables...${NC}"
        add_missing_variables "env_templates/${env}.env.example" "${env}.env"
    fi

done

if [[ -f "env_templates/.env.example" && ! -f ".env" ]]; then
    echo "Creating .env..."
    cp "env_templates/.env.example" ".env"
fi

# Generate secrets and configure app.env
if [[ -f app.env ]]; then
    safe_replace "app.env" "ALLOWED_HOSTS" "$WEBSITE_DOMAIN"
    safe_replace "app.env" "CSRF_TRUSTED_ORIGINS" "$WEBSITE_URL"
    safe_replace "app.env" "CORS_ALLOWED_ORIGINS" "$WEBSITE_URL"

    if [[ "$DB_FILE_EXISTS" == "true" ]]; then
        echo -e "\n${YELLOW}app.env already exists. Skipping secret key generation.${NC}"
    else
        SECRET_KEY=$(generate_random_string 50)
        safe_replace "app.env" "SECRET_KEY" "$SECRET_KEY"
    fi
fi

if [[ -f db.env ]]; then
    if [[ "$APP_FILE_EXISTS" == "true" ]]; then
        echo -e "\n${YELLOW}db.env already exists. Skipping password generation.${NC}"
    else
        DB_PASSWORD=$(generate_random_string 16)
        safe_replace "db.env" "POSTGRES_PASSWORD" "$DB_PASSWORD"
        safe_replace "app.env" "DATABASE_URL" "postgresql://postgres:$DB_PASSWORD@postgres:5432/postgres"
    fi
fi

# if [[ -f minio.env ]]; then
#     MINIO_ACCESS_KEY=$(generate_random_string 20)
#     MINIO_SECRET_KEY=$(generate_random_string 40)
#     safe_replace "minio.env" "MINIO_ROOT_USER" "$MINIO_ACCESS_KEY"
#     safe_replace "minio.env" "MINIO_ROOT_PASSWORD" "$MINIO_SECRET_KEY"
#     safe_replace "app.env" "MINIO_ACCESS_KEY" "$MINIO_ACCESS_KEY"
#     safe_replace "app.env" "MINIO_SECRET_KEY" "$MINIO_SECRET_KEY"
# fi

if [[ -f frontend.env ]]; then
    safe_replace "frontend.env" "VITE_API_URL" "$WEBSITE_URL"
fi

if [[ -f playwright.env ]]; then
    if [[ "$PLAYWRIGHT_FILE_EXISTS" == "true" ]]; then
        echo -e "\n${YELLOW}playwright.env already exists. Skipping API key generation.${NC}"
    else
        AUTH_API_KEY=$(generate_random_string 32)
        safe_replace "playwright.env" "AUTH_API_KEY" "$AUTH_API_KEY"
        safe_replace "app.env" "PLAYWRIGHT_API_KEY" "$AUTH_API_KEY"
    fi
fi

# Validate environment files
validate_env_files

# Finish
echo -e "\n\n\n${GREEN}Environment setup completed successfully!${NC}"
echo "You can now run 'docker compose up -d --build' to start the services."

if [[ "$REINSTALL" == true ]]; then
    echo -e "\n\n${RED}Environment files backed up to: .config_backups/${timestamp}${NC}"
    echo -e "${RED}Yoy have to manually remove the docker volumes. if it is already created.${NC}" 
fi

echo -e "\n\n${GREEN}To create an admin user, run the following command:${NC}"
echo -e "${BLUE}chmod +x create_admin.sh${NC}"
echo -e "${BLUE}./create_admin.sh${NC}"
