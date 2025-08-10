import { useEffect } from 'react';
import { supabase } from './supabase-client';

export default function AuthListener() {
  useEffect(() => {
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event, session) => {
      console.log('Auth event:', event, session);
    });

    return () => subscription.unsubscribe();
  }, []);

  return null;
}
