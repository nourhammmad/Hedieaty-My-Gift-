import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(title:const Text("Hedieaty",style: TextStyle(fontSize: 45,fontFamily: "Lobster",fontWeight:FontWeight.bold),),
          titleSpacing: 73.0,toolbarHeight: 70,
          leading: IconButton(onPressed: (){},alignment: Alignment.topLeft, icon: Icon(Icons.menu,size: 35,)),
          actions:[IconButton(onPressed: (){}, alignment: Alignment.topRight,icon: Icon(Icons.account_circle_outlined,size: 35,color: Colors.black,)),])
    );
  }
}
