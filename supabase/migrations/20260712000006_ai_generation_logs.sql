-- Migration: Create AI Generation Logs Table for Telemetry and Cost Tracking
-- Target: Supabase database

create table if not exists public.ai_generation_logs (
    id uuid default gen_random_uuid() primary key,
    teacher_id uuid references public.profiles(id) on delete cascade not null,
    exam text not null,
    subject text not null,
    chapter text not null,
    model text not null,
    prompt_tokens integer not null default 0,
    completion_tokens integer not null default 0,
    total_tokens integer not null default 0,
    estimated_cost numeric(10, 6) not null default 0.0,
    generation_time_ms integer not null,
    status text not null, -- 'success', 'failed'
    error text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS
alter table public.ai_generation_logs enable row level security;

-- Row Level Security Policies
create policy "Creators can view their own AI logs"
    on public.ai_generation_logs for select to authenticated
    using (
        teacher_id = auth.uid()
        or exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin'))
    );

create policy "Teachers and admins can insert AI logs"
    on public.ai_generation_logs for insert to authenticated
    with check (
        exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin', 'teacher'))
    );
