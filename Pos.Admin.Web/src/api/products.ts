import { apiClient } from './client';
import type { ProductCreateRequest, ProductResponse, ProductUpdateRequest } from '@/types/api';

export async function listProducts(): Promise<ProductResponse[]> {
  const { data } = await apiClient.get<ProductResponse[]>('/products');
  return data;
}

export async function createProduct(payload: ProductCreateRequest): Promise<ProductResponse> {
  const { data } = await apiClient.post<ProductResponse>('/products', payload);
  return data;
}

export async function updateProduct(id: string, payload: ProductUpdateRequest): Promise<ProductResponse> {
  const { data } = await apiClient.put<ProductResponse>(`/products/${id}`, payload);
  return data;
}

export async function deleteProduct(id: string): Promise<void> {
  await apiClient.delete(`/products/${id}`);
}
