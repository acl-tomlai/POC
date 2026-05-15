import { apiClient } from './client';
import type { TenantResponse, TenantUpdateRequest } from '@/types/api';

export async function getCurrentTenant(): Promise<TenantResponse> {
  const { data } = await apiClient.get<TenantResponse>('/tenants/me');
  return data;
}

export async function updateCurrentTenant(payload: TenantUpdateRequest): Promise<TenantResponse> {
  const { data } = await apiClient.put<TenantResponse>('/tenants/me', payload);
  return data;
}
