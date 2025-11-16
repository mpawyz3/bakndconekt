import { createClient } from '@supabase/supabase-js';

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
    storage: window.localStorage
  }
});

export interface Profile {
  id: string;
  name: string;
  tier: 'free' | 'premium' | 'professional' | 'elite';
  loyalty_points: number;
  profile_image?: string;
  account_type: 'creator' | 'member';
  role: 'creator' | 'member';
  is_verified: boolean;
  joined_date: string;
  created_at: string;
  updated_at: string;
}

export interface UserStats {
  id: string;
  user_id: string;
  portfolio_views: number;
  followers: number;
  rating: number;
  loyalty_points: number;
  projects_completed: number;
  created_at: string;
  updated_at: string;
}

export interface UserActivity {
  id: string;
  user_id: string;
  action: string;
  action_type: 'update' | 'follower' | 'approval' | 'achievement';
  created_at: string;
}

export interface Challenge {
  id: string;
  user_id: string;
  title: string;
  description?: string;
  progress: number;
  reward: string;
  status: 'active' | 'completed' | 'expired';
  created_at: string;
  updated_at: string;
}

export interface MediaContent {
  id: string;
  creator_id: string;
  title: string;
  description?: string;
  media_type: 'stream' | 'listen' | 'blog' | 'gallery' | 'resources';
  category: string;
  thumbnail_url: string;
  duration?: string;
  read_time?: string;
  price?: number;
  rating?: number;
  is_premium: boolean;
  views: number;
  plays: number;
  sales: number;
  created_at: string;
  updated_at: string;
}

export interface MediaLike {
  id: string;
  user_id: string;
  media_id: string;
  created_at: string;
}

export interface CreatorFollow {
  id: string;
  follower_id: string;
  creator_id: string;
  created_at: string;
}
