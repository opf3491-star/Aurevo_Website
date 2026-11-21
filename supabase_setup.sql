-- AUREVO: নিজের অ্যাকাউন্ট ডিলিট করার ফাংশন (Supabase > SQL Editor-এ পেস্ট করে Run করুন)
create or replace function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  delete from auth.users where id = auth.uid();
end;
$$;
revoke all on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
