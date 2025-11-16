import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Play, Image, Headphones, ShoppingBag, Heart, Share2, MessageCircle, Eye, Filter, Search, Star, Download, Rss } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { supabase } from '../lib/supabase';
import type { MediaContent, MediaLike, CreatorFollow } from '../lib/supabase';

export default function MediaNew() {
  const { user } = useAuth();
  const navigate = useNavigate();
  const [activeTab, setActiveTab] = useState('stream');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [mediaContent, setMediaContent] = useState<MediaContent[]>([]);
  const [userLikes, setUserLikes] = useState<Set<string>>(new Set());
  const [userFollows, setUserFollows] = useState<Set<string>>(new Set());
  const [loading, setLoading] = useState(true);
  const [likeCounts, setLikeCounts] = useState<Record<string, number>>({});

  const categories = {
    stream: ['all', 'movie', 'music-video', 'documentaries', 'lifestyle', 'Go Live'],
    listen: ['all', 'greatest-of-all-time', 'latest-release', 'new-talent', 'DJ-mixtapes', 'UG-Unscripted', 'Afrobeat', 'hip-hop', 'RnB', 'Others'],
    blog: ['all', 'interviews', 'lifestyle', 'product-reviews', 'others'],
    gallery: ['all', 'design', 'photography', 'art', 'others'],
    resources: ['all', 'templates', 'ebooks', 'software', 'presets']
  };

  const tabs = [
    { id: 'stream', label: 'Stream', icon: <Play className="w-5 h-5" /> },
    { id: 'listen', label: 'Listen', icon: <Headphones className="w-5 h-5" /> },
    { id: 'blog', label: 'Blog', icon: <Rss className="w-5 h-5" /> },
    { id: 'gallery', label: 'Gallery', icon: <Image className="w-5 h-5" /> },
    { id: 'resources', label: 'Resources', icon: <ShoppingBag className="w-5 h-5" /> }
  ];

  // Fetch media content from database
  useEffect(() => {
    fetchMediaContent();
  }, [activeTab, searchQuery, selectedCategory]);

  // Fetch user's likes and follows
  useEffect(() => {
    if (user) {
      fetchUserLikes();
      fetchUserFollows();
    }
  }, [user]);

  // Subscribe to real-time updates for likes
  useEffect(() => {
    const channel = supabase
      .channel('media_likes_changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'media_likes' },
        async () => {
          await fetchUserLikes();
          await fetchLikeCounts();
        }
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, []);

  // Subscribe to real-time updates for follows
  useEffect(() => {
    const channel = supabase
      .channel('creator_follows_changes')
      .on(
        'postgres_changes',
        { event: '*', schema: 'public', table: 'creator_follows' },
        async () => {
          await fetchUserFollows();
        }
      )
      .subscribe();

    return () => {
      channel.unsubscribe();
    };
  }, []);

  const fetchMediaContent = async () => {
    setLoading(true);
    let query = supabase
      .from('media_content')
      .select('*')
      .eq('media_type', activeTab);

    if (selectedCategory !== 'all') {
      query = query.eq('category', selectedCategory);
    }

    if (searchQuery) {
      query = query.or(`title.ilike.%${searchQuery}%,description.ilike.%${searchQuery}%`);
    }

    const { data, error } = await query.order('created_at', { ascending: false });

    if (error) {
      console.error('Error fetching media:', error);
    } else {
      setMediaContent(data || []);
      await fetchLikeCounts();
    }
    setLoading(false);
  };

  const fetchUserLikes = async () => {
    if (!user) return;
    const { data } = await supabase
      .from('media_likes')
      .select('media_id')
      .eq('user_id', user.id);

    if (data) {
      setUserLikes(new Set(data.map(like => like.media_id)));
    }
  };

  const fetchUserFollows = async () => {
    if (!user) return;
    const { data } = await supabase
      .from('creator_follows')
      .select('creator_id')
      .eq('follower_id', user.id);

    if (data) {
      setUserFollows(new Set(data.map(follow => follow.creator_id)));
    }
  };

  const fetchLikeCounts = async () => {
    const { data } = await supabase
      .from('media_likes')
      .select('media_id');

    if (data) {
      const counts: Record<string, number> = {};
      data.forEach(like => {
        counts[like.media_id] = (counts[like.media_id] || 0) + 1;
      });
      setLikeCounts(counts);
    }
  };

  const handleLike = async (mediaId: string) => {
    if (!user) {
      alert('Please sign in to like content.');
      navigate('/signin');
      return;
    }

    const isLiked = userLikes.has(mediaId);

    if (isLiked) {
      // Unlike
      const { error } = await supabase
        .from('media_likes')
        .delete()
        .eq('user_id', user.id)
        .eq('media_id', mediaId);

      if (!error) {
        setUserLikes(prev => {
          const newSet = new Set(prev);
          newSet.delete(mediaId);
          return newSet;
        });
      }
    } else {
      // Like
      const { error } = await supabase
        .from('media_likes')
        .insert({ user_id: user.id, media_id: mediaId });

      if (!error) {
        setUserLikes(prev => new Set(prev).add(mediaId));
      }
    }
  };

  const handleFollow = async (creatorId: string) => {
    if (!user) {
      alert('Please sign up or sign in to follow creators.');
      navigate('/signin');
      return;
    }

    const isFollowing = userFollows.has(creatorId);

    if (isFollowing) {
      // Unfollow
      const { error } = await supabase
        .from('creator_follows')
        .delete()
        .eq('follower_id', user.id)
        .eq('creator_id', creatorId);

      if (!error) {
        setUserFollows(prev => {
          const newSet = new Set(prev);
          newSet.delete(creatorId);
          return newSet;
        });
      }
    } else {
      // Follow
      const { error } = await supabase
        .from('creator_follows')
        .insert({ follower_id: user.id, creator_id: creatorId });

      if (!error) {
        setUserFollows(prev => new Set(prev).add(creatorId));
      }
    }
  };

  const handleSubscribe = (creatorId: string) => {
    if (!user) {
      alert('Please sign in to subscribe.');
      navigate('/signin');
      return;
    }
    alert('Premium subscription activated! Enjoy exclusive content.');
  };

  const filteredContent = mediaContent;

  return (
    <div className="min-h-screen pt-20 pb-12 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="mb-8">
          <h1 className="text-4xl font-playfair font-bold text-white mb-2">Media</h1>
          <p className="text-gray-300">Celebrate amazing content from the Creators of your choice.</p>
        </div>

        <div className="flex space-x-1 mb-8 glass-effect p-2 rounded-xl overflow-x-auto whitespace-nowrap">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex-shrink-0 flex items-center space-x-2 px-6 py-3 rounded-lg font-medium transition-all duration-300 ${
                activeTab === tab.id
                  ? 'bg-gradient-to-r from-rose-500 to-purple-600 text-white shadow-lg'
                  : 'text-gray-300 hover:text-white hover:bg-white/10'
              }`}
            >
              {tab.icon}
              <span>{tab.label}</span>
            </button>
          ))}
        </div>

        <div className="flex flex-col md:flex-row gap-4 mb-8">
          <div className="flex-1 relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
            <input
              type="text"
              placeholder="Search content..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-3 glass-effect rounded-xl border border-white/20 text-white placeholder-gray-400 focus:ring-2 focus:ring-rose-400 focus:border-transparent transition-all"
            />
          </div>

          <div className="flex items-center space-x-4">
            <Filter className="text-gray-400 w-5 h-5" />
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-4 py-3 glass-effect rounded-xl border border-white/20 text-white bg-transparent focus:ring-2 focus:ring-rose-400 focus:border-transparent transition-all"
            >
              {categories[activeTab as keyof typeof categories]?.map((category) => (
                <option key={category} value={category} className="bg-gray-800">
                  {category.charAt(0).toUpperCase() + category.slice(1)}
                </option>
              ))}
            </select>
          </div>
        </div>

        {loading ? (
          <div className="flex justify-center items-center py-12">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-rose-400"></div>
          </div>
        ) : (
          <div className="grid md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredContent.map((item) => {
              const isLiked = userLikes.has(item.id);
              const isFollowing = userFollows.has(item.creator_id);
              const likeCount = likeCounts[item.id] || 0;

              return (
                <div key={item.id} className="glass-effect rounded-2xl overflow-hidden hover-lift group">
                  <div className="relative aspect-video bg-gray-800">
                    <img
                      src={item.thumbnail_url}
                      alt={item.title}
                      className="w-full h-full object-cover"
                    />

                    <div className="absolute inset-0 bg-black/50 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                      {activeTab === 'stream' && <Play className="w-12 h-12 text-white" />}
                      {activeTab === 'listen' && <Headphones className="w-12 h-12 text-white" />}
                      {activeTab === 'blog' && <Rss className="w-12 h-12 text-white" />}
                      {activeTab === 'resources' && <ShoppingBag className="w-12 h-12 text-white" />}
                    </div>

                    {item.is_premium && (
                      <div className="absolute top-2 right-2 px-2 py-1 bg-gradient-to-r from-yellow-400 to-orange-500 text-black text-xs font-bold rounded-full">
                        PREMIUM
                      </div>
                    )}

                    {item.duration && (
                      <div className="absolute bottom-2 right-2 px-2 py-1 bg-black/70 text-white text-xs rounded">
                        {item.duration}
                      </div>
                    )}
                    {item.read_time && (
                      <div className="absolute bottom-2 right-2 px-2 py-1 bg-black/70 text-white text-xs rounded">
                        {item.read_time}
                      </div>
                    )}
                  </div>

                  <div className="p-4">
                    <h3 className="text-white font-semibold mb-2 line-clamp-2">{item.title}</h3>
                    <p className="text-gray-400 text-sm mb-3">by Creator</p>

                    <div className="flex items-center justify-between text-sm text-gray-400 mb-4">
                      {activeTab === 'stream' && (
                        <>
                          <div className="flex items-center space-x-1">
                            <Eye className="w-4 h-4" />
                            <span>{item.views.toLocaleString()}</span>
                          </div>
                          <div className="flex items-center space-x-1">
                            <Heart className={`w-4 h-4 ${isLiked ? 'fill-rose-500 text-rose-500' : ''}`} />
                            <span>{likeCount}</span>
                          </div>
                        </>
                      )}
                      {activeTab === 'listen' && (
                        <div className="flex items-center space-x-1">
                          <Play className="w-4 h-4" />
                          <span>{item.plays.toLocaleString()} plays</span>
                        </div>
                      )}
                      {activeTab === 'gallery' && (
                        <div className="flex items-center space-x-1">
                          <Heart className={`w-4 h-4 ${isLiked ? 'fill-rose-500 text-rose-500' : ''}`} />
                          <span>{likeCount}</span>
                        </div>
                      )}
                      {activeTab === 'resources' && (
                        <>
                          <div className="flex items-center space-x-1">
                            <Star className="w-4 h-4 text-yellow-400" />
                            <span>{item.rating?.toFixed(1) || '0.0'}</span>
                          </div>
                          <div className="text-rose-400 font-bold">UGX {item.price?.toLocaleString()}</div>
                        </>
                      )}
                    </div>

                    <div className="flex space-x-2">
                      {activeTab === 'resources' ? (
                        <>
                          <button className="flex-1 py-2 bg-gradient-to-r from-rose-500 to-purple-600 text-white rounded-lg hover:shadow-lg transition-all text-sm font-medium">
                            Buy Now
                          </button>
                          <button className="p-2 glass-effect text-gray-400 hover:text-white rounded-lg transition-colors">
                            <Download className="w-4 h-4" />
                          </button>
                        </>
                      ) : (
                        <>
                          <button
                            onClick={() => handleFollow(item.creator_id)}
                            className={`flex-1 py-2 rounded-lg hover:shadow-lg transition-all text-sm font-medium ${
                              isFollowing
                                ? 'bg-gray-600 text-white'
                                : 'bg-gradient-to-r from-rose-500 to-purple-600 text-white'
                            }`}
                          >
                            {isFollowing ? 'Following' : 'Follow'}
                          </button>
                          <button
                            onClick={() => handleLike(item.id)}
                            className={`p-2 glass-effect rounded-lg transition-colors ${
                              isLiked ? 'text-rose-500' : 'text-gray-400 hover:text-white'
                            }`}
                          >
                            <Heart className={`w-4 h-4 ${isLiked ? 'fill-current' : ''}`} />
                          </button>
                          <button className="p-2 glass-effect text-gray-400 hover:text-white rounded-lg transition-colors">
                            <Share2 className="w-4 h-4" />
                          </button>
                        </>
                      )}
                    </div>

                    {item.is_premium && user?.tier === 'free' && (
                      <div className="mt-3 p-3 bg-gradient-to-r from-yellow-400/20 to-orange-500/20 border border-yellow-400/30 rounded-lg">
                        <p className="text-yellow-400 text-xs mb-2">Premium content - Subscribe to unlock</p>
                        <button
                          onClick={() => handleSubscribe(item.creator_id)}
                          className="w-full py-1 bg-gradient-to-r from-yellow-400 to-orange-500 text-black text-xs font-bold rounded"
                        >
                          Subscribe Now
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}

        {!loading && filteredContent.length === 0 && (
          <div className="text-center py-12">
            <div className="text-gray-400 mb-4">
              {activeTab === 'stream' && <Play className="w-16 h-16 mx-auto mb-4" />}
              {activeTab === 'listen' && <Headphones className="w-16 h-16 mx-auto mb-4" />}
              {activeTab === 'blog' && <Rss className="w-16 h-16 mx-auto mb-4" />}
              {activeTab === 'gallery' && <Image className="w-16 h-16 mx-auto mb-4" />}
              {activeTab === 'resources' && <ShoppingBag className="w-16 h-16 mx-auto mb-4" />}
            </div>
            <h3 className="text-xl font-semibold text-white mb-2">No content available</h3>
            <p className="text-gray-400">Check back later for new {activeTab} content!</p>
          </div>
        )}
      </div>
    </div>
  );
}
