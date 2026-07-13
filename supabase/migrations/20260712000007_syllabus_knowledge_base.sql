-- Migration: Create Syllabus Knowledge Base and Update DPP Question Schema
-- Target: Supabase database

-- 1. Create Syllabus Table
create table if not exists public.syllabus (
    id uuid default gen_random_uuid() primary key,
    exam text not null, -- 'JEE', 'NEET', 'NDA'
    subject text not null, -- e.g., 'Physics', 'Chemistry', 'Mathematics', 'Biology', etc.
    chapter text not null,
    topics text[] not null,
    created_at timestamp with time zone default timezone('utc'::text, now()) not null,
    unique(exam, subject, chapter)
);

-- Enable RLS on Syllabus
alter table public.syllabus enable row level security;

-- Policy: Everyone can view the syllabus
create policy "Syllabus can be viewed by authenticated users" 
    on public.syllabus for select to authenticated using (true);

create policy "Syllabus can be managed by admins" 
    on public.syllabus for all to authenticated 
    using (exists (select 1 from public.profiles where id = auth.uid() and role in ('super_admin', 'admin')));

-- 2. Seed Syllabus Data for JEE, NEET, and NDA
insert into public.syllabus (exam, subject, chapter, topics) values
  -- JEE Physics
  ('JEE', 'Physics', 'Mechanics', array[
    'Kinematics in One and Two Dimensions',
    'Newton Laws of Motion and Friction',
    'Work, Energy, Power and Collisions',
    'System of Particles and Rotational Dynamics',
    'Gravitation and Kepler Laws'
  ]),
  ('JEE', 'Physics', 'Electrostatics & Magnetism', array[
    'Coulomb Law and Electric Fields',
    'Gauss Law and Electric Potential',
    'Capacitors and Dielectrics',
    'Magnetic Effects of Current and Ampere Law',
    'Electromagnetic Induction and AC Circuits'
  ]),
  ('JEE', 'Physics', 'Optics & Modern Physics', array[
    'Ray Optics and Optical Instruments',
    'Wave Optics and Huygens Principle',
    'Dual Nature of Matter and Photoelectric Effect',
    'Bohr Model of Atom',
    'Nuclear Physics and Radioactivity'
  ]),

  -- JEE Chemistry
  ('JEE', 'Chemistry', 'Physical Chemistry', array[
    'Some Basic Concepts & Stoichiometry',
    'Atomic Structure and Quantum Numbers',
    'Chemical Thermodynamics',
    'Chemical and Ionic Equilibrium',
    'Chemical Kinetics and Rate Laws'
  ]),
  ('JEE', 'Chemistry', 'Organic Chemistry', array[
    'General Organic Chemistry & Isomerism',
    'Hydrocarbons (Alkanes, Alkenes, Alkynes)',
    'Haloalkanes and Haloarenes',
    'Alcohols, Phenols and Ethers',
    'Aldehydes, Ketones and Carboxylic Acids'
  ]),
  ('JEE', 'Chemistry', 'Inorganic Chemistry', array[
    'Periodic Classification of Elements',
    'Chemical Bonding and Molecular Structure',
    'Coordination Compounds',
    'd-Block and f-Block Elements'
  ]),

  -- JEE Mathematics
  ('JEE', 'Mathematics', 'Calculus', array[
    'Limits, Continuity and Differentiability',
    'Application of Derivatives (Max-Min, Tangents)',
    'Definite and Indefinite Integrals',
    'Differential Equations'
  ]),
  ('JEE', 'Mathematics', 'Algebra', array[
    'Quadratic Equations and Complex Numbers',
    'Matrices and Determinants',
    'Probability and Bayes Theorem',
    'Permutations and Combinations',
    'Binomial Theorem'
  ]),
  ('JEE', 'Mathematics', 'Coordinate Geometry', array[
    'Straight Lines and Pair of Lines',
    'Circles',
    'Conic Sections (Parabola, Ellipse, Hyperbola)'
  ]),

  -- NEET Physics
  ('NEET', 'Physics', 'Mechanics', array[
    'Kinematics',
    'Laws of Motion and Friction',
    'Work, Energy and Power',
    'Rotational Motion',
    'Gravitation'
  ]),
  ('NEET', 'Physics', 'Electrostatics & Magnetism', array[
    'Electric Charges and Fields',
    'Electrostatic Potential and Capacitance',
    'Current Electricity',
    'Magnetic Effects of Current and Magnetism',
    'Electromagnetic Induction'
  ]),
  ('NEET', 'Physics', 'Optics & Modern Physics', array[
    'Ray Optics',
    'Wave Optics',
    'Dual Nature of Matter',
    'Atoms and Nuclei'
  ]),

  -- NEET Chemistry
  ('NEET', 'Chemistry', 'Physical Chemistry', array[
    'Basic Concepts of Chemistry',
    'Structure of Atom',
    'Thermodynamics',
    'Equilibrium',
    'Chemical Kinetics'
  ]),
  ('NEET', 'Chemistry', 'Organic Chemistry', array[
    'GOC principles',
    'Hydrocarbons',
    'Alcohols and Ethers',
    'Aldehydes and Carboxylic Acids',
    'Biomolecules'
  ]),
  ('NEET', 'Chemistry', 'Inorganic Chemistry', array[
    'Classification of Elements',
    'Chemical Bonding',
    'Coordination Compounds',
    'p-Block elements'
  ]),

  -- NEET Biology
  ('NEET', 'Biology', 'Diversity & Structural Organisation', array[
    'The Living World and Biological Classification',
    'Plant Kingdom',
    'Animal Kingdom',
    'Morphology of Flowering Plants',
    'Anatomy of Flowering Plants'
  ]),
  ('NEET', 'Biology', 'Cell Biology & Physiology', array[
    'Cell Cycle and Cell Division',
    'Photosynthesis in Higher Plants',
    'Respiration in Plants',
    'Human Digestion and Absorption',
    'Human Circulation and Excretion'
  ]),
  ('NEET', 'Biology', 'Genetics, Biotech & Ecology', array[
    'Principles of Inheritance and Variation',
    'Molecular Basis of Inheritance',
    'Biotechnology: Principles and Processes',
    'Biotechnology and its Applications',
    'Organisms and Populations',
    'Ecosystems'
  ]),

  -- NDA Mathematics
  ('NDA', 'Mathematics', 'Algebra & Trigonometry', array[
    'Sets, Relations and Functions',
    'Quadratic Equations',
    'Arithmetic and Geometric Progressions',
    'Trigonometric Ratios and Identities',
    'Properties of Triangles'
  ]),
  ('NDA', 'Mathematics', 'Calculus & Coordinate Geometry', array[
    'Limits and Derivatives',
    'Integration and Area Under Curves',
    'Straight Lines and Circles',
    'Vector Algebra and 3D Geometry'
  ]),
  ('NDA', 'Mathematics', 'Probability & Statistics', array[
    'Measures of Central Tendency and Dispersion',
    'Probability Events and Bayes Theorem'
  ]),

  -- NDA General Ability
  ('NDA', 'General Ability', 'English', array[
    'Spotting Errors',
    'Synonyms and Antonyms',
    'Sentence Improvement',
    'Comprehension'
  ]),
  ('NDA', 'General Ability', 'General Science', array[
    'Physics (Mechanics, Electricity, Optics)',
    'Chemistry (Acids, Bases, Salts, Metals)',
    'Biology (Cells, Nutrition, Diseases)'
  ]),
  ('NDA', 'General Ability', 'Social Studies & GK', array[
    'Indian History and Freedom Movement',
    'Geography (Physical, India and World)',
    'Indian Constitution and Civics',
    'Current Affairs'
  ])
on conflict (exam, subject, chapter) do update
set topics = excluded.topics;

-- 3. Update DPP Question Schema for Metadata and JSON Explanations
alter table public.dpp_questions 
    alter column explanation type jsonb using to_jsonb(explanation),
    add column if not exists concept text,
    add column if not exists blooms_level text,
    add column if not exists difficulty_score numeric,
    add column if not exists source_type text;
