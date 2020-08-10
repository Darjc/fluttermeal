import 'package:flutterdemo/MealList/models/Ingredient.dart';

class Meal {
  int id;
  String name;
  String category;
  String description;
  String image;
  String thumb;
  String youtubeVideo;
  List<Ingredient> ingredients;

  Meal(this.id, this.name, this.category, this.description, this.image,
      this.thumb, this.ingredients, this.youtubeVideo);

  factory Meal.fromJson(Map<String, dynamic> json) {
    int id = int.parse(json['idMeal'] as String);
    String video = json['strYoutube'] as String;
    String videoId = "";
    if (video != null && video.contains("v=")) {
      videoId = video.substring(video.indexOf("v=") + 2, video.length);
    }
    List<Ingredient> ingridients = new List<Ingredient>();

    for (int i = 0; i <= 40; i++) {
      if (i <= 20) {
        String ingredientName =
            json['strIngredient' + (i + 1).toString()] as String;
        if (ingredientName == null ||
            ingredientName.isEmpty ||
            ingredientName.length < 2) continue;

        Ingredient ingredient =
            new Ingredient((ingredientName == null) ? "" : ingredientName, "");
        ingridients.add(ingredient);
      } else {
        int index = i - 20;

        String ingredientMeasure =
            json['strMeasure' + (index).toString()] as String;

        if (ingredientMeasure == null ||
            ingredientMeasure.isEmpty ||
            ingredientMeasure.length < 2) continue;
        ingridients[index - 1].measure =
            (ingredientMeasure == null) ? "" : ingredientMeasure;
      }
    }
    return new Meal(
        id,
        json['strMeal'] as String,
        json['strCategory'] as String,
        json['strInstructions'] as String,
        json['strMealThumb'] as String,
        json['strMealThumb'] as String,
        ingridients,
        videoId);
  }
}
