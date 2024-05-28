import '/api/place_api_provider.dart';
import '/model/place.dart';
import '/model/suggestion.dart';

class AddressService {
  AddressService(
      {required this.sessionToken,
      this.mapsApiKey,
      this.componentCountry,
      this.proxyServerAutocomplete,
      this.proxyServerDetails,
      this.language}) {
    apiClient = PlaceApiProvider(
        sessionToken: sessionToken,
        mapsApiKey: mapsApiKey,
        componentCountry: componentCountry,
        language: language,
        proxyServerAutocomplete: proxyServerAutocomplete,
        proxyServerDetails: proxyServerDetails);
  }

  final String sessionToken;
  final String? mapsApiKey;
  final String? componentCountry;
  final String? language;
  final Uri? proxyServerAutocomplete;
  final Uri? proxyServerDetails;
  late PlaceApiProvider apiClient;

  Future<List<Suggestion>> search(String query,
          {bool includeFullSuggestionDetails = false,
          bool postalCodeLookup = false}) async =>
      await apiClient.fetchSuggestions(query,
          includeFullSuggestionDetails: includeFullSuggestionDetails,
          postalCodeLookup: postalCodeLookup);

  Future<Place> getPlaceDetail(String placeId) async =>
      await apiClient.getPlaceDetailFromId(placeId);
}
