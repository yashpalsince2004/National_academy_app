-- Add is_cancelled column to exams table for soft delete support
ALTER TABLE public.exams ADD COLUMN IF NOT EXISTS is_cancelled boolean DEFAULT false NOT NULL;
ALTER TABLE public.exams ADD COLUMN IF NOT EXISTS exam_time text;
