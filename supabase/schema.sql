-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- Profiles table (public profile info)
create table public.profiles (
  id uuid references auth.users not null primary key,
  username text,
  avatar_url text,
  updated_at timestamp with time zone
);

-- Inbound APIs table
create table public.inbound_apis (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid, -- Nullable to allow guest users
  path text not null,
  method text not null default 'GET',
  response_body jsonb default '{}'::jsonb,
  response_headers jsonb default '{}'::jsonb,
  response_status integer default 200,
  auth_token text, -- Optional authentication token
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  constraint unique_path_method unique(path, method)
);

-- Outbound Requests table
create table public.outbound_requests (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  name text not null,
  url text not null,
  method text not null default 'GET',
  headers jsonb default '{}'::jsonb,
  body jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Logs table
create table public.logs (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users,
  type text not null, -- 'inbound' or 'outbound'
  method text not null,
  url text not null,
  status integer,
  duration_ms integer,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- RLS Policies
alter table public.profiles enable row level security;
-- RLS disabled for inbound_apis to allow public mock endpoint access
-- alter table public.inbound_apis enable row level security;
alter table public.outbound_requests enable row level security;
alter table public.logs enable row level security;

create policy "Public profiles are viewable by everyone." on public.profiles for select using (true);
create policy "Users can insert their own profile." on public.profiles for insert with check (auth.uid() = id);
create policy "Users can update own profile." on public.profiles for update using (auth.uid() = id);

-- RLS policies for inbound_apis disabled (RLS is off for this table)
-- create policy "Users can view own inbound apis." on public.inbound_apis for select using (auth.uid() = user_id OR user_id IS NULL);
-- create policy "Users can insert own inbound apis." on public.inbound_apis for insert with check (auth.uid() = user_id OR user_id IS NULL);
-- create policy "Users can update own inbound apis." on public.inbound_apis for update using (auth.uid() = user_id OR user_id IS NULL);
-- create policy "Users can delete own inbound apis." on public.inbound_apis for delete using (auth.uid() = user_id OR user_id IS NULL);

create policy "Users can view own outbound requests." on public.outbound_requests for select using (auth.uid() = user_id);
create policy "Users can insert own outbound requests." on public.outbound_requests for insert with check (auth.uid() = user_id);
create policy "Users can update own outbound requests." on public.outbound_requests for update using (auth.uid() = user_id);
create policy "Users can delete own outbound requests." on public.outbound_requests for delete using (auth.uid() = user_id);

create policy "Users can view own logs." on public.logs for select using (auth.uid() = user_id);
create policy "Users can insert own logs." on public.logs for insert with check (auth.uid() = user_id);
