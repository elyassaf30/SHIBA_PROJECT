-- ============================================================
-- AI Knowledge Base Migration (ללא vector — חיפוש טקסט)
-- הרץ את הקוד הזה ב-Supabase Dashboard → SQL Editor
-- ============================================================

-- שלב א: טבלת בסיס הידע
create table if not exists public.knowledge_base (
  id          bigserial    primary key,
  content     text         not null,
  category    text         not null,  -- 'כשרות' | 'שבת' | 'חגים' | 'הלכה' | 'תפילה' | 'כללי'
  metadata    jsonb        not null default '{}'::jsonb,
  created_at  timestamptz  not null default now()
);

-- שלב ב: אינדקס full-text search לעברית
create index if not exists knowledge_base_content_fts_idx
  on public.knowledge_base
  using gin (to_tsvector('simple', content));

-- שלב ג: אינדקס על category לסינון מהיר
create index if not exists knowledge_base_category_idx
  on public.knowledge_base (category);

-- שלב ד: Row Level Security
alter table public.knowledge_base enable row level security;

create policy "knowledge_base_select_public"
  on public.knowledge_base
  for select
  using (true);

-- שלב ה: מניעת כפילויות (הרץ שוב בבטחה)
create policy "knowledge_base_insert_service"
  on public.knowledge_base
  for insert
  with check (true);

create policy "knowledge_base_delete_service"
  on public.knowledge_base
  for delete
  using (true);
