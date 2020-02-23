import 'package:flutter/material.dart';
import 'package:restaurant_recommendator/zomato_client.dart';
import 'package:restaurant_recommendator/restaurant.dart';
import 'package:document_analysis/document_analysis.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

List<Restaurant> _favoriteRestaurants = List<Restaurant>();
List<Restaurant> _restaurantsDisplay = List<Restaurant>();
List<Restaurant> _showRestaurantFixed = List<Restaurant>();
List<double> _weightRatingShow = List<double>();
final _client = ZomatoClient();

_launchURL(String urlR) async {
  String url = urlR;
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant Recommendator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Restaurant Recommendator'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

showAlertDialog(BuildContext context, String but, String tit) {
  Widget okButton = FlatButton(
    child: Text(but),
    onPressed: () {
      Navigator.of(context).pop();
    },
  );

  AlertDialog alert = AlertDialog(
    title: Text(tit),
    actions: [
      okButton,
    ],
  );

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 5.0,
        backgroundColor: Colors.grey[850],
        centerTitle: true,
        title: Text(
          widget.title,
          style: TextStyle(fontWeight: FontWeight.w300, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.dashboard),
          onPressed: () {
            if (_favoriteRestaurants.isEmpty) {
              showAlertDialog(context, 'Ok',
                  "You need to choose your favourite restaurant");
            } else {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => RecommenderRoute()));
            }
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              setState(() {
                _favoriteRestaurants.clear();
              });
            },
          )
        ],
      ),
      body: ListView.builder(
        itemCount: _favoriteRestaurants.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.all(7.0),
            color: Color.fromRGBO(255, 255, 255, 0.20),
            child: ListTile(
              onTap: () {
                _launchURL(_favoriteRestaurants[index].url);
              },
              title: Text(
                _favoriteRestaurants[index].name,
                style: TextStyle(
                    color: Colors.amber[700], fontWeight: FontWeight.w600),
              ),
              leading: new SizedBox(
                height: 100,
                width: 100,
                child: AspectRatio(
                  aspectRatio: 487 / 451,
                  child: new Container(
                    decoration: new BoxDecoration(
                        image: new DecorationImage(
                      fit: BoxFit.fitWidth,
                      alignment: FractionalOffset.topCenter,
                      image: (_favoriteRestaurants[index].imageUrl != null)
                          ? new NetworkImage(
                              _favoriteRestaurants[index].imageUrl)
                          : new NetworkImage(
                              'https://www.theblogstarter.com/wp-content/themes/germaniumify/images/thumbnail.jpg'),
                    )),
                  ),
                ),
              ),
              subtitle: Text(
                _favoriteRestaurants[index].address,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w300),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_favoriteRestaurants.length == 5) {
            showAlertDialog(context, 'Ok', "You already has 5 restaurants");
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchRoute()),
            );
          }
        },
        icon: Icon(
          Icons.add,
          color: Colors.black87,
        ),
        label: Text(
          'Add Your Favourite Restaurant',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w400),
        ), //Icon(Icons.add),

        backgroundColor: Color.fromRGBO(81, 157, 144, 1),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class RecommenderRoute extends StatefulWidget {
  @override
  _RecommenderRouteState createState() => _RecommenderRouteState();
}

