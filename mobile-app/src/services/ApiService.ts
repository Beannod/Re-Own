import AsyncStorage from '@react-native-async-storage/async-storage';
import axios, {AxiosResponse} from 'axios';
import {User, LoginCredentials, RegisterData, Property, Lease, Payment} from '../types';

const API_BASE_URL = 'http://127.0.0.1:8000'; // Your FastAPI backend URL
const TOKEN_KEY = 'auth_token';

// Create axios instance
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  async config => {
    const token = await AsyncStorage.getItem(TOKEN_KEY);
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  },
);

// Response interceptor for error handling
api.interceptors.response.use(
  response => response,
  async error => {
    if (error.response?.status === 401) {
      // Token expired or invalid, clear storage
      await AsyncStorage.removeItem(TOKEN_KEY);
    }
    return Promise.reject(error);
  },
);

export class ApiService {
  // Authentication
  static async login(credentials: LoginCredentials): Promise<{user: User; token: string}> {
    const response: AxiosResponse = await api.post('/auth/login', credentials);
    const {access_token, user} = response.data;
    
    // Store token
    await AsyncStorage.setItem(TOKEN_KEY, access_token);
    
    return {user, token: access_token};
  }

  static async register(data: RegisterData): Promise<{user: User; token: string}> {
    const response: AxiosResponse = await api.post('/auth/register', data);
    const {access_token, user} = response.data;
    
    // Store token
    await AsyncStorage.setItem(TOKEN_KEY, access_token);
    
    return {user, token: access_token};
  }

  static async logout(): Promise<void> {
    try {
      await api.post('/auth/logout');
    } catch (error) {
      console.log('Logout error:', error);
    } finally {
      await AsyncStorage.removeItem(TOKEN_KEY);
    }
  }

  static async getCurrentUser(): Promise<User> {
    const response: AxiosResponse = await api.get('/auth/me');
    return response.data;
  }

  // Properties
  static async getProperties(): Promise<Property[]> {
    const response: AxiosResponse = await api.get('/properties');
    return response.data;
  }

  static async getProperty(id: number): Promise<Property> {
    const response: AxiosResponse = await api.get(`/properties/${id}`);
    return response.data;
  }

  static async createProperty(property: Omit<Property, 'id' | 'created_at' | 'updated_at'>): Promise<Property> {
    const response: AxiosResponse = await api.post('/properties', property);
    return response.data;
  }

  static async updateProperty(id: number, property: Partial<Property>): Promise<Property> {
    const response: AxiosResponse = await api.put(`/properties/${id}`, property);
    return response.data;
  }

  static async deleteProperty(id: number): Promise<void> {
    await api.delete(`/properties/${id}`);
  }

  // Leases
  static async getCurrentLease(): Promise<Lease & {property: Property; owner: User}> {
    const response: AxiosResponse = await api.get('/leases/current');
    return response.data;
  }

  static async getAllLeases(): Promise<Lease[]> {
    const response: AxiosResponse = await api.get('/leases/all');
    return response.data;
  }

  static async assignPropertyToTenant(propertyId: number, leaseData: any): Promise<any> {
    const response: AxiosResponse = await api.post('/leases/assign', {
      property_id: propertyId,
      ...leaseData,
    });
    return response.data;
  }

  static async terminateLease(leaseId: number): Promise<void> {
    await api.put(`/leases/${leaseId}/terminate`);
  }

  // Payments
  static async getPayments(): Promise<Payment[]> {
    const response: AxiosResponse = await api.get('/payments');
    return response.data;
  }

  static async createPayment(payment: Omit<Payment, 'id' | 'created_at' | 'updated_at'>): Promise<Payment> {
    const response: AxiosResponse = await api.post('/payments', payment);
    return response.data;
  }

  // Utilities
  static async getRenterPayments(): Promise<Payment[]> {
    const response: AxiosResponse = await api.get('/payments/renter');
    return response.data;
  }

  static async getPropertyDocuments(propertyId: number): Promise<any[]> {
    const response: AxiosResponse = await api.get(`/properties/${propertyId}/documents`);
    return response.data;
  }
}

export default ApiService;