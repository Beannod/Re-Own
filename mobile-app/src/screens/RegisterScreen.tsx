import React from 'react';
import {View, StyleSheet} from 'react-native';
import {Text} from 'react-native-paper';

const RegisterScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <Text>Register Screen - Coming Soon</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default RegisterScreen;