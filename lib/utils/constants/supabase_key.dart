class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://riaefioxfiwpbiuoxamm.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJpYWVmaW94Zml3cGJpdW94YW1tIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg5ODg4NDEsImV4cCI6MjA3NDU2NDg0MX0.oBSNBBsOV-vNCS9GDB0_t_ZwHKD1qmiN8H7Cpj__zXI';

  // App Configuration
  static const String appName = 'Ecommerce Admin';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String isLoggedInKey = 'isLoggedIn';
  static const String userIdKey = 'userId';
  static const String userEmailKey = 'userEmail';

  // Order Status
  static const List<String> orderStatuses = [
    'pending',
    'confirmed',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
    'refunded',
  ];

  // Payment Status
  static const List<String> paymentStatuses = [
    'pending',
    'paid',
    'failed',
    'refunded',
  ];
}
