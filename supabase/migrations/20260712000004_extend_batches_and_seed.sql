-- Migration: Extend batches table and seed initial courses, subjects, and teachers
alter table public.batches 
  add column if not exists exam_type text,
  add column if not exists class_level text,
  add column if not exists medium text,
  add column if not exists lecture_days text[],
  add column if not exists start_time time,
  add column if not exists end_time time,
  add column if not exists room_number text,
  add column if not exists color text,
  add column if not exists remarks text,
  add column if not exists status text default 'active';

-- Seed initial courses
insert into public.courses (id, name, description, duration_months) values
  ('d1a3b5c7-e9f1-4a3b-8c5d-7e9f1a3b5c7d', 'JEE Masterclass', 'Comprehensive course for JEE Main & Advanced preparation.', 24),
  ('e2b4c6d8-f0a2-5b4c-9d6e-8f0a2b4c6d8e', 'NEET Conqueror', 'Complete biology, physics, and chemistry course for NEET preparation.', 24),
  ('f3c5d7e9-f1a3-6b5c-0d7f-9f1a3b5c7d9e', 'NDA Alpha', 'Dedicated training program for NDA entrance exam.', 12),
  ('a4d6e8f0-a2b4-7b6c-1d8f-0a2b4c6d8e0f', 'Boards Booster', 'Academic syllabus coverage for 11th & 12th state/CBSE boards.', 10)
on conflict (id) do update set name = excluded.name;

-- Seed initial subjects
insert into public.subjects (id, course_id, name, description) values
  -- JEE Subjects
  (gen_random_uuid(), 'd1a3b5c7-e9f1-4a3b-8c5d-7e9f1a3b5c7d', 'Physics (JEE)', 'Advanced Physics for engineering entrance'),
  (gen_random_uuid(), 'd1a3b5c7-e9f1-4a3b-8c5d-7e9f1a3b5c7d', 'Chemistry (JEE)', 'Organic, Inorganic and Physical Chemistry'),
  (gen_random_uuid(), 'd1a3b5c7-e9f1-4a3b-8c5d-7e9f1a3b5c7d', 'Mathematics (JEE)', 'Calculus, Algebra, Coordinate Geometry'),
  -- NEET Subjects
  (gen_random_uuid(), 'e2b4c6d8-f0a2-5b4c-9d6e-8f0a2b4c6d8e', 'Physics (NEET)', 'Physics syllabus targeting medical entrance'),
  (gen_random_uuid(), 'e2b4c6d8-f0a2-5b4c-9d6e-8f0a2b4c6d8e', 'Chemistry (NEET)', 'Chemistry for medical students'),
  (gen_random_uuid(), 'e2b4c6d8-f0a2-5b4c-9d6e-8f0a2b4c6d8e', 'Biology (NEET)', 'Botany and Zoology detailed topics'),
  -- NDA Subjects
  (gen_random_uuid(), 'f3c5d7e9-f1a3-6b5c-0d7f-9f1a3b5c7d9e', 'Mathematics (NDA)', 'Mathematics section for NDA'),
  (gen_random_uuid(), 'f3c5d7e9-f1a3-6b5c-0d7f-9f1a3b5c7d9e', 'General Ability (NDA)', 'English, GK and General Studies'),
  -- Boards Subjects
  (gen_random_uuid(), 'a4d6e8f0-a2b4-7b6c-1d8f-0a2b4c6d8e0f', 'Physics (Boards)', 'Board exam level Physics'),
  (gen_random_uuid(), 'a4d6e8f0-a2b4-7b6c-1d8f-0a2b4c6d8e0f', 'Chemistry (Boards)', 'Board exam level Chemistry'),
  (gen_random_uuid(), 'a4d6e8f0-a2b4-7b6c-1d8f-0a2b4c6d8e0f', 'Mathematics (Boards)', 'Board exam level Mathematics')
on conflict (course_id, name) do nothing;

-- Seed teachers in auth.users
insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at, role) values 
  ('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'sharma.physics@nationalacademy.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Mr. Sharma","role":"teacher"}', now(), now(), 'authenticated'),
  ('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'sen.biology@nationalacademy.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Dr. Sen","role":"teacher"}', now(), now(), 'authenticated'),
  ('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'verma.maths@nationalacademy.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Mr. Verma","role":"teacher"}', now(), now(), 'authenticated'),
  ('d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f0a', 'singh.nda@nationalacademy.com', extensions.crypt('password123', extensions.gen_salt('bf')), now(), '{"provider":"email","providers":["email"]}', '{"full_name":"Maj. Singh","role":"teacher"}', now(), now(), 'authenticated')
on conflict (id) do nothing;

-- Force update role to 'teacher' in public.profiles just in case
update public.profiles set role = 'teacher' where email in (
  'sharma.physics@nationalacademy.com', 
  'sen.biology@nationalacademy.com', 
  'verma.maths@nationalacademy.com',
  'singh.nda@nationalacademy.com'
);
