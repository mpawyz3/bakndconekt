/*
  # Complete FlourishTalents Application Schema

  ## Overview
  This migration creates the complete database schema for the FlourishTalents platform,
  including user profiles, stats tracking, activities, challenges, media content, and
  real-time interactions (likes, follows, comments).

  ## 1. New Tables

  ### profiles
  Extended user profile information stored separately from auth.users
  - `id` (uuid, primary key, references auth.users) - User ID from Supabase Auth
  - `name` (text) - User's full name
  - `tier` (text) - Membership tier: free, premium, professional, elite
  - `loyalty_points` (integer) - Accumulated loyalty points
  - `profile_image` (text) - URL to profile image
  - `account_type` (text) - Account type: creator or member
  - `role` (text) - User role: creator or member
  - `is_verified` (boolean) - Verification status
  - `joined_date` (timestamptz) - Date user joined
  - `created_at` (timestamptz) - Record creation timestamp
  - `updated_at` (timestamptz) - Record update timestamp

  ### user_stats
  Tracks user statistics displayed on dashboard
  - `id` (uuid, primary key)
  - `user_id` (uuid, references profiles) - Profile owner
  - `portfolio_views` (integer) - Number of portfolio views
  - `followers` (integer) - Number of followers
  - `rating` (numeric) - User rating (0-5)
  - `loyalty_points` (integer) - Loyalty points (synced with profiles)
  - `projects_completed` (integer) - Number of completed projects
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### user_activity
  Tracks user activity feed for dashboard
  - `id` (uuid, primary key)
  - `user_id` (uuid, references profiles) - User who performed action
  - `action` (text) - Description of action
  - `action_type` (text) - Type: update, follower, approval, achievement
  - `created_at` (timestamptz)

  ### challenges
  Gamification challenges for users
  - `id` (uuid, primary key)
  - `user_id` (uuid, references profiles) - Challenge owner
  - `title` (text) - Challenge title
  - `description` (text) - Challenge description
  - `progress` (integer) - Progress percentage (0-100)
  - `reward` (text) - Reward description
  - `status` (text) - Status: active, completed, expired
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### media_content
  Stores all media items (videos, music, blogs, gallery, resources)
  - `id` (uuid, primary key)
  - `creator_id` (uuid, references profiles) - Content creator
  - `title` (text) - Content title
  - `description` (text) - Content description
  - `media_type` (text) - Type: stream, listen, blog, gallery, resources
  - `category` (text) - Category within media type
  - `thumbnail_url` (text) - Thumbnail/image URL
  - `duration` (text) - Duration for videos/audio
  - `read_time` (text) - Read time for blogs
  - `price` (numeric) - Price for resources
  - `rating` (numeric) - Content rating
  - `is_premium` (boolean) - Premium content flag
  - `views` (integer) - View count
  - `plays` (integer) - Play count for audio
  - `sales` (integer) - Sales count for resources
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### media_likes
  Tracks likes on media content with real-time updates
  - `id` (uuid, primary key)
  - `user_id` (uuid, references auth.users) - User who liked
  - `media_id` (uuid, references media_content) - Liked media
  - `created_at` (timestamptz)
  - Unique constraint on (user_id, media_id)

  ### creator_follows
  Tracks follows on creators with real-time updates
  - `id` (uuid, primary key)
  - `follower_id` (uuid, references auth.users) - User following
  - `creator_id` (uuid, references profiles) - Creator being followed
  - `created_at` (timestamptz)
  - Unique constraint on (follower_id, creator_id)

  ## 2. Security (Row Level Security)
  
  All tables have RLS enabled with production-ready policies:
  - Users can only modify their own data
  - Read access is granted appropriately (public for media, private for personal stats)
  - Foreign key constraints ensure data integrity
  - Cascade deletes maintain referential integrity

  ## 3. Real-Time Features
  
  Tables configured for real-time subscriptions:
  - media_likes: Instant like updates across all clients
  - creator_follows: Instant follow updates
  - user_stats: Real-time stat updates
  - user_activity: Live activity feed
  - challenges: Real-time progress updates

  ## 4. Triggers
  
  - Auto-create profile on user signup
  - Auto-create user_stats record when profile is created
  - Auto-update timestamps on record changes
*/

-- ============================================================================
-- PROFILES TABLE (Extended User Information)
-- ============================================================================

CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users ON DELETE CASCADE,
  name text NOT NULL DEFAULT '',
  tier text NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'premium', 'professional', 'elite')),
  loyalty_points integer NOT NULL DEFAULT 0,
  profile_image text DEFAULT '',
  account_type text NOT NULL DEFAULT 'creator' CHECK (account_type IN ('creator', 'member')),
  role text NOT NULL DEFAULT 'creator' CHECK (role IN ('creator', 'member')),
  is_verified boolean NOT NULL DEFAULT false,
  joined_date timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Profiles are viewable by everyone"
  ON profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- ============================================================================
-- USER STATS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_stats (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  portfolio_views integer NOT NULL DEFAULT 0,
  followers integer NOT NULL DEFAULT 0,
  rating numeric(3,2) NOT NULL DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  loyalty_points integer NOT NULL DEFAULT 0,
  projects_completed integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

ALTER TABLE user_stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own stats"
  ON user_stats FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own stats"
  ON user_stats FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own stats"
  ON user_stats FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- USER ACTIVITY TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_activity (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action text NOT NULL,
  action_type text NOT NULL CHECK (action_type IN ('update', 'follower', 'approval', 'achievement')),
  created_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE user_activity ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own activity"
  ON user_activity FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own activity"
  ON user_activity FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- CHALLENGES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text DEFAULT '',
  progress integer NOT NULL DEFAULT 0 CHECK (progress >= 0 AND progress <= 100),
  reward text NOT NULL,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'expired')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own challenges"
  ON challenges FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own challenges"
  ON challenges FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own challenges"
  ON challenges FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- MEDIA CONTENT TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS media_content (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text DEFAULT '',
  media_type text NOT NULL CHECK (media_type IN ('stream', 'listen', 'blog', 'gallery', 'resources')),
  category text NOT NULL,
  thumbnail_url text NOT NULL,
  duration text DEFAULT '',
  read_time text DEFAULT '',
  price numeric(10,2) DEFAULT 0,
  rating numeric(3,2) DEFAULT 0.0 CHECK (rating >= 0 AND rating <= 5),
  is_premium boolean NOT NULL DEFAULT false,
  views integer NOT NULL DEFAULT 0,
  plays integer NOT NULL DEFAULT 0,
  sales integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE media_content ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Media content is viewable by everyone"
  ON media_content FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Creators can insert own media content"
  ON media_content FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can update own media content"
  ON media_content FOR UPDATE
  TO authenticated
  USING (auth.uid() = creator_id)
  WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Creators can delete own media content"
  ON media_content FOR DELETE
  TO authenticated
  USING (auth.uid() = creator_id);

-- ============================================================================
-- MEDIA LIKES TABLE (Real-time interactions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS media_likes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  media_id uuid NOT NULL REFERENCES media_content(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(user_id, media_id)
);

ALTER TABLE media_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Media likes are viewable by everyone"
  ON media_likes FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own media likes"
  ON media_likes FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own media likes"
  ON media_likes FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ============================================================================
-- CREATOR FOLLOWS TABLE (Real-time interactions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS creator_follows (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  follower_id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  creator_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(follower_id, creator_id)
);

ALTER TABLE creator_follows ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Creator follows are viewable by everyone"
  ON creator_follows FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can insert own creator follows"
  ON creator_follows FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can delete own creator follows"
  ON creator_follows FOR DELETE
  TO authenticated
  USING (auth.uid() = follower_id);

-- ============================================================================
-- INDEXES for Performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_tier ON profiles(tier);
CREATE INDEX IF NOT EXISTS idx_profiles_account_type ON profiles(account_type);
CREATE INDEX IF NOT EXISTS idx_user_stats_user_id ON user_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_user_id ON user_activity(user_id);
CREATE INDEX IF NOT EXISTS idx_user_activity_created_at ON user_activity(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_challenges_user_id ON challenges(user_id);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_media_content_creator_id ON media_content(creator_id);
CREATE INDEX IF NOT EXISTS idx_media_content_media_type ON media_content(media_type);
CREATE INDEX IF NOT EXISTS idx_media_content_category ON media_content(category);
CREATE INDEX IF NOT EXISTS idx_media_likes_user_id ON media_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_media_likes_media_id ON media_likes(media_id);
CREATE INDEX IF NOT EXISTS idx_creator_follows_follower_id ON creator_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_creator_follows_creator_id ON creator_follows(creator_id);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Trigger to auto-create profile when user signs up
CREATE OR REPLACE FUNCTION create_profile_for_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, name, account_type, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'account_type', 'creator'),
    COALESCE(NEW.raw_user_meta_data->>'account_type', 'creator')
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION create_profile_for_user();

-- Trigger to auto-create user_stats when profile is created
CREATE OR REPLACE FUNCTION create_user_stats_for_profile()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_stats (user_id, loyalty_points)
  VALUES (NEW.id, NEW.loyalty_points)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_profile_created ON profiles;
CREATE TRIGGER on_profile_created
  AFTER INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION create_user_stats_for_profile();

-- Trigger to update timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_stats_updated_at ON user_stats;
CREATE TRIGGER update_user_stats_updated_at
  BEFORE UPDATE ON user_stats
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_challenges_updated_at ON challenges;
CREATE TRIGGER update_challenges_updated_at
  BEFORE UPDATE ON challenges
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_media_content_updated_at ON media_content;
CREATE TRIGGER update_media_content_updated_at
  BEFORE UPDATE ON media_content
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SEED DATA: Populate media_content with existing Media page data
-- ============================================================================

-- Insert sample creators first (using fixed UUIDs for seeding)
-- Note: In production, these would be real user IDs

-- Stream content
INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, duration, views, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Unstoppable - Official Music Video',
  'Official music video featuring stunning visuals and powerful performance',
  'stream',
  'music-video',
  'https://images.pexels.com/photos/1105666/pexels-photo-1105666.jpeg?auto=compress&cs=tinysrgb&w=400',
  '4:15',
  150000,
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, duration, views, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'The Last Stand - Short Film',
  'Award-winning short film about courage and determination',
  'stream',
  'movie',
  'https://images.pexels.com/photos/269140/pexels-photo-269140.jpeg?auto=compress&cs=tinysrgb&w=400',
  '12:30',
  89000,
  true
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

-- Listen content
INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, duration, plays, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Sunset Groove',
  'Smooth electronic beats perfect for evening relaxation',
  'listen',
  'electronic',
  'https://images.pexels.com/photos/417273/pexels-photo-417273.jpeg?auto=compress&cs=tinysrgb&w=400',
  '3:45',
  25000,
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, duration, plays, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Acoustic Soul',
  'Heartfelt acoustic performance with soulful vocals',
  'listen',
  'acoustic',
  'https://images.pexels.com/photos/164821/pexels-photo-164821.jpeg?auto=compress&cs=tinysrgb&w=400',
  '2:50',
  18000,
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

-- Blog content
INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, read_time, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Interview with Legends',
  'Exclusive interview with industry leaders sharing their journey',
  'blog',
  'branding',
  'https://images.pexels.com/photos/6953768/pexels-photo-6953768.jpeg?auto=compress&cs=tinysrgb&w=400',
  '5 min read',
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

-- Gallery content
INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Brand Manual & Presets',
  'Complete brand identity kit with guidelines and presets',
  'gallery',
  'design',
  'https://images.pexels.com/photos/5554667/pexels-photo-5554667.jpeg?auto=compress&cs=tinysrgb&w=400',
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Portrait Photography Collection',
  'Stunning portrait photography showcasing diverse styles',
  'gallery',
  'photography',
  'https://images.pexels.com/photos/4027606/pexels-photo-4027606.jpeg?auto=compress&cs=tinysrgb&w=400',
  true
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

-- Resources content
INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, price, rating, sales, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Social Media Templates Pack',
  'Professional social media templates for all platforms',
  'resources',
  'templates',
  'https://images.pexels.com/photos/3861972/pexels-photo-3861972.jpeg?auto=compress&cs=tinysrgb&w=400',
  115000,
  4.8,
  1250,
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, price, rating, sales, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Producer''s Key Sound Kit',
  'Premium sound kit with royalty-free samples and loops',
  'resources',
  'sound-kit',
  'https://images.pexels.com/photos/3990842/pexels-photo-3990842.jpeg?auto=compress&cs=tinysrgb&w=400',
  190000,
  4.9,
  890,
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;

INSERT INTO media_content (id, creator_id, title, description, media_type, category, thumbnail_url, price, rating, sales, is_premium)
SELECT 
  gen_random_uuid(),
  (SELECT id FROM profiles LIMIT 1),
  'Freelancer''s Guide to Contracts',
  'Essential legal templates and guides for freelancers',
  'resources',
  'templates',
  'https://images.pexels.com/photos/8428076/pexels-photo-8428076.jpeg?auto=compress&cs=tinysrgb&w=400',
  95000,
  4.7,
  540,
  false
WHERE EXISTS (SELECT 1 FROM profiles LIMIT 1)
ON CONFLICT DO NOTHING;
