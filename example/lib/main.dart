import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';
import 'package:flutter_tex_example/tex_view_document_example.dart';
import 'package:flutter_tex_example/tex_view_fonts_example.dart';
import 'package:flutter_tex_example/tex_view_image_video_example.dart';
import 'package:flutter_tex_example/tex_view_ink_well_example.dart';
import 'package:flutter_tex_example/tex_view_markdown_example.dart';
import 'package:flutter_tex_example/tex_view_quiz_example.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text("Flutter TeX (Demo)"),
        ),
        body: Flexible(
          child: TeXView(child: TeXViewDocument("""<body>
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

        """)),
        ));
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
