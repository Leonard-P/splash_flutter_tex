import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex_example/tex_view_document_example.dart';
import 'package:flutter_tex_example/tex_view_fonts_example.dart';
import 'package:flutter_tex_example/tex_view_image_video_example.dart';
import 'package:flutter_tex_example/tex_view_ink_well_example.dart';
import 'package:flutter_tex_example/tex_view_markdown_example.dart';
import 'package:flutter_tex_example/tex_view_quiz_example.dart';

import 'tex_view_carousel_example.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  TeXRederingServer.renderingEngine = const TeXViewRenderingEngine.mathjax();

  if (!kIsWeb) {
    await TeXRederingServer.run();
    await TeXRederingServer.initController(customHeadContent: """
  <meta content="width=device-width, initial-scale=1.0" name="viewport">
  <style>
      body {
          font-family: Arial, sans-serif;
          text-align: center;
          margin: 20px;
      }
      .balance-container {
          display: flex;
          justify-content: center;
          align-items: center;
          margin-top: 40px;
          overflow: visible; /* Allow rotated elements to be visible */
          padding: 50px 0;  /* Extra vertical space for rotation */
      }
      .scale {
          width: 200px;
          height: 20px;
          background-color: gray;
          position: relative;
          transform-origin: center center; /* Rotate around its center */
      }
      .left-weight, .right-weight {
          width: 40px;
          height: 40px;
          background-color: blue;
          position: absolute;
          bottom: 20px;
          transition: transform 0.2s, left 0.2s, right 0.2s;
      }
      .left-weight { left: 20px; }
      .right-weight { right: 20px; }
      .pivot {
          width: 20px;
          height: 20px;
          background-color: red;
          position: absolute;
          bottom: -10px;
          left: 50%;
          transform: translateX(-50%);
      }
      .slider-container {
          margin-top: 20px;
      }
  </style>
  <script>
      function updateBalance() {
          const leftWeight = parseFloat(document.getElementById("leftWeight").value);
          const rightWeight = parseFloat(document.getElementById("rightWeight").value);
          const scale = document.querySelector(".scale");
          // Tilt the scale: difference multiplied by 2 degrees per unit difference
          const tilt = (rightWeight - leftWeight) * 2;
          scale.style.transform = `rotate(\${tilt}deg)`;
          
          // Adjust the positions of the weights:
          // When the left weight is heavier, move the left weight further left (smaller left offset)
          // and the right weight further right (larger right offset)
          const leftWeightElem = document.querySelector(".left-weight");
          const rightWeightElem = document.querySelector(".right-weight");
          // Calculate delta: 2px per unit difference
          const delta = (leftWeight - rightWeight) * 2;
          leftWeightElem.style.left = `\${20 - delta}px`;
          rightWeightElem.style.right = `\${20 + delta}px`;
      }
  </script>
  <title>Interactive Weight Balance</title>
    """);
  }

  runApp(const FlutterTeXExample());
}

class FlutterTeXExample extends StatelessWidget {
  const FlutterTeXExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TeXViewFullExample(),
    );
  }
}

class TeXViewFullExample extends StatefulWidget {
  const TeXViewFullExample({super.key});

  @override
  State<TeXViewFullExample> createState() => _TeXViewFullExampleState();
}

