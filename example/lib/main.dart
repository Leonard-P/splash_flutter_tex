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

  // Example of mixed custom head content with styles, scripts, and font imports
  final String customHeadContent = '''
    <!-- Custom styles -->
    <style>
      .colored-math { 
        color: purple; 
        font-size: 1.2em;
      }
      body { 
        background: linear-gradient(to bottom, #f0f8ff, #ffffff);
      }
    </style>
    
    <!-- Custom script -->
    <script type="text/javascript">
      function customMathFunction(x) {
        return x * x;
      }
      window.customMathFunction = customMathFunction;
    </script>
    
    <!-- Custom font -->
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@300&display=swap" rel="stylesheet">
    <style>
      p { 
        font-family: 'Roboto', sans-serif; 
        font-weight: 300;
      }
    </style>
  ''';

  // Simple page with just a script
  final String scriptOnlyContent = '''
    <script>
      console.log("Script only page loaded");
      
      // Function to highlight equations
      function highlightEquations() {
        var elements = document.querySelectorAll('.MathJax');
        elements.forEach(function(el) {
          el.style.boxShadow = '0 0 5px rgba(0,0,255,0.5)';
        });
      }
      
      // Run after MathJax has rendered
      setTimeout(highlightEquations, 1000);
    </script>
  ''';

  // Just custom styles
  final String stylesOnlyContent = '''
    <style>
      p { 
        border-left: 4px solid #ff9800; 
        padding-left: 10px;
        background-color: #fff3e0;
      }
    </style>
  ''';

  // Custom head content for the interactive lever physics demo
  final String leverDemoHeadContent = r'''
    <style>
      .container {
        position: relative;
        width: 100%;
        height: 300px;
        overflow: hidden;
      }
      
      .lever {
        position: absolute;
        width: 80%;
        height: 10px;
        background-color: #8B4513; /* wooden color */
        top: 50%;
        left: 50%;
        transform-origin: center center;
        transform: translate(-50%, -50%) rotate(0deg);
        transition: transform 0.5s ease;
        border-radius: 5px;
      }
      
      .pivot {
        position: absolute;
        width: 20px;
        height: 20px;
        background-color: #555;
        border-radius: 50%;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%);
        z-index: 2;
      }
      
      .weight {
        position: absolute;
        width: 30px;
        height: 30px;
        border-radius: 50%;
        top: 50%;
        transform: translateY(-50%);
        text-align: center;
        line-height: 30px;
        font-weight: bold;
        color: white;
      }
      
      .weight-left {
        background-color: #ff5722;
        left: 20%;
      }
      
      .weight-right {
        background-color: #2196f3;
        right: 20%;
      }
      
      .control-panel {
        position: relative;
        width: 100%;
        padding: 10px;
        background-color: #f5f5f5;
        border-radius: 5px;
        margin-top: 30px;
      }
      
      .slider-container {
        margin: 10px 0;
      }
      
      .slider {
        width: 80%;
        margin: 0 auto;
      }
      
      .formula {
        text-align: center;
        margin-top: 20px;
        font-style: italic;
      }
    </style>
    
    <script>
      // Global variables
      var leftWeight = 5;
      var rightWeight = 5;
      var leftPosition = 40; // percent from center (0-100)
      var rightPosition = 40; // percent from center (0-100)
      
      // Function to update lever position and angle
      function updateLever() {
        console.log("Updating lever...");
        try {
          // Calculate torques (force * distance)
          var leftTorque = leftWeight * leftPosition;
          var rightTorque = rightWeight * rightPosition;
          
          // Calculate the angle based on the difference in torques
          var torqueDifference = rightTorque - leftTorque;
          var maxTorque = Math.max(leftWeight, rightWeight) * 100; // normalize
          var angle = Math.min(Math.max(torqueDifference / maxTorque * 30, -30), 30);
          
          // Update the lever rotation
          var lever = document.querySelector('.lever');
          if (lever) {
            lever.style.transform = "translate(-50%, -50%) rotate(" + angle + "deg)";
          }
          
          // Update weight positions
          var leftWeightElem = document.querySelector('.weight-left');
          var rightWeightElem = document.querySelector('.weight-right');
          
          if (leftWeightElem && rightWeightElem) {
            // Calculate positions accounting for the lever width (80%)
            var leverWidth = 80;
            var leftPos = 50 - (leverWidth/2 * leftPosition/100);
            var rightPos = 50 + (leverWidth/2 * rightPosition/100);
            
            leftWeightElem.style.left = leftPos + "%";
            leftWeightElem.textContent = leftWeight;
            rightWeightElem.style.right = (100 - rightPos) + "%";
            rightWeightElem.textContent = rightWeight;
            
            // Update weights' vertical positions based on lever angle
            var leftOffsetY = -Math.sin(angle * Math.PI / 180) * (leftPosition * leverWidth / 200);
            var rightOffsetY = Math.sin(angle * Math.PI / 180) * (rightPosition * leverWidth / 200);
            
            leftWeightElem.style.transform = "translateY(calc(-50% + " + leftOffsetY + "px))";
            rightWeightElem.style.transform = "translateY(calc(-50% + " + rightOffsetY + "px))";
          }
          
          // Update formula display
          var formulaElem = document.getElementById('leverFormula');
          if (formulaElem) {
            try {
              var eqSign = leftTorque == rightTorque ? '=' : (leftTorque > rightTorque ? '>' : '<');
              
              // FIX: Use innerHTML with properly escaped LaTeX instead of textContent
              // The key issue was using textContent which doesn't interpret the backslashes correctly
              formulaElem.innerHTML = "\$\$" + leftWeight + " \\\\cdot " + leftPosition + "\\\\text{ cm} " + 
                                    eqSign + " " + rightWeight + " \\\\cdot " + rightPosition + "\\\\text{ cm}\$\$";
              
              // Force MathJax to re-render the element
              if (window.MathJax) {
                try {
                  if (window.MathJax.typeset) {
                    window.MathJax.typeset([formulaElem]);
                  } else if (window.MathJax.Hub) {
                    window.MathJax.Hub.Queue(["Typeset", MathJax.Hub, formulaElem]);
                  }
                } catch (e) {
                  console.error("MathJax error:", e);
                }
              }
            } catch (e) {
              console.error("Formula update error:", e);
            }
          }
        } catch (e) {
          console.error("Error updating lever:", e);
        }
      }
      
      // Function to create the lever demo
      function initLeverDemo() {
        console.log("Creating lever demo");
        try {
          // Clear any existing content
          var demoContainer = document.getElementById('physics-demo-container');
          if (!demoContainer) {
            demoContainer = document.createElement('div');
            demoContainer.id = 'physics-demo-container';
            document.body.appendChild(demoContainer);
          } else {
            demoContainer.innerHTML = '';
          }
          
          // Create the visual elements
          var header = document.createElement('h2');
          header.style.textAlign = 'center';
          header.textContent = 'Interactive Lever Physics';
          demoContainer.appendChild(header);
          
          var subheader = document.createElement('p');
          subheader.style.textAlign = 'center';
          subheader.textContent = 'Adjust the sliders to balance the lever';
          demoContainer.appendChild(subheader);
          
          var container = document.createElement('div');
          container.className = 'container';
          
          var lever = document.createElement('div');
          lever.className = 'lever';
          
          var pivot = document.createElement('div');
          pivot.className = 'pivot';
          
          var weightLeft = document.createElement('div');
          weightLeft.className = 'weight weight-left';
          weightLeft.textContent = leftWeight;
          
          var weightRight = document.createElement('div');
          weightRight.className = 'weight weight-right';
          weightRight.textContent = rightWeight;
          
          container.appendChild(lever);
          container.appendChild(pivot);
          container.appendChild(weightLeft);
          container.appendChild(weightRight);
          demoContainer.appendChild(container);
          
          // Create control panel with sliders
          var controlPanel = document.createElement('div');
          controlPanel.className = 'control-panel';
          
          var sliderLeftPos = document.createElement('div');
          sliderLeftPos.className = 'slider-container';
          sliderLeftPos.innerHTML = '<label>Left Weight Position: <span id="leftPosValue">40</span>%</label><br><input type="range" id="leftPosSlider" class="slider" min="10" max="90" value="40">';
          
          var sliderRightPos = document.createElement('div');
          sliderRightPos.className = 'slider-container';
          sliderRightPos.innerHTML = '<label>Right Weight Position: <span id="rightPosValue">40</span>%</label><br><input type="range" id="rightPosSlider" class="slider" min="10" max="90" value="40">';
          
          var sliderLeftWeight = document.createElement('div');
          sliderLeftWeight.className = 'slider-container';
          sliderLeftWeight.innerHTML = '<label>Left Weight Mass: <span id="leftWeightValue">5</span> kg</label><br><input type="range" id="leftWeightSlider" class="slider" min="1" max="10" value="5">';
          
          var sliderRightWeight = document.createElement('div');
          sliderRightWeight.className = 'slider-container';
          sliderRightWeight.innerHTML = '<label>Right Weight Mass: <span id="rightWeightValue">5</span> kg</label><br><input type="range" id="rightWeightSlider" class="slider" min="1" max="10" value="5">';
          
          controlPanel.appendChild(sliderLeftPos);
          controlPanel.appendChild(sliderRightPos);
          controlPanel.appendChild(sliderLeftWeight);
          controlPanel.appendChild(sliderRightWeight);
          demoContainer.appendChild(controlPanel);
          
          // Add formula display with properly escaped LaTeX
          var formula = document.createElement('div');
          formula.className = 'formula';
          formula.innerHTML = '<div id="leverFormula">\$\$5 \\\\\\\\cdot 40\\\\text{ cm} = 5 \\\\cdot 40\\\\text{ cm}\$\$</div>';
          demoContainer.appendChild(formula);
          
          // Add event listeners for sliders
          document.getElementById('leftPosSlider').addEventListener('input', function(e) {
            leftPosition = parseInt(e.target.value);
            document.getElementById('leftPosValue').textContent = leftPosition;
            updateLever();
          });
          
          document.getElementById('rightPosSlider').addEventListener('input', function(e) {
            rightPosition = parseInt(e.target.value);
            document.getElementById('rightPosValue').textContent = rightPosition;
            updateLever();
          });
          
          document.getElementById('leftWeightSlider').addEventListener('input', function(e) {
            leftWeight = parseInt(e.target.value);
            document.getElementById('leftWeightValue').textContent = leftWeight;
            updateLever();
          });
          
          document.getElementById('rightWeightSlider').addEventListener('input', function(e) {
            rightWeight = parseInt(e.target.value);
            document.getElementById('rightWeightValue').textContent = rightWeight;
            updateLever();
          });
          
          console.log("Lever demo created");
          // Initial update
          setTimeout(updateLever, 1000); 
        } catch (e) {
          console.error("Error initializing lever demo:", e);
        }
      }
      
      // Initialize when custom content is loaded or after a timeout
      window.addEventListener('load', function() {
        console.log('Window loaded');
        setTimeout(function() {
          console.log('Running init with timeout');
          initLeverDemo();
        }, 1000);
      });
      
      document.addEventListener('customContentLoaded', function() {
        console.log('Custom content loaded event fired');
        initLeverDemo();
      });
      
      // Backup initialization if neither event fires
      setTimeout(function() {
        if (!document.getElementById('physics-demo-container')) {
          console.log('Backup initialization');
          initLeverDemo();
        }
      }, 2000);
    </script>
  ''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Flutter TeX Single Demo")),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        children: [
          // Add the interactive lever physics demo as the first page
          buildTeXPage(
            r"""<div id="physics-demo">
              <div id="physics-demo-container"></div>
            </div>""",
            customHead: leverDemoHeadContent,
            expands: true, // This needs to be full height
          ),

          // Keep previous pages
          buildTeXPage(
            r"""<p style="color:red;">Physics Formula</p>
            \(\displaystyle E = mc^2\)""",
            useIndependent: false,
          ),
          buildTeXPage(
            r"""<p>Math Derivative with Custom Styles</p>
            \(\displaystyle \frac{d}{dx} x^n = nx^{n-1}\)""",
            customHead: stylesOnlyContent,
          ),
          buildTeXPage(
            r"""<p>Chemistry Equation with Script</p>
            \(\displaystyle H_2 + O_2 \rightarrow H_2O\)""",
            customHead: scriptOnlyContent,
          ),
          buildTeXPage(
            r"""<p>Trigonometry</p>
            <span class="colored-math">\(\displaystyle \sin^2 \theta + \cos^2 \theta = 1\)</span>""",
            customHead: customHeadContent,
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
      {bool isLastPage = false,
      bool useIndependent = true,
      bool expands = false,
      String customHead = ''}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            useIndependent
                ? Flexible(
                    child: IndependentTeXView(
                      child: TeXViewDocument(latex),
                      expands: expands,
                      customHeadContent: customHead,
                    ),
                  )
                : TeXView(
                    child: TeXViewDocument(latex),
                  ),
            Text("Texview ends here"),
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
