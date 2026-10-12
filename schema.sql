-- =====================================================================
--  Gold Film — baz done Supabase
--  Kopye tout fichye sa a nan Supabase > SQL Editor, epi peze "Run".
--  (Pou yon pwojè Supabase tou nèf.)
-- =====================================================================

-- ---------- Itilizatè app la (pwopriyetè / asosye) ----------
--  role: owner (pwopriyetè), associate (asosye), pending (an atant)
--  code: P1–P3 pou pwopriyetè, A1–A3 pou asosye
--  principal: pwopriyetè prensipal la (sèl ki jere ekip la)
create table if not exists public.app_users (
  id         uuid primary key references auth.users(id) on delete cascade,
  name       text not null,
  email      text,
  role       text not null default 'pending' check (role in ('owner', 'associate', 'pending')),
  code       text unique,
  principal  boolean not null default false,
  created_at timestamptz not null default now()
);
create unique index if not exists app_users_one_principal on public.app_users(principal) where principal;

-- Wòl moun ki konekte a (null si li an atant oswa pa nan ekip la)
create or replace function public.my_role()
returns text
language sql stable security definer
set search_path = public
as $$
  select role from public.app_users where id = auth.uid() and role in ('owner', 'associate')
$$;

create or replace function public.is_principal()
returns boolean
language sql stable security definer
set search_path = public
as $$
  select coalesce((select principal from public.app_users where id = auth.uid() and role = 'owner'), false)
$$;

-- ---------- Paramèt (to dola a) ----------
create table if not exists public.settings (
  id          int primary key default 1 check (id = 1),
  usd_rate    numeric(12,4) not null default 130 check (usd_rate > 0),  -- 1 USD = ? HTG
  pin_lock_days int not null default 3 check (pin_lock_days between 0 and 30),
  updated_at  timestamptz not null default now(),
  updated_by  uuid references public.app_users(id) on delete set null
);
insert into public.settings (id) values (1) on conflict (id) do nothing;

-- ---------- Kont Netflix yo ----------
create table if not exists public.accounts (
  id               bigint generated always as identity primary key,
  label            text not null,                         -- egz: "Kont A"
  login_email      text,                                  -- imèl kont prensipal la
  plan             text not null default 'Premium',
  plan_price_usd   numeric(10,2) not null default 0,      -- pri plan an chak mwa
  extra_price_usd  numeric(10,2) not null default 0,      -- pri pa defo yon manm siplemantè
  main_slots       int not null default 4 check (main_slots between 1 and 5),
  next_billing     date not null,                         -- pwochen dat Netflix ap retire kòb
  notes            text,
  active           boolean not null default true,
  created_at       timestamptz not null default now()
);

-- ---------- Plas manm siplemantè (max 2 aktif pa kont) ----------
create table if not exists public.extra_slots (
  id            bigint generated always as identity primary key,
  account_id    bigint not null references public.accounts(id) on delete cascade,
  label         text not null default 'Siplemantè',
  email         text,                                     -- imèl manm siplemantè a
  billing       text not null default 'shared' check (billing in ('shared', 'own')),
  price_usd     numeric(10,2) not null default 0,
  next_billing  date,                                     -- itilize sèlman si billing = 'own'
  active        boolean not null default true,
  created_at    timestamptz not null default now(),
  check (billing = 'shared' or next_billing is not null)
);
create index if not exists extra_slots_account_idx on public.extra_slots(account_id);

-- ---------- Kliyan yo ----------
create table if not exists public.clients (
  id            bigint generated always as identity primary key,
  name          text not null,
  phone         text not null,
  account_id    bigint references public.accounts(id) on delete set null,
  slot_type     text not null default 'main' check (slot_type in ('main', 'extra')),
  extra_id      bigint references public.extra_slots(id) on delete set null,
  profile_name  text,
  price         numeric(12,2) not null default 0,
  currency      text not null default 'HTG' check (currency in ('HTG', 'USD')),
  next_due      date not null,
  status        text not null default 'active' check (status in ('active', 'paused', 'left')),
  lang          text not null default 'ht' check (lang in ('ht', 'fr')),   -- lang mesaj WhatsApp yo
  notes         text,
  pin           text check (pin ~ '^[0-9]{4}$'),                          -- PIN pwofil la
  pin_set_at    timestamptz,
  pin_set_by    uuid references public.app_users(id) on delete set null,
  created_at    timestamptz not null default now()
);
create index if not exists clients_account_idx on public.clients(account_id);

