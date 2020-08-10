import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/Meal.dart';

class HttpService {
  Future<List<Meal>> getMeals(String query) async {
    String mealDBURL = "https://www.themealdb.com/api/json/v1/1/";
    String searchMeal = "/search.php?s=" + query;
    var res = await http.get(mealDBURL + searchMeal);

    if (res.statusCode == 200) {
      var body = jsonDecode(res.body);
      if (body['meals'] != null) {
        var meals =
            body['meals'].map((dynamic item) => Meal.fromJson(item)).toList();
        return new List<Meal>.from(meals);
      } else {
        return new List<Meal>();
      }
    } else {
      throw "Error on loading meals";
    }
  }
}
