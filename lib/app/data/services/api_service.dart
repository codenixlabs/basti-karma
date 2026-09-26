import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';

class ApiService extends GetConnect {
  static const String defaultBaseUrl =
      'https://bhastikarma-app-backend.onrender.com/api';

  static const Duration defaultTimeout = Duration(seconds: 15);
  Duration timeoutDuration = defaultTimeout;

  /// Pluggable connectivity checker for testability and runtime verification.
  /// Returns `true` if device has active internet access, `false` if completely offline.
  static Future<bool> Function() connectivityChecker =
      _defaultConnectivityChecker;

  /// Cached last known online state for fast/offline fallback.
  static bool? _lastKnownOnlineStatus;

  static Future<bool> _defaultConnectivityChecker() async {
    try {
      final lookup = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        _lastKnownOnlineStatus = true;
        return true;
      }
    } catch (_) {}

    try {
      final lookup = await InternetAddress.lookup(
        '1.1.1.1',
      ).timeout(const Duration(seconds: 3));
      if (lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty) {
        _lastKnownOnlineStatus = true;
        return true;
      }
    } catch (_) {}

    _lastKnownOnlineStatus = false;
    return false;
  }

  static void resetConnectivityChecker() {
    connectivityChecker = _defaultConnectivityChecker;
    _lastKnownOnlineStatus = null;
  }

  /// Toggle logging. Defaults to true to ensure all API responses are logged clearly.
  static bool enableLogging = true;

  /// Custom log consumer (useful for unit testing or structured logger redirection).
  static void Function(String message)? logWriter;

  final AuthService? _authService;

  ApiService({AuthService? authService, String? baseUrl})
    : _authService = authService {
    this.baseUrl = baseUrl ?? defaultBaseUrl;
  }

  AuthService? get authService {
    if (_authService != null) return _authService;
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>();
    }
    return null;
  }

  Map<String, String> buildAuthHeaders([Map<String, String>? existingHeaders]) {
    final headers = <String, String>{};
    if (existingHeaders != null) {
      headers.addAll(existingHeaders);
    }
    final token = authService?.currentToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Determines if an HTTP response represents an unauthorized session failure
  /// that warrants clearing the session and redirecting to login.
  /// Excludes guest/auth endpoints.
  static bool shouldHandleUnauthorized(String urlPath, int? statusCode) {
    if (statusCode != 401) return false;
    final path = urlPath.toLowerCase();
    if (path.contains('/auth/login') ||
        path.contains('/auth/signup') ||
        path.contains('/auth/send-otp') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/verify-reset-otp') ||
        path.contains('/auth/reset-password')) {
      return false;
    }
    return true;
  }

  @override
  void onInit() {
    super.onInit();
    baseUrl = baseUrl ?? defaultBaseUrl;
    httpClient.defaultContentType = 'application/json';
    httpClient.timeout = timeoutDuration;

    // Request modifier: automatically attach Authorization: Bearer <token> for non-guest endpoints
    httpClient.addRequestModifier<dynamic>((request) {
      final path = request.url.path.toLowerCase();
      if (path.contains('/auth/login') ||
          path.contains('/auth/signup') ||
          path.contains('/auth/send-otp') ||
          path.contains('/auth/refresh') ||
          path.contains('/auth/forgot-password') ||
          path.contains('/auth/verify-reset-otp') ||
          path.contains('/auth/reset-password')) {
        return request;
      }
      final token = authService?.currentToken;
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      return request;
    });
  }

  // ── Centralized HTTP Overrides with Logging ─────────────────────────────────

  @override
  Future<Response<T>> get<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    return _loggedCall<T>(
      'GET',
      url,
      null,
      headers: headers,
      query: query,
      () => super.get<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
    );
  }

  @override
  Future<Response<T>> post<T>(
    String? url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _loggedCall<T>(
      'POST',
      url,
      body,
      headers: headers,
      query: query,
      () => super.post<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }

  @override
  Future<Response<T>> put<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _loggedCall<T>(
      'PUT',
      url,
      body,
      headers: headers,
      query: query,
      () => super.put<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }

  @override
  Future<Response<T>> patch<T>(
    String url,
    dynamic body, {
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _loggedCall<T>(
      'PATCH',
      url,
      body,
      headers: headers,
      query: query,
      () => super.patch<T>(
        url,
        body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String url, {
    Map<String, String>? headers,
    String? contentType,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
  }) {
    return _loggedCall<T>(
      'DELETE',
      url,
      null,
      headers: headers,
      query: query,
      () => super.delete<T>(
        url,
        headers: headers,
        contentType: contentType,
        query: query,
        decoder: decoder,
      ),
    );
  }

  @override
  Future<Response<T>> request<T>(
    String url,
    String method, {
    dynamic body,
    String? contentType,
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    Decoder<T>? decoder,
    Progress? uploadProgress,
  }) {
    return _loggedCall<T>(
      method.toUpperCase(),
      url,
      body,
      headers: headers,
      query: query,
      () => super.request<T>(
        url,
        method,
        body: body,
        contentType: contentType,
        headers: headers,
        query: query,
        decoder: decoder,
        uploadProgress: uploadProgress,
      ),
    );
  }

  // ── Binary File Download (PDF Reports) ──────────────────────────────────────

  /// Downloads a patient's complete PDF report from `GET /api/patients/:id/pdf`.
  static const Duration defaultPdfTimeout = Duration(minutes: 2);

  /// Downloads a patient's complete PDF report from `GET /api/patients/:id/pdf`.
  ///
  /// The server sends the raw binary file data of the PDF, along with a `Content-Disposition`
  /// header specifying the patient's name as filename (e.g. `filename="John_Doe_Report.pdf"`).
  ///
  /// Backend PDF rendering queries all clinical and session records, which can take
  /// longer under heavy loads. The default timeout is extended to 2 minutes ([defaultPdfTimeout]).
  ///
  /// On success (200), saves the PDF to device storage (via `path_provider`) and returns the [File].
  /// On error (404/500), parses the JSON error response and throws an [Exception].
  Future<File> downloadPatientPdf(
    String patientId, {
    String? defaultFileName,
    Duration timeout = defaultPdfTimeout,
    bool isRetry = false,
  }) async {
    final fullUrl = _resolveFullUrl('/patients/$patientId/pdf', null);
    final stopwatch = Stopwatch()..start();

    final token = authService?.currentToken;
    final headersStr =
        'Authorization: Bearer ${token != null && token.isNotEmpty ? "[Present]" : "None"}, Accept: application/pdf, application/json';

    final client = HttpClient();
    client.connectionTimeout = timeout;

    try {
      final uri = Uri.parse(fullUrl);
      final request = await client.getUrl(uri).timeout(timeout);

      if (token != null && token.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $token');
      }
      request.headers.set('Accept', 'application/pdf, application/json');

      final response = await request.close().timeout(timeout);
      final statusCode = response.statusCode;
      final durationMs = stopwatch.elapsedMilliseconds;

      // Handle 401 unauthorized session failure on protected endpoints
      if (statusCode == 401 && shouldHandleUnauthorized(fullUrl, 401)) {
        if (!isRetry) {
          final refreshed = await refreshTokenSafely();
          if (refreshed) {
            client.close();
            return downloadPatientPdf(
              patientId,
              defaultFileName: defaultFileName,
              timeout: timeout,
              isRetry: true,
            );
          }
        }
        authService?.handleUnauthorized();
        throw Exception('Session expired or unauthorized. Please log in again.');
      }

      if (statusCode == 200) {
        final contentDisposition =
            response.headers.value('content-disposition');
        final resolvedName = extractFileNameFromContentDisposition(
          contentDisposition,
          fallback: defaultFileName ?? 'Patient_Report.pdf',
        );

        final bytesBuilder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          bytesBuilder.add(chunk);
        }
        final bytes = bytesBuilder.takeBytes();

        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$resolvedName');
        await file.writeAsBytes(bytes, flush: true);

        if (enableLogging) {
          final buffer = StringBuffer();
          buffer.writeln(
            '═══════════════════════════════════════════════════════════════',
          );
          buffer.writeln('🌐 [API REQUEST] → GET $fullUrl');
          buffer.writeln('Headers: $headersStr');
          buffer.writeln();
          buffer.writeln('📥 [API RESPONSE] ← 🟢 SUCCESS 200 (${durationMs}ms)');
          buffer.writeln('Content-Disposition: $contentDisposition');
          buffer.writeln('Saved File: ${file.path} (${bytes.length} bytes)');
          buffer.writeln(
            '═══════════════════════════════════════════════════════════════',
          );
          _log(buffer.toString().trimRight());
        }

        return file;
      }

      // Read error body (JSON expected for 404, 500)
      final bodyString = await utf8.decodeStream(response);
      String errorMessage = '';
      try {
        final decoded = jsonDecode(bodyString);
        if (decoded is Map && decoded['message'] != null) {
          errorMessage = decoded['message'].toString();
        }
      } catch (_) {}

      if (errorMessage.isEmpty) {
        if (statusCode == 404) {
          errorMessage = 'Patient not found or unauthorized';
        } else if (statusCode == 500) {
          errorMessage = 'Failed to generate PDF';
        } else {
          errorMessage = 'Failed to download PDF report (Status $statusCode)';
        }
      }

      if (enableLogging) {
        final buffer = StringBuffer();
        buffer.writeln(
          '═══════════════════════════════════════════════════════════════',
        );
        buffer.writeln('🌐 [API REQUEST] → GET $fullUrl');
        buffer.writeln('Headers: $headersStr');
        buffer.writeln();
        buffer.writeln(
          '📥 [API RESPONSE] ← 🔴 ERROR $statusCode (${durationMs}ms)',
        );
        buffer.writeln('Error: $errorMessage');
        buffer.writeln('Response Body: $bodyString');
        buffer.writeln(
          '═══════════════════════════════════════════════════════════════',
        );
        _log(buffer.toString().trimRight());
      }

      throw Exception(errorMessage);
    } catch (e) {
      if (enableLogging &&
          !e.toString().contains('Failed to generate PDF') &&
          !e.toString().contains('Patient not found')) {
        _log('📥 [API EXCEPTION] GET $fullUrl ← Error: $e');
      }
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Parses filename from `Content-Disposition` header.
  /// Handles `filename="name.pdf"`, `filename=name.pdf`, and `filename*=UTF-8''name.pdf`.
  static String extractFileNameFromContentDisposition(
    String? contentDisposition, {
    String fallback = 'Patient_Report.pdf',
  }) {
    if (contentDisposition == null || contentDisposition.trim().isEmpty) {
      return fallback;
    }

    // 1. Check for filename*=UTF-8''filename.pdf (RFC 5987 / RFC 6266)
    final utf8Match = RegExp(
      r'''filename\*\s*=\s*(?:UTF-8|utf-8)''([^;]+)''',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (utf8Match != null && utf8Match.group(1) != null) {
      final decoded = Uri.decodeComponent(utf8Match.group(1)!.trim());
      return _sanitizeFileName(decoded, fallback);
    }

    // 2. Check for filename="filename.pdf" or filename='filename.pdf'
    final quotedMatch = RegExp(
      r'''filename\s*=\s*["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (quotedMatch != null && quotedMatch.group(1) != null) {
      return _sanitizeFileName(quotedMatch.group(1)!.trim(), fallback);
    }

    // 3. Check for filename=filename.pdf (without quotes)
    final unquotedMatch = RegExp(
      r'filename\s*=\s*([^;\s]+)',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    if (unquotedMatch != null && unquotedMatch.group(1) != null) {
      return _sanitizeFileName(unquotedMatch.group(1)!.trim(), fallback);
    }

    return fallback;
  }

  static String _sanitizeFileName(String name, String fallback) {
    var cleaned = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (cleaned.isEmpty) return fallback;
    if (!cleaned.toLowerCase().endsWith('.pdf')) {
      cleaned = '$cleaned.pdf';
    }
    return cleaned;
  }

  Completer<bool>? _refreshCompleter;

  /// Concurrency-safe token refresh.
  /// Prevents multiple parallel /auth/refresh calls by awaiting an in-flight refresh.
  Future<bool> refreshTokenSafely() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      final currentRefresh = authService?.currentRefreshToken;
      if (currentRefresh == null || currentRefresh.isEmpty) {
        completer.complete(false);
        return false;
      }

      final refreshUrl = _resolveFullUrl('/auth/refresh', null);
      if (enableLogging) {
        _log('🔄 [AUTH REFRESH REQUEST] POST $refreshUrl');
      }
      final response = await httpClient.post(
        refreshUrl,
        body: jsonEncode({'refreshToken': currentRefresh}),
        headers: {'Content-Type': 'application/json'},
      );
      if (enableLogging) {
        _log('🔄 [AUTH REFRESH RESPONSE] Status: ${response.statusCode}, Body: ${response.body ?? response.bodyString}');
      }

      if (response.statusCode == 200 && response.body != null) {
        final dynamic rawBody = response.body;
        final Map<String, dynamic>? body = rawBody is Map
            ? Map<String, dynamic>.from(rawBody)
            : (rawBody is String
                  ? jsonDecode(rawBody) as Map<String, dynamic>?
                  : null);

        if (body != null && body['success'] == true && body['data'] != null) {
          final data = body['data'] as Map<String, dynamic>;
          final newAccessToken = data['token'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;

          if (newAccessToken != null &&
              newAccessToken.isNotEmpty &&
              newRefreshToken != null &&
              newRefreshToken.isNotEmpty) {
            await authService?.updateTokens(
              token: newAccessToken,
              refreshToken: newRefreshToken,
            );
            completer.complete(true);
            return true;
          }
        }
      }

      completer.complete(false);
      return false;
    } catch (e) {
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  // ── Logging Internals ───────────────────────────────────────────────────────

  @visibleForTesting
  Future<Response<T>> loggedCall<T>(
    String method,
    String? url,
    dynamic body,
    Future<Response<T>> Function() call, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    bool isRetry = false,
  }) => _loggedCall<T>(
    method,
    url,
    body,
    call,
    headers: headers,
    query: query,
    isRetry: isRetry,
  );

  Future<Response<T>> _loggedCall<T>(
    String method,
    String? url,
    dynamic body,
    Future<Response<T>> Function() call, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
    bool isRetry = false,
  }) async {
    final fullUrl = _resolveFullUrl(url, query);
    final effectiveHeaders = <String, String>{};
    final path = (url ?? '').toLowerCase();
    final isGuestAuthPath = path.contains('/auth/login') ||
        path.contains('/auth/signup') ||
        path.contains('/auth/send-otp') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/verify-reset-otp') ||
        path.contains('/auth/reset-password');
    if (!isGuestAuthPath) {
      final token = authService?.currentToken;
      if (token != null &&
          token.isNotEmpty &&
          (headers == null ||
              (!headers.containsKey('Authorization') &&
                  !headers.containsKey('authorization')))) {
        effectiveHeaders['Authorization'] = 'Bearer $token';
      }
    }
    if (headers != null) {
      effectiveHeaders.addAll(headers);
    }
    if (!effectiveHeaders.containsKey('Content-Type') &&
        !effectiveHeaders.containsKey('content-type')) {
      if (body is FormData) {
        effectiveHeaders['Content-Type'] = 'multipart/form-data';
      } else {
        effectiveHeaders['Content-Type'] = httpClient.defaultContentType;
      }
    }
    if (!effectiveHeaders.containsKey('Accept') &&
        !effectiveHeaders.containsKey('accept')) {
      effectiveHeaders['Accept'] = 'application/json';
    }

    final headersStr = effectiveHeaders.isEmpty
        ? 'None'
        : effectiveHeaders.entries.map((e) => '${e.key}: ${e.value}').join(', ');

    final stopwatch = Stopwatch()..start();
    Response<T> response;
    bool isTimeout = false;
    final timeout = timeoutDuration;

    try {
      try {
        final completer = Completer<Response<T>>();
        final timer = Timer(timeout, () {
          isTimeout = true;
          if (!completer.isCompleted) {
            completer.complete(
              Response<T>(
                statusCode: 408,
                statusText:
                    'The server is taking too long to respond. Please try again.',
              ),
            );
          }
        });

        call().then(
          (res) {
            if (!completer.isCompleted) {
              timer.cancel();
              completer.complete(res);
            }
          },
          onError: (Object e, StackTrace s) {
            if (!completer.isCompleted) {
              timer.cancel();
              completer.completeError(e, s);
            }
          },
        );

        response = await completer.future;
      } on SocketException catch (e) {
        response = Response<T>(
          statusCode: null,
          statusText: e.message.isNotEmpty ? e.message : e.toString(),
        );
      } on TimeoutException {
        isTimeout = true;
        response = Response<T>(
          statusCode: 408,
          statusText:
              'The server is taking too long to respond. Please try again.',
        );
      }

      stopwatch.stop();
      final durationMs = stopwatch.elapsedMilliseconds;

      // Check if response indicates timeout
      if (!isTimeout) {
        if (response.statusCode == 408 ||
            (response.statusText != null &&
                (response.statusText!.toLowerCase().contains('timeout') ||
                    response.statusText!.toLowerCase().contains(
                      'timed out',
                    )))) {
          isTimeout = true;
        } else if ((response.statusCode == null || response.statusCode == 0) &&
            durationMs >= (timeout.inMilliseconds - 500)) {
          isTimeout = true;
        }
      }

      if (isTimeout) {
        response = Response<T>(
          statusCode: 408,
          statusText:
              'The server is taking too long to respond. Please try again.',
          headers: response.headers,
          body: response.body,
          request: response.request,
        );
      } else if (response.status.connectionError ||
          response.statusCode == null ||
          response.statusCode == 0) {
        final isOnline = await connectivityChecker();
        _lastKnownOnlineStatus = isOnline;

        if (!isOnline) {
          response = Response<T>(
            statusCode: 0,
            statusText: 'No internet connection. Please check your connection.',
            headers: response.headers,
            body: response.body,
            request: response.request,
          );
        } else {
          response = Response<T>(
            statusCode: 0,
            statusText:
                'Unable to reach the server right now. Please try again.',
            headers: response.headers,
            body: response.body,
            request: response.request,
          );
        }
      }

      if (enableLogging) {
        _logRequestAndResponse(
          method: method,
          fullUrl: fullUrl,
          headersStr: headersStr,
          requestBody: body,
          response: response,
          durationMs: durationMs,
          isTimeout: isTimeout,
        );
      }

      // Check for 401 unauthorized session failure on protected endpoints
      if (response.statusCode == 401 &&
          shouldHandleUnauthorized(fullUrl, 401)) {
        if (isRetry) {
          // Prevent infinite refresh loop: already retried once
          authService?.handleUnauthorized();
          return response;
        }

        final currentRefresh = authService?.currentRefreshToken;
        if (currentRefresh != null && currentRefresh.isNotEmpty) {
          final refreshed = await refreshTokenSafely();
          if (refreshed) {
            if (headers != null && headers.containsKey('Authorization')) {
              final newToken = authService?.currentToken;
              if (newToken != null && newToken.isNotEmpty) {
                headers['Authorization'] = 'Bearer $newToken';
              }
            }
            return _loggedCall<T>(
              method,
              url,
              body,
              call,
              headers: headers,
              query: query,
              isRetry: true,
            );
          }
        }
        authService?.handleUnauthorized();
      }

      return response;
    } catch (error) {
      stopwatch.stop();
      if (enableLogging) {
        _logRequestAndException(
          method: method,
          fullUrl: fullUrl,
          headersStr: headersStr,
          requestBody: body,
          error: error,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }
      rethrow;
    }
  }

  String _resolveFullUrl(String? url, Map<String, dynamic>? query) {
    final effectiveUrl = url ?? '';
    String resolved;
    if (effectiveUrl.startsWith('http://') ||
        effectiveUrl.startsWith('https://')) {
      resolved = effectiveUrl;
    } else {
      final base = baseUrl ?? defaultBaseUrl;
      final cleanBase = base.endsWith('/')
          ? base.substring(0, base.length - 1)
          : base;
      final cleanUrl = effectiveUrl.startsWith('/')
          ? effectiveUrl
          : '/$effectiveUrl';
      resolved = '$cleanBase$cleanUrl';
    }

    if (query != null && query.isNotEmpty) {
      final queryString = query.entries
          .map(
            (e) =>
                '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value?.toString() ?? '')}',
          )
          .join('&');
      resolved = resolved.contains('?')
          ? '$resolved&$queryString'
          : '$resolved?$queryString';
    }

    return resolved;
  }

  static dynamic _maskSensitiveData(dynamic data) {
    // Unmasked as requested: "dont masked anything"
    if (data is Map) {
      final result = <String, dynamic>{};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final lower = key.toLowerCase();
        if (_isDocumentOrBinaryKey(lower)) {
          result[key] = '[Document/Binary data omitted]';
        } else {
          result[key] = _maskSensitiveData(entry.value);
        }
      }
      return result;
    } else if (data is List) {
      if (data is List<int> && data.length > 32) {
        return '[Binary bytes (${data.length} bytes)]';
      }
      return data.map((item) => _maskSensitiveData(item)).toList();
    } else if (data is FormData) {
      return _maskFormData(data);
    } else if (data is String) {
      final trimmed = data.trim();
      if ((trimmed.startsWith('{') && trimmed.endsWith('}')) ||
          (trimmed.startsWith('[') && trimmed.endsWith(']'))) {
        try {
          final decoded = jsonDecode(trimmed);
          return _maskSensitiveData(decoded);
        } catch (_) {
          return data;
        }
      }
      return data;
    }
    return data;
  }

  static bool _isDocumentOrBinaryKey(String key) {
    return key.contains('filebytes') ||
        key.contains('docbytes') ||
        key.contains('attachment') ||
        key.contains('base64');
  }

  static Map<String, dynamic> _maskFormData(FormData formData) {
    final fields = <String, dynamic>{};
    for (final field in formData.fields) {
      fields[field.key] = field.value;
    }
    final files = formData.files.map((f) {
      return '${f.key}: ${f.value.filename} (${f.value.length} bytes)';
    }).toList();

    return {
      if (fields.isNotEmpty) 'fields': fields,
      if (files.isNotEmpty) 'files': files,
    };
  }

  static String _formatPayload(dynamic data) {
    if (data == null) return 'None';
    final masked = _maskSensitiveData(data);
    try {
      const encoder = JsonEncoder.withIndent('  ');
      if (masked is Map || masked is List) {
        return encoder.convert(masked);
      }
      return masked.toString();
    } catch (_) {
      return masked.toString();
    }
  }

  void _logRequestAndResponse({
    required String method,
    required String fullUrl,
    required String headersStr,
    required dynamic requestBody,
    required Response response,
    required int durationMs,
    bool isTimeout = false,
  }) {
    final statusCode = response.statusCode;
    final isConnectionError =
        response.status.connectionError ||
        statusCode == null ||
        statusCode == 0;
    final isOk = response.isOk;

    final String statusBadge;
    if (isTimeout || statusCode == 408) {
      statusBadge = '⏱️ TIMEOUT';
    } else if (isConnectionError) {
      statusBadge = '📡 NO CONNECTION';
    } else if (statusCode >= 200 && statusCode < 300) {
      statusBadge = '🟢 SUCCESS $statusCode';
    } else if (statusCode >= 400 && statusCode < 500) {
      statusBadge = '🟠 CLIENT ERROR $statusCode';
    } else if (statusCode >= 500) {
      statusBadge = '🔴 SERVER ERROR $statusCode';
    } else {
      statusBadge = '⚪ $statusCode';
    }

    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('🌐 [API REQUEST] → $method $fullUrl');
    buffer.writeln('Headers: $headersStr');
    if (requestBody != null) {
      buffer.writeln('Request Body:');
      buffer.writeln(_formatPayload(requestBody));
    }
    buffer.writeln();

    buffer.writeln('📥 [API RESPONSE] ← $statusBadge (${durationMs}ms)');
    if (isTimeout || statusCode == 408) {
      buffer.writeln('Error: The server is taking too long to respond. Please try again.');
    } else if (isConnectionError) {
      final isOffline =
          response.statusText ==
              'No internet connection. Please check your connection.' ||
          _lastKnownOnlineStatus == false;
      if (isOffline) {
        buffer.writeln('Error: No internet connection. Please check your connection.');
      } else {
        buffer.writeln('Error: Unable to reach the server right now. Please try again.');
      }
    } else if (!isOk) {
      final errorMsg = extractErrorMessage(response);
      buffer.writeln('Error: $errorMsg');
    }

    if (response.headers != null && response.headers!.isNotEmpty) {
      final respHeadersStr = response.headers!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      buffer.writeln('Response Headers: $respHeadersStr');
    }

    final responsePayload = response.body ?? response.bodyString;
    if (responsePayload != null) {
      buffer.writeln('Response Body:');
      buffer.writeln(_formatPayload(responsePayload));
    } else {
      buffer.writeln('Response Body: <empty>');
    }
    buffer.write('═══════════════════════════════════════════════════════════════');

    _log(buffer.toString());
  }

  void _logRequestAndException({
    required String method,
    required String fullUrl,
    required String headersStr,
    required dynamic requestBody,
    required dynamic error,
    required int durationMs,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('═══════════════════════════════════════════════════════════════');
    buffer.writeln('🌐 [API REQUEST] → $method $fullUrl');
    buffer.writeln('Headers: $headersStr');
    if (requestBody != null) {
      buffer.writeln('Request Body:');
      buffer.writeln(_formatPayload(requestBody));
    }
    buffer.writeln();
    buffer.writeln('💥 [API RESPONSE EXCEPTION] (${durationMs}ms)');
    buffer.writeln('Error: $error');
    buffer.write('═══════════════════════════════════════════════════════════════');

    _log(buffer.toString());
  }

  static void _log(String message) {
    if (logWriter != null) {
      logWriter!(message);
      return;
    }

    // Line-by-line print to prevent Android Logcat & VS Code / Studio console truncation
    // Standard terminal/logcat buffers truncate at 1024 characters per print.
    for (final line in message.split('\n')) {
      // ignore: avoid_print
      print(line);
    }
  }

  /// Public logging hook for repositories/controllers to log API events.
  static void log(String message) => _log(message);

  // ── Error Message Parsing ───────────────────────────────────────────────────

  /// Parses error message from backend response or network error.
  /// Distinguishes between device offline, backend unreachable, timeouts,
  /// HTTP 5xx server errors, and HTTP 4xx client errors.
  static String extractErrorMessage(Response response, {bool? isDeviceOnline}) {
    // 1. Timeout check
    if (response.statusCode == 408 ||
        (response.statusText != null &&
            (response.statusText!.contains('taking too long') ||
                response.statusText!.toLowerCase().contains('timeout') ||
                response.statusText!.toLowerCase().contains('timed out')))) {
      return 'The server is taking too long to respond. Please try again.';
    }

    // 2. Connection / Network error (statusCode == null or 0, or connectionError)
    if (response.status.connectionError ||
        response.statusCode == null ||
        response.statusCode == 0) {
      if (response.statusText ==
          'No internet connection. Please check your connection.') {
        return 'No internet connection. Please check your connection.';
      }
      if (response.statusText ==
          'Unable to reach the server right now. Please try again.') {
        return 'Unable to reach the server right now. Please try again.';
      }
      final online = isDeviceOnline ?? _lastKnownOnlineStatus;
      if (online == false) {
        return 'No internet connection. Please check your connection.';
      }
      return 'Unable to reach the server right now. Please try again.';
    }

    // 3. HTTP 502/503/504 Server starting up or temporarily unavailable
    if (response.statusCode == 502 ||
        response.statusCode == 503 ||
        response.statusCode == 504) {
      return 'Server is currently starting up or temporarily unavailable. Please try again in a moment.';
    }

    // 4. Backend custom error messages in body
    if (response.body is Map) {
      final error = response.body['error'];
      final msg = response.body['message'];

      // For 400 validation errors, extract specific validation description
      if (response.statusCode == 400) {
        if (error != null && error.toString().trim().isNotEmpty) {
          return error.toString().trim();
        }
        if (msg != null && msg.toString().trim().isNotEmpty) {
          return msg.toString().trim();
        }
      }

      final msgStr = msg?.toString().trim();
      final errStr = error?.toString().trim();
      final is5xx =
          response.statusCode != null &&
          response.statusCode! >= 500 &&
          response.statusCode! <= 599;

      if (msgStr != null && msgStr.isNotEmpty) {
        final lower = msgStr.toLowerCase();
        final isGenericServerErr =
            lower == 'server error' || lower == 'internal server error';
        if (!is5xx || !isGenericServerErr) {
          return msgStr;
        }
      }
      if (errStr != null && errStr.isNotEmpty) {
        final lower = errStr.toLowerCase();
        final isGenericServerErr =
            lower == 'server error' || lower == 'internal server error';
        if (!is5xx || !isGenericServerErr) {
          return errStr;
        }
      }
    }

    // 5. Standard status code messages
    if (response.statusCode == 400) {
      return 'Server validation failed. Please check the entered details.';
    }
    if (response.statusCode == 401) {
      return 'Invalid credentials or session expired.';
    }
    if (response.statusCode == 403) {
      return 'Access denied.';
    }
    if (response.statusCode == 404) {
      return 'Requested resource not found.';
    }
    if (response.statusCode != null &&
        response.statusCode! >= 500 &&
        response.statusCode! <= 599) {
      return 'Server error. Please try again later.';
    }

    if (response.statusText != null && response.statusText!.isNotEmpty) {
      return response.statusText!;
    }

    return 'Something went wrong. Please try again.';
  }

  /// Translates a Dart/HTTP exception into a user-friendly UI message.
  static String friendlyExceptionMessage(
    dynamic error, {
    bool? isDeviceOnline,
  }) {
    if (error == null) return 'Something went wrong. Please try again.';
    final str = error.toString().toLowerCase();
    if (str.contains('timeout') || str.contains('timed out')) {
      return 'The server is taking too long to respond. Please try again.';
    }
    final online = isDeviceOnline ?? _lastKnownOnlineStatus;
    if (online == false) {
      return 'No internet connection. Please check your connection.';
    }
    return 'Unable to reach the server right now. Please try again.';
  }
}
