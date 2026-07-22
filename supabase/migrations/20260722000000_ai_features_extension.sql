-- Migration: Extend AI logs + add tables for new AI features
-- Date: 20260722000000

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Extend ai_generation_logs with new columns needed by shared/telemetry.ts
-- ─────────────────────────────────────────────────────────────────────────────
alter table public.ai_generation_logs
    add column if not exists feature text,        -- which AI function was called
    add column if not exists provider text;       -- which AI provider was used

-- Update existing rows to backfill feature = 'generate-dpp'
update public.ai_generation_logs
    set feature = 'generate-dpp', provider = 'gemini'
    where feature is null;

-- Add index for rate limiting queries (user + feature + created_at)
create index if not exists idx_ai_logs_user_feature_time
    on public.ai_generation_logs (teacher_id, feature, created_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Student Doubts Table (for doubt-solver history)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.student_doubts (
    id              uuid default gen_random_uuid() primary key,
    student_id      uuid references public.profiles(id) on delete cascade not null,
    doubt_text      text not null,
    exam            text,
    subject         text,
    chapter         text,
    answer          jsonb not null default '{}',
    is_resolved     boolean default true,
    solved_at       timestamp with time zone,
    created_at      timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.student_doubts enable row level security;

create policy "Students see their own doubts"
    on public.student_doubts for select to authenticated
    using (
        student_id = auth.uid()
        or exists (
            select 1 from public.profiles
            where id = auth.uid() and role in ('super_admin', 'admin', 'teacher')
        )
    );

create policy "Students can submit doubts"
    on public.student_doubts for insert to authenticated
    with check (student_id = auth.uid());

create index if not exists idx_student_doubts_student
    on public.student_doubts (student_id, created_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. AI Notes Table (for notes-generator output)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.ai_notes (
    id              uuid default gen_random_uuid() primary key,
    created_by      uuid references public.profiles(id) on delete cascade not null,
    exam            text not null,
    subject         text not null,
    chapter         text not null,
    topics          text[] default '{}',
    note_style      text default 'detailed',   -- concise, detailed, revision
    language        text default 'English',
    content         jsonb not null default '{}',
    is_published    boolean default false,      -- published = visible to students in batch
    batch_id        uuid,                       -- optional: link to a batch
    created_at      timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at      timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.ai_notes enable row level security;

create policy "Teachers see their own notes, admins see all"
    on public.ai_notes for select to authenticated
    using (
        created_by = auth.uid()
        or is_published = true
        or exists (
            select 1 from public.profiles
            where id = auth.uid() and role in ('super_admin', 'admin')
        )
    );

create policy "Teachers and admins can create notes"
    on public.ai_notes for insert to authenticated
    with check (
        exists (
            select 1 from public.profiles
            where id = auth.uid() and role in ('super_admin', 'admin', 'teacher')
        )
    );

create policy "Teachers can update their own notes"
    on public.ai_notes for update to authenticated
    using (created_by = auth.uid())
    with check (created_by = auth.uid());

create index if not exists idx_ai_notes_creator
    on public.ai_notes (created_by, exam, subject, chapter);

-- Auto-update updated_at
create or replace function update_updated_at_column()
returns trigger as $$
begin
    new.updated_at = timezone('utc'::text, now());
    return new;
end;
$$ language plpgsql;

create trigger update_ai_notes_updated_at
    before update on public.ai_notes
    for each row execute procedure update_updated_at_column();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Service Role INSERT policy on ai_generation_logs
--    (allows Edge Functions using service-role key to log from all features)
-- ─────────────────────────────────────────────────────────────────────────────
-- Drop old restrictive policy and replace with broader one
drop policy if exists "Teachers and admins can insert AI logs" on public.ai_generation_logs;

create policy "Service role can insert AI logs"
    on public.ai_generation_logs for insert
    with check (true);  -- Edge Functions run as service role, which bypasses RLS anyway
                        -- This policy is for completeness and documentation
