import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';

import '/model/place.dart';
import '/model/suggestion.dart';

class PlaceApiProvider {
  PlaceApiProvider(
      {required this.sessionToken,
      this.mapsApiKey,
      this.proxyServerAutocomplete,
      this.proxyServerDetails,
      this.componentCountry,
      this.language});

  final client = Client();
  final String sessionToken;
  final String? mapsApiKey;
  final String? componentCountry;
  final String? language;
  final Uri? proxyServerAutocomplete;
  final Uri? proxyServerDetails;

  /* Example JSON returned from Places autocomplete suggestions API request
    (ie.
      host: 'maps.googleapis.com',
        path: '/maps/api/place/autocomplete/json', )
    request below

result["predictions"] =
[
  {
    "description": "678 North Market Street, Redding, CA, USA",
    "matched_substrings": [
      {
        "length": 3,
        "offset": 0
      }
    ],
    "place_id": "ChIJiRzbkjrt0lQRVvD61FBwlmw",
    "reference": "ChIJiRzbkjrt0lQRVvD61FBwlmw",
    "structured_formatting": {
      "main_text": "678 North Market Street",
      "main_text_matched_substrings": [
        {
          "length": 3,
          "offset": 0
        }
      ],
      "secondary_text": "Redding, CA, USA"
    },
    "terms": [
      {
        "offset": 0,
        "value": "678"
      },
      {
        "offset": 4,
        "value": "North Market Street"
      },
      {
        "offset": 25,
        "value": "Redding"
      },
      {
        "offset": 34,
        "value": "CA"
      },
      {
        "offset": 38,
        "value": "USA"
      }
    ],
    "types": [
      "premise",
      "geocode"
    ]
  },

  ... repeating the other suggestions in same format
  
]
*/

