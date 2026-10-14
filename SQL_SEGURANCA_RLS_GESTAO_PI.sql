-- ============================================================
-- SEGURANÇA SUPABASE - GESTÃO DE PI IFSC
-- Projeto atual: ptxtclyfwlcwqgwzqieu
--
-- OBJETIVO:
-- 1) Habilitar RLS em todas as tabelas do schema public.
-- 2) Impedir acesso direto de anon/authenticated às tabelas.
-- 3) Manter acesso do backend Streamlit através da SECRET KEY.
-- 4) Não apagar nem alterar dados.
--
-- IMPORTANTE:
-- ANTES de executar este SQL, configure no Streamlit Cloud:
-- SUPABASE_SECRET_KEY = sb_secret_...
--
-- A SECRET KEY NÃO deve ser colocada no GitHub, no código ou no
-- navegador. O database.py deste projeto já dá prioridade a ela.
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. RLS em todas as tabelas existentes do schema public
-- ------------------------------------------------------------
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT tablename
        FROM pg_tables
        WHERE schemaname = 'public'
    LOOP
        EXECUTE format(
            'ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY',
            r.tablename
        );
    END LOOP;
END $$;

-- ------------------------------------------------------------
-- 2. Retira acesso direto das roles públicas.
-- O Streamlit usará a SECRET KEY, que opera com service_role
-- e pode acessar as tabelas mesmo com RLS habilitado.
-- ------------------------------------------------------------
REVOKE ALL PRIVILEGES ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
REVOKE ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public FROM anon, authenticated;

-- ------------------------------------------------------------
-- 3. Garante acesso do backend service_role.
-- A secret key do Supabase usa service_role internamente.
-- ------------------------------------------------------------
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO service_role;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;

-- ------------------------------------------------------------
-- 4. Novas tabelas/sequências/funções no schema public
-- continuam protegidas por padrão.
-- ------------------------------------------------------------
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL ON TABLES FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL ON SEQUENCES FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE ALL ON FUNCTIONS FROM anon, authenticated;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT EXECUTE ON FUNCTIONS TO service_role;

COMMIT;

-- ------------------------------------------------------------
-- CONFERÊNCIA
-- Deve retornar todas as tabelas public com relrowsecurity = true.
-- ------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    rowsecurity AS rls_habilitado
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;

-- Deve mostrar que anon/authenticated não possuem privilégios
-- diretos nas tabelas administrativas.
SELECT
    table_schema,
    table_name,
    grantee,
    privilege_type
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('anon', 'authenticated')
ORDER BY table_name, grantee, privilege_type;
