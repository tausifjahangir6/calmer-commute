-- ============================================================================
-- 03_roles_security.sql
-- Role-based access control -- the SQL evidence behind the DMP's
-- "restricted database credentials and role-based access" claim.
--
-- Run as your superuser (postgres). Safe to re-run.
-- CHANGE THE PASSWORDS below before running.
-- ============================================================================

SET search_path TO hush, public;

-- --- Group roles (cannot log in) -------------------------------------------
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hush_etl') THEN
        CREATE ROLE hush_etl NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hush_app') THEN
        CREATE ROLE hush_app NOLOGIN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'hush_analyst') THEN
        CREATE ROLE hush_analyst NOLOGIN;
    END IF;
END
$$;

GRANT USAGE ON SCHEMA hush TO hush_etl, hush_app, hush_analyst;

-- ETL: writes facts, cannot drop anything
GRANT SELECT, INSERT, UPDATE ON ALL TABLES IN SCHEMA hush TO hush_etl;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA hush TO hush_etl;

-- Analyst: read-only across everything
GRANT SELECT ON ALL TABLES IN SCHEMA hush TO hush_analyst;

-- App grants are issued in 08_views_and_analysis.sql, because the app reads
-- through views only and those views are created there.

-- Future objects inherit the same grants
ALTER DEFAULT PRIVILEGES IN SCHEMA hush
    GRANT SELECT, INSERT, UPDATE ON TABLES TO hush_etl;
ALTER DEFAULT PRIVILEGES IN SCHEMA hush
    GRANT SELECT ON TABLES TO hush_analyst;

-- --- Login users -----------------------------------------------------------
-- CHANGE THESE. Store real passwords in .env or AWS Secrets Manager, not git.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'etl_service') THEN
        CREATE ROLE etl_service LOGIN PASSWORD 'CHANGE_ME_etl';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_service') THEN
        CREATE ROLE app_service LOGIN PASSWORD 'CHANGE_ME_app';
    END IF;
END
$$;

GRANT hush_etl TO etl_service;
GRANT hush_app TO app_service;

-- Remove the PostgreSQL default that lets any role create objects in public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Confirm
SELECT rolname, rolcanlogin FROM pg_roles
WHERE rolname LIKE 'hush%' OR rolname LIKE '%_service'
ORDER BY rolname;
