import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import type { LoginResponse, Role } from '@/types/api';

interface AuthUser {
  userId: string;
  fullName: string;
  email: string;
  role: Role;
  restaurantId: string;
  restaurantName: string;
  restaurantSlug: string;
}

interface AuthState {
  token: string | null;
  user: AuthUser | null;
  signIn: (response: LoginResponse) => void;
  signOut: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      signIn: (response) =>
        set({
          token: response.token,
          user: {
            userId: response.userId,
            fullName: response.fullName,
            email: response.email,
            role: response.role,
            restaurantId: response.restaurantId,
            restaurantName: response.restaurantName,
            restaurantSlug: response.restaurantSlug,
          },
        }),
      signOut: () => set({ token: null, user: null }),
    }),
    { name: 'pos-admin-auth' }
  )
);
