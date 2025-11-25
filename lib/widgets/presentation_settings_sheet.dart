import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/presentation_config.dart';
import '../providers/presentation_config_provider.dart';

class PresentationSettingsSheet extends StatelessWidget {
  const PresentationSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Presentation Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: Consumer<PresentationConfigProvider>(
              builder: (context, provider, child) {
                return ListView(
                  children: [
                    _buildSectionHeader('Text Scale'),
                    Slider(
                      value: provider.config.scale,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${provider.config.scale.toStringAsFixed(1)}x',
                      activeColor: const Color(0xFF03DAC6),
                      onChanged: (value) => provider.setScale(value),
                    ),
                    
                    _buildSectionHeader('Animation Style'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<PresentationAnimation>(
                        value: provider.config.animation,
                        dropdownColor: const Color(0xFF2C2C2C),
                        style: const TextStyle(color: Colors.white),
                        isExpanded: true,
                        underline: Container(height: 1, color: const Color(0xFF03DAC6)),
                        items: PresentationAnimation.values.map((anim) {
                          return DropdownMenuItem(
                            value: anim,
                            child: Text(anim.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) provider.setAnimation(value);
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    _buildSectionHeader('Colors'),
                    _buildColorTile(
                      context,
                      'Background Color',
                      provider.config.backgroundColor,
                      (color) => provider.setBackground(color),
                    ),
                    _buildColorTile(
                      context,
                      'Reference Color',
                      provider.config.referenceColor,
                      (color) => provider.setReference(color),
                    ),
                    _buildColorTile(
                      context,
                      'Verse Text Color',
                      provider.config.verseColor,
                      (color) => provider.setVerse(color),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF03DAC6),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildColorTile(
    BuildContext context,
    String title,
    Color currentColor,
    Function(Color) onColorChanged,
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
      ),
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Pick a color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: currentColor,
                onColorChanged: onColorChanged,
                enableAlpha: false,
                displayThumbColor: true,
                paletteType: PaletteType.hsvWithHue,
              ),
            ),
            actions: [
              TextButton(
                child: const Text('Done'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
