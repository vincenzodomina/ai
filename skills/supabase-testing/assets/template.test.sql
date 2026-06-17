-- Risk: <one line — the named regression this file is the only thing catching>
--
-- Each assertion is a top-level SELECT so pgTAP emits one TAP line per
-- assertion. PERFORM inside DO blocks is for non-assertion setup only.

BEGIN;
\ir _fixtures.sql              -- remove if not using shared pg_temp helpers

SELECT plan(1);                -- exact count; pgTAP fails if mismatched

-- ---------- Setup -----------------------------------------------------------
DO $$
DECLARE
    v_user uuid := pg_temp.seed_user();
BEGIN
    PERFORM set_config('test.user', v_user::text, true);
END $$;

-- ---------- Scenario 1: <descriptive name> ----------------------------------
SELECT is(
    (SELECT 1),
    1,
    'placeholder — replace me');

-- ---------- Finish ----------------------------------------------------------
SELECT * FROM finish();
ROLLBACK;
