
-- EventFlow: инвентаризация функций базы данных
-- Диагностический запрос. Ничего не изменяет.
-- Показывает функции схемы public и параметры их безопасности.

SELECT
    n.nspname AS schema_name,
    p.proname AS function_name,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    pg_get_function_result(p.oid) AS return_type,
    l.lanname AS language,
    pg_get_userbyid(p.proowner) AS function_owner,
    p.prosecdef AS security_definer,
    p.provolatile AS volatility,
    p.proconfig AS function_settings,
    p.proacl AS access_privileges
FROM pg_proc AS p
JOIN pg_namespace AS n
    ON n.oid = p.pronamespace
JOIN pg_language AS l
    ON l.oid = p.prolang
WHERE n.nspname = 'public'
ORDER BY
    p.proname,
    arguments;
