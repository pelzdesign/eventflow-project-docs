
-- EventFlow: проверка прямых прав доступа к таблицам
-- Диагностический запрос. Ничего не изменяет.
-- Проверка после отзыва избыточных привилегий.

SELECT
    roles.role_name,
    tables.table_name,
    has_table_privilege(
        roles.role_name,
        'public.' || tables.table_name,
        'SELECT'
    ) AS can_select,
    has_table_privilege(
        roles.role_name,
        'public.' || tables.table_name,
        'INSERT'
    ) AS can_insert,
    has_table_privilege(
        roles.role_name,
        'public.' || tables.table_name,
        'UPDATE'
    ) AS can_update,
    has_table_privilege(
        roles.role_name,
        'public.' || tables.table_name,
        'DELETE'
    ) AS can_delete,
    has_table_privilege(
        roles.role_name,
        'public.' || tables.table_name,
        'TRUNCATE'
    ) AS can_truncate,
    has_table_privilege(
        roles.role_name,
        'public.' || tables.table_name,
        'REFERENCES'
    ) AS can_references,
    has_table_privilege(
        roles.role_name,
        'public.' || tables.table_name,
        'TRIGGER'
    ) AS can_trigger
FROM (
    VALUES ('anon'), ('authenticated')
) AS roles(role_name)
CROSS JOIN (
    VALUES
        ('events'),
        ('guest_groups'),
        ('guests'),
        ('rsvp')
) AS tables(table_name)
ORDER BY
    roles.role_name,
    tables.table_name;
