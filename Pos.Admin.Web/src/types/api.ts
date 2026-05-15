export type Role = 'Admin' | 'Manager' | 'Cashier';

export const ROLES: Role[] = ['Admin', 'Manager', 'Cashier'];

export interface LoginRequest {
  email: string;
  password: string;
}

export interface LoginResponse {
  token: string;
  userId: string;
  fullName: string;
  email: string;
  role: Role;
  restaurantId: string;
  restaurantName: string;
  restaurantSlug: string;
}

export interface TenantSignupRequest {
  restaurant: {
    name: string;
    slug: string;
    contactEmail: string;
    phone?: string | null;
  };
  admin: {
    fullName: string;
    email: string;
    password: string;
  };
}

export interface TenantResponse {
  id: string;
  name: string;
  slug: string;
  contactEmail: string;
  phone?: string | null;
  isActive: boolean;
  createdAt: string;
}

export interface TenantUpdateRequest {
  name: string;
  contactEmail: string;
  phone?: string | null;
}

export interface UserResponse {
  id: string;
  fullName: string;
  email: string;
  role: Role;
  isActive: boolean;
  createdAt: string;
}

export interface UserCreateRequest {
  fullName: string;
  email: string;
  password: string;
  role: Role;
}

export interface UserUpdateRequest {
  fullName: string;
  role: Role;
  isActive: boolean;
}

export interface CategoryResponse {
  id: string;
  name: string;
  displayOrder: number;
  isActive: boolean;
  createdAt: string;
}

export interface CategoryCreateRequest {
  name: string;
  displayOrder: number;
  isActive: boolean;
}

export type CategoryUpdateRequest = CategoryCreateRequest;

export interface ProductResponse {
  id: string;
  categoryId: string;
  categoryName: string;
  name: string;
  description?: string | null;
  sku?: string | null;
  barcode?: string | null;
  price: number;
  costPrice?: number | null;
  imageUrl?: string | null;
  isActive: boolean;
  createdAt: string;
}

export interface ProductCreateRequest {
  categoryId: string;
  name: string;
  description?: string | null;
  sku?: string | null;
  barcode?: string | null;
  price: number;
  costPrice?: number | null;
  imageUrl?: string | null;
  isActive: boolean;
}

export type ProductUpdateRequest = ProductCreateRequest;

export interface StoreResponse {
  id: string;
  name: string;
  address?: string | null;
  phone?: string | null;
  isActive: boolean;
  createdAt: string;
}

export interface StoreCreateRequest {
  name: string;
  address?: string | null;
  phone?: string | null;
  isActive: boolean;
}

export type StoreUpdateRequest = StoreCreateRequest;

export type PrinterType = 'Receipt' | 'Kitchen' | 'Label';

export const PRINTER_TYPES: PrinterType[] = ['Receipt', 'Kitchen', 'Label'];

export interface PrinterResponse {
  id: string;
  storeId: string;
  name: string;
  ipAddress: string;
  port: number;
  printerType: string;
  isActive: boolean;
  createdAt: string;
}

export interface PrinterCreateRequest {
  storeId: string;
  name: string;
  ipAddress: string;
  port: number;
  printerType: string;
  isActive: boolean;
}

export type PrinterUpdateRequest = PrinterCreateRequest;

export interface OrderLineResponse {
  id: string;
  productId: string;
  productName: string;
  quantity: number;
  unitPrice: number;
  discountAmount: number;
  lineTotal: number;
}

export interface PaymentResponse {
  id: string;
  paymentMethod: string;
  amount: number;
  reference?: string | null;
  paidAt: string;
}

export interface OrderResponse {
  id: string;
  storeId: string;
  orderNumber: string;
  status: string;
  subtotal: number;
  taxAmount: number;
  discountAmount: number;
  totalAmount: number;
  paymentStatus: string;
  createdByUserId: string;
  createdAt: string;
  lines: OrderLineResponse[];
  payments: PaymentResponse[];
}

export interface OrderStatusUpdateRequest {
  status: string;
}

export interface PaymentCreateRequest {
  paymentMethod: string;
  amount: number;
  reference?: string | null;
}

export interface ApiError {
  type?: string;
  title?: string;
  status?: number;
  detail?: string;
  errors?: Record<string, string[]>;
}
