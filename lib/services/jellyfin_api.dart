


import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/jellyfin_models.dart';

class JellyfinApi {
  static const _clientInfo =
      'MediaBrowser Client="Vantage", Device="Flutter", DeviceId="vantage_flutter", Version="1.0"';

  String _authHeader({String? token}) {
    if (token != null) {
      return 'MediaBrowser Token="$token", $_clientInfo';
    }
    return _clientInfo;
  }

  Map<String, String> _headers({String? token}) => {
        'Authorization': _authHeader(token: token),
        'Accept': 'application/json',
      };

  Future<AuthResult> authenticate(
      String serverUrl, String username, String password) async {
    final uri =
        Uri.parse('${serverUrl.trimRight()}/Users/AuthenticateByName');
    final response = await http
        .post(
          uri,
          headers: {
            ..._headers(),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'Username': username, 'Pw': password}),
        )
        .timeout(const Duration(seconds: 30));

    if (!response.statusCode.isSuccess) {
      throw Exception(
          'Auth failed (${response.statusCode}): ${response.body}');
    }
    return AuthResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ItemsResult> getItems(
    String serverUrl,
    String token,
    String userId, {
    String? parentId,
    String? includeItemTypes,
    bool recursive = true,
    int startIndex = 0,
    int limit = 20,
  }) async {
    final params = {
      'Recursive': '$recursive',
      'StartIndex': '$startIndex',
      'Limit': '$limit',
      'Fields': 'ImageTags,MediaType,Tags',
      'Tags': 'JellyEmu',
      'SortBy': 'SortName',
      'SortOrder': 'Ascending',
      if (parentId != null) 'ParentId': parentId,
      if (includeItemTypes != null) 'IncludeItemTypes': includeItemTypes,
    };

    final uri = Uri.parse('${serverUrl.trimRight()}/Users/$userId/Items')
        .replace(queryParameters: params);

    final response = await http
        .get(uri, headers: _headers(token: token))
        .timeout(const Duration(minutes: 5));

    if (!response.statusCode.isSuccess) {
      throw Exception(
          'getItems failed (${response.statusCode}): ${response.body}');
    }
    return ItemsResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<ItemsResult> getViews(
      String serverUrl, String token, String userId) async {
    final uri = Uri.parse('${serverUrl.trimRight()}/Users/$userId/Views');
    final response = await http
        .get(uri, headers: _headers(token: token))
        .timeout(const Duration(seconds: 30));
    if (!response.statusCode.isSuccess) {
      throw Exception('getViews failed (${response.statusCode})');
    }
    return ItemsResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Uint8List?> downloadSave(
    String serverUrl,
    String token,
    String userId,
    String itemId, {
    int? slot,
  }) async {
    var url = '${serverUrl.trimRight()}/jellyemu/save/$itemId/$userId';
    if (slot != null) url += '?slot=$slot';
    final response = await http
        .get(Uri.parse(url), headers: _headers(token: token))
        .timeout(const Duration(minutes: 5));
    if (response.statusCode == 404) return null;
    if (!response.statusCode.isSuccess) {
      throw Exception('Download save failed (${response.statusCode})');
    }
    return response.bodyBytes;
  }

  Future<void> uploadSave(
    String serverUrl,
    String token,
    String userId,
    String itemId,
    Uint8List data, {
    int? slot,
  }) async {
    var url = '${serverUrl.trimRight()}/jellyemu/save/$itemId/$userId';
    if (slot != null) url += '?slot=$slot';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            ..._headers(token: token),
            'Content-Type': 'application/octet-stream',
          },
          body: data,
        )
        .timeout(const Duration(minutes: 5));
    if (!response.statusCode.isSuccess) {
      throw Exception('Upload save failed (${response.statusCode})');
    }
  }

  Future<void> uploadSaveScreenshot(
    String serverUrl,
    String token,
    String userId,
    String itemId,
    int slot,
    String dataUrl,
  ) async {
    final url =
        '${serverUrl.trimRight()}/jellyemu/save-screenshot/$itemId/$userId/$slot';
    final response = await http
        .post(
          Uri.parse(url),
          headers: {
            ..._headers(token: token),
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'dataUrl': dataUrl}),
        )
        .timeout(const Duration(minutes: 2));
    if (!response.statusCode.isSuccess) {
      throw Exception('Upload screenshot failed (${response.statusCode})');
    }
  }
}

extension on int {
  bool get isSuccess => this >= 200 && this < 300;
}

