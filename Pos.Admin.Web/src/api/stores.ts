import { apiClient } from './client';
import type { StoreCreateRequest, StoreResponse, StoreUpdateRequest } from '@/types/api';

export async function listStores(): Promise<StoreResponse[]> {
  const { data } = await apiClient.get<StoreResponse[]>('/stores');
  return data;
}

export async function createStore(payload: StoreCreateRequest): Promise<StoreResponse> {
  const { data } = await apiClient.post<StoreResponse>('/stores', payload);
  return data;
}

export async function updateStore(id: string, payload: StoreUpdateRequest): Promise<StoreResponse> {
  const { data } = await apiClient.put<StoreResponse>(`/stores/${id}`, payload);
  return data;
}
