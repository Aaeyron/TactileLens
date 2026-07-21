import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../styles/screens/home/home_styles.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomeStyles.backgroundColor,
      body: Column(
        children: [
          // ==========================
          // Top Header
          // ==========================
          const AppHeader(),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: HomeStyles.contentPadding,
                child: Column(
                  children: [

                    // ==========================
                    // Main Blue Card
                    // ==========================
                    Container(
                      width: double.infinity,
                      height: HomeStyles.mainCardHeight,
                      decoration: BoxDecoration(
                        color: HomeStyles.mainCardColor,
                        borderRadius: HomeStyles.mainCardRadius,
                        boxShadow: HomeStyles.mainCardShadow,
                      ),
                      child: Padding(
                        padding: HomeStyles.mainCardPadding,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Text(
                              "Scan General Algebra Materials",
                              style: HomeStyles.mainCardTitleStyle,
                            ),

                            SizedBox(
                              height: HomeStyles.mainCardTitleSpacing,
                            ),

                            Text(
                              "Capture printed algebra equations and instantly convert them into accessible Nemeth Braille using AI-powered OCR.",
                              style: HomeStyles.mainCardSubtitleStyle,
                            ),

                          ],
                        ),
                      ),
                    ),


                    const SizedBox(
                      height: HomeStyles.sectionSpacing,
                    ),


                      // ==========================
                      // Feature Cards
                      // ==========================

                      Row(
                        children: [

                          Expanded(
                            child: _featureCard(
                              icon: Icons.smart_toy_outlined,
                              title: "AI-Powered OCR",
                              description:
                                  "Recognizes printed algebra equations.",
                            ),
                          ),

                          const SizedBox(
                          width: HomeStyles.featureCardSpacing,
                        ),

                          Expanded(
                            child: _featureCard(
                              icon: Icons.accessibility_new_outlined,
                              title: "Nemeth Braille Translation",
                              description:
                                  "Converts equations into Nemeth Braille.",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                      height: HomeStyles.featureCardSpacing,
                    ),
                      Row(
                        children: [

                          Expanded(
                            child: _featureCard(
                              icon: Icons.description_outlined,
                              title: "Printed Algebra Materials",
                              description:
                                  "Supports printed algebra materials.",
                            ),
                          ),

                          const SizedBox(
                          width: HomeStyles.featureCardSpacing,
                        ),

                          Expanded(
                            child: _featureCard(
                              icon: Icons.bolt_outlined,
                              title: "Fast & Offline Processing",
                              description:
                                  "Fast processing with offline support.",
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(
                      height: HomeStyles.sectionSpacing,
                    ),

                    // ==========================
                    // Recent Scans Title
                    // ==========================
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Recent Scans",
                        style: HomeStyles.sectionTitleStyle,
                      ),
                    ),

                    const SizedBox(
                    height: HomeStyles.sectionTitleBottomSpacing,
                  ),

                    // ==========================
                    // Recent Scans Card
                    // ==========================
                    Container(
                      width: double.infinity,
                      height: HomeStyles.recentCardHeight,
                      padding: HomeStyles.recentCardPadding,
                      decoration: BoxDecoration(
                        color: HomeStyles.recentCardColor,
                        borderRadius: HomeStyles.recentCardRadius,
                        boxShadow: HomeStyles.recentCardShadow,
                      ),

                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [

                            Container(
                             width: HomeStyles.recentEmptyIconContainerSize,
                             height: HomeStyles.recentEmptyIconContainerSize,
                              decoration: BoxDecoration(
                                color: HomeStyles.recentEmptyIconBackgroundColor,
                                borderRadius: HomeStyles.recentEmptyIconRadius,
                              ),

                              child: Icon(
                                Icons.document_scanner_outlined,
                                size: HomeStyles.recentIconSize,
                               color: HomeStyles.recentIconColor,
                              ),
                            ),


                            const SizedBox(
                            height: HomeStyles.recentIconTextSpacing,
                          ),


                            Text(
                              "No scans yet",
                              style: HomeStyles.recentTitleStyle,
                              textAlign: TextAlign.center,
                            ),


                            const SizedBox(
                            height: HomeStyles.recentSubtitleTopSpacing,
                          ),


                            Text(
                              "Scan your first algebra problem to see it appear here.",
                              textAlign: TextAlign.center,
                              style: HomeStyles.recentSubtitleStyle,
                            ),

                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ==========================
// Feature Card Widget
// ==========================

Widget _featureCard({
  required IconData icon,
  required String title,
  required String description,
}) {

  return Container(
    height: HomeStyles.featureCardHeight,
    padding: HomeStyles.featureCardPadding,

    decoration: BoxDecoration(
      color: HomeStyles.featureCardColor,
      borderRadius: HomeStyles.featureCardRadius,
      boxShadow: HomeStyles.featureCardShadow,
    ),


    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Icon(
        icon,
        size: HomeStyles.featureIconSize,
        color: HomeStyles.featureIconColor,
      ),


        const Spacer(),


        Text(
          title,
          style: HomeStyles.featureTitleStyle,
        ),


         const SizedBox(
          height: HomeStyles.featureDescriptionSpacing,
        ),


        Text(
          description,
          style: HomeStyles.featureDescriptionStyle,
        ),

      ],
    ),
  );
}