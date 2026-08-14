/// Dukaan Dost — Constants & Config

class AppConstants {
  // Dukaan Dost Billing Local Backend Endpoint (Port 5001)
  // 10.0.2.2 accesses localhost on host machine from Android Emulator
  static const String defaultEcoWalletBaseUrl = "http://10.0.2.2:5001/api";
  
  // Storage keys
  static const String keyApiKey = "dukaan_dost_api_key";
  static const String keyWebhookSecret = "dukaan_dost_webhook_secret";
  static const String keyMerchantId = "dukaan_dost_merchant_id";
  static const String keyShopName = "dukaan_dost_shop_name";
  static const String keyOwnerName = "dukaan_dost_owner_name";
  static const String keyBaseUrl = "dukaan_dost_base_url";

  // App details
  static const String appName = "Dukaan Dost";
  static const String appVersion = "1.0.0";
}