-- ---------- Peman kliyan yo ----------
create table if not exists public.payments (
  id           bigint generated always as identity primary key,
  client_id    bigint references public.clients(id) on delete set null,
  client_name  text,                                      -- kenbe non an menm si kliyan an efase
  amount       numeric(12,2) not null check (amount >= 0),
  currency     text not null check (currency in ('HTG', 'USD')),
  rate         numeric(12,4) not null,                    -- to dola jou peman an
  months       int not null default 1,
  paid_on      date not null default current_date,
  recorded_by  uuid references public.app_users(id) on delete set null,
  created_at   timestamptz not null default now()
);
create index if not exists payments_date_idx on public.payments(paid_on);

-- ---------- Balans kat kado (liv kont) ----------
--  card   = kat kado ajoute (+), ak sa w te peye pou li
--  charge = Netflix retire pri mwa a (−)
--  adjust = koreksyon balans (+/−)
--  extra_id null = balans kont prensipal la; sinon = balans plas siplemantè a
create table if not exists public.card_ledger (
  id             bigint generated always as identity primary key,
  account_id     bigint not null references public.accounts(id) on delete cascade,
  extra_id       bigint references public.extra_slots(id) on delete cascade,
  kind           text not null check (kind in ('card', 'charge', 'adjust')),
  amount_usd     numeric(10,2) not null,
  paid_amount    numeric(12,2),
  paid_currency  text check (paid_currency in ('HTG', 'USD')),
  paid_rate      numeric(12,4),
  entry_date     date not null default current_date,
  note           text,
  created_by     uuid references public.app_users(id) on delete set null,
  created_at     timestamptz not null default now()
);
create index if not exists card_ledger_acc_idx on public.card_ledger(account_id, extra_id);
create index if not exists card_ledger_date_idx on public.card_ledger(entry_date);

-- ---------- Modpas kont yo (aktif + an atant + 2 ansyen) ----------
create table if not exists public.account_passwords (
  id            bigint generated always as identity primary key,
  account_id    bigint not null references public.accounts(id) on delete cascade,
  password      text not null,
  status        text not null check (status in ('pending', 'active', 'old')),
  created_at    timestamptz not null default now(),
  created_by    uuid references public.app_users(id) on delete set null,
  confirmed_at  timestamptz,
  confirmed_by  uuid references public.app_users(id) on delete set null
);
create index if not exists account_passwords_acc_idx on public.account_passwords(account_id);
create unique index if not exists account_passwords_one_active  on public.account_passwords(account_id) where status = 'active';
create unique index if not exists account_passwords_one_pending on public.account_passwords(account_id) where status = 'pending';

-- =====================================================================
--  Règ plas yo
-- =====================================================================
create or replace function public.check_client_slot()
returns trigger
language plpgsql
as $$
declare
  v_max  int;
  v_used int;
  v_ok   boolean;
begin
  if new.slot_type = 'main' then
    new.extra_id := null;
  end if;
  if new.account_id is null or new.status = 'left' then
    return new;
  end if;

  if new.slot_type = 'main' then
    select main_slots into v_max from public.accounts where id = new.account_id;
    select count(*) into v_used from public.clients
     where account_id = new.account_id and slot_type = 'main'
       and status in ('active', 'paused') and id <> coalesce(new.id, -1);
    if v_used >= v_max then
      raise exception 'Pa gen plas nòmal lib sou kont sa a (% / %)', v_used, v_max;
    end if;
  else
    if new.extra_id is null then
      raise exception 'Chwazi ki plas siplemantè kliyan an ap okipe';
    end if;
    select exists (select 1 from public.extra_slots
                    where id = new.extra_id and account_id = new.account_id and active)
      into v_ok;
    if not v_ok then
      raise exception 'Plas siplemantè sa a pa sou kont sa a oswa li pa aktif';
    end if;
    if exists (select 1 from public.clients
                where extra_id = new.extra_id and status in ('active', 'paused')
                  and id <> coalesce(new.id, -1)) then
      raise exception 'Gen yon lòt kliyan deja sou plas siplemantè sa a';
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists clients_slot_check on public.clients;
create trigger clients_slot_check
  before insert or update of account_id, slot_type, extra_id, status on public.clients
  for each row execute function public.check_client_slot();

