-- Migration: Create DPP Module Tables
-- Target: Supabase database

-- 1. Chapters Table
create table if not exists public.chapters (
    id uuid default gen_random_uuid() primary key,
    subject_id uuid references public.subjects(id) on delete cascade not null,
    name text not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(subject_id, name)
);

-- Enable RLS on Chapters
alter table public.chapters enable row level security;

-- 2. DPPs Table
create table if not exists public.dpps (
    id uuid default gen_random_uuid() primary key,
    title text not null,
    exam_type text not null,
    class_level text not null,
    subject_id uuid references public.subjects(id) on delete cascade not null,
    chapter_name text,
    chapter_id uuid references public.chapters(id) on delete set null,
    topics text[],
    difficulty text not null,
    config_questions integer not null,
    config_time_minutes integer not null,
    config_marks_per_question integer not null,
    config_negative_marking numeric not null default 0.0,
    config_total_marks integer not null,
    config_question_types text[] not null,
    ai_generation_option text not null,
    additional_instructions text,
    prompt text,
    ai_response text,
    created_by uuid references public.profiles(id) on delete cascade not null,
    status text not null default 'draft', -- 'draft', 'published', 'archived'
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on DPPs
alter table public.dpps enable row level security;

-- 3. DPP Questions Table
create table if not exists public.dpp_questions (
    id uuid default gen_random_uuid() primary key,
    dpp_id uuid references public.dpps(id) on delete cascade not null,
    question_text text not null,
    question_type text not null,
    options jsonb, -- e.g. ["Option A", "Option B", "Option C", "Option D"]
    correct_answer text not null,
    explanation text,
    difficulty text,
    estimated_time_seconds integer,
    marks integer not null,
    learning_outcome text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on DPP Questions
alter table public.dpp_questions enable row level security;

-- 4. DPP Assignments Table
create table if not exists public.dpp_assignments (
    id uuid default gen_random_uuid() primary key,
    dpp_id uuid references public.dpps(id) on delete cascade not null,
    assigned_by uuid references public.profiles(id) on delete cascade not null,
    assignee_type text not null, -- 'batch', 'individual'
    batch_id uuid references public.batches(id) on delete cascade,
    student_id uuid references public.students(id) on delete cascade,
    scheduled_at timestamp with time zone not null,
    due_at timestamp with time zone,
    notify boolean not null default true,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on DPP Assignments
alter table public.dpp_assignments enable row level security;

-- 5. DPP Attempts Table
create table if not exists public.dpp_attempts (
    id uuid default gen_random_uuid() primary key,
    assignment_id uuid references public.dpp_assignments(id) on delete cascade not null,
    student_id uuid references public.students(id) on delete cascade not null,
    started_at timestamp with time zone default timezone('utc'::text, now()) not null,
    submitted_at timestamp with time zone,
    answers_json jsonb, -- e.g. [{"question_id": "...", "answer": "..."}]
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on DPP Attempts
alter table public.dpp_attempts enable row level security;

-- 6. DPP Results Table
create table if not exists public.dpp_results (
    id uuid default gen_random_uuid() primary key,
    attempt_id uuid references public.dpp_attempts(id) on delete cascade not null,
    student_id uuid references public.students(id) on delete cascade not null,
    score numeric not null,
    total_questions integer not null,
    correct_answers integer not null,
    wrong_answers integer not null,
    skipped_questions integer not null,
    time_taken_seconds integer not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on DPP Results
alter table public.dpp_results enable row level security;

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- Chapters: Everyone can view chapters
create policy "Chapters can be viewed by authenticated users" 
    on public.chapters for select to authenticated using (true);
create policy "Chapters can be created/updated/deleted by admin/teacher"
    on public.chapters for all to authenticated 
    using (exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin', 'teacher')));

-- DPPs: View, Insert, Update, Delete policies
create policy "DPPs can be viewed by creators, admins and assigned students"
    on public.dpps for select to authenticated
    using (
        created_by = auth.uid()
        or exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin'))
        or exists (
            select 1 from public.dpp_assignments a
            left join public.students s on s.id = a.student_id or s.id in (select student_id from public.batch_enrollments where batch_id = a.batch_id)
            where a.dpp_id = public.dpps.id and s.profile_id = auth.uid()
        )
    );

create policy "DPPs can be created/updated/deleted by teachers and admins"
    on public.dpps for all to authenticated
    using (
        exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin', 'teacher'))
    );

-- DPP Questions
create policy "DPP Questions can be viewed by users who can select the parent DPP"
    on public.dpp_questions for select to authenticated
    using (
        exists (select 1 from public.dpps where id = public.dpp_questions.dpp_id)
    );

create policy "DPP Questions can be managed by teachers and admins"
    on public.dpp_questions for all to authenticated
    using (
        exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin', 'teacher'))
    );

-- DPP Assignments
create policy "DPP Assignments can be viewed by creators, admins, and target students"
    on public.dpp_assignments for select to authenticated
    using (
        assigned_by = auth.uid()
        or exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin'))
        or exists (
            select 1 from public.students s
            where s.profile_id = auth.uid() and (
                s.id = public.dpp_assignments.student_id 
                or s.id in (select student_id from public.batch_enrollments where batch_id = public.dpp_assignments.batch_id)
            )
        )
    );

create policy "DPP Assignments can be managed by teachers and admins"
    on public.dpp_assignments for all to authenticated
    using (
        exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin', 'teacher'))
    );

-- DPP Attempts
create policy "DPP Attempts can be viewed by owners, creators of DPP, and admins"
    on public.dpp_attempts for select to authenticated
    using (
        exists (select 1 from public.students s where s.id = public.dpp_attempts.student_id and s.profile_id = auth.uid())
        or exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin'))
        or exists (
            select 1 from public.dpp_assignments a
            join public.dpps d on d.id = a.dpp_id
            where a.id = public.dpp_attempts.assignment_id and d.created_by = auth.uid()
        )
    );

create policy "DPP Attempts can be made by students"
    on public.dpp_attempts for insert to authenticated
    with check (
        exists (select 1 from public.students s where s.id = student_id and s.profile_id = auth.uid())
    );

create policy "DPP Attempts can be updated by student owner"
    on public.dpp_attempts for update to authenticated
    using (
        exists (select 1 from public.students s where s.id = student_id and s.profile_id = auth.uid())
    );

-- DPP Results
create policy "DPP Results can be viewed by student, dpp creator, and admins"
    on public.dpp_results for select to authenticated
    using (
        exists (select 1 from public.students s where s.id = public.dpp_results.student_id and s.profile_id = auth.uid())
        or exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin'))
        or exists (
            select 1 from public.dpp_attempts att
            join public.dpp_assignments a on a.id = att.assignment_id
            join public.dpps d on d.id = a.dpp_id
            where att.id = public.dpp_results.attempt_id and d.created_by = auth.uid()
        )
    );

create policy "DPP Results can be created by students"
    on public.dpp_results for insert to authenticated
    with check (
        exists (select 1 from public.students s where s.id = student_id and s.profile_id = auth.uid())
    );
