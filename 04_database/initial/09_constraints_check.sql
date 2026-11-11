
-- EventFlow: проверка ограничений базы данных
-- Диагностический запрос. Ничего не изменяет.
-- Выводит ограничения основных таблиц и их определения.

SELECT
    n.nspname AS schema_name,
    t.relname AS table_name,
    c.conname AS constraint_name,
    CASE c.contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'c' THEN 'CHECK'
        WHEN 'x' THEN 'EXCLUSION'
        ELSE c.contype::text
    END AS constraint_type,
    c.convalidated AS is_validated,
    pg_get_constraintdef(c.oid) AS definition
FROM pg_constraint AS c
JOIN pg_class AS t
    ON t.oid = c.conrelid
JOIN pg_namespace AS n
    ON n.oid = t.relnamespace
WHERE n.nspname = 'public'
  AND t.relname IN (
      'events',
      'guest_groups',
      'guests',
      'rsvp'
  )
ORDER BY
    t.relname,
    c.contype,
    c.conname;
