class Place {
  String placeId;
  String? name;
  String? formattedAddress;
  String? formattedAddressZipPlus4;
  String? streetAddress;
  String? streetNumber;
  String? streetShort;
  String? street;
  String? city;
  String? county;
  String? state;
  String? stateShort;
  String? zipCode;
  String? zipCodeSuffix;
  String? zipCodePlus4;
  String? vicinity;
  String? country;
  double? lat;
  double? lng;
  String? neighborhood;

  Place(
      {this.name,
      this.formattedAddress,
      this.formattedAddressZipPlus4,
      this.streetAddress,
      this.streetNumber,
      this.streetShort,
      this.street,
      this.city,
      this.county,
      this.neighborhood,
      this.state,
      this.stateShort,
      this.zipCode,
      this.zipCodeSuffix,
      this.zipCodePlus4,
      this.vicinity,
      this.country,
      this.lat,
      this.lng,
      required this.placeId});

  factory Place.fromJson(Map<String, dynamic> json) {
    final Map<String, AddressComponent> components =
        (json['addressComponents'] as List).asMap().map((index, value) =>
            MapEntry(value['types'].first, AddressComponent.fromJson(value)));
    return Place(
      placeId: json['id'],
      name: json['displayName']['text'],
      formattedAddress: json['formattedAddress'],
      streetShort: components['route']?.shortName,
      streetNumber: components['street_number']?.longName,
      street: components['route']?.longName,
      city: components['administrative_area_level_2']?.longName,
      state: components['administrative_area_level_1']?.longName,
      stateShort: components['administrative_area_level_1']?.shortName,
      zipCode: components['postal_code']?.longName,
      zipCodeSuffix: components['postal_code_suffix']?.longName,
      country: components['country']?.longName,
      neighborhood: components['neighborhood']?.longName ??
          components['sublocality_level_1']?.longName,
      lat: json['location']['latitude'],
      lng: json['location']['longitude'],
    );
  }

  @override
  String toString() {
    return 'Place(name:$name formattedAddressZipPlus4:$formattedAddressZipPlus4 formattedAddress:$formattedAddress streetNumber: $streetNumber, streetShort: $streetShort street: $street, city: $city, state:$state startShort:$stateShort county: $county, zipCode: $zipCode zipCodeSuffix: $zipCodeSuffix zipCodePlus4:$zipCodePlus4)';
  }
}

class AddressComponent {
  String longName;
  String shortName;
  List<String> types;

  AddressComponent(
      {required this.longName, required this.shortName, required this.types});

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['longText'],
      shortName: json['shortText'],
      types: json['types'].cast<String>(),
    );
  }
}
