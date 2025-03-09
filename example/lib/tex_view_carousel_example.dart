import 'package:flutter/material.dart';
import 'package:flutter_tex/flutter_tex.dart';

class TexViewCarouselExample extends StatelessWidget {
  const TexViewCarouselExample({super.key});

  @override
  Widget build(BuildContext context) {
    final pool = TeXViewControllerProvider.poolOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Shared Controller TeXViews")),
      body: PageView(
        children: [
          // Page 0: Complex mathematical equation with multiple lines
          SharedControllerTeXView(
            controllerPool: pool,
            id: 'page_0',
            child: TeXViewDocument(
              r"""
              \begin{align}
              \frac{\partial}{\partial t}\left( \rho \mathbf{v} \right) + \nabla \cdot \left( \rho \mathbf{v} \otimes \mathbf{v} \right) &= -\nabla p + \nabla \cdot \boldsymbol{\tau} + \rho \mathbf{g} \\
              \nabla \cdot \mathbf{v} &= 0 \\
              \frac{\partial \rho}{\partial t} + \nabla \cdot \left( \rho \mathbf{v} \right) &= 0 \\
              \rho C_p \left( \frac{\partial T}{\partial t} + \mathbf{v} \cdot \nabla T \right) &= k \nabla^2 T + \Phi
              \end{align}
              
              <p style="font-size:14px; text-align:center;">Navier-Stokes equations for incompressible fluid flow with heat transfer</p>
              """,
              style: const TeXViewStyle(
                margin: TeXViewMargin.all(10),
                padding: TeXViewPadding.all(15),
                backgroundColor: Color.fromARGB(50, 200, 200, 200),
                borderRadius: TeXViewBorderRadius.all(10),
              ),
            ),
          ),

          // Page 1: Chemistry formulas and reactions
          SharedControllerTeXView(
            controllerPool: pool,
            id: 'page_1',
            child: TeXViewDocument(
              r"""
              <h3 style="text-align:center;">Complex Chemical Reactions</h3>
              
              <p>Equilibrium constant for the dissolution of calcium carbonate:</p>
              
              \begin{align}
              \ce{CaCO3(s) <=> Ca^2+(aq) + CO3^2-(aq)} \\
              K_{sp} = [\ce{Ca^2+}][\ce{CO3^2-}]
              \end{align}
              
              <p>Photosynthesis overall reaction:</p>
              
              \begin{align}
              \ce{6CO2(g) + 6H2O(l) ->[\text{sunlight}] C6H12O6(aq) + 6O2(g)}
              \end{align}
              
              <p>Glucose oxidation with electron transport chain:</p>
              
              \begin{align}
              \ce{C6H12O6 + 6O2 + 36ADP + 36Pi -> 6CO2 + 6H2O + 36ATP}
              \end{align}
              
              <div style="text-align:center;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/57/Benzene_resonance_structures.svg/600px-Benzene_resonance_structures.svg.png" width="300"/>
                <p style="font-size:12px;">Benzene resonance structures</p>
              </div>
              """,
              style: const TeXViewStyle(
                margin: TeXViewMargin.all(10),
                padding: TeXViewPadding.all(15),
                backgroundColor: Color.fromARGB(50, 220, 220, 250),
                borderRadius: TeXViewBorderRadius.all(10),
              ),
            ),
          ),

          // Page 2: Physics with complex formulas and diagrams
          SharedControllerTeXView(
            controllerPool: pool,
            id: 'page_2',
            child: TeXViewDocument(
              r"""
              <h3 style="text-align:center; color:#333;">Quantum Field Theory</h3>
              
              <p>The Dirac Lagrangian density:</p>
              
              $$\mathcal{L} = \bar{\psi}(i\gamma^\mu\partial_\mu - m)\psi$$
              
              <p>The path integral for quantum field theory:</p>
              
              $$Z[J] = \int \mathcal{D}\phi \, \exp\left(i\int d^4x \, \left[\mathcal{L}(\phi,\partial_\mu\phi) + J(x)\phi(x)\right]\right)$$
              
              <p>Standard model Lagrangian (simplified):</p>
              
              $$\mathcal{L}_{SM} = -\frac{1}{4}F_{\mu\nu}F^{\mu\nu} + \bar{\psi}i\gamma^\mu D_\mu \psi + |D_\mu\phi|^2 - V(\phi) + \bar{\psi}_i y_{ij} \psi_j \phi$$
              
              <div style="text-align:center;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/7/7f/Feynmandiagram.svg/500px-Feynmandiagram.svg.png" width="250"/>
                <p style="font-size:12px;">Feynman diagram for electron-positron annihilation</p>
              </div>
              
              <p>Einstein field equations:</p>
              
              $$R_{\mu\nu} - \frac{1}{2}g_{\mu\nu}R + \Lambda g_{\mu\nu} = \frac{8\pi G}{c^4}T_{\mu\nu}$$
              """,
              style: const TeXViewStyle(
                margin: TeXViewMargin.all(10),
                padding: TeXViewPadding.all(15),
                backgroundColor: Color.fromARGB(50, 240, 220, 220),
                borderRadius: TeXViewBorderRadius.all(10),
              ),
            ),
          ),

          // Page 3: page with two SharedControllerTeXViews with complex content
          Row(
            children: [
              Expanded(
                child: SharedControllerTeXView(
                  controllerPool: pool,
                  id: 'page_3_left',
                  child: TeXViewDocument(
                    r"""
                    <h4>Fourier Transform Pairs</h4>
                    
                    $$\mathcal{F}[f(t)] = \int_{-\infty}^{\infty} f(t) e^{-i\omega t} dt$$
                    
                    $$\mathcal{F}^{-1}[F(\omega)] = \frac{1}{2\pi}\int_{-\infty}^{\infty} F(\omega) e^{i\omega t} d\omega$$
                    
                    $$\mathcal{F}[\delta(t)] = 1$$
                    
                    $$\mathcal{F}[e^{-a|t|}] = \frac{2a}{a^2 + \omega^2}$$
                    
                    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/7/72/Fourier_transform_time_and_frequency_domains_%28small%29.gif/400px-Fourier_transform_time_and_frequency_domains_%28small%29.gif" width="100%"/>
                    """,
                    style: const TeXViewStyle(
                      margin: TeXViewMargin.all(10),
                      padding: TeXViewPadding.all(10),
                      backgroundColor: Color.fromARGB(50, 220, 250, 220),
                      borderRadius: TeXViewBorderRadius.all(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SharedControllerTeXView(
                  controllerPool: pool,
                  id: 'page_3_right',
                  child: TeXViewDocument(
                    r"""
                    <h4>Statistical Mechanics</h4>
                    
                    <p>Partition function:</p>
                    
                    $$Z = \sum_i e^{-\beta E_i}$$
                    
                    <p>Boltzmann distribution:</p>
                    
                    $$P_i = \frac{e^{-\beta E_i}}{Z}$$
                    
                    <p>Entropy:</p>
                    
                    $$S = -k_B \sum_i P_i \ln P_i = k_B \ln \Omega$$
                    
                    <p>Free energy:</p>
                    
                    $$F = -k_B T \ln Z = U - TS$$
                    
                    <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Maxwell-Boltzmann_distribution.svg/400px-Maxwell-Boltzmann_distribution.svg.png" width="100%"/>
                    """,
                    style: const TeXViewStyle(
                      margin: TeXViewMargin.all(10),
                      padding: TeXViewPadding.all(10),
                      backgroundColor: Color.fromARGB(50, 250, 220, 250),
                      borderRadius: TeXViewBorderRadius.all(10),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Page 4: Advanced electromagnetic theory
          SharedControllerTeXView(
            controllerPool: pool,
            id: 'page_4',
            child: TeXViewDocument(
              r"""
              <h3 style="text-align:center;">Maxwell's Equations</h3>
              
              <div style="display:flex; justify-content:space-around;">
                <div>
                  <p>Differential form:</p>
                  \begin{align}
                  \nabla \cdot \mathbf{E} &= \frac{\rho}{\epsilon_0} \\
                  \nabla \cdot \mathbf{B} &= 0 \\
                  \nabla \times \mathbf{E} &= -\frac{\partial \mathbf{B}}{\partial t} \\
                  \nabla \times \mathbf{B} &= \mu_0\mathbf{J} + \mu_0\epsilon_0\frac{\partial \mathbf{E}}{\partial t}
                  \end{align}
                </div>
                <div>
                  <p>Integral form:</p>
                  \begin{align}
                  \oint_{\partial \Omega} \mathbf{E} \cdot d\mathbf{S} &= \frac{1}{\epsilon_0} \int_{\Omega} \rho \, dV \\
                  \oint_{\partial \Omega} \mathbf{B} \cdot d\mathbf{S} &= 0 \\
                  \oint_{\partial \Sigma} \mathbf{E} \cdot d\boldsymbol{\ell} &= -\frac{d}{dt}\int_{\Sigma} \mathbf{B} \cdot d\mathbf{S} \\
                  \oint_{\partial \Sigma} \mathbf{B} \cdot d\boldsymbol{\ell} &= \mu_0\int_{\Sigma} \mathbf{J} \cdot d\mathbf{S} + \mu_0\epsilon_0\frac{d}{dt}\int_{\Sigma} \mathbf{E} \cdot d\mathbf{S}
                  \end{align}
                </div>
              </div>
              
              <div style="text-align:center;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/c7/VFPt_charges_plus_minus_thumb.svg/600px-VFPt_charges_plus_minus_thumb.svg.png" width="300"/>
                <p style="font-size:12px;">Electric field of positive and negative charges</p>
              </div>
              
              <p>Electromagnetic wave equation:</p>
              $$\nabla^2\mathbf{E} - \mu_0\epsilon_0\frac{\partial^2 \mathbf{E}}{\partial t^2} = \mu_0\frac{\partial \mathbf{J}}{\partial t} + \frac{\nabla \rho}{\epsilon_0}$$
              """,
              style: const TeXViewStyle(
                margin: TeXViewMargin.all(10),
                padding: TeXViewPadding.all(15),
                backgroundColor: Color.fromARGB(50, 220, 250, 250),
                borderRadius: TeXViewBorderRadius.all(10),
              ),
            ),
          ),

          // Page 5: Advanced thermodynamics with HTML and LaTeX
          SharedControllerTeXView(
            controllerPool: pool,
            id: 'page_5',
            child: TeXViewDocument(
              r"""
              <div style="background-color:#f8f9fa; border-left:4px solid #2196F3; padding:8px; margin-bottom:16px;">
                <h3 style="text-align:center; color:#0D47A1;">Thermodynamic Potentials</h3>
              </div>
              
              <table border="1" style="width:100%; border-collapse:collapse; text-align:center;">
                <tr style="background-color:#e3f2fd;">
                  <th>Potential</th>
                  <th>Formula</th>
                  <th>Natural Variables</th>
                </tr>
                <tr>
                  <td>Internal Energy \(U\)</td>
                  <td>\(U = TS - pV + \sum_i \mu_i N_i\)</td>
                  <td>\(S, V, N_i\)</td>
                </tr>
                <tr>
                  <td>Enthalpy \(H\)</td>
                  <td>\(H = U + pV = TS + \sum_i \mu_i N_i\)</td>
                  <td>\(S, p, N_i\)</td>
                </tr>
                <tr>
                  <td>Helmholtz Free Energy \(F\)</td>
                  <td>\(F = U - TS = -pV + \sum_i \mu_i N_i\)</td>
                  <td>\(T, V, N_i\)</td>
                </tr>
                <tr>
                  <td>Gibbs Free Energy \(G\)</td>
                  <td>\(G = H - TS = \sum_i \mu_i N_i\)</td>
                  <td>\(T, p, N_i\)</td>
                </tr>
              </table>
              
              <p>The fundamental thermodynamic relation:</p>
              $$dU = T\,dS - p\,dV + \sum_i \mu_i \, dN_i$$
              
              <p>Maxwell relations:</p>
              \begin{align}
              \left(\frac{\partial T}{\partial V}\right)_S &= -\left(\frac{\partial p}{\partial S}\right)_V \\
              \left(\frac{\partial T}{\partial p}\right)_S &= \left(\frac{\partial V}{\partial S}\right)_p \\
              \left(\frac{\partial S}{\partial V}\right)_T &= \left(\frac{\partial p}{\partial T}\right)_V \\
              \left(\frac{\partial S}{\partial p}\right)_T &= -\left(\frac{\partial V}{\partial T}\right)_p
              \end{align}
              
              <div style="display:flex; justify-content:center;">
                <img src="https://upload.wikimedia.org/wikipedia/commons/thumb/3/3b/Carnot_heat_engine_2.svg/500px-Carnot_heat_engine_2.svg.png" width="250"/>
              </div>
              <p style="text-align:center; font-size:12px;">Carnot cycle P-V diagram</p>
              """,
              style: const TeXViewStyle(
                margin: TeXViewMargin.all(10),
                padding: TeXViewPadding.all(15),
                backgroundColor: Color.fromARGB(50, 250, 250, 220),
                borderRadius: TeXViewBorderRadius.all(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
