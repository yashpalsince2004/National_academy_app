-- Migration: Add password_changed to students table
alter table public.students add column if not exists password_changed boolean not null default false;
