import 'dart:convert';

import 'package:http/http.dart' as http;

class CurrencyService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/USD';
  static const Duration _cacheTimeout = Duration(hours: 1);

  static Map<String, double>? _cachedRates;
  static DateTime? _lastFetch;

  static const Map<String, String> supportedCurrencies = {
    'USD': '\$',
    'KHR': '៛', 
    'THB': '฿', 
  };

  static const Map<String, double> _defaultRates = {
    'USD': 1.0,
    'KHR': 4100.0, 
    'THB': 40.0,   
  };

  static Future<Map<String, double>> _fetchExchangeRates() async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final ratesData = data['rates'] as Map<String, dynamic>;

        final rates = <String, double>{};
        ratesData.forEach((key, value) {
          rates[key] = (value as num).toDouble();
        });

        _cachedRates = rates;
        _lastFetch = DateTime.now();

        return rates;
      } else {
        print('Failed to fetch exchange rates: ${response.statusCode}');
        return _defaultRates;
      }
    } catch (e) {
      print('Error fetching exchange rates: $e');
      return _defaultRates;
    }
  }

  static Future<Map<String, double>> getExchangeRates() async {
    if (_cachedRates != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedRates!;
    }

    return await _fetchExchangeRates();
  }

  static Future<double?> convertFromUSD(
      double usdAmount, String targetCurrency) async {
    if (targetCurrency == 'USD') return usdAmount;

    final rates = await getExchangeRates();
    if (!rates.containsKey(targetCurrency)) {
      return null;
    }

    return usdAmount * rates[targetCurrency]!;
  }

  static Future<double?> convertCurrency(
      double amount, String fromCurrency, String toCurrency) async {
    if (fromCurrency == toCurrency) return amount;

    final rates = await getExchangeRates();

    double usdAmount;
    if (fromCurrency == 'USD') {
      usdAmount = amount;
    } else if (rates.containsKey(fromCurrency)) {
      usdAmount = amount / rates[fromCurrency]!;
    } else {
      return null;
    }

    if (toCurrency == 'USD') {
      return usdAmount;
    } else if (rates.containsKey(toCurrency)) {
      return usdAmount * rates[toCurrency]!;
    } else {
      return null;
    }
  }

  static String formatCurrency(double amount, String currencyCode) {
    final symbol = supportedCurrencies[currencyCode] ?? currencyCode;

    switch (currencyCode) {
      case 'KHR':
      case 'JPY':
      case 'VND':
        return '$symbol${amount.toStringAsFixed(0)}';
      default:
        return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  static String getCurrencyName(String currencyCode) {
    const currencyNames = {
      'USD': 'US Dollar',
      'KHR': 'Cambodian Riel',
      'THB': 'Thai Baht',
    };

    return currencyNames[currencyCode] ?? currencyCode;
  }

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