  ///[includeFullSuggestionDetails] if we should include ALL details that are returned in API suggestions.
  ///   (This is sent as true when the `onInitialSuggestionClick` is in use)
  ///[postalCodeLookup] if we should request `postal_code` type return information
  ///   instead of address type information.
  Future<List<Suggestion>> fetchSuggestions(String input,
      {bool includeFullSuggestionDetails = false,
      bool postalCodeLookup = false}) async {
    final Map<String, dynamic> parameters = {
      'input': input,
      'types': postalCodeLookup ? 'postal_code' : 'address',
      'sessiontoken': sessionToken
    };

    if (proxyServerAutocomplete != null) {
      parameters['key'] = mapsApiKey;
    }
    if (language != null) {
      parameters['language'] = language;
    }
    if (componentCountry != null) {
      parameters['components'] = 'country:$componentCountry';
    }

    final Uri request = Uri(
        scheme: 'https',
        host: proxyServerAutocomplete?.host ?? 'maps.googleapis.com',
        path: proxyServerAutocomplete?.path ??
            '/maps/api/place/autocomplete/json',
        queryParameters: parameters);

    final response = await client.get(request);

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        // compose suggestions in a list
        return result['predictions'].map<Suggestion>((p) {
          if (includeFullSuggestionDetails) {
            // Package everything useful from API json
            final mainText = p['structured_formatting']?['main_text'];
            final secondaryText = p['structured_formatting']?['secondary_text'];
            final terms = p['terms']
                .map<String>((term) => term['value'] as String)
                .toList();
            final types =
                p['types'].map<String>((atype) => atype as String).toList();

            return Suggestion(p['place_id'], p['description'],
                mainText: mainText,
                secondaryText: secondaryText,
                terms: terms,
                types: types);
          } else {
            // just use the simple Suggestion parts we need
            return Suggestion(p['place_id'], p['description']);
          }
        }).toList();
      }
      if (result['status'] == 'ZERO_RESULTS') {
        return [];
      }
      throw Exception(result['error_message']);
    } else {
      throw const HttpException('Failed to fetch suggestion');
    }
  }

  /* EXAMPLE JSON returned from Places Detail
     (ie.   host: 'maps.googleapis.com',
        path: '/maps/api/place/details/json',  )
    request below:

result["result"]
{
  "address_components": [
    {
      "long_name": "6781",
      "short_name": "6781",
      "types": [
        "street_number"
      ]
    },
    {
      "long_name": "Eastside Road",
      "short_name": "Eastside Rd",
      "types": [
        "route"
      ]
    },
    {
      "long_name": "Metz Road",
      "short_name": "Metz Road",
      "types": [
        "neighborhood",
        "political"
      ]
    },
    {
      "long_name": "Anderson",
      "short_name": "Anderson",
      "types": [
        "locality",
        "political"
      ]
    },
    {
      "long_name": "Shasta County",
      "short_name": "Shasta County",
      "types": [
        "administrative_area_level_2",
        "political"
      ]
    },
    {
      "long_name": "California",
      "short_name": "CA",
      "types": [
        "administrative_area_level_1",
        "political"
      ]
    },
    {
      "long_name": "United States",
      "short_name": "US",
      "types": [
        "country",
        "political"
      ]
    },
    {
      "long_name": "96007",
      "short_name": "96007",
      "types": [
        "postal_code"
      ]
    },
    {
      "long_name": "9406",
      "short_name": "9406",
      "types": [
        "postal_code_suffix"
      ]
    }
  ],
  "formatted_address": "6781 Eastside Rd, Anderson, CA 96007, USA",
  "geometry": {
    "location": {
      "lat": 40.4839756,
      "lng": -122.34802
    },
    "viewport": {
      "northeast": {
        "lat": 40.48515498029149,
        "lng": -122.3471568197085
      },
      "southwest": {
        "lat": 40.48245701970849,
        "lng": -122.3498547802915
      }
    }
  },
  "name": "6781 Eastside Rd"
}
  */

  ///Requests full address info from Google Places API for the specified
  ///[placeId] and returns a [Place] object returned info.
  Future<Place> getPlaceDetailFromId(String placeId) async {
    // if you want to get the details of the selected place by place_id
    final Map<String, dynamic> parameters = <String, dynamic>{
      'place_id': placeId,
      'fields': 'name,formatted_address,address_component,geometry',
      'sessiontoken': sessionToken
    };
    final Uri request = Uri(
        scheme: proxyServerDetails?.scheme ?? 'https',
        host: proxyServerDetails?.host ?? 'maps.googleapis.com',
        path: proxyServerDetails?.path ?? '/maps/api/place/details/json',

        //PlaceApiNew     host: 'places.googleapis.com',
        //PlaceApiNew     path: '/v1/places/$placeId',

        queryParameters: parameters);

    if (proxyServerDetails != null) {
      parameters['key'] = mapsApiKey;
    }

    final response = await client.get(request);
    /* PlaceApiNew:
        , headers: {
            'X-Goog-Api-Key': mapsApiKey,
            'X-Goog-FieldMask': 'displayName,formattedAddress',
      });
    PlaceApiNew */

    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'OK') {
        final components =
            result['result']['address_components'] as List<dynamic>;

        // build result
        final place = Place();

        place.formattedAddress = result['result']['formatted_address'];
        place.name = result['result']['name'];
        place.lat = result['result']['geometry']['location']['lat'] as double;
        place.lng = result['result']['geometry']['location']['lng'] as double;

        for (var component in components) {
          final List type = component['types'];
          if (type.contains('street_address')) {
            place.streetAddress = component['long_name'];
          }
          if (type.contains('street_number')) {
            place.streetNumber = component['long_name'];
          }
          if (type.contains('route')) {
            place.street = component['long_name'];
            place.streetShort = component['short_name'];
          }
          if (type.contains('sublocality') ||
              type.contains('sublocality_level_1')) {
            place.vicinity = component['long_name'];
          }
          if (type.contains('locality')) {
            place.city = component['long_name'];
          }
          if (type.contains('administrative_area_level_2')) {
            place.county = component['long_name'];
          }
          if (type.contains('administrative_area_level_1')) {
            place.state = component['long_name'];
            place.stateShort = component['short_name'];
          }
          if (type.contains('country')) {
            place.country = component['long_name'];
          }
          if (type.contains('postal_code')) {
            place.zipCode = component['long_name'];
          }
          if (type.contains('postal_code_suffix')) {
            place.zipCodeSuffix = component['long_name'];
          }
        }

        place.zipCodePlus4 ??=
            '${place.zipCode}${place.zipCodeSuffix != null ? '-${place.zipCodeSuffix}' : ''}';
        if (place.streetNumber != null) {
          place.streetAddress ??= '${place.streetNumber} ${place.streetShort}';
          place.formattedAddress ??=
              '${place.streetNumber} ${place.streetShort}, ${place.city}, ${place.stateShort} ${place.zipCode}';
          place.formattedAddressZipPlus4 ??=
              '${place.streetNumber} ${place.streetShort}, ${place.city}, ${place.stateShort} ${place.zipCodePlus4}';
        }
        return place;
      }
      throw HttpException(result['error_message']);
    } else {
      throw const HttpException('Failed to fetch suggestion');
    }
  }
}
