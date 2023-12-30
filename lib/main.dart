//importing the packages which are to be used in this particular app.
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


//This creates Album class, When we receive data from a network request
// it often comes in the form of JSON. The fromJson method in the Album class is likely used to convert a JSON representation into a Dart object.
class Album {
  final int id;
  final String title;

  Album({
    required this.id,
    required this.title,
  });
   // known as factory method to create album from json,
  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }
}

void main() => runApp(const MyApp());
//this defines the main appliction widget
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Album Data',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
     
      home: const AlbumScreen(),
    );
  }
}
// Manages the asynchronous loading of album data, displays a list of albums using FutureBuilder, and handles album deletion.
class AlbumScreen extends StatefulWidget {
  const AlbumScreen({Key? key}) : super(key: key);

  @override
  _AlbumScreenState createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late Future<List<Album>> futureAlbum;
//Basically this initialise futurealbum var with result of fetchalbum() func.
  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  @override
  //scaffold provides basic structure of visual interface includy body of appliction
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple, Colors.indigo],
          ),
        ),
        child: Center(
          child: FutureBuilder<List<Album>>(
            future: futureAlbum,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Album album = snapshot.data![index];
                    //This feature allows to delete album one by one by swipe gesture , this increase ui expirence
                    return Dismissible(
                      key: Key(album.id.toString()),
                      onDismissed: (direction) async {
                        await deleteAlbum(album.id);
                        setState(() {
                          futureAlbum = fetchAlbum(); // Refresh the list
                        });
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.all(10),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                      //i personally used this card to basically increase UI;
                      child: Card(
                        elevation: 5,
                        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: ListTile(
                          title: Text(
                            album.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('ID: ${album.id}'),
                        ),
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return const RefreshProgressIndicator();

            },
          ),
        ),
      ),
      //this is button that triggeers the display of a dialog to add new album
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final String? newAlbumTitle = await _showDialog(context);

          if (newAlbumTitle != null && newAlbumTitle.isNotEmpty) {
            Album newAlbum = await createAlbum(newAlbumTitle);
            setState(() {
              futureAlbum = fetchAlbum(); // Refresh the list
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  //Displays a dialog for adding a new album
  Future<String?> _showDialog(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    //basically it displays alertdialog for adding new album and gives title
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create New Album'),
          content: TextField(
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Exit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

//this part makes http get request to fetch the list of albums
Future<List<Album>> fetchAlbum() async {
  final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/albums'));
//this line basically checks whether the http response status code is =200, itmeans request is successful;
  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    List<Album> albums = data
        .map((json) => Album.fromJson(json as Map<String, dynamic>))
        .toList();
    return albums;
  } else {
    throw Exception('Failed to load album');
  }
}
//this part makes http post requestto create a new album with title you had given.
Future<Album> createAlbum(String title) async {
  final createUrl = Uri.parse('https://jsonplaceholder.typicode.com/albums');
  final headers = {'Content-Type': 'application/json; charset=UTF-8'};
  final albumData = {'title': title};
  final response = await http.post(createUrl, headers: headers, body: jsonEncode(albumData));
//basically this line is responsible in checkng if resources had been successfully created;
  if (response.statusCode == 201) {
    return Album.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to create album');
  }
}
//this part makes http delete requset to delete an album with specified id.
Future<void> deleteAlbum(int id) async {
  final deleteUrl = Uri.parse('https://jsonplaceholder.typicode.com/albums/$id');
  final response = await http.delete(deleteUrl);
//here if reuest is not successfully done then message is hardcoded as failed to delete album.
  if (response.statusCode != 200) {
    throw Exception('Failed to delete album');
  }
}
