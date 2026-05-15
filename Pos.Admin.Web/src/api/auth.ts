import { apiClient } from './client';
import type { LoginRequest, LoginResponse, TenantSignupRequest } from '@/types/api';

export async function login(payload: LoginRequest): Promise<LoginResponse> {
  const { data } = await apiClient.post<LoginResponse>('/auth/login', payload);
  return data;
}

export async function signup(payload: TenantSignupRequest): Promise<LoginResponse> {
  const { data } = await apiClient.post<LoginResponse>('/tenants/signup', payload);
  return data;
}
