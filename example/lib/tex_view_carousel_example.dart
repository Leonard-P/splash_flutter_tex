// import 'package:flutter/material.dart';
// import 'package:flutter_tex/flutter_tex.dart';

// class TeXViewCarouselExample extends StatefulWidget {
//   const TeXViewCarouselExample({Key? key}) : super(key: key);

//   @override
//   State<TeXViewCarouselExample> createState() => _TeXViewCarouselExampleState();
// }

// class _TeXViewCarouselExampleState extends State<TeXViewCarouselExample> {
//   bool isDarkMode = false;
//   int currentPage = 0;
//   final PageController _pageController = PageController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('TeXView Carousel Example'),
//         actions: [
//           // Theme toggle button
//           IconButton(
//             icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
//             onPressed: () {
//               setState(() {
//                 isDarkMode = !isDarkMode;
//               });
//             },
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Page indicator
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Text(
//               'Page ${currentPage + 1} of 6',
//               style: const TextStyle(fontSize: 16),
//             ),
//           ),

//           // The carousel
//           Flexible(
//             child: TeXViewCarousel(
//               controller: _pageController,
//               customHeadContent: _getCustomHeadContent(),
//               onPageChanged: (index) {
//                 setState(() {
//                   currentPage = index;
//                 });
//               },
//               onRenderFinished: (pageIndex, height) {
//                 print('Page $pageIndex rendered with height: $height');
//               },
//               loadingWidgetBuilder: (context) => const Center(
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     CircularProgressIndicator(),
//                     SizedBox(height: 16),
//                     Text('Loading...')
//                   ],
//                 ),
//               ),
//               items: [
//                 // A regular Flutter widget (Page 1)
//                 Container(
//                   color:
//                       isDarkMode ? Colors.grey.shade800 : Colors.blue.shade100,
//                   child: Center(
//                     child: Text(
//                       'This is a regular, expanded Flutter widget\n(Page 1)',
//                       style: TextStyle(
//                         fontSize: 24,
//                         color: isDarkMode ? Colors.white : Colors.black,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),

//                 // A TeXViewDocument (Page 2)
//                 TeXViewDocument(r"""
//                   <h2>Quadratic Formula</h2>
//                   <p>The solutions to a quadratic equation $ax^2 + bx + c = 0$ are given by:</p>
//                   $$x = \frac{-b \pm \sqrt{b^2 - 4ac}}{2a}$$
//                   <p>This formula gives us the two roots of the quadratic equation.</p>
//                 """),

//                 // Another Flutter widget (Page 3)
//                 Container(
//                   color: isDarkMode
//                       ? Colors.blueGrey.shade800
//                       : Colors.green.shade100,
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Text(
//                           'Regular Flutter Widget with Button',
//                           style: TextStyle(
//                             fontSize: 24,
//                             color: isDarkMode ? Colors.white : Colors.black,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 20),
//                         ElevatedButton(
//                           onPressed: () {
//                             _pageController.nextPage(
//                               duration: const Duration(milliseconds: 300),
//                               curve: Curves.easeInOut,
//                             );
//                           },
//                           child: const Text('Go to Next Page'),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 // NEW: TeXViewComposite with Flutter widgets above and below (Page 4)
//                 TeXViewComposite(
//                   // Top widget
//                   above: Container(
//                     padding: const EdgeInsets.all(16.0),
//                     color: isDarkMode
//                         ? Colors.indigo.shade800
//                         : Colors.amber.shade200,
//                     child: Column(
//                       children: [
//                         Text(
//                           'Euler\'s Identity',
//                           style: TextStyle(
//                             fontSize: 22,
//                             fontWeight: FontWeight.bold,
//                             color: isDarkMode ? Colors.white : Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           'This is a Flutter widget above the TeXView content.',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: isDarkMode ? Colors.white70 : Colors.black87,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                         const SizedBox(height: 12),
//                         Card(
//                           elevation: 4,
//                           color: isDarkMode
//                               ? Colors.deepPurple.shade700
//                               : Colors.white,
//                           child: Padding(
//                             padding: const EdgeInsets.all(12.0),
//                             child: Text(
//                               'Considered the most beautiful equation in mathematics',
//                               style: TextStyle(
//                                 fontStyle: FontStyle.italic,
//                                 color: isDarkMode
//                                     ? Colors.white70
//                                     : Colors.black87,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   // TeXView content in the middle
//                   document: TeXViewDocument(r"""
//                     <div style="padding: 16px; text-align: center;">
//                       <p>Euler's Identity elegantly connects five fundamental constants:</p>
//                       <div style="font-size: 1.5em; margin: 20px 0;">$$e^{i\pi} + 1 = 0$$</div>
//                       <ul style="text-align: left; display: inline-block;">
//                         <li>$e$ - Euler's number (base of natural logarithm)</li>
//                         <li>$i$ - Imaginary unit</li>
//                         <li>$\pi$ - Pi (ratio of circumference to diameter)</li>
//                         <li>$1$ - Multiplicative identity</li>
//                         <li>$0$ - Additive identity</li>
//                       </ul>
//                     </div>
//                   """),

//                   // Bottom widget
//                   below: Container(
//                     padding: const EdgeInsets.all(16.0),
//                     color: isDarkMode
//                         ? Colors.indigo.shade800
//                         : Colors.amber.shade200,
//                     child: Column(
//                       children: [
//                         Text(
//                           'Interactive Flutter Widgets',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: isDarkMode ? Colors.white : Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                           children: [
//                             ElevatedButton.icon(
//                               icon: const Icon(Icons.favorite),
//                               label: const Text('Amazing!'),
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: isDarkMode
//                                     ? Colors.pinkAccent
//                                     : Colors.redAccent,
//                                 foregroundColor: Colors.white,
//                               ),
//                               onPressed: () {
//                                 ScaffoldMessenger.of(context).showSnackBar(
//                                   const SnackBar(
//                                     content: Text('Indeed, it\'s beautiful!'),
//                                     duration: Duration(seconds: 1),
//                                   ),
//                                 );
//                               },
//                             ),
//                             ElevatedButton.icon(
//                               icon: const Icon(Icons.info_outline),
//                               label: const Text('Learn More'),
//                               onPressed: () {
//                                 showDialog(
//                                   context: context,
//                                   builder: (context) => AlertDialog(
//                                     title:
//                                         const Text('About Euler\'s Identity'),
//                                     content: const SingleChildScrollView(
//                                       child: Text(
//                                         'Euler\'s identity is considered by many mathematicians to be '
//                                         'the most beautiful theorem in mathematics. It links five fundamental '
//                                         'mathematical constants in a single formula.\n\n'
//                                         'This equation was named after Leonhard Euler, who first proved it.',
//                                       ),
//                                     ),
//                                     actions: [
//                                       TextButton(
//                                         onPressed: () => Navigator.pop(context),
//                                         child: const Text('Close'),
//                                       ),
//                                     ],
//                                   ),
//                                 );
//                               },
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),

//                   // Spacing between elements
//                   spacing: 0, // No spacing needed as containers have padding
//                 ),

//                 // A TeXViewDocument with an image (Page 5)
//                 TeXViewDocument(r"""
//                   <h2>Pythagorean Theorem</h2>
//                   <p>In a right-angled triangle, the square of the hypotenuse equals the sum of squares of the other two sides:</p>
//                   $$a^2 + b^2 = c^2$$
//                   <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Pythagorean.svg/300px-Pythagorean.svg.png" width="200px" />
//                   <p>This theorem is a fundamental relation in Euclidean geometry.</p>
//                 """),

//                 // A TeXViewDocument with complex math (Page 6)
//                 TeXViewDocument(r"""
//                   <h2>Maxwell's Equations</h2>
//                   <p>These four equations describe how electric and magnetic fields are generated:</p>
//                   $$\nabla \cdot \vec{E} = \frac{\rho}{\varepsilon_0}$$
//                   $$\nabla \cdot \vec{B} = 0$$
//                   $$\nabla \times \vec{E} = -\frac{\partial \vec{B}}{\partial t}$$
//                   $$\nabla \times \vec{B} = \mu_0 \vec{J} + \mu_0 \varepsilon_0 \frac{\partial \vec{E}}{\partial t}$$
//                   <p>These equations form the foundation of classical electrodynamics.</p>
//                 """),
//               ],
//             ),
//           ),

//           // Navigation buttons
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: currentPage > 0
//                       ? () => _pageController.previousPage(
//                             duration: const Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                           )
//                       : null,
//                   child: const Text('Previous'),
//                 ),
//                 ElevatedButton(
//                   onPressed: currentPage < 5
//                       ? () => _pageController.nextPage(
//                             duration: const Duration(milliseconds: 300),
//                             curve: Curves.easeInOut,
//                           )
//                       : null,
//                   child: const Text('Next'),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _getCustomHeadContent() {
//     return isDarkMode
//         ? '''
//       <style>
//         body {
//           background-color: #121212;
//           color: #ffffff;
//         }
//         h2 {
//           color: #bb86fc;
//         }
//         img {
//           filter: brightness(0.8) contrast(1.2);
//         }
//       </style>
//     '''
//         : '''
//       <style>
//         body {
//           background-color: #ffffff;
//           color: #000000;
//         }
//         h2 {
//           color: #1565c0;
//         }
//       </style>
//     ''';
//   }

//   @override
//   void dispose() {
//     _pageController.dispose();
//     super.dispose();
//   }
// }
