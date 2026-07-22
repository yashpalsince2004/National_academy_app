-- Migration: Create dedicated tests table with batch-scoped RLS policies
-- Date: 2026-07-22

-- 1. Create public.tests Table
CREATE TABLE IF NOT EXISTS public.tests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    batch_id UUID REFERENCES public.batches(id) ON DELETE CASCADE NOT NULL,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    test_date DATE NOT NULL,
    timing TEXT NOT NULL,
    total_marks INTEGER NOT NULL DEFAULT 100,
    is_cancelled BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Index for fast batch lookup and date ordering
CREATE INDEX IF NOT EXISTS idx_tests_batch_date ON public.tests(batch_id, test_date);

-- 2. Enable Row Level Security
ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;

-- 3. Policy: Enrolled students can view tests scheduled for their assigned batches
DROP POLICY IF EXISTS "Students can view tests for enrolled batches" ON public.tests;
CREATE POLICY "Students can view tests for enrolled batches"
    ON public.tests FOR SELECT
    USING (
        auth.role() = 'authenticated'
        AND batch_id IN (
            SELECT be.batch_id FROM public.batch_enrollments be
            JOIN public.students s ON s.id = be.student_id
            WHERE s.profile_id = auth.uid()
        )
    );

-- 4. Policy: Admins and assigned teachers can full manage tests
DROP POLICY IF EXISTS "Admins and assigned teachers can manage tests" ON public.tests;
CREATE POLICY "Admins and assigned teachers can manage tests"
    ON public.tests FOR ALL
    USING (
        public.get_my_role() IN ('super_admin', 'admin')
        OR (
            public.get_my_role() = 'teacher'
            AND batch_id IN (
                SELECT batch_id FROM public.teacher_assignments
                WHERE teacher_id = auth.uid()
            )
        )
    );
