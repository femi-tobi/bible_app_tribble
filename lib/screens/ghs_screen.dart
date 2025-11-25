import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/ghs_provider.dart';
import '../services/presentation_window_service.dart';
import 'ghs_presentation_screen.dart';

class GhsScreen extends StatefulWidget {
  const GhsScreen({super.key});

  @override
  State<GhsScreen> createState() => _GhsScreenState();
}

class _GhsScreenState extends State<GhsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _keyboardFocusNode = FocusNode();
  int _totalHymns = 0;
  double _previewHeight = 120.0; // Adjustable preview height

  @override
  void initState() {
    super.initState();
    _loadTotalHymns();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    });
  }

  Future<void> _loadTotalHymns() async {
    final provider = context.read<GhsProvider>();
    final total = await provider.getTotalHymns();
    setState(() {
      _totalHymns = total;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    if (_searchController.text.isNotEmpty) {
      final number = int.tryParse(_searchController.text);
      if (number != null) {
        context.read<GhsProvider>().selectHymn(number);
      }
    }
  }

  void _onHymnSelected(int number) {
    context.read<GhsProvider>().selectHymn(number);
  }

  void _goLive() async {
    final ghsProvider = context.read<GhsProvider>();
    if (ghsProvider.currentHymn != null) {
      try {
        await PresentationWindowService.openFullscreenPresentation(
          context,
          ghsProvider.currentHymn!,
        );
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Presentation window opened! Use arrow keys to navigate.'),
              backgroundColor: Color(0xFF03DAC6),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening presentation: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a hymn first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ghsProvider = context.watch<GhsProvider>();

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): _goLive,
        const SingleActivator(LogicalKeyboardKey.keyR): _goLive,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () {
          PresentationWindowService.sendNavigationCommand('previous');
        },
        const SingleActivator(LogicalKeyboardKey.arrowRight): () {
          PresentationWindowService.sendNavigationCommand('next');
        },
        const SingleActivator(LogicalKeyboardKey.escape): () async {
          // Close presentation window if active, otherwise go back
          if (PresentationWindowService.isPresentationActive) {
            await PresentationWindowService.closePresentationWindow();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Presentation closed'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            Navigator.pop(context);
          }
        },
      },
      child: Focus(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        child: Scaffold(
          backgroundColor: const Color(0xFF121212),
          appBar: AppBar(
            title: const Text('Gospel Hymns & Songs'),
            backgroundColor: const Color(0xFF2C2C2C),
            foregroundColor: Colors.white,
          ),
          body: Row(
            children: [
              // Left: Hymn Grid (80%)
              Expanded(
                flex: 8,
                child: Container(
                  color: const Color(0xFF121212),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      // Search Bar
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'Enter hymn number',
                            hintStyle: TextStyle(color: Colors.grey[600]),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _handleSearch(),
                        ),
                      ),
                      // Grid
                      Expanded(
                        child: _totalHymns > 0
                            ? GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  mainAxisSpacing: 4,
                                  crossAxisSpacing: 4,
                                  childAspectRatio: 1.0,
                                ),
                                itemCount: _totalHymns,
                                itemBuilder: (context, index) {
                                  final number = index + 1;
                                  final isSelected = ghsProvider.currentHymn?.number == number;
                                  
                                  return InkWell(
                                    onTap: () => _onHymnSelected(number),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFF03DAC6)
                                            : const Color(0xFF2C2C2C),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF03DAC6)
                                              : Colors.white12,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$number',
                                          style: TextStyle(
                                            color: isSelected ? Colors.black : Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const Center(
                                child: CircularProgressIndicator(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Right: Hymn Preview (20%)
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    border: Border(
                      left: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Presentation Preview
                      if (ghsProvider.currentHymn != null)
                        Column(
                          children: [
                            Container(
                              margin: const EdgeInsets.all(8),
                              height: _previewHeight,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF03DAC6).withValues(alpha: 0.3)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Stack(
                                  children: [
                                    // Preview content
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'GHS ${ghsProvider.currentHymn!.number}',
                                              style: const TextStyle(
                                                color: Color(0xFF03DAC6),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              ghsProvider.currentHymn!.title,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Flexible(
                                              child: Text(
                                                ghsProvider.currentHymn!.verses.isNotEmpty
                                                    ? ghsProvider.currentHymn!.verses.first.split('\n').take(2).join('\n')
                                                    : '',
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 7,
                                                  height: 1.2,
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // "LIVE" indicator if presentation is active
                                    if (PresentationWindowService.isPresentationActive)
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'LIVE',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Resize slider
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.photo_size_select_small, size: 12, color: Colors.white30),
                                  Expanded(
                                    child: Slider(
                                      value: _previewHeight,
                                      min: 80,
                                      max: 300,
                                      divisions: 22,
                                      activeColor: const Color(0xFF03DAC6),
                                      inactiveColor: Colors.white12,
                                      onChanged: (value) {
                                        setState(() {
                                          _previewHeight = value;
                                        });
                                      },
                                    ),
                                  ),
                                  const Icon(Icons.photo_size_select_large, size: 16, color: Colors.white30),
                                ],
                              ),
                            ),
                          ],
                        ),
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        color: const Color(0xFF2C2C2C),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Preview',
                              style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Row(
                              children: [
                                _ShortcutBadge(label: 'R'),
                                const SizedBox(width: 4),
                                _ShortcutBadge(label: 'F5'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Content
                      Expanded(
                        child: ghsProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ghsProvider.currentHymn != null
                                ? SingleChildScrollView(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title
                                        Text(
                                          '#${ghsProvider.currentHymn!.number}',
                                          style: const TextStyle(
                                            color: Color(0xFF03DAC6),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          ghsProvider.currentHymn!.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Verses
                                        ...ghsProvider.currentHymn!.verses.asMap().entries.map((entry) {
                                          return Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Verse ${entry.key + 1}',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  entry.value,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 14,
                                                    height: 1.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        // Chorus
                                        if (ghsProvider.currentHymn!.chorus != null) ...[
                                          const Text(
                                            'Chorus',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ghsProvider.currentHymn!.chorus!,
                                            style: const TextStyle(
                                              color: Color(0xFF03DAC6),
                                              fontSize: 14,
                                              height: 1.5,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      'Select a hymn',
                                      style: TextStyle(color: Colors.white30),
                                    ),
                                  ),
                      ),
                      // Go Live Button
                      if (ghsProvider.currentHymn != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _goLive,
                            icon: const Icon(Icons.tv),
                            label: const Text('GO LIVE'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              textStyle: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  final String label;

  const _ShortcutBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
