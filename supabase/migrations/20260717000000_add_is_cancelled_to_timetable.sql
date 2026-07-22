-- Add is_cancelled column to timetable table for soft delete support
ALTER TABLE public.timetable ADD COLUMN is_cancelled boolean DEFAULT false NOT NULL;
