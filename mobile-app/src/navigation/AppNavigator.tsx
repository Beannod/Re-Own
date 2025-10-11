import React from 'react';
import {createStackNavigator} from '@react-navigation/stack';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {useAuth} from '../utils/AuthContext';
import {RootStackParamList, MainTabParamList} from '../types';

// Screens
import LoginScreen from '../screens/LoginScreen';
import RegisterScreen from '../screens/RegisterScreen';
import DashboardScreen from '../screens/DashboardScreen';
import PropertiesScreen from '../screens/PropertiesScreen';
import PropertyDetailsScreen from '../screens/PropertyDetailsScreen';
import PaymentsScreen from '../screens/PaymentsScreen';
import ProfileScreen from '../screens/ProfileScreen';
import LoadingScreen from '../screens/LoadingScreen';

const Stack = createStackNavigator<RootStackParamList>();
const Tab = createBottomTabNavigator<MainTabParamList>();

const MainTabNavigator = () => {
  const {user} = useAuth();
  
  return (
    <Tab.Navigator
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: '#2196F3',
        tabBarInactiveTintColor: '#757575',
      }}>
      <Tab.Screen 
        name="Dashboard" 
        component={DashboardScreen}
        options={{
          tabBarLabel: 'Dashboard',
          // tabBarIcon: ({color, size}) => <Icon name="home" size={size} color={color} />
        }}
      />
      <Tab.Screen 
        name="Properties" 
        component={PropertiesScreen}
        options={{
          tabBarLabel: user?.role === 'owner' ? 'My Properties' : 'Property',
          // tabBarIcon: ({color, size}) => <Icon name="building" size={size} color={color} />
        }}
      />
      <Tab.Screen 
        name="Payments" 
        component={PaymentsScreen}
        options={{
          tabBarLabel: 'Payments',
          // tabBarIcon: ({color, size}) => <Icon name="payment" size={size} color={color} />
        }}
      />
      <Tab.Screen 
        name="Profile" 
        component={ProfileScreen}
        options={{
          tabBarLabel: 'Profile',
          // tabBarIcon: ({color, size}) => <Icon name="person" size={size} color={color} />
        }}
      />
    </Tab.Navigator>
  );
};

const AppNavigator = () => {
  const {isAuthenticated, loading} = useAuth();

  if (loading) {
    return <LoadingScreen />;
  }

  return (
    <Stack.Navigator screenOptions={{headerShown: false}}>
      {isAuthenticated ? (
        <>
          <Stack.Screen name="Main" component={MainTabNavigator} />
          <Stack.Screen 
            name="PropertyDetails" 
            component={PropertyDetailsScreen}
            options={{headerShown: true, title: 'Property Details'}}
          />
        </>
      ) : (
        <>
          <Stack.Screen name="Login" component={LoginScreen} />
          <Stack.Screen name="Register" component={RegisterScreen} />
        </>
      )}
    </Stack.Navigator>
  );
};

export default AppNavigator;