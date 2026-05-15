import { apiClient } from './client';
import type { UserCreateRequest, UserResponse, UserUpdateRequest } from '@/types/api';

export async function listUsers(): Promise<UserResponse[]> {
  const { data } = await apiClient.get<UserResponse[]>('/users');
  return data;
}

export async function createUser(payload: UserCreateRequest): Promise<UserResponse> {
  const { data } = await apiClient.post<UserResponse>('/users', payload);
  return data;
}

export async function updateUser(id: string, payload: UserUpdateRequest): Promise<UserResponse> {
  const { data } = await apiClient.put<UserResponse>(`/users/${id}`, payload);
  return data;
}

export async function deleteUser(id: string): Promise<void> {
  await apiClient.delete(`/users/${id}`);
}