create or replace function public.check_extra_slot()
returns trigger
language plpgsql
as $$
begin
  if new.active then
    if (select count(*) from public.extra_slots
         where account_id = new.account_id and active and id <> coalesce(new.id, -1)) >= 2 then
      raise exception 'Yon kont pa ka gen plis pase 2 plas siplemantè';
    end if;
  elsif tg_op = 'UPDATE' and old.active then
    if exists (select 1 from public.clients
                where extra_id = new.id and status in ('active', 'paused')) then
      raise exception 'Gen yon kliyan sou plas sa a. Deplase l oswa make l "Kite" anvan.';
    end if;
  end if;
  return new;
end
$$;

drop trigger if exists extra_slots_check on public.extra_slots;
create trigger extra_slots_check
  before insert or update on public.extra_slots
  for each row execute function public.check_extra_slot();

-- =====================================================================
--  Fonksyon (RPC)
-- =====================================================================

-- To dola (pwopriyetè sèlman)
create or replace function public.set_rate(p_rate numeric)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if coalesce(public.my_role(), '') <> 'owner' then raise exception 'Se pwopriyetè a sèl ki ka chanje to a'; end if;
  if p_rate is null or p_rate <= 0 then raise exception 'To a pa valid'; end if;
  update public.settings set usd_rate = p_rate, updated_at = now(), updated_by = auth.uid() where id = 1;
end
$$;

-- Peman yon kliyan: pwochen dat la kalkile depi pwòp dat pa l
create or replace function public.record_payment(
  p_client_id bigint, p_amount numeric, p_currency text, p_months int default 1
)
returns date
language plpgsql security definer
set search_path = public
as $$
declare
  v_c   public.clients%rowtype;
  v_new date;
begin
  if public.my_role() is null then raise exception 'Ou pa gen aksè'; end if;
  if p_months < 1 or p_months > 12 then raise exception 'Kantite mwa a pa valid'; end if;
  if p_amount is null or p_amount < 0 then raise exception 'Montan an pa valid'; end if;
  if p_currency not in ('HTG', 'USD') then raise exception 'Lajan an pa valid'; end if;

  select * into v_c from public.clients where id = p_client_id for update;
  if not found then raise exception 'Kliyan sa a pa egziste'; end if;

  v_new := (v_c.next_due + make_interval(months => p_months))::date;
  if v_new <= current_date then
    v_new := (current_date + make_interval(months => p_months))::date;
  end if;

  insert into public.payments (client_id, client_name, amount, currency, rate, months, recorded_by)
  values (p_client_id, v_c.name, p_amount, p_currency,
          (select usd_rate from public.settings where id = 1), p_months, auth.uid());

  update public.clients
     set next_due = v_new,
         status = case when status = 'left' then status else 'active' end
   where id = p_client_id;
  return v_new;
end
$$;

-- Ajoute yon kat kado (sou kont lan, oswa sou yon plas siplemantè ki gen pwòp kat)
create or replace function public.add_card(
  p_account_id bigint, p_extra_id bigint, p_amount_usd numeric,
  p_paid_amount numeric, p_paid_currency text, p_date date default current_date
)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if coalesce(public.my_role(), '') <> 'owner' then raise exception 'Se pwopriyetè a sèl ki ka ajoute kat'; end if;
  if p_amount_usd is null or p_amount_usd <= 0 then raise exception 'Montan kat la pa valid'; end if;
  if p_paid_amount is not null and p_paid_amount < 0 then raise exception 'Pri kat la pa valid'; end if;
  if p_extra_id is not null and not exists (
       select 1 from public.extra_slots where id = p_extra_id and account_id = p_account_id and billing = 'own') then
    raise exception 'Plas siplemantè sa a pa peye ak pwòp kat li';
  end if;
  insert into public.card_ledger (account_id, extra_id, kind, amount_usd, paid_amount, paid_currency, paid_rate, entry_date, note, created_by)
  values (p_account_id, p_extra_id, 'card', p_amount_usd, coalesce(p_paid_amount, 0),
          coalesce(p_paid_currency, 'HTG'), (select usd_rate from public.settings where id = 1),
          coalesce(p_date, current_date), 'Kat kado', auth.uid());
end
$$;