class _TeXViewFullExampleState extends State<TeXViewFullExample> {
  int radVal = 0;
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Flutter TeX (Demo)"),
          actions: [
            // Add a theme toggle button
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                setState(() {
                  isDarkMode = !isDarkMode;
                  _updateTheme(); // Update the injected head content
                });
              },
            ),
            // Add a button to test loading images
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: () {
                _addImage();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // TeXView example
              SizedBox(
                height: 500,
                child: TeXView(
                  child: _currentTeXViewDocument,
                  onRenderFinished: (height) {
                    if (kDebugMode) {
                      print("TeXView rendered with height: $height");
                    }
                  },
                ),
              ),
              const Divider(),
              // Button to open carousel example
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeXViewCarouselExample(),
                      ),
                    );
                  },
                  child: const Text('Open TeXView Carousel Example'),
                ),
              ),
              // Rest of the example buttons
              Column(
                children: [
                  getExampleButton(context, "TeXView Document Examples",
                      const TeXViewDocumentExamples()),
                  getExampleButton(context, "TeXView Quiz Examples",
                      const TeXViewQuizExample()),
                  getExampleButton(context, "TeXView Markdown Examples",
                      const TeXViewMarkdownExamples()),
                  getExampleButton(context, "TeXView Ink Well Examples",
                      const TeXViewInkWellExample()),
                  getExampleButton(context, "TeXView Image & Video Examples",
                      const TeXViewImageVideoExample()),
                ],
              ),
            ],
          ),
        ));
  }

  // Current TeXView document
  TeXViewDocument get _currentTeXViewDocument => TeXViewDocument(
        _includeImages ? _contentWithImages : _contentWithoutImages,
        autoResizeOnResourceLoad: true,
      );

  // Flag to toggle image content
  bool _includeImages = false;

  // Content without images
  final String _contentWithoutImages = """<body>
  <h2>Interactive Weight Balance</h2>
  
  <div class="slider-container">
      <label>
        Left Weight: 
        <input type="range" id="leftWeight" min="0" max="10" step="1" value="5" oninput="updateBalance()">
      </label>
      <br>
      <label>
        Right Weight: 
        <input type="range" id="rightWeight" min="0" max="10" step="1" value="5" oninput="updateBalance()">
      </label>
  </div>
  
  <div class="balance-container">
      <div class="scale">
          <div class="left-weight"></div>
          <div class="right-weight"></div>
          <div class="pivot"></div>
      </div>
  </div>
</body>
  """;

  // Content with images that will trigger height adjustment
  final String _contentWithImages = """<body>
  <h2>Interactive Weight Balance with Images</h2>
  
  <div class="slider-container">
      <label>
        Left Weight: 
        <input type="range" id="leftWeight" min="0" max="10" step="1" value="5" oninput="updateBalance()">
      </label>
      <br>
      <label>
        Right Weight: 
        <input type="range" id="rightWeight" min="0" max="10" step="1" value="5" oninput="updateBalance()">
      </label>
  </div>
  
  <div class="balance-container">
      <div class="scale">
          <div class="left-weight"></div>
          <div class="right-weight"></div>
          <div class="pivot"></div>
      </div>
  </div>
  
  <h3>Images will trigger automatic height adjustment</h3>
  <a data-flickr-embed="true" href="https://www.flickr.com/photos/186236561@N02/54364893402/in/pool-veryverylargephotos/" title="coast scene"><img src="https://live.staticflickr.com/65535/54364893402_3b8c9e560e_6k.jpg" width="400" alt="coast scene"/></a><script async src="//embedr.flickr.com/assets/client-code.js" charset="utf-8"></script>
  </body>
  """;

  // Toggle between content with and without images
  void _addImage() {
    setState(() {
      _includeImages = !_includeImages;
    });
  }

  // Method to update the theme by changing the injected CSS
  void _updateTheme() {
    if (kIsWeb) return;

    final darkThemeCSS = """
  <meta content="width=device-width, initial-scale=1.0" name="viewport">
  <style>
      body {
          font-family: Arial, sans-serif;
          text-align: center;
          margin: 20px;
          background-color: #121212;
          color: #ffffff;
      }
      .balance-container {
          display: flex;
          justify-content: center;
          align-items: center;
          margin-top: 40px;
          overflow: visible;
          padding: 50px 0;
      }
      .scale {
          width: 200px;
          height: 20px;
          background-color: #505050;
          position: relative;
          transform-origin: center center;
      }
      .left-weight, .right-weight {
          width: 40px;
          height: 40px;
          background-color: #4285F4;
          position: absolute;
          bottom: 20px;
          transition: transform 0.2s, left 0.2s, right 0.2s;
      }
      .left-weight { left: 20px; }
      .right-weight { right: 20px; }
      .pivot {
          width: 20px;
          height: 20px;
          background-color: #EA4335;
          position: absolute;
          bottom: -10px;
          left: 50%;
          transform: translateX(-50%);
      }
      .slider-container {
          margin-top: 20px;
      }
      input[type="range"] {
          background: #4285F4;
      }
  </style>
  <script>
      function updateBalance() {
          const leftWeight = parseFloat(document.getElementById("leftWeight").value);
          const rightWeight = parseFloat(document.getElementById("rightWeight").value);
          const scale = document.querySelector(".scale");
          // Tilt the scale: difference multiplied by 2 degrees per unit difference
          const tilt = (rightWeight - leftWeight) * 2;
          scale.style.transform = `rotate(\${tilt}deg)`;
          
          // Adjust the positions of the weights:
          // When the left weight is heavier, move the left weight further left (smaller left offset)
          // and the right weight further right (larger right offset)
          const leftWeightElem = document.querySelector(".left-weight");
          const rightWeightElem = document.querySelector(".right-weight");
          // Calculate delta: 2px per unit difference
          const delta = (leftWeight - rightWeight) * 2;
          leftWeightElem.style.left = `\${20 - delta}px`;
          rightWeightElem.style.right = `\${20 + delta}px`;
      }
  </script>
  <title>Interactive Weight Balance</title>
  
    """;

    final lightThemeCSS = """
  <meta content="width=device-width, initial-scale=1.0" name="viewport">
  <style>
      body {
          font-family: Arial, sans-serif;
          text-align: center;
          margin: 20px;
          background-color: #ffffff;
          color: #000000;
      }
      .balance-container {
          display: flex;
          justify-content: center;
          align-items: center;
          margin-top: 40px;
          overflow: visible;
          padding: 50px 0;
      }
      .scale {
          width: 200px;
          height: 20px;
          background-color: gray;
          position: relative;
          transform-origin: center center;
      }
      .left-weight, .right-weight {
          width: 40px;
          height: 40px;
          background-color: blue;
          position: absolute;
          bottom: 20px;
          transition: transform 0.2s, left 0.2s, right 0.2s;
      }
      .left-weight { left: 20px; }
      .right-weight { right: 20px; }
      .pivot {
          width: 20px;
          height: 20px;
          background-color: red;
          position: absolute;
          bottom: -10px;
          left: 50%;
          transform: translateX(-50%);
      }
      .slider-container {
          margin-top: 20px;
      }
  </style>
  <script>
      function updateBalance() {
          const leftWeight = parseFloat(document.getElementById("leftWeight").value);
          const rightWeight = parseFloat(document.getElementById("rightWeight").value);
          const scale = document.querySelector(".scale");
          const tilt = (rightWeight - leftWeight) * 2;
          scale.style.transform = `rotate(\${tilt}deg)`;
          
          const leftWeightElem = document.querySelector(".left-weight");
          const rightWeightElem = document.querySelector(".right-weight");
          const delta = (leftWeight - rightWeight) * 2;
          leftWeightElem.style.left = `\${20 - delta}px`;
          rightWeightElem.style.right = `\${20 + delta}px`;
      }
  </script>
  <title>Interactive Weight Balance (Light Mode)</title>
    """;

    // Update the custom head content based on the selected theme
    TeXRederingServer.updateCustomHeadContent(
        isDarkMode ? darkThemeCSS : lightThemeCSS);
  }

  getExampleButton(BuildContext context, String title, Widget widget) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: ElevatedButton(
        style: ButtonStyle(
            elevation: WidgetStateProperty.all(5),
            backgroundColor: WidgetStateProperty.all(Colors.white)),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => widget));
        },
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
