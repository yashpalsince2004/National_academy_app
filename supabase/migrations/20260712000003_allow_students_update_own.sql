-- Migration: Allow students to update their own student record
create policy "Students can update their own student record"
    on public.students for update
    using ( profile_id = auth.uid() )
    with check ( profile_id = auth.uid() );
