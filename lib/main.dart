import 'package:flutter/material.dart';
import 'package:flutterdemo/MealList/models/Ingredient.dart';
import 'MealList/api/HttpService.dart';
import 'MealList/models/Meal.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MealApp',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SearchMealApp(),
    );
  }
}

class SearchMealApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<Ingredient> ingredients = new List<Ingredient>();
    ingredients.add(new Ingredient("Papa", "1 kg"));
    ingredients.add(new Ingredient("Aceite", "1 Lt"));
    ingredients.add(new Ingredient("Pimienta", "1 cucharada"));
    ingredients.add(new Ingredient("Sal", "3 cucharadas"));

    //return DetailMealScreen(meal);
    return ChangeNotifierProvider(
        create: (context) => new SearchQuery(),
        child: Scaffold(appBar: SearchMealBar(), body: MealCardList()));
  }
}

class SearchMealBar extends StatefulWidget with PreferredSizeWidget {
  SearchMealBar({Key key}) : super(key: key);

  @override
  SearchMealBarState createState() => new SearchMealBarState();

  @override
  Size get preferredSize => Size.fromHeight(50.0);
}

class SearchMealBarState extends State<SearchMealBar> {
  TextEditingController _searchQuery;
  bool searchView = false;

  @override
  Widget build(BuildContext context) {
    SearchQuery searchQuery = Provider.of<SearchQuery>(context);
    _searchQuery = new TextEditingController();
    _searchQuery.text = searchQuery.query;

    Widget title = new Text('Search Meals');
    Widget textField = new TextField(
      controller: _searchQuery,
      onSubmitted: (value) => {searchQuery.search(value)},
      style: new TextStyle(color: Colors.white, fontSize: 20),
      decoration: new InputDecoration(
          prefixIcon: new Icon(Icons.search, color: Colors.white),
          hintText: " Search...",
          border: InputBorder.none,
          hintStyle: new TextStyle(color: Colors.white, fontSize: 20)),
    );

    Widget appBarTitle = searchView ? textField : title;

    Icon actionIcon = new Icon(
      searchView ? Icons.cancel : Icons.search,
      color: Colors.white,
    );

    return new AppBar(centerTitle: true, title: appBarTitle, actions: <Widget>[
      new IconButton(
        icon: actionIcon,
        onPressed: () {
          if (searchView && _searchQuery.text.isNotEmpty) {
            searchQuery.stopSearching();
          }

          setState(() {
            this.searchView = !this.searchView;
          });
        },
      ),
    ]);
  }
}

class MealCardList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SearchQuery searchQuery = Provider.of<SearchQuery>(context);

    HttpService api = new HttpService();
    String query = searchQuery.query;

    return FutureBuilder(
        future: api.getMeals(query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData) {
            List<Meal> meals = snapshot.data;

            if (meals.isEmpty) {
              return Center(
                  child: Text("We haven't found results for: " + query));
            }

            return ListView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: meals.length,
              itemBuilder: (BuildContext context, int index) {
                return new MealCard(meals[index]);
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text("Paso un error"));
          }
        });
  }
}

class MealCard extends StatelessWidget {
  final Meal meal;
  MealCard(this.meal);

  Container getPicture(String thumb) {
    return new Container(
        width: 48.0,
        height: 48.0,
        decoration: new BoxDecoration(
            shape: BoxShape.circle,
            image: new DecorationImage(
                fit: BoxFit.fill, image: new NetworkImage(thumb))));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DetailMealScreen(meal)),
            ),
        child: new Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: getPicture(meal.thumb), // Image.network(meal.thumb),
                title: Text(meal.name),
                subtitle: Text(meal.category),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Image.network(meal.image),
              ),
              ButtonBar(
                children: <Widget>[
                  FlatButton(
                    child: Icon(Icons.favorite),
                    onPressed: () {},
                  ),
                  FlatButton(
                    child: Icon(Icons.share),
                    onPressed: () {},
                  )
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  meal.description.substring(0, 150) + "...",
                  textAlign: TextAlign.left,
                ),
              ),
              ButtonBar(
                alignment: MainAxisAlignment.start,
                children: <Widget>[
                  FlatButton(
                    child: const Text('SEE MORE'),
                    onPressed: () {/* ... */},
                  )
                ],
              )
            ],
          ),
        ));
  }
}

// State Provider

class SearchQuery with ChangeNotifier {
  bool isSearching = false;
  String query = "";

  void search(String query) {
    this.isSearching = true;
    this.query = query;
    notifyListeners();
  }

  void stopSearching() {
    this.isSearching = false;
    this.query = "";
    notifyListeners();
  }
}

// Detail screen
class DetailMealScreen extends StatefulWidget {
  Meal meal;
  DetailMealScreen(this.meal);

  @override
  DetailMealScreenState createState() => DetailMealScreenState(meal);
}

class DetailMealScreenState extends State<DetailMealScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  YoutubePlayerController _controller;
  TextEditingController _idController;
  TextEditingController _seekToController;

  PlayerState _playerState;
  YoutubeMetaData _videoMetaData;
  double _volume = 100;
  bool _muted = false;
  bool _isPlayerReady = false;

  Meal meal;

  DetailMealScreenState(this.meal);

  @override
  void initState() {
    _controller = YoutubePlayerController(
      initialVideoId: meal.youtubeVideo,
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: false,
        disableDragSeek: false,
        loop: false,
        isLive: false,
        forceHD: false,
        enableCaption: true,
      ),
    )..addListener(listener);

    _idController = TextEditingController();
    _seekToController = TextEditingController();
    _videoMetaData = const YoutubeMetaData();
    _playerState = PlayerState.unknown;
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    _controller.pause();
    super.deactivate();
  }

  @override
  void dispose() {
    _controller.dispose();
    _idController.dispose();
    _seekToController.dispose();
    super.dispose();
  }

  void listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {
        _playerState = _controller.value.playerState;
        _videoMetaData = _controller.metadata;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
        appBar: AppBar(title: Text(meal.name)),
        body: ListView.builder(
            itemCount: 1,
            itemBuilder: (BuildContext context, int index) {
              return Container(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        meal.image,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.fill,
                      ),
                      ListTile(
                          title: Text(meal.name),
                          subtitle: Text(meal.category),
                          trailing: Icon(Icons.favorite, color: Colors.blue)),
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          "Ingridients",
                          style: TextStyle(
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      IngredientList(meal.ingredients),
                      Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          "Instruccions",
                          style: TextStyle(
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16, top: 16),
                        child: Text(
                          meal.description,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 16, top: 16),
                        child: Text(
                          "Watch Video",
                          style: TextStyle(
                            fontSize: 24,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                          padding: EdgeInsets.only(bottom: 100, top: 16),
                          child: YoutubePlayer(
                            controller: _controller,
                            showVideoProgressIndicator: true,
                            onReady: () {
                              _controller.addListener(listener);
                            },
                          ))
                    ]),
              );
            }));
  }
}

class IngredientList extends StatelessWidget {
  List<Ingredient> ingredients;
  IngredientList(this.ingredients);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    List<Widget> views = new List<Widget>();
    for (int i = 0; i < ingredients.length; i++) {
      Padding view = new Padding(
          padding: EdgeInsets.only(left: 16.0, right: 16.0),
          child: ListTile(
              title: Text(ingredients[i].name),
              subtitle: Text(ingredients[i].measure)));

      views.add(view);
    }
    return new Column(children: views);
  }
}
