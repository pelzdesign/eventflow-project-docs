
-- EventFlow: проверка индексов базы данных
-- Диагностический запрос. Ничего не изменяет.
-- Позволяет увидеть фактические индексы и их определения.

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename IN (
      'events',
      'guest_groups',
      'guests',
      'rsvp'
  )
ORDER BY
    tablename,
    indexname;

-- Результат предыдущего аудита:
-- Дублирующий idx_rsvp_guest удалён.
-- Уникальный rsvp_guest_id_key сохранён.
--
-- При повторной проверке ориентироваться на фактический
-- результат запроса, а не только на комментарии выше.
