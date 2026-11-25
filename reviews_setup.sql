-- AUREVO রিভিউ টেবিল: Supabase > SQL Editor-এ পুরোটা পেস্ট করে Run চাপুন।
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id text not null,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  user_name text,
  user_avatar text,
  body text not null check (char_length(body) between 3 and 600),
  approved boolean not null default false,
  created_at timestamptz not null default now()
);
create index if not exists reviews_product_idx on public.reviews (product_id, approved, created_at desc);
alter table public.reviews enable row level security;

drop policy if exists "reviews read approved" on public.reviews;
create policy "reviews read approved" on public.reviews for select using (approved = true);
drop policy if exists "reviews read own" on public.reviews;
create policy "reviews read own" on public.reviews for select to authenticated using (auth.uid() = user_id);
drop policy if exists "reviews insert own" on public.reviews;
create policy "reviews insert own" on public.reviews for insert to authenticated with check (auth.uid() = user_id);
drop policy if exists "reviews delete own" on public.reviews;
create policy "reviews delete own" on public.reviews for delete to authenticated using (auth.uid() = user_id);

-- নাম/ছবি নিজে বসে, আর নতুন রিভিউ সবসময় "অননুমোদিত" থাকে।
create or replace function public.reviews_before_insert() returns trigger
language plpgsql security definer set search_path = '' as $$
declare m jsonb;
begin
  select raw_user_meta_data into m from auth.users where id = auth.uid();
  new.user_id := auth.uid();
  new.user_name := coalesce(m->>'full_name', m->>'name', split_part((select email from auth.users where id = auth.uid()), '@', 1));
  new.user_avatar := coalesce(m->>'avatar_url', m->>'picture');
  new.approved := false;
  return new;
end $$;
drop trigger if exists reviews_before_insert on public.reviews;
create trigger reviews_before_insert before insert on public.reviews
for each row execute function public.reviews_before_insert();
-- অনুমোদন: Table Editor > reviews > approved ঘরটি true করুন (Admin Panel এলে সেখান থেকে হবে)।
