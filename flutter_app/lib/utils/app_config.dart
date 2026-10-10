/// Global application configuration and environment constants.
class AppConfig {
  const AppConfig._();

  static const String appName = 'e commerce app';
  static const String appVersion = '1.0.0';

  /// Remote backend URL hosted on Vercel
  static const String backendBaseUrl = 'https://e-commerce-app-flutter-backend-five.vercel.app';

  /// Default flat delivery fee in PKR minor units (paisa)
  /// e.g. 25000 paisa = PKR 250.00
  static const int defaultDeliveryFeeMinor = 25000;

  /// Free delivery threshold in PKR minor units (paisa)
  /// e.g. 500000 paisa = PKR 5,000.00
  static const int freeDeliveryThresholdMinor = 500000;

  /// Maximum allowed quantity per line item in cart
  static const int maxCartItemQuantity = 20;

  /// OTP length and cooldown constants
  static const int otpLength = 6;
  static const int otpCooldownSeconds = 60;
  static const int maxOtpAttempts = 5;
}
