import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:joul_v2/core/helpers/api_helper.dart';
import 'package:joul_v2/core/sync/outbox.dart';

/// How a push run ended.
enum PushOutcome {
  /// Everything that could be sent was sent (failed changes may remain).
  done,

  /// A change hit a network error, timeout or server error and will be
  /// retried later. Later changes wait so the order is kept.
  waiting,

  /// The server rejected the token. Nothing is lost; sync resumes after
  /// the user signs in again.
  unauthorized,
}

/// What happened to one change sent to the API.
enum SendResult { success, retry, failed, unauthorized }

/// The result of sending one change, with the reply body or error.
class SentChange {
  const SentChange(this.result, {this.error, this.data});
  final SendResult result;
  final String? error;
  final Object? data;
}

/// Sends outbox changes to the API one at a time, oldest first.
class OutboxPusher {
  OutboxPusher(this._outbox, [ApiHelper? apiHelper])
      : _api = apiHelper ?? ApiHelper.instance;

  final Outbox _outbox;
  final ApiHelper _api;

  Future<PushOutcome> pushAll() async {
    while (true) {
      final op = _outbox.nextReady(DateTime.now());
      if (op == null) return PushOutcome.done;

      final opId = op['opId'] as String;
      // Cleared when the result is recorded below.
      _outbox.markSending(opId);
      final sent = await _send(op);

      switch (sent.result) {
        case SendResult.success:
          await _rememberServerId(op, sent.data);
          await _outbox.markDone(opId);
          break;
        case SendResult.retry:
          await _outbox.markRetry(opId, sent.error ?? 'Network error');
          return PushOutcome.waiting;
        case SendResult.failed:
          await _outbox.markFailed(opId, sent.error ?? 'Rejected by server');
          break;
        case SendResult.unauthorized:
          _outbox.markSending(null);
          return PushOutcome.unauthorized;
      }
    }
  }

  /// After an offline create reaches the server, point every later change
  /// at the server's id instead of the one made on the phone.
  Future<void> _rememberServerId(Map<String, dynamic> op, Object? body) async {
    if (op['type'] != 'create') return;
    final localId = (op['data'] as Map?)?['localId']?.toString();
    if (localId == null) return;
    final serverId = _serverIdFrom(body);
    if (serverId != null) await _outbox.applyIdMapping(localId, serverId);
  }

  static String? _serverIdFrom(Object? body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is Map && data['id'] != null) return data['id'].toString();
    if (body['id'] != null) return body['id'].toString();
    return null;
  }

  Future<SentChange> _send(Map<String, dynamic> op) async {
    final token = await _api.storage.read(key: 'auth_token');
    if (token == null) return const SentChange(SendResult.unauthorized);

    final type = op['type'] as String;
    final endpoint = op['endpoint'] as String;
    final data = Map<String, dynamic>.from(op['data'] as Map);
    final file = await _existingFile(op);
    final fileField = op['fileFieldName'] as String?;

    try {
      final Response<dynamic>? response;
      switch (type) {
        case 'create':
          response = file != null && fileField != null
              ? await _api.uploadWithFile(
                  endpoint: endpoint,
                  data: data,
                  file: file,
                  fileFieldName: fileField,
                  method: 'POST',
                )
              : await _api.dio.post('${_api.baseUrl}$endpoint',
                  data: data, options: _options(token));
          break;
        // 'updateStatus' was used by older app versions for report status.
        case 'update':
        case 'updateStatus':
          response = file != null && fileField != null
              ? await _api.uploadWithFile(
                  endpoint: endpoint,
                  data: data,
                  file: file,
                  fileFieldName: fileField,
                  method: 'PUT',
                )
              : await _api.dio.put('${_api.baseUrl}$endpoint',
                  data: data, options: _options(token));
          break;
        case 'delete':
          response = await _api.dio
              .delete('${_api.baseUrl}$endpoint', options: _options(token));
          break;
        default:
          return SentChange(SendResult.failed,
              error: 'Unknown change type $type');
      }
      return classify(type, response?.statusCode, response?.data);
    } on DioException catch (e) {
      final response = e.response;
      if (response != null) {
        return classify(type, response.statusCode, response.data);
      }
      return SentChange(SendResult.retry, error: e.message ?? e.type.name);
    } catch (e) {
      if (kDebugMode) print('Unexpected error sending $type $endpoint: $e');
      return SentChange(SendResult.retry, error: e.toString());
    }
  }

  static Options _options(String token) => Options(
        headers: {'Authorization': 'Bearer $token'},
        sendTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        validateStatus: (_) => true,
      );

  Future<File?> _existingFile(Map<String, dynamic> op) async {
    final path = op['filePath'] as String?;
    if (path == null || op['fileFieldName'] == null) return null;
    final file = File(path);
    if (await file.exists()) return file;
    if (kDebugMode) print('Outbox file missing at $path, sending without it');
    return null;
  }

  @visibleForTesting
  static SentChange classify(String type, int? status, Object? body) {
    final code = status ?? 0;
    if (code >= 200 && code < 300) {
      return SentChange(SendResult.success, data: body);
    }
    // Already created by an earlier attempt whose reply was lost.
    if (type == 'create' && code == 409) {
      return SentChange(SendResult.success, data: body);
    }
    // Already deleted.
    if (type == 'delete' && code == 404) {
      return const SentChange(SendResult.success);
    }
    if (code == 401) return const SentChange(SendResult.unauthorized);
    if (code == 0 || code == 408 || code == 429 || code >= 500) {
      return SentChange(SendResult.retry, error: _message(body, code));
    }
    return SentChange(SendResult.failed, error: _message(body, code));
  }

  static String _message(Object? body, int code) {
    if (body is Map) {
      final message = body['message'] ?? body['error'];
      if (message != null) return message.toString();
    }
    return code == 0 ? 'No response from server' : 'Server replied $code';
  }
}
