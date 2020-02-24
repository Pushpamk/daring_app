import 'package:flutter/material.dart';

import './tabs/index.dart';
import './utils/fonts.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
//   This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HookUps',
      theme: ThemeData(
          primarySwatch: Colors.red,
          primaryColorBrightness: Brightness.light,
          fontFamily: ProximaNovaSoftRegular),
      home: Index(),
    );
  }
}
