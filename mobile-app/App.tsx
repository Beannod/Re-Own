import React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {PaperProvider} from 'react-native-paper';
import {SafeAreaProvider} from 'react-native-safe-area-context';
import AppNavigator from './src/navigation/AppNavigator';
import {AuthProvider} from './src/utils/AuthContext';

const App = (): JSX.Element => {
  return (
    <SafeAreaProvider>
      <PaperProvider>
        <AuthProvider>
          <NavigationContainer>
            <AppNavigator />
          </NavigationContainer>
        </AuthProvider>
      </PaperProvider>
    </SafeAreaProvider>
  );
};

export default App;