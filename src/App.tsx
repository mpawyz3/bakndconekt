import React, { useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Navbar from './components/Navbar';
import LandingPage from './pages/LandingPage';
import SignIn from './pages/SignIn';
import SignUp from './pages/SignUp';
import Dashboard from './pages/Dashboard';
import Portfolio from './pages/Portfolio';
import Media from './pages/Media';
import Masterclass from './pages/Masterclass';
import Projects from './pages/Projects';
import HelpCenter from './pages/HelpCenter';
import Events from './pages/Events';
import Profile from './pages/Profile';
import CreatorMembership from './pages/CreatorMembership';
import MemberMembership from './pages/MemberMembership';
import Content from './pages/Content';
import Account from './pages/Account';
import Connect from './pages/Connect';
import CareerGuidance from './pages/CareerGuidance';
import Settings from './pages/Settings';
import { AuthProvider, useAuth } from './context/AuthContext';
import { supabase } from './lib/supabase';
import './App.css';

function AppContent() {
  const { user, loading } = useAuth();

  useEffect(() => {
    // Initialize Supabase auth listener
    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      // Auth state is managed by AuthContext, this just keeps the connection alive
      if (_event === 'SIGNED_OUT') {
        // Handle any sign-out side effects if needed
      }
    });

    return () => {
      subscription.unsubscribe();
    };
  }, []);

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-900 flex items-center justify-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-white"></div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-900">
      <Router>
        <Navbar />
        <Routes>
          <Route path="/" element={user ? <Navigate to="/dashboard" /> : <LandingPage />} />
          <Route path="/signin" element={user ? <Navigate to="/dashboard" /> : <SignIn />} />
          <Route path="/signup" element={user ? <Navigate to="/dashboard" /> : <SignUp />} />
          <Route path="/dashboard" element={user ? <Dashboard /> : <Navigate to="/" />} />
          <Route path="/portfolio" element={user ? <Portfolio /> : <Navigate to="/" />} />
          <Route path="/settings" element={user ? <Settings /> : <Navigate to="/" />} />
          <Route path="/media" element={<Media />} />
          <Route path="/masterclass" element={<Masterclass />} />
          <Route path="/projects" element={<Projects />} />
          <Route path="/events" element={<Events />} />
          <Route path="/profile" element={user ? <Profile /> : <Navigate to="/" />} />
          <Route path="/creator-membership" element={user ? <CreatorMembership /> : <Navigate to="/" />} />
          <Route path="/member-membership" element={user ? <MemberMembership /> : <Navigate to="/" />} />
          <Route path="/content" element={user ? <Content /> : <Navigate to="/" />} />
          <Route path="/account" element={user ? <Account /> : <Navigate to="/" />} />
          <Route path="/connect" element={user ? <Connect /> : <Navigate to="/" />} />
          <Route path="/career-guidance/:masterclassId" element={user ? <CareerGuidance /> : <Navigate to="/" />} />
          <Route path="/help-center" element={<HelpCenter />} />
        </Routes>
      </Router>
    </div>
  );
}

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;
