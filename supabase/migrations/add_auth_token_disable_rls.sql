-- Migration: Add auth_token column and disable RLS for inbound_apis
-- Created: 2025-11-30

-- Add auth_token column to inbound_apis table
ALTER TABLE public.inbound_apis 
ADD COLUMN IF NOT EXISTS auth_token text;

-- Disable RLS on inbound_apis table
ALTER TABLE public.inbound_apis DISABLE ROW LEVEL SECURITY;

-- Drop existing RLS policies for inbound_apis
DROP POLICY IF EXISTS "Users can view own inbound apis." ON public.inbound_apis;
DROP POLICY IF EXISTS "Users can insert own inbound apis." ON public.inbound_apis;
DROP POLICY IF EXISTS "Users can update own inbound apis." ON public.inbound_apis;
DROP POLICY IF EXISTS "Users can delete own inbound apis." ON public.inbound_apis;
