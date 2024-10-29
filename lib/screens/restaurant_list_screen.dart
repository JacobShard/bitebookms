import 'package:flutter/material.dart';

class RestaurantListScreen extends StatelessWidget {
  const RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Restaurant Listings'),
        backgroundColor: Colors.lightBlue[200],
      ),
      body: ListView(
        children: const <Widget>[
          ListTile(
            title: Text('The Food Place'),
            subtitle: Text('123 Main St'),
          ),
          ListTile(
            title: Text('Good Eats'),
            subtitle: Text('456 Oak Ave'),
          ),
          ListTile(
            title: Text('Tasty Treats'),
            subtitle: Text('789 Pine Rd'),
          ),
        ],
      ),
    );
  }
}
