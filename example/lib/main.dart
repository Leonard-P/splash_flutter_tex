import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

main() async {
  TeXRederingServer.renderingEngine = const TeXViewRenderingEngine.mathjax();

  if (!kIsWeb) {
    await TeXRederingServer.run();
    await TeXRederingServer.initController();
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
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Flutter TeX Single Demo")),
      body: PageView(
        controller: _pageController,
        children: [
          // Keep one regular TeXView as an example
          buildTeXPage(
            r"""<p style="color:red;">Physics Formula</p>
            \(\displaystyle E = mc^2\)""",
            useIndependent: false,
          ),
          // Use IndependentTeXView for all others
          buildTeXPage(
            r"""<p style="background:yellow;">Math Derivative</p>
            \(\displaystyle \frac{d}{dx} x^n = nx^{n-1}\)""",
          ),
          buildTeXPage(
            r"""<p style="font-style:italic;">Chemistry Equation</p>
            \(\displaystyle H_2 + O_2 \rightarrow H_2O\)""",
          ),
          buildTeXPage(
            r"""<p style="text-decoration:underline;">Trigonometry</p>
            \(\displaystyle \sin^2 \theta + \cos^2 \theta = 1\)""",
          ),
          buildTeXPage(
            r"""<p style="color:blue;">Combined Math/Chem</p>
            \(\displaystyle \frac{Na^+}{Cl^-} + \frac{d}{dx} e^x = e^x\)""",
            isLastPage: true,
          ),
        ],
      ),
    );
  }

  Widget buildTeXPage(String latex,
      {bool isLastPage = false, bool useIndependent = true}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: useIndependent
                  ? IndependentTeXView(
                      child: TeXViewDocument(latex),
                    )
                  : TeXView(
                      child: TeXViewDocument(latex),
                    ),
            ),
            ElevatedButton(
              onPressed: () {
                if (!isLastPage) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeIn,
                  );
                }
              },
              child: Text(isLastPage ? "Done" : "Continue"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    TeXRederingServer.stop();
    TeXRenderingController.stop(iReallyWantToStop: true);
    super.dispose();
  }
}
