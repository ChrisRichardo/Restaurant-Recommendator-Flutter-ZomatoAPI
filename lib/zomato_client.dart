import 'dart:async';
import 'dart:convert' show json;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:restaurant_recommendator/restaurant.dart';

class ZomatoClient {
  final _apiKey = '1272c4b03882596843565454200b09a2';
  final _host = 'developers.zomato.com';
  final _contextRoot = 'api/v2.1';

  Map<String, String> get _headers =>
      {'Accept': 'application/json', 'user-key': _apiKey};

  Future<Map> request(
      {@required String path, Map<String, String> parameters}) async {
    final uri = Uri.https(_host, '$_contextRoot/$path', parameters);
    final results = await http.get(uri, headers: _headers);
    if(results.statusCode == 500){
      return Map();
    }
    final jsonObject = json.decode(results.body);

    return jsonObject;
  }


  Future<List<Restaurant>> fetchRestaurants(
      String location, String query,String count) async {
    final results = await request(path: 'search', parameters: {
      //'entity_id': location,
      'q': query,
      'count': count
    });
    if(results.length != 0){
    final restaurants = results['restaurants']
        .map<Restaurant>((json) => Restaurant.fromJson(json['restaurant']))
        .toList(growable: false);

    return restaurants;
    }
    else{
      return [];
    }
  }

}