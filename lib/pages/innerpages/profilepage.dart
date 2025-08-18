import 'package:flutter/material.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name,style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.green[800],
            centerTitle: true,

      ),
      body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(height: 20),
        Text(
          name,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          "${name} details go here",
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
        SizedBox(height: 20),
      ])),
    );
  }
}
