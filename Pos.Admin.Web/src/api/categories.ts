import { apiClient } from './client';
import type { CategoryCreateRequest, CategoryResponse, CategoryUpdateRequest } from '@/types/api';

export async function listCategories(): Promise<CategoryResponse[]> {
  const { data } = await apiClient.get<CategoryResponse[]>('/categories');
  return data;
}

export async function createCategory(payload: CategoryCreateRequest): Promise<CategoryResponse> {
  const { data } = await apiClient.post<CategoryResponse>('/categories', payload);
  return data;
}

export async function updateCategory(id: string, payload: CategoryUpdateRequest): Promise<CategoryResponse> {
  const { data } = await apiClient.put<CategoryResponse>(`/categories/${id}`, payload);
  return data;
}

export async function deleteCategory(id: string): Promise<void> {
  await apiClient.delete(`/categories/${id}`);
}