-- Korije balans lan pou li dakò ak sa Netflix montre
create or replace function public.adjust_balance(p_account_id bigint, p_extra_id bigint, p_new_balance numeric)
returns void
language plpgsql security definer
set search_path = public
as $$
declare v_bal numeric;
begin
  if coalesce(public.my_role(), '') <> 'owner' then raise exception 'Se pwopriyetè a sèl ki ka korije balans lan'; end if;
  if p_new_balance is null or p_new_balance < 0 then raise exception 'Balans lan pa valid'; end if;
  select coalesce(sum(amount_usd), 0) into v_bal from public.card_ledger
   where account_id = p_account_id and extra_id is not distinct from p_extra_id;
  if p_new_balance <> v_bal then
    insert into public.card_ledger (account_id, extra_id, kind, amount_usd, note, created_by)
    values (p_account_id, p_extra_id, 'adjust', p_new_balance - v_bal, 'Koreksyon balans', auth.uid());
  end if;
end
$$;

-- Retrè otomatik: chak dat peman Netflix ki pase, retire pri mwa a sou balans lan
-- (si balans lan sifi). App la rele fonksyon sa a chak fwa li louvri.
create or replace function public.process_billing()
returns int
language plpgsql security definer
set search_path = public
as $$
declare
  r     record;
  v_cost numeric;
  v_bal  numeric;
  v_n    int := 0;
  i      int;
begin
  if public.my_role() is null then return 0; end if;

  for r in select * from public.accounts where active and next_billing <= current_date for update loop
    v_cost := r.plan_price_usd + coalesce((select sum(price_usd) from public.extra_slots
                                           where account_id = r.id and active and billing = 'shared'), 0);
    if v_cost <= 0 then continue; end if;
    for i in 1..24 loop
      exit when r.next_billing > current_date;
      select coalesce(sum(amount_usd), 0) into v_bal from public.card_ledger where account_id = r.id and extra_id is null;
      exit when v_bal < v_cost;
      insert into public.card_ledger (account_id, extra_id, kind, amount_usd, entry_date, note)
      values (r.id, null, 'charge', -v_cost, r.next_billing, 'Netflix retire pri mwa a');
      r.next_billing := (r.next_billing + interval '1 month')::date;
      v_n := v_n + 1;
    end loop;
    update public.accounts set next_billing = r.next_billing where id = r.id;
  end loop;

  for r in select x.* from public.extra_slots x join public.accounts a on a.id = x.account_id
            where x.active and a.active and x.billing = 'own' and x.next_billing <= current_date
            for update of x loop
    if r.price_usd <= 0 then continue; end if;
    for i in 1..24 loop
      exit when r.next_billing > current_date;
      select coalesce(sum(amount_usd), 0) into v_bal from public.card_ledger where extra_id = r.id;
      exit when v_bal < r.price_usd;
      insert into public.card_ledger (account_id, extra_id, kind, amount_usd, entry_date, note)
      values (r.account_id, r.id, 'charge', -r.price_usd, r.next_billing, 'Netflix retire pri mwa a');
      r.next_billing := (r.next_billing + interval '1 month')::date;
      v_n := v_n + 1;
    end loop;
    update public.extra_slots set next_billing = r.next_billing where id = r.id;
  end loop;

  return v_n;
end
$$;

-- Modpas: pwopoze (an atant) → konfime (vin aktif) oswa anile
create or replace function public.propose_password(p_account_id bigint, p_password text)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if public.my_role() is null then raise exception 'Ou pa gen aksè'; end if;
  if p_password is null or length(p_password) < 8 then raise exception 'Modpas la twò kout'; end if;
  delete from public.account_passwords where account_id = p_account_id and status = 'pending';
  insert into public.account_passwords (account_id, password, status, created_by)
  values (p_account_id, p_password, 'pending', auth.uid());
end
$$;

create or replace function public.confirm_password(p_account_id bigint)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if public.my_role() is null then raise exception 'Ou pa gen aksè'; end if;
  if not exists (select 1 from public.account_passwords where account_id = p_account_id and status = 'pending') then
    raise exception 'Pa gen modpas an atant pou konfime';
  end if;
  update public.account_passwords set status = 'old' where account_id = p_account_id and status = 'active';
  update public.account_passwords
     set status = 'active', confirmed_at = now(), confirmed_by = auth.uid()
   where account_id = p_account_id and status = 'pending';
  -- Kenbe sèlman 2 ansyen modpas (aktif la + 2 ansyen = 3)
  delete from public.account_passwords
   where id in (select id from public.account_passwords
                 where account_id = p_account_id and status = 'old'
                 order by confirmed_at desc nulls last, id desc offset 2);
