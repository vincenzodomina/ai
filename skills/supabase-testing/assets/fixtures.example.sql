-- Shared pg_temp helpers for pgTAP database tests.
-- Loaded inside each test's BEGIN/ROLLBACK via:  \ir _fixtures.sql
-- Helpers vanish on ROLLBACK because pg_temp is connection-scoped.

-- ---------------------------------------------------------------------------
-- Auth user. Includes every column Supabase's auth.users requires NOT NULL.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pg_temp.seed_user(p_label text DEFAULT 'u')
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE
    v_id    uuid := gen_random_uuid();
    v_email text := p_label || '_' || replace(v_id::text, '-', '') || '@test.local';
BEGIN
    INSERT INTO auth.users (
        id, instance_id, aud, role, email,
        encrypted_password, email_confirmed_at,
        created_at, updated_at,
        raw_app_meta_data, raw_user_meta_data,
        is_super_admin, is_sso_user, is_anonymous,
        confirmation_token, recovery_token,
        email_change_token_new, email_change,
        phone_change, phone_change_token,
        email_change_token_current, email_change_confirm_status,
        reauthentication_token
    ) VALUES (
        v_id, '00000000-0000-0000-0000-000000000000',
        'authenticated', 'authenticated', v_email,
        '', now(), now(), now(),
        '{}'::jsonb, '{}'::jsonb,
        false, false, false,
        '', '', '', '', '', '', '', 0, ''
    );
    -- Mirror to your domain user table if you have one:
    -- INSERT INTO public.user_profile (id, email) VALUES (v_id, v_email);
    RETURN v_id;
END $$;

-- ---------------------------------------------------------------------------
-- Predicate-only row builder. Bypasses CHECK constraints — use ONLY for
-- pure-predicate tests where you want to feed jsonb into the row type.
-- ---------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION pg_temp.mk_<table>(p_attrs jsonb)
-- RETURNS public.<table> LANGUAGE sql AS $$
--     SELECT jsonb_populate_record(NULL::public.<table>, p_attrs)
-- $$;

-- ---------------------------------------------------------------------------
-- Generic seeder template. Copy + rename per table.
-- ---------------------------------------------------------------------------
-- CREATE OR REPLACE FUNCTION pg_temp.seed_<thing>(
--     p_user_id uuid,
--     p_label   text DEFAULT 'thing'
-- ) RETURNS uuid LANGUAGE plpgsql AS $$
-- DECLARE v_id uuid := gen_random_uuid();
-- BEGIN
--     INSERT INTO public.<thing> (id, user_id, slug, name, …)
--     VALUES (v_id, p_user_id, p_label, 'Test Thing', …);
--     RETURN v_id;
-- END $$;
