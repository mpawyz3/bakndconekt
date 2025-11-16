/*
  # Fix Profile Creation Trigger

  This migration replaces the profile creation trigger with a more robust version
  that properly handles signup and ensures profile is created even if metadata is not provided.
  
  Changes:
  1. Drop old trigger
  2. Create new trigger function with better error handling
  3. Recreate trigger with AFTER INSERT event
*/

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS create_profile_for_user();

CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS TRIGGER AS $$
DECLARE
  v_name text;
  v_account_type text;
BEGIN
  -- Extract values from metadata, with fallbacks
  v_name := COALESCE(NEW.raw_user_meta_data->>'name', NEW.email, '');
  v_account_type := COALESCE(NEW.raw_user_meta_data->>'account_type', 'creator');

  INSERT INTO profiles (
    id,
    name,
    tier,
    loyalty_points,
    profile_image,
    account_type,
    role,
    is_verified,
    joined_date,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    v_name,
    'free',
    0,
    '',
    v_account_type,
    v_account_type,
    false,
    now(),
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in create_profile_for_user: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_user();

-- Also ensure the user_stats trigger is working
DROP TRIGGER IF EXISTS on_profile_created ON profiles;
DROP FUNCTION IF EXISTS create_user_stats_for_profile();

CREATE OR REPLACE FUNCTION create_user_stats_for_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_stats (
    user_id,
    portfolio_views,
    followers,
    rating,
    loyalty_points,
    projects_completed,
    created_at,
    updated_at
  )
  VALUES (
    NEW.id,
    0,
    0,
    0.0,
    NEW.loyalty_points,
    0,
    now(),
    now()
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'Error in create_user_stats_for_profile: %', SQLERRM;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_profile_created
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION create_user_stats_for_profile();
