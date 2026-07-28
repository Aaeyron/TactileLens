import 'package:flutter/material.dart';

class AboutTactileLensScreen extends StatelessWidget {
  const AboutTactileLensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About TactileLens"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Center(
              child: Icon(
                Icons.visibility,
                size: 80,
                color: Colors.blue,
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "TactileLens",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 6),

            const Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "About",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "TactileLens is a mobile application developed to assist visually impaired learners by converting printed educational materials into accessible Braille formats.\n\n"
              "The application utilizes Optical Character Recognition (OCR), mathematical expression recognition, and AI-assisted translation to convert text into Unified English Braille (UEB) and Nemeth Braille Code.",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Key Features",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("Scan printed educational materials"),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("OCR text recognition"),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("Mathematical expression recognition"),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("Translate to UEB Braille"),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("Translate to Nemeth Braille"),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("Manual region selection"),
            ),

            const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text("History of scanned materials"),
            ),

            const SizedBox(height: 30),

            const Text(
              "Developed By",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              "Capstone Project\n"
              "TactileLens [78-13]",
              style: TextStyle(
                fontSize: 16,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}