end
$$;

create or replace function public.cancel_password(p_account_id bigint)
returns void
language plpgsql security definer
set search_path = public
as $$
begin
  if public.my_role() is null then raise exception 'Ou pa gen aksè'; end if;
  delete from public.account_passwords where account_id = p_account_id and status = 'pending';
end
$$;

-- =====================================================================
--  Ekip
-- =====================================================================

-- Yon moun ki fèk enskri mande aksè. Premye moun ki enskri a vin
-- pwopriyetè prensipal (P1) otomatikman.
create or replace function public.request_access(p_name text)
returns text
language plpgsql security definer
set search_path = public
as $$
declare
  v_email text;
  v_first boolean;
begin
  if auth.uid() is null then raise exception 'Ou pa konekte'; end if;
  if exists (select 1 from public.app_users where id = auth.uid()) then
    return (select role from public.app_users where id = auth.uid());
  end if;
  select email into v_email from auth.users where id = auth.uid();
  lock table public.app_users in exclusive mode;
  v_first := not exists (select 1 from public.app_users);
  insert into public.app_users (id, name, email, role, code, principal)
  values (auth.uid(), coalesce(nullif(trim(p_name), ''), split_part(v_email, '@', 1)), v_email,
          case when v_first then 'owner' else 'pending' end,
          case when v_first then 'P1' end, v_first);
  return case when v_first then 'owner' else 'pending' end;
end
$$;

-- Pwopriyetè prensipal la bay yon wòl, chanje l, oswa retire yon moun
create or replace function public.set_member_role(p_user_id uuid, p_role text)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_u      public.app_users%rowtype;
  v_prefix text;
  v_n      int := 1;
begin
  if not public.is_principal() then
    raise exception 'Se pwopriyetè prensipal la sèlman ki jere ekip la';
  end if;
  select * into v_u from public.app_users where id = p_user_id for update;
  if not found then raise exception 'Moun sa a pa egziste'; end if;
  if v_u.principal then raise exception 'Ou pa ka chanje wòl pwopriyetè prensipal la'; end if;

  if p_role = 'remove' then
    delete from public.app_users where id = p_user_id;
    return;
  end if;
  if p_role not in ('owner', 'associate') then raise exception 'Wòl la pa valid'; end if;
  if v_u.role = p_role then return; end if;
  if (select count(*) from public.app_users where role = p_role and id <> p_user_id) >= 3 then
    raise exception 'Deja gen 3 %', case when p_role = 'owner' then 'pwopriyetè' else 'asosye' end;
  end if;

  v_prefix := case when p_role = 'owner' then 'P' else 'A' end;
  while exists (select 1 from public.app_users where code = v_prefix || v_n) loop
    v_n := v_n + 1;
  end loop;
  update public.app_users set role = p_role, code = v_prefix || v_n where id = p_user_id;
end
$$;

-- =====================================================================
--  PIN kliyan: chanje sèlman atravè set_client_pin, epi bloke X jou
-- =====================================================================
create or replace function public.guard_client_pin()
returns trigger
language plpgsql
as $$
begin
  if coalesce(current_setting('app.pin_ok', true), '') = '1' then
    return new;
  end if;
  if tg_op = 'INSERT' then
    new.pin := null; new.pin_set_at := null; new.pin_set_by := null;
  elsif new.pin is distinct from old.pin or new.pin_set_at is distinct from old.pin_set_at
        or new.pin_set_by is distinct from old.pin_set_by then
    raise exception 'Chanje PIN nan nan fich kliyan an';
  end if;
  return new;
end
$$;

drop trigger if exists clients_pin_guard on public.clients;
create trigger clients_pin_guard
  before insert or update on public.clients
  for each row execute function public.guard_client_pin();

create or replace function public.set_client_pin(p_client_id bigint, p_pin text)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_c     public.clients%rowtype;
  v_days  int;
  v_until timestamptz;
