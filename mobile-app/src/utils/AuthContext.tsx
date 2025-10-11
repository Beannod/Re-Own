import React, {createContext, useContext, useReducer, useEffect, ReactNode} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {AuthState, User, LoginCredentials, RegisterData} from '../types';
import ApiService from '../services/ApiService';

interface AuthContextType extends AuthState {
  login: (credentials: LoginCredentials) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => Promise<void>;
  loading: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

type AuthAction =
  | {type: 'SET_LOADING'; payload: boolean}
  | {type: 'SET_AUTHENTICATED'; payload: {user: User; token: string}}
  | {type: 'SET_UNAUTHENTICATED'};

const authReducer = (state: AuthState & {loading: boolean}, action: AuthAction) => {
  switch (action.type) {
    case 'SET_LOADING':
      return {...state, loading: action.payload};
    case 'SET_AUTHENTICATED':
      return {
        ...state,
        isAuthenticated: true,
        user: action.payload.user,
        token: action.payload.token,
        loading: false,
      };
    case 'SET_UNAUTHENTICATED':
      return {
        ...state,
        isAuthenticated: false,
        user: null,
        token: null,
        loading: false,
      };
    default:
      return state;
  }
};

const initialState: AuthState & {loading: boolean} = {
  isAuthenticated: false,
  user: null,
  token: null,
  loading: true,
};

export const AuthProvider: React.FC<{children: ReactNode}> = ({children}) => {
  const [state, dispatch] = useReducer(authReducer, initialState);

  useEffect(() => {
    checkAuthState();
  }, []);

  const checkAuthState = async () => {
    try {
      dispatch({type: 'SET_LOADING', payload: true});
      const token = await AsyncStorage.getItem('auth_token');
      
      if (token) {
        const user = await ApiService.getCurrentUser();
        dispatch({type: 'SET_AUTHENTICATED', payload: {user, token}});
      } else {
        dispatch({type: 'SET_UNAUTHENTICATED'});
      }
    } catch (error) {
      console.error('Auth check failed:', error);
      dispatch({type: 'SET_UNAUTHENTICATED'});
    }
  };

  const login = async (credentials: LoginCredentials) => {
    try {
      dispatch({type: 'SET_LOADING', payload: true});
      const {user, token} = await ApiService.login(credentials);
      dispatch({type: 'SET_AUTHENTICATED', payload: {user, token}});
    } catch (error) {
      dispatch({type: 'SET_UNAUTHENTICATED'});
      throw error;
    }
  };

  const register = async (data: RegisterData) => {
    try {
      dispatch({type: 'SET_LOADING', payload: true});
      const {user, token} = await ApiService.register(data);
      dispatch({type: 'SET_AUTHENTICATED', payload: {user, token}});
    } catch (error) {
      dispatch({type: 'SET_UNAUTHENTICATED'});
      throw error;
    }
  };

  const logout = async () => {
    try {
      await ApiService.logout();
    } catch (error) {
      console.error('Logout error:', error);
    } finally {
      dispatch({type: 'SET_UNAUTHENTICATED'});
    }
  };

  const value: AuthContextType = {
    ...state,
    login,
    register,
    logout,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};