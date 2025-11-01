import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:dio/dio.dart';

class CurrencyService {
  static const String _baseUrl =
      'https://api.exchangerate-api.com/v4/latest/USD';
  static const Duration _cacheTimeout = Duration(hours: 1);

  static final ApiHelper _apiHelper = ApiHelper.instance;

  static Map<String, double>? _cachedRates;
  static DateTime? _lastFetch;

  static const Map<String, String> supportedCurrencies = {
    'USD': '\$',
    'KHR': '៛',
    'CNY': '¥',
  };

  static const Map<String, double> _defaultRates = {
    'USD': 1.0,
    'KHR': 4100.0,
    'CNY': 7.2,
  };

  static Future<Map<String, double>> _fetchExchangeRates() async {
    // Check network availability first
    if (!await _apiHelper.hasNetwork()) {
      debugPrint('No network available, using default rates');
      return _defaultRates;
    }

    try {
      final response = await _apiHelper.dio.get(
        _baseUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.data['cancelled'] == true) {
        debugPrint('Request cancelled, using default rates');
        return _defaultRates;
      }

      if (response.statusCode == 200) {
        final ratesData = response.data['rates'] as Map<String, dynamic>;

        final rates = <String, double>{};
        ratesData.forEach((key, value) {
          rates[key] = (value as num).toDouble();
        });

        _cachedRates = rates;
        _lastFetch = DateTime.now();

        return rates;
      } else {
        debugPrint('Failed to fetch exchange rates: ${response.statusCode}');
        return _defaultRates;
      }
    } on DioException catch (e) {
      debugPrint('Dio error fetching exchange rates: ${e.type} - ${e.message}');

      // Use cached rates if available, otherwise default
      if (_cachedRates != null) {
        debugPrint('Using cached rates due to error');
        return _cachedRates!;
      }

      return _defaultRates;
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');

      // Use cached rates if available, otherwise default
      if (_cachedRates != null) {
        debugPrint('Using cached rates due to error');
        return _cachedRates!;
      }

      return _defaultRates;
    }
  }

  static Future<Map<String, double>> getExchangeRates() async {
    // Return cached rates if still valid
    if (_cachedRates != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheTimeout) {
      return _cachedRates!;
    }

    // Otherwise fetch new rates
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
        // Round to nearest 100 and add commas
        final rounded = (amount / 100).round() * 100;
        final formatted = rounded
            .toStringAsFixed(0)
            .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
        return '$formatted ៛';
      case 'CNY':
        // Chinese Yuan, keep 2 decimals and commas
        final formatted = amount
            .toStringAsFixed(2)
            .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
        return '$symbol$formatted';
      default:
        // USD and others
        final formatted = amount
            .toStringAsFixed(2)
            .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
        return '$symbol$formatted';
    }
  }

  static String getCurrencyName(String currencyCode) {
    const currencyNames = {
      'USD': 'US Dollar',
      'KHR': 'Cambodian Riel',
      'CNY': 'Chinese Yuan',
    };

    return currencyNames[currencyCode] ?? currencyCode;
  }

  static Future<bool> isServiceAvailable() async {
    // Check network availability first
    if (!await _apiHelper.hasNetwork()) {
      return false;
    }

    try {
      final response = await _apiHelper.dio.get(
        _baseUrl,
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );

      if (response.data['cancelled'] == true) {
        return false;
      }

      return response.statusCode == 200;
    } on DioException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Clear cached rates (useful for testing or manual refresh)
  static void clearCache() {
    _cachedRates = null;
    _lastFetch = null;
  }

  /// Force refresh rates (ignores cache)
  static Future<Map<String, double>> refreshRates() async {
    clearCache();
    return await _fetchExchangeRates();
  }
}
