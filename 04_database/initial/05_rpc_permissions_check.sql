
-- EventFlow: проверка прав доступа к RPC-функциям
-- Источник: проверка в Supabase, 10.11.2026.
-- Запрос диагностический: повторный запуск безопасен.

SELECT
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_userbyid(p.proowner) AS function_owner,
    p.prosecdef AS security_definer,
    p.proconfig AS function_settings,
    has_function_privilege(
        'anon',
        p.oid,
        'EXECUTE'
    ) AS anon_can_execute,
    has_function_privilege(
        'authenticated',
        p.oid,
        'EXECUTE'
    ) AS authenticated_can_execute
FROM pg_proc p
JOIN pg_namespace n
    ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
      'get_invitation',
      'submit_rsvp'
  )
ORDER BY p.proname;

-- Результат проверки от 10.11.2026:
--
-- get_invitation:
-- owner = postgres
-- security_definer = true
-- search_path = ""
-- anon_can_execute = true
-- authenticated_can_execute = true
--
-- submit_rsvp:
-- owner = postgres
-- security_definer = true
-- search_path = ""
-- anon_can_execute = true
-- authenticated_can_execute = true
