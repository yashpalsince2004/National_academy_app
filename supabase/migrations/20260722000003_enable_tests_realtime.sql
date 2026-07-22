-- Enable real-time publication for tests and exams tables
alter publication supabase_realtime add table public.tests;
alter publication supabase_realtime add table public.exams;
