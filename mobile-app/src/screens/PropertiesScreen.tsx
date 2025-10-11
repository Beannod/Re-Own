import React from 'react';
import {View, StyleSheet} from 'react-native';
import {Text} from 'react-native-paper';

const PropertiesScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <Text>Properties Screen - Coming Soon</Text>
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

export default PropertiesScreen;