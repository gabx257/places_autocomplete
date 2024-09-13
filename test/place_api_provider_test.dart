import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_places_autocomplete_widgets/api/place_api_provider.dart';
import 'package:google_maps_places_autocomplete_widgets/model/place.dart';
import 'package:google_maps_places_autocomplete_widgets/model/suggestion.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'dart:convert';

void main() {
  group('PlaceApiProvider', () {
    mockClientHandler(Request request) async {
      switch (request.url.path) {
        case '/place':
          return Response(
              jsonEncode({
                "suggestions": [
                  {
                    "placePrediction": {
                      "place": "places/ChIJ5YQQf1GHhYARPKG7WLIaOko",
                      "placeId": "ChIJ5YQQf1GHhYARPKG7WLIaOko",
                      "text": {
                        "text":
                            "Amoeba Music, Haight Street, San Francisco, CA, USA",
                        "matches": [
                          {"endOffset": 6}
                        ]
                      },
                      "structuredFormat": {
                        "mainText": {
                          "text": "Amoeba Music",
                          "matches": [
                            {"endOffset": 6}
                          ]
                        },
                        "secondaryText": {
                          "text": "Haight Street, San Francisco, CA, USA"
                        }
                      },
                      "types": [
                        "home_goods_store",
                        "establishment",
                        "store",
                        "point_of_interest",
                        "electronics_store"
                      ]
                    }
                  },
                  {
                    "placePrediction": {
                      "place": "places/ChIJ5YQQf1GHhYARPKG7WLIaOko",
                      "placeId": "ChIJ5YQQf1GHhYARPKG7WLIaOko",
                      "text": {
                        "text":
                            "Amoeba Music, Haight Street, San Francisco, CA, USA",
                        "matches": [
                          {"endOffset": 6}
                        ]
                      },
                      "structuredFormat": {
                        "mainText": {
                          "text": "Amoeba Music",
                          "matches": [
                            {"endOffset": 6}
                          ]
                        },
                        "secondaryText": {
                          "text": "Haight Street, San Francisco, CA, USA"
                        }
                      },
                      "types": [
                        "home_goods_store",
                        "establishment",
                        "store",
                        "point_of_interest",
                        "electronics_store"
                      ]
                    }
                  }
                ]
              }),
              200);

        case '/details':
          return Response(
              jsonEncode({
                "id":
                    "EjJSLiBBdWd1c3RhIC0gQ29uc29sYcOnw6NvLCBTw6NvIFBhdWxvIC0gU1AsIEJyYXppbCIuKiwKFAoSCQdQLvHMWc6UEXxRAEkSAks5EhQKEgktsqyqylnOlBF-UxSq0mRI8Q",
                "formattedAddress":
                    "R. Augusta - Consolação, São Paulo - SP, Brazil",
                "addressComponents": [
                  {
                    "longText": "Rua Augusta",
                    "shortText": "R. Augusta",
                    "types": ["route"],
                    "languageCode": "pt"
                  },
                  {
                    "longText": "Consolação",
                    "shortText": "Consolação",
                    "types": [
                      "sublocality_level_1",
                      "sublocality",
                      "political"
                    ],
                    "languageCode": "pt"
                  },
                  {
                    "longText": "São Paulo",
                    "shortText": "São Paulo",
                    "types": ["administrative_area_level_2", "political"],
                    "languageCode": "pt"
                  },
                  {
                    "longText": "São Paulo",
                    "shortText": "SP",
                    "types": ["administrative_area_level_1", "political"],
                    "languageCode": "pt"
                  },
                  {
                    "longText": "Brazil",
                    "shortText": "BR",
                    "types": ["country", "political"],
                    "languageCode": "en"
                  }
                ],
                "location": {"latitude": -23.5539749, "longitude": -46.655794},
                "displayName": {"text": "Augusta Street", "languageCode": "en"}
              }),
              200);
        default:
          return Response('Not Found', 404);
      }
    }

    MockClient mockClient = MockClient(mockClientHandler);
    PlaceApiProvider placeApiProvider = PlaceApiProvider(
      sessionToken: 'test-session-token',
      mapsApiKey: 'test-api-key',
      proxyServerAutocomplete: Uri.parse('http://localhost.com/place'),
      proxyServerDetails: Uri.parse('http://localhost.com/details'),
      componentCountry: ['us'],
      language: 'en',
      client: mockClient,
    );

    test('fetchSuggestions returns list of suggestions on success', () async {
      final suggestions =
          await placeApiProvider.fetchSuggestions('rua augusta');

      expect(suggestions, isA<List<Suggestion>>());
      expect(suggestions.length, 2);
      expect(suggestions[0].placeId, 'ChIJ5YQQf1GHhYARPKG7WLIaOko');
      expect(suggestions[0].description,
          'Amoeba Music, Haight Street, San Francisco, CA, USA');
      expect(suggestions[0].mainText, 'Amoeba Music');
      expect(suggestions[0].secondaryText,
          'Haight Street, San Francisco, CA, USA');
      expect(suggestions[0].terms, isNull);
      expect(suggestions[0].types, [
        'home_goods_store',
        'establishment',
        'store',
        'point_of_interest',
        'electronics_store'
      ]);

      expect(suggestions[1].placeId, 'ChIJ5YQQf1GHhYARPKG7WLIaOko');
      expect(suggestions[1].description,
          'Amoeba Music, Haight Street, San Francisco, CA, USA');
      expect(suggestions[1].mainText, 'Amoeba Music');
      expect(suggestions[1].secondaryText,
          'Haight Street, San Francisco, CA, USA');
      expect(suggestions[1].terms, isNull);
      expect(suggestions[1].types, [
        'home_goods_store',
        'establishment',
        'store',
        'point_of_interest',
        'electronics_store'
      ]);
    });

    test('getPlaceDetailFromId returns place details on success', () async {
      final place =
          await placeApiProvider.getPlaceDetailFromId('test-place-id');

      expect(place, isA<Place>());
      expect(place.placeId,
          'EjJSLiBBdWd1c3RhIC0gQ29uc29sYcOnw6NvLCBTw6NvIFBhdWxvIC0gU1AsIEJyYXppbCIuKiwKFAoSCQdQLvHMWc6UEXxRAEkSAks5EhQKEgktsqyqylnOlBF-UxSq0mRI8Q');
      expect(place.name, 'Augusta Street');
      expect(place.formattedAddress,
          'R. Augusta - Consolação, São Paulo - SP, Brazil');
      expect(place.formattedAddressZipPlus4, isNull);
      expect(place.streetAddress, isNull);
      expect(place.streetNumber, isNull);
      expect(place.streetShort, 'R. Augusta');
      expect(place.street, 'Rua Augusta');
      expect(place.city, 'São Paulo');
      expect(place.county, isNull);
      expect(place.neighborhood, 'Consolação');
      expect(place.state, 'São Paulo');
      expect(place.stateShort, 'SP');
      expect(place.zipCode, isNull);
      expect(place.zipCodeSuffix, isNull);
      expect(place.zipCodePlus4, isNull);
      expect(place.vicinity, isNull);
      expect(place.country, 'Brazil');
      expect(place.lat, -23.5539749);
      expect(place.lng, -46.655794);
    });
  });
}
