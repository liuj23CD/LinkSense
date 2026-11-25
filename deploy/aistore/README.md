# AIStore Deployment Guide

## Overview

AIStore (AIS) is a high-performance, scalable storage system designed for AI workloads. It provides an S3-compatible API, making it a drop-in replacement for MinIO in the LinkSense project.

## Features

- **S3-Compatible API**: Fully compatible with MinIO and AWS S3 SDKs
- **High Performance**: Optimized for AI/ML workloads with kTLS offload
- **Multi-Cloud Support**: Can use AWS S3, GCS, Azure Blob, or OCI as backend
- **Unified Namespace**: Access data across multiple clusters
- **Built-in ETL**: Data transformation capabilities
- **Monitoring**: Integrated Prometheus metrics and Grafana dashboards

## Configuration

### Environment Variables

Update your `.env` file with the following AIStore-specific settings:

```env
# AIStore Configuration
MINIO_ENDPOINT=aistore
MINIO_PORT=8080
MINIO_USE_SSL=false
MINIO_REGION=us-east-1
MINIO_ACCESS_KEY=your-access-key
MINIO_SECRET_KEY=your-secret-key
MINIO_BUCKET=linksense-files
MINIO_KNOWLEDGE_BUCKET=linksense-knowledge
MINIO_PUBLIC_URL=http://localhost:8080
```

### Docker Compose

AIStore service is already configured in `docker-compose.yml`:

```yaml
aistore:
  image: nvidia/aistore:v5.2.0
  restart: unless-stopped
  command: ["proxy", "--ais-listen-port=8080", "--log-level=info"]
  environment:
    AIS_LOG_LEVEL: ${AISTORE_LOG_LEVEL:-info}
  ports:
    - "${AISTORE_BIND_ADDRESS:-127.0.0.1}:${AISTORE_PORT:-8080}:8080"
  volumes:
    - aistore-data:/var/lib/aistore
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8080/v1/health"]
    interval: 5s
    timeout: 5s
    retries: 20
    start_period: 10s
  networks:
    - default
```

## Deployment

### Quick Start

1. **Pull the AIStore image**:
   ```bash
   docker pull nvidia/aistore:v5.2.0
   ```

2. **Start the services**:
   ```bash
   docker-compose up -d aistore
   ```

3. **Initialize buckets**:
   ```bash
   docker-compose run --rm aistore-init
   ```

4. **Verify the deployment**:
   ```bash
   # Check AIStore health
   curl http://localhost:8080/v1/health
   
   # Test bucket creation
   curl -X PUT http://localhost:8080/v1/buckets/linksense-files
   curl -X PUT http://localhost:8080/v1/buckets/linksense-knowledge
   ```

### Production Deployment

For production environments, consider the following:

1. **Enable SSL/TLS**:
   ```yaml
   aistore:
     environment:
       AIS_TLS_CERT_FILE: /etc/aistore/tls/cert.pem
       AIS_TLS_KEY_FILE: /etc/aistore/tls/key.pem
     ports:
       - "8443:8443"
   ```

2. **Configure persistent storage**:
   ```yaml
   volumes:
     - aistore-data:/var/lib/aistore
     - ./aistore-config:/etc/aistore
   ```

3. **Set up monitoring**:
   ```yaml
   aistore:
     environment:
       AIS_PROMETHEUS_JOB: aistore
       AIS_PROMETHEUS_INSTANCE: aistore-main
   ```

## API Compatibility

AIStore is fully compatible with the S3 API and MinIO SDKs. All existing LinkSense code that uses `minio/node-minio` will work without modification.

### Supported Operations

- `putObject`: Upload objects
- `getObject`: Download objects
- `getObjectStream`: Get object as stream
- `removeObject`: Delete objects
- `presignedGetObject`: Generate presigned URLs
- `bucketExists`: Check bucket existence
- `makeBucket`: Create buckets

## Troubleshooting

### Service Not Starting

Check AIStore logs:
```bash
docker-compose logs aistore
```

Common issues:
1. Port 8080 already in use - change `AISTORE_PORT` in `.env`
2. Health check failing - verify network connectivity
3. Permission denied - ensure volume permissions are correct

### Bucket Creation Failed

Run the initialization script:
```bash
bash deploy/aistore-init.sh
```

### Connection Refused

1. Verify AIStore is running: `docker-compose ps aistore`
2. Check network: `docker-compose exec aistore ping api`
3. Test S3 API: `curl http://localhost:8080/v1/buckets`

## Resources

- [AIStore Documentation](https://github.com/liuj23CD/aistore)
- [S3 Compatibility Guide](https://github.com/liuj23CD/aistore/blob/main/docs/s3compat.md)
- [Deployment Options](https://github.com/liuj23CD/aistore/blob/main/deploy/README.md)

## Migration from MinIO

To migrate from MinIO to AIStore:

1. **Backup existing data**:
   ```bash
   # Using MinIO client
   mc cp myminio/linksense-files ais-backup/ --recursive
   ```

2. **Deploy AIStore**:
   ```bash
   docker-compose up -d aistore
   ```

3. **Restore data**:
   ```bash
   # Using AIStore CLI
   ais bucket create linksense-files
   ais put ais://linksense-files/ <backup-path>
   ```

4. **Update configuration**:
   ```env
   MINIO_ENDPOINT=aistore
   MINIO_PORT=8080
   ```

5. **Verify**:
   ```bash
   docker-compose exec api node scripts/verify-storage.js
   ```
