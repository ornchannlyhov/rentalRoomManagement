import 'dart:convert';
import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/USD';
  static const Duration _cacheTimeout = Duration(hours: 1);

  static Map<String, double>? _cachedRates;
  static DateTime? _lastFetch;

  // Supported currencies with their symbols
  static const Map<String, String> supportedCurrencies = {
    'USD': '\$',
    'KHR': '៛', // Cambodian Riel
    'THB': '฿', // Thai Baht
  };

  /// Get current exchange rates from USD to other currencies
  static Future<Map<String, double>?> _fetchExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ratesData = data['rates'] as Map<String, dynamic>;

        // Convert all values to double to handle both int and double responses
        final rates = <String, double>{};
        ratesData.forEach((key, value) {
          rates[key] = (value as num).toDouble();
        });

        // Cache the results
        _cachedRates = rates;
        _lastFetch = DateTime.now();

        return rates;
      } else {
        print('Failed to fetch exchange rates: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
      return null;
    }
  }

  /// Get exchange rates with caching
  static Future<Map<String, double>?> getExchangeRates() async {
    // Check if we have cached data and it's still valid
    if (_cachedRates != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedRates;
    }

    // Fetch new rates
    return await _fetchExchangeRates();
  }

  /// Convert amount from USD to target currency
  static Future<double?> convertFromUSD(
      double usdAmount, String targetCurrency) async {
    if (targetCurrency == 'USD') return usdAmount;

    final rates = await getExchangeRates();
    if (rates == null || !rates.containsKey(targetCurrency)) {
      return null;
    }

    return usdAmount * rates[targetCurrency]!;
  }

  /// Convert amount between any two currencies
  static Future<double?> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return amount;

    final rates = await getExchangeRates();
    if (rates == null) return null;

    // Convert to USD first, then to target currency
    double usdAmount;
    if (fromCurrency == 'USD') {
      usdAmount = amount;
    } else if (rates.containsKey(fromCurrency)) {
      usdAmount = amount / rates[fromCurrency]!;
    } else {
      return null;
    }

    // Convert from USD to target currency
    if (toCurrency == 'USD') {
      return usdAmount;
    } else if (rates.containsKey(toCurrency)) {
      return usdAmount * rates[toCurrency]!;
    } else {
      return null;
    }
  }

  /// Format currency amount with proper symbol and decimal places
  static String formatCurrency(double amount, String currencyCode) {
    final symbol = supportedCurrencies[currencyCode] ?? currencyCode;

    // Special formatting for different currencies
    switch (currencyCode) {
      case 'KHR':
        return '$symbol${amount.toStringAsFixed(0)}'; // No decimals for Riel
      case 'JPY':
        return '$symbol${amount.toStringAsFixed(0)}'; // No decimals for Yen
      case 'VND':
        return '$symbol${amount.toStringAsFixed(0)}'; // No decimals for Dong
      default:
        return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  /// Get currency name for display
  static String getCurrencyName(String currencyCode) {
    const currencyNames = {
      'USD': 'US Dollar',
      'KHR': 'Cambodian Riel',
      'THB': 'Thai Baht',
    };

    return currencyNames[currencyCode] ?? currencyCode;
  }

  /// Check if service is available (for offline handling)
  static Future<bool> isServiceAvailable() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
