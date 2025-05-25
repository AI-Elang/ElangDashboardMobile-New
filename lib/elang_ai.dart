import 'package:flutter/material.dart';

class ElangAIChatUI extends StatelessWidget {
  const ElangAIChatUI({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Elang AI title and model dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menu icon placeholder
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white70),
                    onPressed: () {},
                  ),

                  // Center section with title and dropdown
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Elang AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Model selection dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'GPT-4 Turbo',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white70,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile icon placeholder
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'U',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area
            Expanded(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 800),
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width > 600 ? 40 : 20,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Welcome message
                    Text(
                      'Hai, Asisten AI siap membantu!',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width > 600 ? 32 : 24,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Subtitle
                    Text(
                      'Tanyakan apa saja, dari ide kreatif hingga solusi teknis. Saya di sini untuk membantu Anda.',
                      style: TextStyle(
                        fontSize:
                            MediaQuery.of(context).size.width > 600 ? 16 : 14,
                        color: Colors.white60,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Feature chips
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeatureChip('💡 Ide Kreatif'),
                        _buildFeatureChip('📊 Analisis Data'),
                        _buildFeatureChip('🎨 Desain & Seni'),
                        _buildFeatureChip('💻 Coding'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Input area
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 800),
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600 ? 40 : 16,
                vertical: 20,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Attachment button
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Colors.white54,
                        size: MediaQuery.of(context).size.width > 600 ? 24 : 22,
                      ),
                      onPressed: () {},
                    ),

                    // Text input
                    Expanded(
                      child: TextField(
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ketik pesan Anda di sini...',
                          hintStyle: TextStyle(
                            color: Colors.white38,
                            fontSize: MediaQuery.of(context).size.width > 600
                                ? 16
                                : 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 16,
                          ),
                        ),
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                      ),
                    ),

                    // Additional options
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.mic_none,
                            color: Colors.white54,
                            size: MediaQuery.of(context).size.width > 600
                                ? 24
                                : 22,
                          ),
                          onPressed: () {},
                        ),
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                              size: MediaQuery.of(context).size.width > 600
                                  ? 24
                                  : 22,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
