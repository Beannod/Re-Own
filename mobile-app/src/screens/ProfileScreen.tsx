import React from 'react';
import {View, StyleSheet} from 'react-native';
import {Text, Button} from 'react-native-paper';
import {useAuth} from '../utils/AuthContext';

const ProfileScreen: React.FC = () => {
  const {user, logout} = useAuth();

  return (
    <View style={styles.container}>
      <Text>Profile Screen</Text>
      <Text>Welcome, {user?.full_name}</Text>
      <Text>Role: {user?.role}</Text>
      <Button mode="contained" onPress={logout} style={styles.button}>
        Logout
      </Button>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 20,
  },
  button: {
    marginTop: 20,
  },
});

export default ProfileScreen;