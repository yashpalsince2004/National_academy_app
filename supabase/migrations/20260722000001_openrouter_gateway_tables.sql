-- Migration: OpenRouter AI Gateway Database Schema
-- Date: 20260722000001
-- Target: Supabase PostgreSQL

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. AI Usage & Telemetry Table (for rate limiting, cost tracking, monitoring)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.ai_usage (
    id                  uuid default gen_random_uuid() primary key,
    user_id             uuid references public.profiles(id) on delete cascade not null,
    feature             text not null,            -- 'generate-dpp', 'generate-bpp', 'ai-chat', etc.
    model               text not null,            -- e.g. 'google/gemini-2.0-flash-exp:free'
    provider            text not null default 'openrouter',
    prompt_tokens       integer default 0 not null,
    completion_tokens   integer default 0 not null,
    total_tokens        integer generated always as (prompt_tokens + completion_tokens) stored,
    estimated_cost      numeric(10, 8) default 0.0 not null,
    latency_ms          integer default 0 not null,
    status              text not null check (status in ('success', 'failed')),
    error               text,                     -- error message if status = 'failed'
    created_at          timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS for ai_usage
alter table public.ai_usage enable row level security;

create policy "Users can view their own AI usage"
    on public.ai_usage for select to authenticated
    using (
        user_id = auth.uid()
        or exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin'))
    );

create policy "Service role can insert AI usage"
    on public.ai_usage for insert
    with check (true);

-- Index for fast rate limiting queries: COUNT(*) WHERE user_id = $1 AND feature = $2 AND created_at >= $3
create index if not exists idx_ai_usage_rate_limit
    on public.ai_usage (user_id, feature, status, created_at desc);

-- Index for admin cost reporting
create index if not exists idx_ai_usage_created_at
    on public.ai_usage (created_at desc);

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. AI Cache Table (Content-Addressed Response Caching)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.ai_cache (
    id                  uuid default gen_random_uuid() primary key,
    cache_key           text unique not null,     -- SHA-256 hex hash of canonical request
    feature             text not null,
    response            jsonb not null,           -- cached AI JSON payload
    hit_count           integer default 0 not null,
    created_at          timestamp with time zone default timezone('utc'::text, now()) not null,
    expires_at          timestamp with time zone not null
);

alter table public.ai_cache enable row level security;

-- Only service role accesses cache
create policy "Service role full access to cache"
    on public.ai_cache for all
    using (true)
    with check (true);

create index if not exists idx_ai_cache_lookup
    on public.ai_cache (cache_key);

create index if not exists idx_ai_cache_ttl
    on public.ai_cache (expires_at);

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Prompt Templates Table (for dynamic backend prompt management)
-- ─────────────────────────────────────────────────────────────────────────────
create table if not exists public.prompt_templates (
    id                  uuid default gen_random_uuid() primary key,
    feature             text unique not null,     -- 'generate-dpp', 'ai-chat', etc.
    system_prompt       text not null,
    user_template       text not null,
    version             integer default 1 not null,
    is_active           boolean default true not null,
    updated_at          timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.prompt_templates enable row level security;

create policy "Admins can manage prompt templates"
    on public.prompt_templates for all to authenticated
    using (
        exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin'))
    );