begin
  if public.my_role() is null then raise exception 'Ou pa gen aksè'; end if;
  if p_pin is null or p_pin !~ '^[0-9]{4}$' then raise exception 'PIN nan dwe gen 4 chif'; end if;
  select * into v_c from public.clients where id = p_client_id for update;
  if not found then raise exception 'Kliyan sa a pa egziste'; end if;
  select pin_lock_days into v_days from public.settings where id = 1;
  if v_c.pin_set_at is not null then
    v_until := v_c.pin_set_at + make_interval(days => v_days);
    if now() < v_until then
      raise exception 'PIN nan bloke jiska %', to_char(v_until, 'DD/MM/YYYY');
    end if;
  end if;
  perform set_config('app.pin_ok', '1', true);
  update public.clients set pin = p_pin, pin_set_at = now(), pin_set_by = auth.uid() where id = p_client_id;
  perform set_config('app.pin_ok', '', true);
end
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'request_access(text)', 'set_member_role(uuid,text)', 'set_client_pin(bigint,text)', 'is_principal()',
    'set_rate(numeric)', 'record_payment(bigint,numeric,text,int)',
    'add_card(bigint,bigint,numeric,numeric,text,date)', 'adjust_balance(bigint,bigint,numeric)',
    'process_billing()', 'propose_password(bigint,text)', 'confirm_password(bigint)',
    'cancel_password(bigint)', 'my_role()'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end
$$;

-- =====================================================================
--  Sekirite (Row Level Security)
--  Pwopriyetè: tout bagay.
--  Asosye: wè kont, plas siplemantè, kliyan ak modpas; ajoute/modifye
--          kliyan; anrejistre peman; jenere/konfime/voye modpas.
--          Li pa wè lajan (peman, kat kado, balans) e li pa efase anyen.
-- =====================================================================
alter table public.app_users         enable row level security;
alter table public.settings          enable row level security;
alter table public.accounts          enable row level security;
alter table public.extra_slots       enable row level security;
alter table public.clients           enable row level security;
alter table public.payments          enable row level security;
alter table public.card_ledger       enable row level security;
alter table public.account_passwords enable row level security;

drop policy if exists app_users_read on public.app_users;
create policy app_users_read on public.app_users for select to authenticated
  using (id = auth.uid() or public.my_role() in ('owner', 'associate'));
-- Pa gen okenn politik insert/update/delete sou app_users: tout chanjman
-- pase pa request_access ak set_member_role.

drop policy if exists settings_read on public.settings;
create policy settings_read on public.settings for select to authenticated
  using (public.my_role() in ('owner', 'associate'));

drop policy if exists accounts_read on public.accounts;
create policy accounts_read on public.accounts for select to authenticated
  using (public.my_role() in ('owner', 'associate'));
drop policy if exists accounts_owner on public.accounts;
create policy accounts_owner on public.accounts for all to authenticated
  using (public.my_role() = 'owner') with check (public.my_role() = 'owner');

drop policy if exists extra_read on public.extra_slots;
create policy extra_read on public.extra_slots for select to authenticated
  using (public.my_role() in ('owner', 'associate'));
drop policy if exists extra_owner on public.extra_slots;
create policy extra_owner on public.extra_slots for all to authenticated
  using (public.my_role() = 'owner') with check (public.my_role() = 'owner');

drop policy if exists clients_read on public.clients;
create policy clients_read on public.clients for select to authenticated
  using (public.my_role() in ('owner', 'associate'));
drop policy if exists clients_insert on public.clients;
create policy clients_insert on public.clients for insert to authenticated
  with check (public.my_role() in ('owner', 'associate'));
drop policy if exists clients_update on public.clients;
create policy clients_update on public.clients for update to authenticated
  using (public.my_role() in ('owner', 'associate')) with check (public.my_role() in ('owner', 'associate'));
drop policy if exists clients_delete on public.clients;
create policy clients_delete on public.clients for delete to authenticated
  using (public.my_role() = 'owner');

drop policy if exists payments_owner on public.payments;
create policy payments_owner on public.payments for select to authenticated
  using (public.my_role() = 'owner');

drop policy if exists ledger_owner on public.card_ledger;
create policy ledger_owner on public.card_ledger for select to authenticated
  using (public.my_role() = 'owner');

drop policy if exists passwords_read on public.account_passwords;
create policy passwords_read on public.account_passwords for select to authenticated
  using (public.my_role() in ('owner', 'associate'));
