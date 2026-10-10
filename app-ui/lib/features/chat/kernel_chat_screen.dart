
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kernel_contracts/kernel_contracts.dart';

import '../../agents/agents.dart';
import '../../app/providers.dart';

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.audioMedia,
    this.visualMedia,
    this.verdict,
    this.guidance,
    this.acousticReport,
    this.visualReport,
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final PickedMedia? audioMedia;
  final PickedMedia? visualMedia;
  final QualityWeightedVerdict? verdict;
  final GroundedGuidanceReport? guidance;
  final AcousticEvidenceReport? acousticReport;
  final VisualEvidenceReport? visualReport;
}

class KernelChatScreen extends ConsumerStatefulWidget {
  const KernelChatScreen({super.key});

  @override
  ConsumerState<KernelChatScreen> createState() => _KernelChatScreenState();
}

class _KernelChatScreenState extends ConsumerState<KernelChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  PickedMedia? _pendingAudio;
  PickedMedia? _pendingVisual;
  SensorType _selectedSensor = SensorType.contactPiezo;
  String? _selectedNodeId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        id: 'msg_init',
        isUser: false,
        text: '🌾 **Welcome to Kernel Autonomous Multi-Agent Grain Screening.**\n\n'
            'I coordinate specialized bioacoustic and computer vision agents running directly on your phone:\n'
            '• **Acoustic Diagnostic Agent** (InsectSet32 16 kHz Log-Mel Classifier)\n'
            '• **Visual Diagnostic Agent** (Sharpness & Macro Pest ID)\n'
            '• **Evidence Fusion Agent** (Calibrated Quality Weighting W_media)\n'
            '• **Agronomy Safety Agent** (Grounded IPM & statutory safety protocols)\n\n'
            'Attach a grain sound recording (.wav) or insect photo below, or ask any grain protection question.',
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleAudioUpload() async {
    final picker = ref.read(mediaPickerServiceProvider);

    // Show sensor selection bottom sheet
    final sensor = await showModalBottomSheet<SensorType>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select Acoustic Sensor Transducer',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Physical coupling calibrates the acoustic quality weight Q_sensor.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.touch_app, color: Color(0xFF1B4D3E)),
                  title: const Text('Contact Piezo Sensor (Grain Probe)'),
                  subtitle: const Text('Direct mechanical contact (Q = 1.0)'),
                  onTap: () => Navigator.pop(ctx, SensorType.contactPiezo),
                ),
                ListTile(
                  leading: const Icon(Icons.mic, color: Color(0xFF2E7D32)),
                  title: const Text('Acoustic Air Microphone (Phone / Lab)'),
                  subtitle: const Text('Air-coupled acoustic capture (Q = 0.88)'),
                  onTap: () => Navigator.pop(ctx, SensorType.audioAir),
                ),
                ListTile(
                  leading: const Icon(Icons.waves, color: Color(0xFF0277BD)),
                  title: const Text('Ultrasonic Air Transducer (20-40 kHz)'),
                  subtitle: const Text('Ultrasonic insect pulses (Q = 0.90)'),
                  onTap: () => Navigator.pop(ctx, SensorType.usAir),
                ),
                ListTile(
                  leading: const Icon(Icons.vibration, color: Color(0xFFF57F17)),
                  title: const Text('Contact Accelerometer'),
                  subtitle: const Text('Vibration pulse pickup (Q = 0.95)'),
                  onTap: () => Navigator.pop(ctx, SensorType.contactAccel),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (sensor == null) return;
    final media = await picker.pickAudioFile(sensorType: sensor);
    if (media != null) {
      setState(() {
        _pendingAudio = media;
        _selectedSensor = sensor;
      });
    }
  }

  Future<void> _handleImageUpload() async {
    final picker = ref.read(mediaPickerServiceProvider);
    final media = await picker.pickImage();
    if (media != null) {
      setState(() => _pendingVisual = media);
    }
  }

  Future<void> _handleVideoUpload() async {
    final picker = ref.read(mediaPickerServiceProvider);
    final media = await picker.pickVideo();
    if (media != null) {
      setState(() => _pendingVisual = media);
    }
  }

  Future<void> _handleLiveCapture() async {
    final orchestrator = ref.read(orchestratorAgentProvider);
    setState(() => _isProcessing = true);

    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: '🎙️ Live 2-second Acoustic Grain Screening',
      timestamp: DateTime.now(),
    );
    setState(() => _messages.add(userMsg));
    _scrollToBottom();

    try {
      final response = await orchestrator.execute(
        const OrchestratorTask(
          userMessage: 'Live capture screening',
          isLiveCapture: true,
        ),
      );

      final agentMsg = ChatMessage(
        id: 'agent_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: response.responseText,
        timestamp: DateTime.now(),
        verdict: response.verdict,
        guidance: response.guidance,
        acousticReport: response.acousticReport,
        visualReport: response.visualReport,
      );
      setState(() => _messages.add(agentMsg));
    } catch (e) {
      _messages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: 'Screening error: $e',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingAudio == null && _pendingVisual == null) return;

    final audio = _pendingAudio;
    final visual = _pendingVisual;
    _textController.clear();
    setState(() {
      _pendingAudio = null;
      _pendingVisual = null;
      _isProcessing = true;
    });

    final userMsg = ChatMessage(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: text.isNotEmpty ? text : 'Multimodal Screening Analysis',
      timestamp: DateTime.now(),
      audioMedia: audio,
      visualMedia: visual,
    );
    setState(() => _messages.add(userMsg));
    _scrollToBottom();

    final orchestrator = ref.read(orchestratorAgentProvider);
    try {
      final response = await orchestrator.execute(
        OrchestratorTask(
          userMessage: text,
          audioMedia: audio,
          visualMedia: visual,
          sensorNodeId: _selectedNodeId,
        ),
      );

      final agentMsg = ChatMessage(
        id: 'agent_${DateTime.now().millisecondsSinceEpoch}',
        isUser: false,
        text: response.responseText,
        timestamp: DateTime.now(),
        verdict: response.verdict,
        guidance: response.guidance,
        acousticReport: response.acousticReport,
        visualReport: response.visualReport,
      );
      setState(() => _messages.add(agentMsg));
    } catch (e) {
      _messages.add(
        ChatMessage(
          id: 'err_${DateTime.now().millisecondsSinceEpoch}',
          isUser: false,
          text: 'Autonomous processing error: $e',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4D3E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.grain, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kernel Agent Chat',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Autonomous On-Device Screening',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic),
            tooltip: 'Live Acoustic Scan',
            onPressed: _isProcessing ? null : _handleLiveCapture,
          ),
        ],
      ),
      body: Column(
        children: [
          // Message stream
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _MessageBubble(message: message);
              },
            ),
          ),

          if (_isProcessing)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.amber.withOpacity(0.1),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Agents processing on-device: computing ASQI, InsectSet32 classification & IPM...',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // Pending attachments preview bar
          if (_pendingAudio != null || _pendingVisual != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
              child: Row(
                children: [
                  if (_pendingAudio != null)
                    Chip(
                      avatar: const Icon(Icons.audiotrack, size: 16),
                      label: Text(
                        '${_pendingAudio!.fileName} (${_selectedSensor.name})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => setState(() => _pendingAudio = null),
                    ),
                  const SizedBox(width: 8),
                  if (_pendingVisual != null)
                    Chip(
                      avatar: Icon(
                        _pendingVisual!.isVideo ? Icons.videocam : Icons.image,
                        size: 16,
                      ),
                      label: Text(
                        _pendingVisual!.fileName,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onDeleted: () => setState(() => _pendingVisual = null),
                    ),
                ],
              ),
            ),

          // Bottom multimodal input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  // Audio upload button
                  IconButton(
                    icon: const Icon(Icons.audio_file, color: Color(0xFF1B4D3E)),
                    tooltip: 'Upload Audio (.wav) with Sensor Tag',
                    onPressed: _isProcessing ? null : _handleAudioUpload,
                  ),
                  // Photo upload button
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
                    tooltip: 'Take / Upload Pest Photo',
                    onPressed: _isProcessing ? null : _handleImageUpload,
                  ),
                  // Video upload button
                  IconButton(
                    icon: const Icon(Icons.videocam, color: Color(0xFF0277BD)),
                    tooltip: 'Upload Pest Video',
                    onPressed: _isProcessing ? null : _handleVideoUpload,
                  ),

                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Type query or send attachments...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),

                  const SizedBox(width: 6),
                  // Send button
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      shape: const CircleBorder(),
                    ),
                    onPressed: _isProcessing ? null : _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.88,
            ),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF1B4D3E)
                  : theme.colorScheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachments in user message
                if (message.audioMedia != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.audiotrack, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                        Text(
                          '${message.audioMedia!.fileName} (${message.audioMedia!.sensorType.name})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (message.visualMedia != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          message.visualMedia!.isVideo ? Icons.videocam : Icons.image,
                          size: 16,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          message.visualMedia!.fileName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Text body
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isUser ? Colors.white : theme.textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),

                // Quality Badge Card (Agent responses)
                if (message.verdict != null) ...[
                  const SizedBox(height: 12),
                  _QualityVerdictCard(verdict: message.verdict!),
                ],

                // IPM Protocol Card (Agent responses)
                if (message.guidance != null) ...[
                  const SizedBox(height: 10),
                  _IpmProtocolCard(guidance: message.guidance!),
                ],
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
            child: Text(
              '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualityVerdictCard extends StatelessWidget {
  const _QualityVerdictCard({required this.verdict});

  final QualityWeightedVerdict verdict;

  @override
  Widget build(BuildContext context) {
    final badgeColor = switch (verdict.qualityBadge) {
      QualityBadge.clear => const Color(0xFF2E7D32),
      QualityBadge.fair => const Color(0xFFF57F17),
      QualityBadge.noisy => const Color(0xFFC62828),
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  verdict.plainLanguageQuality,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Weight: ${(verdict.qualityWeight * 100).toInt()}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            verdict.speciesName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B4D3E),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text('Calibrated Confidence: ', style: TextStyle(fontSize: 12, color: Colors.black54)),
              Text(
                '${(verdict.calibratedConfidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: verdict.calibratedConfidence >= 0.70 ? Colors.green.shade800 : Colors.orange.shade800,
                ),
              ),
            ],
          ),
          const Divider(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 15, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  verdict.userAdvice,
                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IpmProtocolCard extends StatelessWidget {
  const _IpmProtocolCard({required this.guidance});

  final GroundedGuidanceReport guidance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1B4D3E).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield, size: 16, color: Color(0xFF1B4D3E)),
              SizedBox(width: 6),
              Text(
                'Safe Non-Chemical IPM Protocols',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final step in guidance.safeSteps)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                step,
                style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.3),
              ),
            ),
          if (guidance.legalNote != null) ...[
            const SizedBox(height: 6),
            Text(
              guidance.legalNote!,
              style: TextStyle(fontSize: 10, color: Colors.red.shade800, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}
