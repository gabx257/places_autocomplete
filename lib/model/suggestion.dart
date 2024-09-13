import 'dart:convert';

import 'package:http/http.dart';

class Suggestion {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;
  final List<String>? terms;
  final List<String>? types;
  Suggestion(
      {required this.placeId,
      required this.description,
      this.mainText,
      this.secondaryText,
      this.terms,
      this.types});

  factory Suggestion.fromJson(Map<String, dynamic> json) {
    return Suggestion(
      placeId: json['placeId'],
      description: json['text']['text'],
      mainText: json['structuredFormat']?['mainText']['text'],
      secondaryText: json['structuredFormat']?['secondaryText']['text'],
      terms: json['terms']?.map<String>((term) => term).toList(),
      types: json['types'].cast<String>(),
    );
  }

  static List<Suggestion> fromResponse(Response response) {
    final result = jsonDecode(response.body);

    return result['suggestions']
        .map((s) => Suggestion.fromJson(s['placePrediction']))
        .toList()
        .cast<Suggestion>();
  }

  @override
  String toString() {
    return "Suggestion(description:'$description', placeId:'$placeId', main_text:${mainText == null ? 'null' : "'$mainText'"}, secondary_text:${mainText == null ? 'null' : "'$secondaryText'"}, terms:${terms == null ? 'null' : terms.toString()}, types:${types == null ? 'null' : types.toString()})";
  }
}
