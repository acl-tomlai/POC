import type { ReactNode } from 'react';
import { useAuthStore } from './authStore';
import type { Role } from '@/types/api';

interface RoleGateProps {
  roles: Role[];
  children: ReactNode;
  fallback?: ReactNode;
}

export function RoleGate({ roles, children, fallback = null }: RoleGateProps) {
  const role = useAuthStore((s) => s.user?.role);
  if (!role || !roles.includes(role)) return <>{fallback}</>;
  return <>{children}</>;
}

export function useHasRole(roles: Role[]): boolean {
  const role = useAuthStore((s) => s.user?.role);
  return !!role && roles.includes(role);
}
