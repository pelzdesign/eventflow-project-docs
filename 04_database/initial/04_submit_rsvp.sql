
-- EventFlow: исходное определение функции submit_rsvp
-- Источник: pg_get_functiondef из Supabase.
-- Исторический снимок. Не запускать поверх действующей базы без проверки.

CREATE OR REPLACE FUNCTION public.submit_rsvp(
    p_token text,
    p_responses jsonb,
    p_comment text DEFAULT NULL::text
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO ''
AS $function$
DECLARE
    v_group_id uuid;
    v_event_id uuid;
    v_deadline date;
    v_timezone text;
    v_event_status text;

    v_total_guests integer;
    v_response_count integer;
    v_distinct_count integer;
    v_valid_count integer;
    v_invalid_count integer;
BEGIN
    -- 1. Проверяем формат ответов
    IF p_responses IS NULL
       OR jsonb_typeof(p_responses) <> 'array' THEN
        RAISE EXCEPTION 'Invalid responses format';
    END IF;

    -- 2. Находим группу и блокируем её
    -- на время обработки запроса
    SELECT
        gg.id,
        e.id,
        e.rsvp_deadline,
        e.timezone,
        e.status
    INTO
        v_group_id,
        v_event_id,
        v_deadline,
        v_timezone,
        v_event_status
    FROM public.guest_groups AS gg
    JOIN public.events AS e
        ON e.id = gg.event_id
    WHERE gg.access_token = p_token
    FOR UPDATE OF gg, e;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Invitation not found';
    END IF;

    -- 3. Проверяем статус мероприятия
    IF v_event_status <> 'active' THEN
        RAISE EXCEPTION 'Event is not active';
    END IF;

    -- 4. Проверяем срок RSVP
    IF v_deadline IS NULL THEN
        RAISE EXCEPTION 'RSVP deadline is not configured';
    END IF;

    IF (
        (CURRENT_TIMESTAMP AT TIME ZONE
            COALESCE(v_timezone, 'Europe/Moscow'))::date
    ) > v_deadline THEN
        RAISE EXCEPTION 'RSVP deadline has passed';
    END IF;

    -- 5. Считаем гостей в группе
    SELECT count(*)
    INTO v_total_guests
    FROM public.guests
    WHERE group_id = v_group_id;

    -- 6. Проверяем переданные ответы
    SELECT
        count(*),
        count(DISTINCT x.guest_id),
        count(*) FILTER (
            WHERE x.guest_id IS NULL
               OR x.attendance NOT IN ('yes', 'no')
        )
    INTO
        v_response_count,
        v_distinct_count,
        v_invalid_count
    FROM jsonb_to_recordset(p_responses)
        AS x(guest_id uuid, attendance text);

    -- 7. Проверяем принадлежность всех гостей группе
    SELECT count(*)
    INTO v_valid_count
    FROM jsonb_to_recordset(p_responses)
        AS x(guest_id uuid, attendance text)
    JOIN public.guests AS g
        ON g.id = x.guest_id
    WHERE g.group_id = v_group_id;

    IF v_response_count <> v_total_guests
       OR v_distinct_count <> v_response_count
       OR v_valid_count <> v_total_guests
       OR v_invalid_count > 0 THEN
        RAISE EXCEPTION 'Invalid guest responses';
    END IF;

    -- 8. Сохраняем ответы.
    -- При повторной отправке обновляем существующие.
    INSERT INTO public.rsvp (
        guest_id,
        attendance,
        comment,
        responded_at
    )
    SELECT
        x.guest_id,
        x.attendance,
        NULLIF(TRIM(p_comment), ''),
        CURRENT_TIMESTAMP
    FROM jsonb_to_recordset(p_responses)
        AS x(guest_id uuid, attendance text)
    ON CONFLICT (guest_id)
    DO UPDATE SET
        attendance = EXCLUDED.attendance,
        comment = EXCLUDED.comment,
        responded_at = CURRENT_TIMESTAMP;

    -- 9. Обновляем статусы гостей
    UPDATE public.guests AS g
    SET rsvp_status = CASE
        WHEN x.attendance = 'yes' THEN 'confirmed'
        WHEN x.attendance = 'no' THEN 'declined'
    END
    FROM jsonb_to_recordset(p_responses)
        AS x(guest_id uuid, attendance text)
    WHERE g.id = x.guest_id
      AND g.group_id = v_group_id;

    -- 10. Возвращаем результат
    RETURN jsonb_build_object(
        'success', true,
        'message', 'RSVP successfully saved',
        'guests_updated', v_total_guests,
        'rsvp_deadline', v_deadline
    );
END;
$function$;
