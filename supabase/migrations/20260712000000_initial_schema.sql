-- ============================================================
-- National Academy ERP — Initial Database Schema
-- ============================================================

-- Create schema extensions
create extension if not exists pgcrypto;
create extension if not exists "uuid-ossp";
create extension if not exists citext;

-- Define Custom Enum Types
create type user_role as enum ('super_admin', 'admin', 'teacher', 'student', 'parent');
create type enrollment_status as enum ('active', 'on_hold', 'dropped', 'completed');
create type attendance_status as enum ('present', 'absent', 'late');
create type fee_payment_mode as enum ('cash', 'upi', 'card', 'bank_transfer', 'cheque');
create type notification_type as enum ('fee_reminder', 'attendance_alert', 'new_result', 'new_notice', 'general');

-- 1. Profiles Table (Linked 1:1 to auth.users)
create table public.profiles (
    id uuid references auth.users on delete cascade primary key,
    email citext unique not null,
    full_name text not null,
    phone text,
    role user_role not null default 'student',
    avatar_url text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Profiles
alter table public.profiles enable row level security;

-- 2. Students Table (Scoped profiles data)
create table public.students (
    id uuid default gen_random_uuid() primary key,
    profile_id uuid references public.profiles(id) on delete cascade unique not null,
    roll_no text unique, -- Nullable so that trigger can populate it
    dob date,
    address text,
    school_name text,
    guardian_name text,
    guardian_phone text,
    guardian_relation text,
    photo_url text,
    id_proof_url text,
    marksheet_url text,
    previous_school text,
    previous_class text,
    previous_percentage text,
    status enrollment_status not null default 'active',
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Students
alter table public.students enable row level security;

-- 3. Courses Table
create table public.courses (
    id uuid default gen_random_uuid() primary key,
    name text unique not null,
    description text,
    duration_months integer,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Courses
alter table public.courses enable row level security;

-- 4. Subjects Table
create table public.subjects (
    id uuid default gen_random_uuid() primary key,
    course_id uuid references public.courses(id) on delete cascade not null,
    name text not null,
    description text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(course_id, name)
);

-- Enable RLS on Subjects
alter table public.subjects enable row level security;

-- 5. Batches Table
create table public.batches (
    id uuid default gen_random_uuid() primary key,
    course_id uuid references public.courses(id) on delete cascade not null,
    name text not null,
    capacity integer not null default 30,
    start_date date,
    end_date date,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Batches
alter table public.batches enable row level security;

-- 6. Batch Enrollments Table
create table public.batch_enrollments (
    id uuid default gen_random_uuid() primary key,
    student_id uuid references public.students(id) on delete cascade not null,
    batch_id uuid references public.batches(id) on delete cascade not null,
    enrolled_at timestamp with time zone default timezone('utc'::text, now()) not null,
    status enrollment_status not null default 'active',
    unique(student_id, batch_id)
);

-- Enable RLS on Batch Enrollments
alter table public.batch_enrollments enable row level security;

-- 7. Teacher Assignments Table
create table public.teacher_assignments (
    id uuid default gen_random_uuid() primary key,
    teacher_id uuid references public.profiles(id) on delete cascade not null,
    batch_id uuid references public.batches(id) on delete cascade not null,
    subject_id uuid references public.subjects(id) on delete cascade not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(teacher_id, batch_id, subject_id)
);

-- Enable RLS on Teacher Assignments
alter table public.teacher_assignments enable row level security;

-- 8. Timetable Table
create table public.timetable (
    id uuid default gen_random_uuid() primary key,
    batch_id uuid references public.batches(id) on delete cascade not null,
    subject_id uuid references public.subjects(id) on delete cascade not null,
    teacher_id uuid references public.profiles(id) on delete cascade not null,
    day_of_week integer not null check (day_of_week between 0 and 6), -- 0 = Monday
    start_time time not null,
    end_time time not null,
    room text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Timetable
alter table public.timetable enable row level security;

-- 9. Attendance Table
create table public.attendance (
    id uuid default gen_random_uuid() primary key,
    student_id uuid references public.students(id) on delete cascade not null,
    batch_id uuid references public.batches(id) on delete cascade not null,
    subject_id uuid references public.subjects(id) on delete cascade not null,
    date date not null,
    status attendance_status not null default 'present',
    marked_by uuid references public.profiles(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(student_id, batch_id, subject_id, date)
);

-- Enable RLS on Attendance
alter table public.attendance enable row level security;

-- 10. Fee Structures Table
create table public.fee_structures (
    id uuid default gen_random_uuid() primary key,
    course_id uuid references public.courses(id) on delete cascade unique not null,
    total_amount bigint not null, -- stored in paisa (INR * 100)
    installment_plan_json jsonb,
    gst_applicable boolean not null default false,
    gst_percentage integer default 0,
    gst_number text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Fee Structures
alter table public.fee_structures enable row level security;

-- 11. Fee Payments Table
create table public.fee_payments (
    id uuid default gen_random_uuid() primary key,
    student_id uuid references public.students(id) on delete cascade not null,
    amount bigint not null, -- stored in paisa
    payment_date date not null default current_date,
    mode fee_payment_mode not null default 'upi',
    reference_no text,
    receipt_url text,
    recorded_by uuid references public.profiles(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Fee Payments
alter table public.fee_payments enable row level security;

-- 12. Exams Table
create table public.exams (
    id uuid default gen_random_uuid() primary key,
    batch_id uuid references public.batches(id) on delete cascade not null,
    subject_id uuid references public.subjects(id) on delete cascade not null,
    name text not null,
    exam_date date not null,
    max_marks integer not null default 100,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Exams
alter table public.exams enable row level security;

-- 13. Exam Results Table
create table public.exam_results (
    id uuid default gen_random_uuid() primary key,
    exam_id uuid references public.exams(id) on delete cascade not null,
    student_id uuid references public.students(id) on delete cascade not null,
    marks_obtained integer not null,
    remarks text,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(exam_id, student_id)
);

-- Enable RLS on Exam Results
alter table public.exam_results enable row level security;

-- 14. Study Materials Table
create table public.study_materials (
    id uuid default gen_random_uuid() primary key,
    batch_id uuid references public.batches(id) on delete cascade not null,
    subject_id uuid references public.subjects(id) on delete cascade not null,
    title text not null,
    file_url text not null,
    uploaded_by uuid references public.profiles(id) on delete set null,
    uploaded_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Study Materials
alter table public.study_materials enable row level security;

-- 15. Notices Table
create table public.notices (
    id uuid default gen_random_uuid() primary key,
    title text not null,
    body text not null,
    target_batch_id uuid references public.batches(id) on delete set null, -- Null = Academy-wide
    created_by uuid references public.profiles(id) on delete set null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Notices
alter table public.notices enable row level security;

-- 16. Notifications Table
create table public.notifications (
    id uuid default gen_random_uuid() primary key,
    profile_id uuid references public.profiles(id) on delete cascade not null,
    title text not null,
    body text not null,
    type notification_type not null default 'general',
    read_status boolean not null default false,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Enable RLS on Notifications
alter table public.notifications enable row level security;


-- ============================================================
-- Helper Security Functions (SECURITY DEFINER)
-- ============================================================

create or replace function public.get_my_role()
returns user_role
language plpgsql
security definer
set search_path = public
as $$
begin
    return (
        select role from public.profiles
        where id = auth.uid()
    );
end;
$$;

create or replace function public.get_my_student_id()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
begin
    return (
        select id from public.students
        where profile_id = auth.uid()
        limit 1
    );
end;
$$;

create or replace function public.get_my_child_student_ids()
returns table(student_id uuid)
language plpgsql
security definer
set search_path = public
as $$
begin
    return query
    select id from public.students
    where guardian_phone = (select phone from public.profiles where id = auth.uid());
end;
$$;


-- ============================================================
-- Profile Sync Trigger (Auth.users -> Public.profiles)
-- ============================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    insert into public.profiles (id, email, full_name, role)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data->>'full_name', new.email),
        coalesce((new.raw_user_meta_data->>'role')::user_role, 'student'::user_role)
    );
    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute procedure public.handle_new_user();


-- ============================================================
-- Roll Number Sequence & Generation Trigger
-- ============================================================

create sequence public.student_roll_seq start 1;

create or replace function public.generate_roll_number()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
    current_year text;
    next_val text;
begin
    current_year := to_char(current_date, 'YYYY');
    next_val := lpad(nextval('public.student_roll_seq')::text, 4, '0');
    new.roll_no := 'NA-' || current_year || '-' || next_val;
    return new;
end;
$$;

create trigger on_student_admitted
    before insert on public.students
    for each row
    when (new.roll_no is null)
    execute procedure public.generate_roll_number();


-- ============================================================
-- Reusable updated_at Column Trigger
-- ============================================================

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
    new.updated_at = timezone('utc'::text, now());
    return new;
end;
$$;

create trigger set_profiles_updated_at before update on public.profiles for each row execute procedure public.update_updated_at_column();
create trigger set_students_updated_at before update on public.students for each row execute procedure public.update_updated_at_column();
create trigger set_courses_updated_at before update on public.courses for each row execute procedure public.update_updated_at_column();
create trigger set_subjects_updated_at before update on public.subjects for each row execute procedure public.update_updated_at_column();
create trigger set_batches_updated_at before update on public.batches for each row execute procedure public.update_updated_at_column();
create trigger set_fee_structures_updated_at before update on public.fee_structures for each row execute procedure public.update_updated_at_column();


-- ============================================================
-- Computed Database Views (Security Invoker Enabled)
-- ============================================================

-- Attendance Summary View
create or replace view public.attendance_summary with (security_invoker = true) as
select
    a.student_id,
    a.subject_id,
    to_char(a.date, 'YYYY-MM') as month,
    count(case when a.status in ('present', 'late') then 1 end) as present_count,
    count(*) as total_count,
    round((count(case when a.status in ('present', 'late') then 1 end)::numeric / count(*)::numeric) * 100, 2) as percentage
from public.attendance a
group by a.student_id, a.subject_id, to_char(a.date, 'YYYY-MM');

-- Fee Dues View
create or replace view public.fee_dues with (security_invoker = true) as
with total_payments as (
    select student_id, sum(amount) as paid_amount
    from public.fee_payments
    group by student_id
)
select
    s.id as student_id,
    be.batch_id,
    fs.total_amount as total_due,
    coalesce(tp.paid_amount, 0) as total_paid,
    (fs.total_amount - coalesce(tp.paid_amount, 0)) as balance
from public.students s
join public.batch_enrollments be on s.id = be.student_id
join public.batches b on be.batch_id = b.id
join public.fee_structures fs on b.course_id = fs.course_id
left join total_payments tp on s.id = tp.student_id;

-- Exam Ranks View
create or replace view public.exam_ranks with (security_invoker = true) as
select
    er.exam_id,
    er.student_id,
    er.marks_obtained,
    e.max_marks,
    round((er.marks_obtained::numeric / e.max_marks::numeric) * 100, 2) as percentage,
    dense_rank() over (partition by er.exam_id order by er.marks_obtained desc) as rank_in_batch
from public.exam_results er
join public.exams e on er.exam_id = e.id;



-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

-- PROFILES Policies
create policy "Admins can view and update all profiles"
    on public.profiles for all
    using (public.get_my_role() in ('super_admin', 'admin'));

create policy "Users can view and update their own profiles"
    on public.profiles for select
    using (auth.uid() = id);

create policy "Users can update their own profile basic fields"
    on public.profiles for update
    using (auth.uid() = id)
    with check (auth.uid() = id);

-- STUDENTS Policies
create policy "Admins can manage students"
    on public.students for all
    using (public.get_my_role() in ('super_admin', 'admin'));

create policy "Teachers can view students in their batches"
    on public.students for select
    using (
        public.get_my_role() = 'teacher'
        and id in (
            select student_id from public.batch_enrollments
            where batch_id in (
                select batch_id from public.teacher_assignments
                where teacher_id = auth.uid()
            )
        )
    );

create policy "Students can view their own profile"
    on public.students for select
    using (profile_id = auth.uid());

create policy "Parents can view their child's profile"
    on public.students for select
    using (
        public.get_my_role() = 'parent'
        and id in (select public.get_my_child_student_ids())
    );

-- COURSES Policies
create policy "Anyone authenticated can view courses"
    on public.courses for select
    using (auth.role() = 'authenticated');

create policy "Admins can manage courses"
    on public.courses for all
    using (public.get_my_role() in ('super_admin', 'admin'));

-- SUBJECTS Policies
create policy "Anyone authenticated can view subjects"
    on public.subjects for select
    using (auth.role() = 'authenticated');

create policy "Admins can manage subjects"
    on public.subjects for all
    using (public.get_my_role() in ('super_admin', 'admin'));

-- BATCHES Policies
create policy "Anyone authenticated can view batches"
    on public.batches for select
    using (auth.role() = 'authenticated');

create policy "Admins can manage batches"
    on public.batches for all
    using (public.get_my_role() in ('super_admin', 'admin'));

-- BATCH ENROLLMENTS Policies
create policy "Admins can manage batch enrollments"
    on public.batch_enrollments for all
    using (public.get_my_role() in ('super_admin', 'admin'));

create policy "Teachers can view enrollments in their batches"
    on public.batch_enrollments for select
    using (
        public.get_my_role() = 'teacher'
        and batch_id in (
            select batch_id from public.teacher_assignments
            where teacher_id = auth.uid()
        )
    );

create policy "Students can view their own enrollments"
    on public.batch_enrollments for select
    using (student_id = public.get_my_student_id());

create policy "Parents can view their child's enrollments"
    on public.batch_enrollments for select
    using (
        public.get_my_role() = 'parent'
        and student_id in (select public.get_my_child_student_ids())
    );

-- TEACHER ASSIGNMENTS Policies
create policy "Anyone authenticated can view teacher assignments"
    on public.teacher_assignments for select
    using (auth.role() = 'authenticated');

create policy "Admins can manage teacher assignments"
    on public.teacher_assignments for all
    using (public.get_my_role() in ('super_admin', 'admin'));

-- TIMETABLE Policies
create policy "Anyone authenticated can view timetable"
    on public.timetable for select
    using (auth.role() = 'authenticated');

create policy "Admins can manage timetable"
    on public.timetable for all
    using (public.get_my_role() in ('super_admin', 'admin'));

-- ATTENDANCE Policies
create policy "Admins can manage attendance"
    on public.attendance for all
    using (public.get_my_role() in ('super_admin', 'admin'));

create policy "Teachers can manage attendance for their assigned subjects in batches"
    on public.attendance for all
    using (
        public.get_my_role() = 'teacher'
        and (batch_id, subject_id) in (
            select batch_id, subject_id from public.teacher_assignments
            where teacher_id = auth.uid()
        )
    );

create policy "Students can view their own attendance"
    on public.attendance for select
    using (student_id = public.get_my_student_id());

create policy "Parents can view their child's attendance"
    on public.attendance for select
    using (
        public.get_my_role() = 'parent'
        and student_id in (select public.get_my_child_student_ids())
    );

-- FEE STRUCTURES Policies
create policy "Anyone authenticated can view fee structures"
    on public.fee_structures for select
    using (auth.role() = 'authenticated');

create policy "Admins can manage fee structures"
    on public.fee_structures for all
    using (public.get_my_role() in ('super_admin', 'admin'));

-- FEE PAYMENTS Policies
create policy "Admins can manage fee payments"
    on public.fee_payments for all
    using (public.get_my_role() in ('super_admin', 'admin'));

create policy "Students can view their own payments"
    on public.fee_payments for select
    using (student_id = public.get_my_student_id());

create policy "Parents can view their child's payments"
    on public.fee_payments for select
    using (
        public.get_my_role() = 'parent'
        and student_id in (select public.get_my_child_student_ids())
    );

-- EXAMS Policies
create policy "Anyone authenticated can view exams"
    on public.exams for select
    using (auth.role() = 'authenticated');

create policy "Admins and assigned teachers can manage exams"
    on public.exams for all
    using (
        public.get_my_role() in ('super_admin', 'admin')
        or (
            public.get_my_role() = 'teacher'
            and batch_id in (
                select batch_id from public.teacher_assignments
                where teacher_id = auth.uid()
            )
        )
    );

-- EXAM RESULTS Policies
create policy "Admins can manage exam results"
    on public.exam_results for all
    using (public.get_my_role() in ('super_admin', 'admin'));

create policy "Teachers can manage exam results for their classes"
    on public.exam_results for all
    using (
        public.get_my_role() = 'teacher'
        and exam_id in (
            select id from public.exams
            where batch_id in (
                select batch_id from public.teacher_assignments
                where teacher_id = auth.uid()
            )
        )
    );

create policy "Students can view their own results"
    on public.exam_results for select
    using (student_id = public.get_my_student_id());

create policy "Parents can view their child's exam results"
    on public.exam_results for select
    using (
        public.get_my_role() = 'parent'
        and student_id in (select public.get_my_child_student_ids())
    );

-- STUDY MATERIALS Policies
create policy "Admins and teachers can manage study materials"
    on public.study_materials for all
    using (
        public.get_my_role() in ('super_admin', 'admin', 'teacher')
    );

create policy "Students can read study materials for batches they are enrolled in"
    on public.study_materials for select
    using (
        batch_id in (
            select batch_id from public.batch_enrollments
            where student_id = public.get_my_student_id()
        )
    );

create policy "Parents can read study materials for their children's batches"
    on public.study_materials for select
    using (
        public.get_my_role() = 'parent'
        and batch_id in (
            select batch_id from public.batch_enrollments
            where student_id in (select public.get_my_child_student_ids())
        )
    );

-- NOTICES Policies
create policy "Admins and teachers can manage notices"
    on public.notices for all
    using (
        public.get_my_role() in ('super_admin', 'admin', 'teacher')
    );

create policy "Anyone can read academy-wide notices"
    on public.notices for select
    using (target_batch_id is null);

create policy "Students can read notices for their batches"
    on public.notices for select
    using (
        target_batch_id in (
            select batch_id from public.batch_enrollments
            where student_id = public.get_my_student_id()
        )
    );

create policy "Parents can read notices for their children's batches"
    on public.notices for select
    using (
        public.get_my_role() = 'parent'
        and target_batch_id in (
            select batch_id from public.batch_enrollments
            where student_id in (select public.get_my_child_student_ids())
        )
    );

-- NOTIFICATIONS Policies
create policy "Users can manage their own notifications"
    on public.notifications for all
    using (profile_id = auth.uid());


-- ============================================================
-- Default Privileges & Grants for Supabase Roles
-- ============================================================

grant usage on schema public to authenticator, anon, authenticated, service_role;
grant all on schema public to postgres, authenticator, anon, authenticated, service_role;

grant all on all tables in schema public to postgres, authenticator, anon, authenticated, service_role;
grant all on all sequences in schema public to postgres, authenticator, anon, authenticated, service_role;
grant all on all routines in schema public to postgres, authenticator, anon, authenticated, service_role;

alter default privileges in schema public grant all on tables to postgres, authenticator, anon, authenticated, service_role;
alter default privileges in schema public grant all on sequences to postgres, authenticator, anon, authenticated, service_role;
alter default privileges in schema public grant all on routines to postgres, authenticator, anon, authenticated, service_role;


-- ============================================================
-- Student Registration Drafts Table
-- ============================================================

create table if not exists public.student_registration_drafts (
    id uuid default gen_random_uuid() primary key,
    email text unique not null,
    step integer not null default 1,
    data jsonb not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.student_registration_drafts enable row level security;

create policy "Admins can view and edit drafts"
    on public.student_registration_drafts for all
    using (public.get_my_role() = 'admin' or public.get_my_role() = 'super_admin');

grant all on public.student_registration_drafts to postgres, anon, authenticated, service_role, authenticator;


-- ============================================================
-- Supabase Storage Buckets & Policies
-- ============================================================

insert into storage.buckets (id, name, public)
values ('student-documents', 'student-documents', true)
on conflict (id) do nothing;

create policy "Allow public read access to student-documents"
    on storage.objects for select
    using (bucket_id = 'student-documents');

create policy "Allow authenticated uploads to student-documents"
    on storage.objects for all
    using (bucket_id = 'student-documents' and auth.role() = 'authenticated');




