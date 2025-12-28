-- GuideScope V1: Initial Schema (Idempotent for Persistence)
-- Targets: Supabase / Local PostgreSQL
-- Actions: Ensure Tables, Columns, Indexes, and Seed Data exist.

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- 1. Documents Table & Search Components
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type VARCHAR(50) NOT NULL,
    year INTEGER NOT NULL,
    title TEXT NOT NULL,
    link TEXT NOT NULL,
    region VARCHAR(100) NOT NULL,
    field VARCHAR(100) NOT NULL,
    authors TEXT,
    source TEXT,
    citation TEXT,
    keywords TEXT[],
    slug TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_document_type_year_slug UNIQUE (type, year, slug)
);

-- Idempotent Column Additions (Repair Schema Drift)
ALTER TABLE documents ADD COLUMN IF NOT EXISTS search_vector TSVECTOR;
ALTER TABLE documents ADD COLUMN IF NOT EXISTS keywords TEXT[];
ALTER TABLE documents ADD COLUMN IF NOT EXISTS authors TEXT;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_documents_type ON documents(type);
CREATE INDEX IF NOT EXISTS idx_documents_region ON documents(region);
CREATE INDEX IF NOT EXISTS idx_documents_field ON documents(field);
CREATE INDEX IF NOT EXISTS idx_documents_keywords ON documents USING GIN (keywords);
CREATE INDEX IF NOT EXISTS idx_documents_title_trgm ON documents USING GIN (title gin_trgm_ops);
CREATE INDEX IF NOT EXISTS idx_documents_search_vector ON documents USING GIN (search_vector);

-- Search Trigger (Logic Migration)
CREATE OR REPLACE FUNCTION documents_search_vector_trigger() RETURNS trigger AS $$
BEGIN
  new.search_vector :=
    setweight(to_tsvector('english', coalesce(new.title,'')), 'A') ||
    setweight(to_tsvector('english', coalesce(new.authors,'')), 'B');
  return new;
END
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tsvectorupdate ON documents;
CREATE TRIGGER tsvectorupdate BEFORE INSERT OR UPDATE
ON documents FOR EACH ROW EXECUTE FUNCTION documents_search_vector_trigger();

-- 2. System Stats
CREATE TABLE IF NOT EXISTS system_stats (
    id SERIAL PRIMARY KEY,
    visit_count BIGINT NOT NULL DEFAULT 0,
    search_count BIGINT NOT NULL DEFAULT 0
);
INSERT INTO system_stats (id, visit_count, search_count)
VALUES (1, 0, 0) ON CONFLICT (id) DO NOTHING;

-- 3. Feature Flags
CREATE TABLE IF NOT EXISTS feature_flags (
    feature_key VARCHAR(255) NOT NULL PRIMARY KEY,
    enabled BOOLEAN NOT NULL,
    description VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP
);

-- 4. Ad Campaigns
CREATE TABLE IF NOT EXISTS ad_campaigns (
    id UUID NOT NULL PRIMARY KEY,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    content VARCHAR(255),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    cta VARCHAR(255),
    dimension VARCHAR(255),
    end_date TIMESTAMP,
    image VARCHAR(255),
    link VARCHAR(255),
    name VARCHAR(100) NOT NULL,
    priority VARCHAR(20) NOT NULL,
    slot VARCHAR(20) NOT NULL,
    start_date TIMESTAMP,
    subtext VARCHAR(255),
    theme VARCHAR(255),
    type VARCHAR(20) NOT NULL,
    updated_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_ad_campaign_priority_active ON ad_campaigns (priority, active);
CREATE INDEX IF NOT EXISTS idx_ad_campaign_slot ON ad_campaigns (slot);

-- 5. Data Seeding (Safe Insert)
INSERT INTO feature_flags (feature_key, enabled, description)
VALUES ('ads', true, 'Monetization System')
ON CONFLICT (feature_key) DO UPDATE SET enabled = EXCLUDED.enabled;

INSERT INTO ad_campaigns (id, name, priority, slot, active, content, subtext, cta, link, theme, type)
VALUES 
(
    uuid_generate_v4(), 'Pro Launch', 'DIRECT_DEAL', 'header', true, 
    'GuideScope Pro: Clinical AI Assistant', 
    'Unlock advanced reasoning.', 'Upgrade Now', '#premium', 'teal', 'banner'
),
(
    uuid_generate_v4(), 'MedConf 2025', 'BACKFILL', 'sidebar', true, 
    'Global Medical Summit 2025', 
    'Join 50,000+ clinicians.', 'Register', '#conference', 'blue', 'card'
)
ON CONFLICT DO NOTHING;
