import React, {useEffect, useState} from 'react';
import {View, StyleSheet, ScrollView, RefreshControl} from 'react-native';
import {Card, Title, Paragraph, Button, Chip} from 'react-native-paper';
import {useAuth} from '../utils/AuthContext';
import ApiService from '../services/ApiService';
import {Property, Lease, Payment} from '../types';

const DashboardScreen: React.FC = () => {
  const {user} = useAuth();
  const [properties, setProperties] = useState<Property[]>([]);
  const [currentLease, setCurrentLease] = useState<any>(null);
  const [recentPayments, setRecentPayments] = useState<Payment[]>([]);
  const [loading, setLoading] = useState(true);

  const loadDashboardData = async () => {
    try {
      setLoading(true);
      
      if (user?.role === 'owner') {
        const propertiesData = await ApiService.getProperties();
        setProperties(propertiesData);
        
        const paymentsData = await ApiService.getPayments();
        setRecentPayments(paymentsData.slice(0, 3)); // Latest 3 payments
      } else {
        // Renter
        try {
          const leaseData = await ApiService.getCurrentLease();
          setCurrentLease(leaseData);
        } catch (error) {
          console.log('No current lease found');
        }
        
        const paymentsData = await ApiService.getRenterPayments();
        setRecentPayments(paymentsData.slice(0, 3));
      }
    } catch (error) {
      console.error('Failed to load dashboard data:', error);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadDashboardData();
  }, [user]);

  const OwnerDashboard = () => (
    <ScrollView
      refreshControl={<RefreshControl refreshing={loading} onRefresh={loadDashboardData} />}>
      <Card style={styles.card}>
        <Card.Content>
          <Title>Welcome back, {user?.full_name}!</Title>
          <Paragraph>Manage your properties and tenants</Paragraph>
        </Card.Content>
      </Card>

      <Card style={styles.card}>
        <Card.Content>
          <Title>Property Overview</Title>
          <View style={styles.statsRow}>
            <Chip style={styles.statChip}>Total: {properties.length}</Chip>
            <Chip style={styles.statChip}>
              Rented: {properties.filter(p => p.status === 'rented').length}
            </Chip>
            <Chip style={styles.statChip}>
              Available: {properties.filter(p => p.status === 'available').length}
            </Chip>
          </View>
        </Card.Content>
      </Card>

      <Card style={styles.card}>
        <Card.Content>
          <Title>Recent Payments</Title>
          {recentPayments.length > 0 ? (
            recentPayments.map(payment => (
              <View key={payment.id} style={styles.paymentItem}>
                <Paragraph>${payment.amount} - {payment.payment_status}</Paragraph>
                <Paragraph style={styles.dateText}>
                  {new Date(payment.payment_date).toLocaleDateString()}
                </Paragraph>
              </View>
            ))
          ) : (
            <Paragraph>No recent payments</Paragraph>
          )}
        </Card.Content>
      </Card>
    </ScrollView>
  );

  const RenterDashboard = () => (
    <ScrollView
      refreshControl={<RefreshControl refreshing={loading} onRefresh={loadDashboardData} />}>
      <Card style={styles.card}>
        <Card.Content>
          <Title>Welcome, {user?.full_name}!</Title>
          <Paragraph>Your rental dashboard</Paragraph>
        </Card.Content>
      </Card>

      {currentLease ? (
        <Card style={styles.card}>
          <Card.Content>
            <Title>Current Property</Title>
            <Paragraph>Property: {currentLease.property?.title}</Paragraph>
            <Paragraph>Address: {currentLease.property?.address}</Paragraph>
            <Paragraph>Monthly Rent: ${currentLease.rent_amount}</Paragraph>
            <Paragraph>Lease Start: {new Date(currentLease.start_date).toLocaleDateString()}</Paragraph>
          </Card.Content>
        </Card>
      ) : (
        <Card style={styles.card}>
          <Card.Content>
            <Title>No Active Lease</Title>
            <Paragraph>You don't have an active lease at the moment.</Paragraph>
          </Card.Content>
        </Card>
      )}

      <Card style={styles.card}>
        <Card.Content>
          <Title>Recent Payments</Title>
          {recentPayments.length > 0 ? (
            recentPayments.map(payment => (
              <View key={payment.id} style={styles.paymentItem}>
                <Paragraph>${payment.amount} - {payment.payment_status}</Paragraph>
                <Paragraph style={styles.dateText}>
                  {new Date(payment.payment_date).toLocaleDateString()}
                </Paragraph>
              </View>
            ))
          ) : (
            <Paragraph>No recent payments</Paragraph>
          )}
        </Card.Content>
      </Card>
    </ScrollView>
  );

  return (
    <View style={styles.container}>
      {user?.role === 'owner' ? <OwnerDashboard /> : <RenterDashboard />}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  card: {
    margin: 16,
    marginBottom: 8,
  },
  statsRow: {
    flexDirection: 'row',
    marginTop: 8,
  },
  statChip: {
    marginRight: 8,
  },
  paymentItem: {
    borderBottomWidth: 1,
    borderBottomColor: '#eee',
    paddingVertical: 8,
  },
  dateText: {
    fontSize: 12,
    color: '#666',
  },
});

export default DashboardScreen;