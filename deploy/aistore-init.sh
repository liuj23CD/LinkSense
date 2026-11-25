#!/bin/bash
set -e

echo "Waiting for AIStore to be ready..."
while ! curl -s http://aistore:8080/v1/health > /dev/null 2>&1; do
    sleep 2
done

echo "Creating AIStore buckets..."

# Create main bucket
curl -s -X PUT http://aistore:8080/v1/buckets/${MINIO_BUCKET:-linksense-files} > /dev/null

# Create knowledge bucket
curl -s -X PUT http://aistore:8080/v1/buckets/${MINIO_KNOWLEDGE_BUCKET:-linksense-knowledge} > /dev/null

echo "AIStore initialization complete"