class _RecommenderRouteState extends State<RecommenderRoute> {
  void getRecommendation() async {
    _showRestaurantFixed.clear();
    _weightRatingShow.clear();
    List<Restaurant> _showRestaurant = List<Restaurant>();
    List<double> _weightRating = List<double>();
    List<Restaurant> _restaurantsRecommended = List<Restaurant>();
    var _combinedString = '';
    for (int a = 0; a < _favoriteRestaurants.length; a++) {
      List<String> temp = _favoriteRestaurants[a].cuisines.split(',');
      for (int b = 0; b < temp.length; b++) {
        _combinedString = _combinedString + temp[b].trim() + ' ';
      }
      List<String> tempB = _favoriteRestaurants[a].name.split(' ');
      for (int b = 0; b < tempB.length; b++) {
        _combinedString = _combinedString + tempB[b].trim() + ' ';
      }
    }
    var _tempToken = documentTokenizer([_combinedString]);
    var _wordFrequency = wordFrequencyProbability(_tempToken);
    var sortedEntries = _wordFrequency.entries.toList()
      ..sort((e1, e2) {
        var diff = e2.value.compareTo(e1.value);
        if (diff == 0.0) diff = e2.key.compareTo(e1.key);
        return diff;
      });
    var newMap = Map<String, double>.fromEntries(sortedEntries);
    for (int a = 0; a < (newMap.length * 0.7).ceil().toInt(); a++) {
      List<Restaurant> _tempRestaurants =
          await _client.fetchRestaurants('', newMap.keys.elementAt(a), '15');
      for (int b = 0; b < _tempRestaurants.length; b++) {
        bool notExist = false;
        ;
        for (int c = 0; c < _restaurantsRecommended.length; c++) {
          if (_restaurantsRecommended[c].id == _tempRestaurants[b].id) {
            c = _restaurantsRecommended.length;
            notExist = true;
          }
        }
        for (int c = 0; c < _favoriteRestaurants.length; c++) {
          if (_favoriteRestaurants[c].id == _tempRestaurants[b].id) {
            c = _restaurantsRecommended.length;
            notExist = true;
          }
        }
        if (!notExist) {
          _restaurantsRecommended.add(_tempRestaurants[b]);
        }
      }
    }
    for (int a = 0; a < _restaurantsRecommended.length; a++) {
      for (int b = a + 1; b < _restaurantsRecommended.length;) {
        if (_restaurantsRecommended[a].name ==
            _restaurantsRecommended[b].name) {
          _restaurantsRecommended.removeAt(b);
        } else {
          b++;
        }
      }
    }
    for (int a = 0; a < _restaurantsRecommended.length; a++) {
      String _combinedString2 = '';
      List<String> temp = _restaurantsRecommended[a].cuisines.split(',');
      for (int b = 0; b < temp.length; b++) {
        _combinedString2 = _combinedString2 + temp[b].trim() + ' ';
      }
      List<String> tempB = _restaurantsRecommended[a].name.split(' ');
      for (int b = 0; b < tempB.length; b++) {
        _combinedString2 = _combinedString2 + tempB[b].trim() + ' ';
      }
      _weightRating.add(num.parse(
          wordFrequencySimilarity(_combinedString, _combinedString2)
              .toStringAsFixed(2)));
      _weightRating[_weightRating.length - 1] =
          _weightRating[_weightRating.length - 1] +
              num.parse(double.parse(_restaurantsRecommended[a].rating.average)
                  .toStringAsFixed(2));
    }
    for (int a = 0; a < _restaurantsRecommended.length - 1; a++) {
      for (int b = 0; b < _restaurantsRecommended.length - a - 1; b++) {
        if (_weightRating[b] < _weightRating[b + 1]) {
          var swapA = _weightRating[b + 1];
          _weightRating[b + 1] = _weightRating[b];
          _weightRating[b] = swapA;
          var swapB = _restaurantsRecommended[b + 1];
          _restaurantsRecommended[b + 1] = _restaurantsRecommended[b];
          _restaurantsRecommended[b] = swapB;
        }
      }
    }
    int maxAmount = _restaurantsRecommended.length < 10
        ? _restaurantsRecommended.length
        : 10;
    for (int a = 0; a < maxAmount; a++) {
      _showRestaurant.add(_restaurantsRecommended[a]);
    }
    setState(() {
      _weightRatingShow = _weightRating;
      _showRestaurantFixed = _showRestaurant;
    });
  }

