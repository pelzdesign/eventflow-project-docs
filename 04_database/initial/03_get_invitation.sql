
-- EventFlow: исходное определение функции get_invitation
-- Источник: pg_get_functiondef из Supabase.
-- Исторический снимок. Не запускать поверх действующей базы без проверки.

CREATE OR REPLACE FUNCTION public.get_invitation(p_token text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
    SELECT jsonb_build_object(
        'event', jsonb_build_object(
            'title', e.title,
            'event_date', e.event_date,
            'event_time', e.event_time,
            'timezone', e.timezone,
            'venue_name', e.venue_name,
            'venue_address', e.venue_address
        ),
        'group', jsonb_build_object(
            'name', gg.name
        ),
        'guests', COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'id', g.id,
                    'first_name', g.first_name,
                    'last_name', g.last_name,
                    'rsvp_status', g.rsvp_status
                )
                ORDER BY g.created_at
            ) FILTER (WHERE g.id IS NOT NULL),
            '[]'::jsonb
        )
    )
    FROM public.guest_groups AS gg
    JOIN public.events AS e
        ON e.id = gg.event_id
    LEFT JOIN public.guests AS g
        ON g.group_id = gg.id
    WHERE gg.access_token = p_token
      AND e.status = 'active'
    GROUP BY
        e.id,
        gg.id;
$function$;
