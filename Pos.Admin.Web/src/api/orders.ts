import { apiClient } from './client';
import type {
  OrderResponse,
  OrderStatusUpdateRequest,
  PaymentCreateRequest,
  PaymentResponse,
} from '@/types/api';

export async function listOrders(): Promise<OrderResponse[]> {
  const { data } = await apiClient.get<OrderResponse[]>('/orders');
  return data;
}

export async function getOrder(id: string): Promise<OrderResponse> {
  const { data } = await apiClient.get<OrderResponse>(`/orders/${id}`);
  return data;
}

export async function updateOrderStatus(id: string, payload: OrderStatusUpdateRequest): Promise<OrderResponse> {
  const { data } = await apiClient.put<OrderResponse>(`/orders/${id}/status`, payload);
  return data;
}

export async function listPayments(orderId: string): Promise<PaymentResponse[]> {
  const { data } = await apiClient.get<PaymentResponse[]>(`/orders/${orderId}/payments`);
  return data;
}

export async function createPayment(orderId: string, payload: PaymentCreateRequest): Promise<PaymentResponse> {
  const { data } = await apiClient.post<PaymentResponse>(`/orders/${orderId}/payments`, payload);
  return data;
}
