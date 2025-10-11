export interface User {
  id: number;
  email: string;
  username: string;
  full_name: string;
  first_name?: string;
  last_name?: string;
  role: 'owner' | 'renter';
  is_active: boolean;
  created_at: string;
  updated_at?: string;
}

export interface Property {
  id: number;
  owner_id: number;
  title: string;
  address: string;
  property_type: string;
  bedrooms: number;
  bathrooms: number;
  area: number;
  rent_amount: number;
  deposit_amount?: number;
  description?: string;
  status: 'available' | 'rented' | 'maintenance' | 'deleted';
  created_at: string;
  updated_at?: string;
  latitude?: number;
  longitude?: number;
  year_built?: number;
  square_feet?: number;
  property_features?: string;
}

export interface Lease {
  id: number;
  tenant_id: number;
  unit_id: number;
  start_date: string;
  end_date?: string;
  rent_amount: number;
  deposit_amount?: number;
  status: 'active' | 'terminated' | 'expired';
  lease_terms?: string;
  late_fee_amount?: number;
  late_fee_grace_days?: number;
  payment_due_day?: number;
  created_at: string;
  updated_at?: string;
}

export interface Payment {
  id: number;
  property_id: number;
  tenant_id: number;
  amount: number;
  payment_type: string;
  payment_method: string;
  payment_status: 'pending' | 'completed' | 'failed';
  payment_date: string;
  reference_number?: string;
  late_fee?: number;
  discount_amount?: number;
  created_at: string;
  updated_at?: string;
}

export interface AuthState {
  isAuthenticated: boolean;
  user: User | null;
  token: string | null;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface RegisterData {
  email: string;
  username: string;
  password: string;
  full_name: string;
  role: 'owner' | 'renter';
}

export type RootStackParamList = {
  Login: undefined;
  Register: undefined;
  Main: undefined;
  PropertyDetails: {propertyId: number};
  PaymentHistory: undefined;
  Profile: undefined;
};

export type MainTabParamList = {
  Dashboard: undefined;
  Properties: undefined;
  Payments: undefined;
  Profile: undefined;
};