  @override
  void initState() {
    getRecommendation();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        elevation: 5.0,
        backgroundColor: Colors.grey[850],
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Recommendation"),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          if (_showRestaurantFixed.length == 0) {
            return Center(
              child: Text('wait'),
            );
          } else {
            return Container(
              child: Card(
                color: Colors.grey[850],
                child: ListTile(
                  onTap: () {
                    _launchURL(_showRestaurantFixed[index].url);
                  },
                  trailing: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        Icons.star,
                        color: Colors.amber[400],
                      ),
                      Text(
                        ' ' + _showRestaurantFixed[index].rating.average,
                        style: TextStyle(color: Colors.amber[400]),
                      )
                    ],
                  ),
                  isThreeLine: true,
                  title: Text(
                    _showRestaurantFixed.elementAt(index).name,
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w400),
                  ),
                  leading: new SizedBox(
                    height: 100,
                    width: 100,
                    child: AspectRatio(
                      aspectRatio: 487 / 451,
                      child: new Container(
                        decoration: new BoxDecoration(
                            image: new DecorationImage(
                          fit: BoxFit.fitWidth,
                          alignment: FractionalOffset.topCenter,
                          image: (_showRestaurantFixed[index].imageUrl != null)
                              ? new NetworkImage(
                                  _showRestaurantFixed[index].imageUrl)
                              : new NetworkImage(
                                  'https://www.theblogstarter.com/wp-content/themes/germaniumify/images/thumbnail.jpg'),
                        )),
                      ),
                    ),
                  ),
                  subtitle: Text(
                    _showRestaurantFixed[index].address,
                    style: TextStyle(color: Color.fromRGBO(81, 157, 144, 1)),
                  ),
                ),
              ),
            );
          }
        },
        itemCount: _showRestaurantFixed.length,
      ),
    );
  }
}

class SearchRoute extends StatefulWidget {
  @override
  _SearchRouteState createState() => _SearchRouteState();
}

class _SearchRouteState extends State<SearchRoute> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        centerTitle: true,
        elevation: 5.0,
        backgroundColor: Colors.grey[850],
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Add Your Favourite Restaurant",
          style: TextStyle(fontSize: 18),
        ),
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return index == 0 ? _searchBar() : _listItem(index - 1);
        },
        itemCount: _restaurantsDisplay.length + 1,
      ),
    );
  }

  _searchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search...',
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white, width: 2.0),
            borderRadius: BorderRadius.circular(25.0),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.teal, width: 2.0),
            borderRadius: BorderRadius.circular(25.0),
          ),
        ),
        onChanged: (text) async {
          text = text.toLowerCase();
          List<Restaurant> _tempRestaurants =
              await _client.fetchRestaurants('', text, '10');
          setState(() {
            _restaurantsDisplay = _tempRestaurants.where((temp) {
              var restaurantName = temp.name.toLowerCase();
              return restaurantName.contains(text);
            }).toList();
          });
        },
      ),
    );
  }

  _listItem(index) {
    if (_favoriteRestaurants.contains(_restaurantsDisplay[index])) {
      return Card(
        color: Colors.orange,
        child: Padding(
          padding: const EdgeInsets.only(
              top: 32.0, bottom: 32.0, left: 16.0, right: 16.0),
          child: GestureDetector(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _restaurantsDisplay[index].name,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  _restaurantsDisplay[index].address,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container(
        child: Card(
          color: Colors.white,
          child: Container(
            child: GestureDetector(
              child: SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                        child: GestureDetector(
                            onTap: () {
                              _launchURL(_restaurantsDisplay[index].url);
                            },
                            child: Container(
                                padding: EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      _restaurantsDisplay[index].name,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _restaurantsDisplay[index].address,
                                      style: TextStyle(
                                          color: Colors.grey.shade600),
                                    ),
                                  ],
                                )))),
                    GestureDetector(
                      onTap: () {
                        _favoriteRestaurants.add(_restaurantsDisplay[index]);
                        Navigator.pop(context);
                      },
                      child: Container(
                          width: 80,
                          alignment: Alignment.center,
                          color: Colors.teal,
                          child: Icon(Icons.add)),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }
}
