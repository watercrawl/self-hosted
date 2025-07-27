## Project Moved

This project has moved to [https://github.com/watercrawl/watercrawl](https://github.com/watercrawl/watercrawl) to be part of a mono repo. The project will continue there.

## Archive Notice

This project is now archived.

# WaterCrawl Self-Hosted

A self-hosted version of WaterCrawl, a powerful web crawling and data extraction platform.

## Prerequisites

- Docker Engine 24.0.0+
- Docker Compose v2.0.0+
- At least 2GB of RAM
- 10GB of free disk space

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/watercrawl/self-hosted.git
cd self-hosted
```

2. Run the installation script:
```bash
chmod +x install.sh
./install.sh
```

3. Start the services:
```bash
docker compose up -d
```

4. Create an admin user:
```bash
chmod +x create_admin.sh
./create_admin.sh
```

5. Access the application at `http://localhost:8000`

## Environment Configuration

The application uses several environment files for configuration:

### app.env
Contains the main application configuration including:
- Django settings
- Database configuration
- JWT settings
- Celery configuration
- MinIO settings
- CORS settings
- Plugin configuration

### db.env
PostgreSQL database configuration:
- Database credentials
- Database name

### minio.env
MinIO object storage configuration:
- Access credentials
- Server URLs
- Browser configuration

## Services

The application consists of several services:

- **App**: Main Django application
- **Celery**: Background task processing
- **PostgreSQL**: Primary database
- **Redis**: Message broker and caching
- **MinIO**: Object storage for files and media

## Directory Structure

```
watercrawl_self_hosted/
├── app.env                 # Application environment variables
├── app.env.example         # Example application environment file
├── create_admin.sh         # Script to create admin user
├── db.env                  # Database environment variables
├── db.env.example          # Example database environment file
├── docker-compose.yml      # Docker Compose configuration
├── install.sh             # Installation script
├── minio.env              # MinIO environment variables
├── minio.env.example      # Example MinIO environment file
└── watercrawl/            # Application source code
    ├── Dockerfile         # Application Dockerfile
    └── plugin_requirements.txt  # Plugin dependencies
```

## Installation Options

The installation script (`install.sh`) supports the following options:

- `--reinstall`: Backs up existing environment files and performs a fresh installation
- Interactive prompts for:
  - Website Domain
  - Storage Domain
  - Website Protocol (http/https)
  - Storage Protocol (http/https)

## Backup and Restore

Environment files are automatically backed up when using the `--reinstall` option. Backups are stored in:
```
.config_backups/DELETE_DATA/
```

## Troubleshooting

1. **Services not starting**: Check logs with
```bash
docker compose logs [service_name]
```

2. **Database connection issues**: Verify db.env configuration and ensure PostgreSQL is running
```bash
docker compose ps postgres
```

3. **Storage issues**: Check MinIO credentials in both minio.env and app.env match

## Security Considerations

1. Change default credentials in production:
   - Database password
   - MinIO access keys
   - Django secret key
   - Admin user password

2. Enable HTTPS in production by setting:
   - `MINIO_USE_HTTPS=True`
   - `MINIO_EXTERNAL_ENDPOINT_USE_HTTPS=True`
   - Configure proper SSL certificates

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under a modified MIT License. Key points:

1. You can freely use, modify, and distribute this software
2. You must include the original copyright notice and license
3. **Important Restrictions**:
   - The software may not be used to run a service similar to watercrawl.dev or any commercial service without explicit permission
   - Contributions are welcome through pull requests for community usage and development

See the [LICENSE](LICENSE) file for the complete terms.
