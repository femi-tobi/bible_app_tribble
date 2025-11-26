import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sermon_provider.dart';
import '../providers/presentation_config_provider.dart';
import '../services/presentation_window_service.dart';

class SermonEditorScreen extends StatelessWidget {
  const SermonEditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sermon Editor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Go Live',
            onPressed: () {
              final sermon = context.read<SermonProvider>().currentSermon;
              final config = context.read<PresentationConfigProvider>().config;
              PresentationWindowService.openSermonPresentation(
                context,
                sermon,
                config.toMap(),
              );
            },
          ),
        ],
      ),
      body: Consumer<SermonProvider>(
        builder: (context, provider, child) {
          final sermon = provider.currentSermon;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Sermon Topic',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: sermon.topic)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: sermon.topic.length),
                    ),
                  onChanged: (value) => provider.updateTopic(value),
                ),
                const SizedBox(height: 16),
                
                // Bible Text
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Main Bible Text',
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: sermon.bibleText)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: sermon.bibleText.length),
                    ),
                  onChanged: (value) => provider.updateBibleText(value),
                ),
                const SizedBox(height: 24),
                
                // Points Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Points',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => provider.addPoint(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Point'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Points List
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sermon.points.length,
                  itemBuilder: (context, index) {
                    final point = sermon.points[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: 'Point ${index + 1}',
                                      border: const OutlineInputBorder(),
                                    ),
                                    controller: TextEditingController(text: point.text)
                                      ..selection = TextSelection.fromPosition(
                                        TextPosition(offset: point.text.length),
                                      ),
                                    onChanged: (value) => provider.updatePointText(index, value),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => provider.removePoint(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Sub-points
                            Padding(
                              padding: const EdgeInsets.only(left: 32.0),
                              child: Column(
                                children: [
                                  ...point.subPoints.asMap().entries.map((entry) {
                                    final subIndex = entry.key;
                                    final subText = entry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              decoration: InputDecoration(
                                                labelText: 'Sub-point ${subIndex + 1}',
                                                isDense: true,
                                              ),
                                              controller: TextEditingController(text: subText)
                                                ..selection = TextSelection.fromPosition(
                                                  TextPosition(offset: subText.length),
                                                ),
                                              onChanged: (value) => provider.updateSubPointText(index, subIndex, value),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            onPressed: () => provider.removeSubPoint(index, subIndex),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: () => provider.addSubPoint(index),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Add Sub-point'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
