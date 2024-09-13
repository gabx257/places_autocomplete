import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

import '/model/place.dart';
import '/model/suggestion.dart';

class PlaceApiProvider {
  late final Client _client;
  final String sessionToken;
  final String? mapsApiKey;
  final List<String>? componentCountry;
  final String? language;
  final Uri? proxyServerAutocomplete;
  final Uri? proxyServerDetails;

  PlaceApiProvider(
      {required this.sessionToken,
      this.mapsApiKey,
      this.proxyServerAutocomplete,
      this.proxyServerDetails,
      this.componentCountry,
      this.language,
      Client? client}) {
    _client = client ?? Client();
  }

  /// Fetches a list of suggestions based on the provided input.
  ///
  /// Returns a [Future] that resolves to a list of [Suggestion] objects.
  /// Throws an [HttpException] if the suggestion fetching fails.
  Future<List<Suggestion>> fetchSuggestions(String input) async {
    final Map<String, dynamic> parameters = {
      'input': input,
      'sessionToken': sessionToken
    };

    if (proxyServerAutocomplete == null) parameters['key'] = mapsApiKey;

    if (language != null) parameters['languageCode'] = language;

    if (componentCountry != null) {
      parameters['includedRegionCodes'] = componentCountry;
    }

    final Uri request = Uri(
        scheme: proxyServerAutocomplete?.scheme ?? 'https',
        host: proxyServerAutocomplete?.host ?? 'maps.googleapis.com',
        path: proxyServerAutocomplete?.path ??
            '/maps/api/place/autocomplete/json',
        port: proxyServerAutocomplete?.port,
        queryParameters: parameters);

    final response = await _client.get(request);

    if (response.statusCode != 200) {
      kDebugMode ? print('Failed to fetch suggestion: ${response.body}') : null;
      throw const HttpException('Failed to fetch suggestion');
    }
    return Suggestion.fromResponse(response);
  }

  Future<Place> getPlaceDetailFromId(String placeId,
      {List<String>? fields}) async {
    final Map<String, dynamic> parameters = <String, dynamic>{
      'place_id': placeId,
      'fields': fields ??
          'id,displayName,formattedAddress,addressComponents,location,plusCode',
      'sessionToken': sessionToken
    };
    final Uri request = Uri(
        scheme: proxyServerDetails?.scheme ?? 'https',
        host: proxyServerDetails?.host ?? 'maps.googleapis.com',
        path: proxyServerDetails?.path ?? '/maps/api/place/details/json',
        port: proxyServerDetails?.port,
        queryParameters: parameters);

    if (proxyServerDetails != null) parameters['key'] = mapsApiKey;

    final response = await _client.get(request);

    if (response.statusCode != 200) {
      kDebugMode ? print('Failed to fetch place: ${response.body}') : null;
      throw const HttpException('Failed to fetch place');
    }
    final result = json.decode(response.body);

    final place = Place.fromJson(result);

    return place;
  }
}
