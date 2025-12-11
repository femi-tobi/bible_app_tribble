import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_config.dart';
import '../providers/timer_provider.dart';
import '../providers/presentation_config_provider.dart';
import '../services/presentation_window_service.dart';

class TimerEditorScreen extends StatefulWidget {
  const TimerEditorScreen({super.key});

  @override
  State<TimerEditorScreen> createState() => _TimerEditorScreenState();
}

class _TimerEditorScreenState extends State<TimerEditorScreen> {
  final TextEditingController _hoursController = TextEditingController();
  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _updateControllersFromProvider();
  }

  void _updateControllersFromProvider() {
    final config = context.read<TimerProvider>().config;
    final duration = config.duration;
    _hoursController.text = duration.inHours.toString().padLeft(2, '0');
    _minutesController.text = (duration.inMinutes % 60).toString().padLeft(2, '0');
    _secondsController.text = (duration.inSeconds % 60).toString().padLeft(2, '0');
    _titleController.text = config.title;
  }

  void _updateConfigFromControllers() {
    final hours = int.tryParse(_hoursController.text) ?? 0;
    final minutes = int.tryParse(_minutesController.text) ?? 0;
    final seconds = int.tryParse(_secondsController.text) ?? 0;
    
    final provider = context.read<TimerProvider>();
    final newConfig = provider.config.copyWith(
      duration: Duration(hours: hours, minutes: minutes, seconds: seconds),
      title: _titleController.text,
    );
    provider.updateConfig(newConfig);
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _goLive() {
    final provider = context.read<TimerProvider>();
    final configProvider = context.read<PresentationConfigProvider>();
    
    final timerData = {
      'config': provider.config.toMap(),
      'currentSeconds': provider.currentDuration.inSeconds,
      'isRunning': provider.isRunning,
      'isPaused': provider.isPaused,
    };
    
    PresentationWindowService.openTimerPresentation(
      context, 
      timerData, 
      configProvider.config.toMap()
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimerProvider>();
    final config = provider.config;
    final isRunning = provider.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Timer Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save as Preset',
            onPressed: () {
              _showSavePresetDialog(context);
            },
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel: Configuration
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration Input
                  const Text('Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTimeInput(_hoursController, 'HH'),
                      const Text(' : ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      _buildTimeInput(_minutesController, 'MM'),
                      const Text(' : ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      _buildTimeInput(_secondsController, 'SS'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Title Input
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _updateConfigFromControllers(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Toggles
                  SwitchListTile(
                    title: const Text('Count Up Mode'),
                    value: config.isCountUp,
                    onChanged: (val) {
                      provider.updateConfig(config.copyWith(isCountUp: val));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Play Sound Alert'),
                    value: config.playAlert,
                    onChanged: (val) {
                      provider.updateConfig(config.copyWith(playAlert: val));
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Show Milliseconds'),
                    value: config.showMilliseconds,
                    onChanged: (val) {
                      provider.updateConfig(config.copyWith(showMilliseconds: val));
                    },
                  ),
                  
                  const Spacer(),
                  
                  // Presets List
                  const Text('Presets', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.presets.length,
                      itemBuilder: (context, index) {
                        final preset = provider.presets[index];
                        return ListTile(
                          title: Text(preset.title.isNotEmpty ? preset.title : 'Untitled Preset'),
                          subtitle: Text(_formatDuration(preset.duration) + (preset.isCountUp ? ' (Count Up)' : '')),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => provider.removePreset(index),
                          ),
                          onTap: () {
                            provider.updateConfig(preset);
                            _updateControllersFromProvider();
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const VerticalDivider(width: 1),
          
          // Right Panel: Preview & Controls
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.black87,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Preview
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (config.title.isNotEmpty)
                          Text(
                            config.title,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 24,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _formatDuration(provider.currentDuration),
                          style: TextStyle(
                            color: provider.isOvertime ? Colors.red : Colors.white,
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildControlButton(
                        icon: isRunning ? Icons.pause : Icons.play_arrow,
                        label: isRunning ? 'PAUSE' : 'START',
                        color: isRunning ? Colors.orange : Colors.green,
                        onPressed: () {
                          if (!isRunning) {
                            _updateConfigFromControllers(); // Ensure latest config before start
                            provider.start();
                          } else {
                            provider.pause();
                          }
                        },
                      ),
                      const SizedBox(width: 24),
                      _buildControlButton(
                        icon: Icons.refresh,
                        label: 'RESET',
                        color: Colors.blue,
                        onPressed: () {
                          provider.reset();
                          _updateControllersFromProvider();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Go Live Button
                  ElevatedButton.icon(
                    onPressed: _goLive,
                    icon: const Icon(Icons.connected_tv),
                    label: const Text('GO LIVE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInput(TextEditingController controller, String label) {
    return SizedBox(
      width: 70,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onChanged: (_) => _updateConfigFromControllers(),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showSavePresetDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Preset'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Preset Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                final provider = context.read<TimerProvider>();
                final preset = provider.config.copyWith(title: nameController.text);
                provider.savePreset(preset);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
