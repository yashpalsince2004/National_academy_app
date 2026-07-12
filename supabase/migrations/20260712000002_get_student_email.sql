-- Migration: Add get_student_email_by_roll function
create or replace function public.get_student_email_by_roll(entered_roll_no text)
returns table (email text, profile_id uuid, status text)
language plpgsql
security definer
set search_path = public
as $$
begin
    return query
    select p.email::text, s.profile_id, s.status::text
    from public.students s
    join public.profiles p on s.profile_id = p.id
    where upper(s.roll_no) = upper(entered_roll_no);
end;
$$;

-- Grant execution permission to anonymous and authenticated users
grant execute on function public.get_student_email_by_roll(text) to anon, authenticated;
