# PostgreSQL 16 + PostGIS + pgvector

FROM postgres:16.6-bookworm

# PostGIS ve pgvector kur
RUN apt-get update \
   && apt-get install -y --no-install-recommends \
   postgresql-16-postgis-3 \
   postgresql-16-pgvector \
   && rm -rf /var/lib/apt/lists/*
