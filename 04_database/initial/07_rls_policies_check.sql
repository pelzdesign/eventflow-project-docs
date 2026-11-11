
-- EventFlow: проверка RLS и политик доступа
-- Диагностический запрос. Ничего не изменяет.
-- Зафиксированный результат предыдущего аудита:
-- RLS включён, FORCE RLS выключен, политик не обнаружено.

-- 1. Состояние RLS для основных таблиц

SELECT
    schemaname,
    tablename,
    rowsecurity AS rls_enabled,
    forcerowsecurity AS force_rls_enabled
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
      'events',
      'guest_groups',
      'guests',
      'rsvp'
  )
ORDER BY tablename;

-- 2. Существующие RLS-политики

SELECT
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
      'events',
      'guest_groups',
      'guests',
      'rsvp'
  )
ORDER BY tablename, policyname;
