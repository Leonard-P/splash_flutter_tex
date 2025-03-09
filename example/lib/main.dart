import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

import 'tex_view_carousel_example.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Create a controller pool for our app
  final SharedTexViewControllerPool _controllerPool =
      SharedTexViewControllerPool(maxControllers: 3);

  @override
  void dispose() {
    // Dispose the controller pool when the app is terminated
    _controllerPool.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TeXViewControllerProvider(
      pool: _controllerPool,
      child: MaterialApp(
        title: 'Flutter TeX Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter TeX Examples'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SharedControllerTeXView(
                id: "f",
                child: TeXViewDocument(
                    "<p style=\"padding: 0\"> Some multiline quesiton that might span multiple lines- or might not öjksfha sölkadfhj aöslkdfj aöslkdfj öaslkdjf aöslkdfj !</p>"),
                controllerPool: TeXViewControllerProvider.poolOf(context)),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TexViewCarouselExample()));
              },
              child: const Text('TeX View Carousel Example'),
            ),
            // More examples can be added here
          ],
        ),
      ),
    );
  }
}
