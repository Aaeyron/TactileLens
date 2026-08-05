import 'package:flutter/material.dart';
import '../../styles/screens/profile/about_tactilelens_screen_styles.dart';

class AboutTactileLensScreen extends StatelessWidget {
  const AboutTactileLensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AboutTactileLensScreenStyles.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "About TactileLens",
          style: AboutTactileLensScreenStyles.appBarTitleStyle,
        ),
        elevation: 0,
        backgroundColor: AboutTactileLensScreenStyles.backgroundColor,
        foregroundColor: AboutTactileLensScreenStyles.textDark,
      ),
      body: SingleChildScrollView(
        padding: AboutTactileLensScreenStyles.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO HEADER CONTAINER
            Container(
              width: double.infinity,
              padding: AboutTactileLensScreenStyles.headerCardPadding,
              decoration: BoxDecoration(
                color: AboutTactileLensScreenStyles.cardColor,
                borderRadius: AboutTactileLensScreenStyles.headerRadius,
                boxShadow: AboutTactileLensScreenStyles.softShadow,
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AboutTactileLensScreenStyles.primaryLightColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AboutTactileLensScreenStyles.appIcon,
                      size: AboutTactileLensScreenStyles.appIconSize,
                      color: AboutTactileLensScreenStyles.primaryColor,
                    ),
                  ),
                  AboutTactileLensScreenStyles.spaceSm,
                  const Text(
                    "TactileLens",
                    style: AboutTactileLensScreenStyles.appTitleStyle,
                  ),
                  AboutTactileLensScreenStyles.spaceXs,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AboutTactileLensScreenStyles.primaryLightColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Version 1.0.0",
                      style: AboutTactileLensScreenStyles.versionBadgeStyle,
                    ),
                  ),
                ],
              ),
            ),

            AboutTactileLensScreenStyles.spaceLg,

            // ABOUT SECTION CARD
            const Text(
              "About",
              style: AboutTactileLensScreenStyles.sectionTitleStyle,
            ),
            AboutTactileLensScreenStyles.spaceSm,
            Container(
              padding: AboutTactileLensScreenStyles.cardPadding,
              decoration: BoxDecoration(
                color: AboutTactileLensScreenStyles.cardColor,
                borderRadius: AboutTactileLensScreenStyles.cardRadius,
                boxShadow: AboutTactileLensScreenStyles.softShadow,
              ),
              child: const Text(
                "TactileLens is a mobile application developed to assist visually impaired learners by converting printed educational materials into accessible Braille formats.\n\n"
                "The application utilizes Optical Character Recognition (OCR), mathematical expression recognition, and AI-assisted translation to convert text into Unified English Braille (UEB) and Nemeth Braille Code.",
                style: AboutTactileLensScreenStyles.bodyTextStyle,
              ),
            ),

            AboutTactileLensScreenStyles.spaceLg,

            // KEY FEATURES SECTION
            const Text(
              "Key Features",
              style: AboutTactileLensScreenStyles.sectionTitleStyle,
            ),
            AboutTactileLensScreenStyles.spaceSm,
            Container(
              decoration: BoxDecoration(
                color: AboutTactileLensScreenStyles.cardColor,
                borderRadius: AboutTactileLensScreenStyles.cardRadius,
                boxShadow: AboutTactileLensScreenStyles.softShadow,
              ),
              child: Column(
                children: const [
                  _FeatureTile(title: "Scan printed educational materials"),
                  _TileDivider(),
                  _FeatureTile(title: "OCR text recognition"),
                  _TileDivider(),
                  _FeatureTile(title: "Mathematical expression recognition"),
                  _TileDivider(),
                  _FeatureTile(title: "Translate to UEB Braille"),
                  _TileDivider(),
                  _FeatureTile(title: "Translate to Nemeth Braille"),
                  _TileDivider(),
                  _FeatureTile(title: "Manual region selection"),
                  _TileDivider(),
                  _FeatureTile(title: "History of scanned materials"),
                ],
              ),
            ),

            AboutTactileLensScreenStyles.spaceLg,

            // DEVELOPED BY SECTION
            const Text(
              "Developed By",
              style: AboutTactileLensScreenStyles.sectionTitleStyle,
            ),
            AboutTactileLensScreenStyles.spaceSm,
            Container(
              padding: AboutTactileLensScreenStyles.cardPadding,
              decoration: BoxDecoration(
                color: AboutTactileLensScreenStyles.cardColor,
                borderRadius: AboutTactileLensScreenStyles.cardRadius,
                boxShadow: AboutTactileLensScreenStyles.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AboutTactileLensScreenStyles.primaryLightColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      AboutTactileLensScreenStyles.developerIcon,
                      color: AboutTactileLensScreenStyles.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "Capstone Project",
                        style: AboutTactileLensScreenStyles.devTitleStyle,
                      ),
                      SizedBox(height: 2),
                      Text(
                        "TactileLens [78-13]",
                        style: AboutTactileLensScreenStyles.devSubtitleStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            AboutTactileLensScreenStyles.spaceLg,
          ],
        ),
      ),
    );
  }
}

// HELPER WIDGETS FOR CLEAN UI
class _FeatureTile extends StatelessWidget {
  final String title;
  const _FeatureTile({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AboutTactileLensScreenStyles.featureTilePadding,
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AboutTactileLensScreenStyles.primaryLightColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            AboutTactileLensScreenStyles.featureIcon,
            color: AboutTactileLensScreenStyles.iconAccent,
            size: 18,
          ),
        ),
        title: Text(
          title,
          style: AboutTactileLensScreenStyles.featureTitleStyle,
        ),
      ),
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 16,
      endIndent: 16,
      color: Colors.grey.withOpacity(0.12),
    );
  }
}