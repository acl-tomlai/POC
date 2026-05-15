import { apiClient } from './client';
import type { PrinterCreateRequest, PrinterResponse, PrinterUpdateRequest } from '@/types/api';

export async function listPrintersForStore(storeId: string): Promise<PrinterResponse[]> {
  const { data } = await apiClient.get<PrinterResponse[]>(`/stores/${storeId}/printers`);
  return data;
}

export async function createPrinter(payload: PrinterCreateRequest): Promise<PrinterResponse> {
  const { data } = await apiClient.post<PrinterResponse>('/printers', payload);
  return data;
}

export async function updatePrinter(id: string, payload: PrinterUpdateRequest): Promise<PrinterResponse> {
  const { data } = await apiClient.put<PrinterResponse>(`/printers/${id}`, payload);
  return data;
}

export async function deletePrinter(id: string): Promise<void> {
  await apiClient.delete(`/printers/${id}`);
}
