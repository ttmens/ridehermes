import { create } from 'zustand';
import { getToken, setToken, clearToken } from '@/utils/token';

interface AuthUser {
  id: number;
  phone: string;
  nickname: string;
  role: number;
}

interface AuthState {
  token: string | null;
  user: AuthUser | null;
  isAuthenticated: boolean;
  setAuth: (token: string, user: AuthUser) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  token: getToken(),
  user: null,
  get isAuthenticated() {
    return !!this.token;
  },
  setAuth: (token, user) => {
    setToken(token);
    set({ token, user });
  },
  logout: () => {
    clearToken();
    set({ token: null, user: null });
  },
}));
