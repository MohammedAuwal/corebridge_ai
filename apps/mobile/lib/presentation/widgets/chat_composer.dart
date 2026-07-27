import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/voice_input_service.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/chat_attachment.dart';
import 'model_picker_chip.dart';

class ChatComposer extends StatefulWidget {
  final void Function(String text, List<ChatAttachment> attachments) onSend;
  final bool isSending;
  final VoidCallback? onStop;

  const ChatComposer({
    super.key,
    required this.onSend,
    required this.isSending,
    this.onStop,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _voiceInput = VoiceInputService();
  final _imagePicker = ImagePicker();

  static const int _pasteCharThreshold = 300;
  static const int _pasteLineThreshold = 8;
  static const int _maxImageDimension = 1568; // keeps base64 payloads reasonable

  String? _attachedContent;
  int _previousLength = 0;
  final List<ChatAttachment> _attachedImages = [];
  bool _isListening = false;
  String _preVoiceText = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChange);
  }

  void _handleTextChange() {
    if (_isListening) return; // don't treat voice-populated text as a paste

    final current = _controller.text;
    final delta = current.length - _previousLength;
    _previousLength = current.length;

    final lineCount = current.split('\n').length;
    final looksLikeAPaste = delta >= _pasteCharThreshold || lineCount > _pasteLineThreshold;

    if (looksLikeAPaste && _attachedContent == null) {
      setState(() {
        _attachedContent = current.trim();
        _controller.clear();
        _previousLength = 0;
      });
    }
  }

  void _removeAttachment() {
    setState(() => _attachedContent = null);
  }

  void _removeImage(int index) {
    setState(() => _attachedImages.removeAt(index));
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: _maxImageDimension.toDouble(),
      maxHeight: _maxImageDimension.toDouble(),
      imageQuality: 85,
    );
    if (picked == null) return;

    final Uint8List bytes = await picked.readAsBytes();
    final base64Data = base64Encode(bytes);
    final mimeType = picked.mimeType ?? _guessMimeType(picked.name);

    setState(() {
      _attachedImages.add(ChatAttachment(
        mimeType: mimeType,
        base64Data: base64Data,
        fileName: picked.name,
      ));
    });
  }

  String _guessMimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  Future<void> _pickTextFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) return;

    try {
      final text = utf8.decode(file.bytes!);
      setState(() {
        _attachedContent = text.trim();
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${file.name}" isn\'t a readable text file. Try an image or a plain-text file instead.')),
        );
      }
    }
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceRaised,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xl))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accentBlue),
              title: const Text('Photo Library'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.accentBlue),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.accentBlue),
              title: const Text('Attach File (text)'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickTextFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _voiceInput.stopListening();
      setState(() => _isListening = false);
      return;
    }

    _preVoiceText = _controller.text;
    final started = await _voiceInput.startListening(
      onResult: (recognizedText, isFinal) {
        if (!mounted) return;
        final separator = _preVoiceText.trim().isEmpty ? '' : ' ';
        setState(() {
          _controller.text = '$_preVoiceText$separator$recognizedText';
          _controller.selection = TextSelection.collapsed(offset: _controller.text.length);
        });
        if (isFinal) {
          setState(() => _isListening = false);
        }
      },
    );

    if (!started) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is needed for voice input.')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
  }

  void _submit() {
    final typed = _controller.text.trim();
    final attachment = _attachedContent;

    if (typed.isEmpty && attachment == null && _attachedImages.isEmpty) return;

    final String message;
    if (attachment != null) {
      final fenced = '```text\n$attachment\n```';
      message = typed.isEmpty ? fenced : '$typed\n\n$fenced';
    } else {
      message = typed;
    }

    widget.onSend(message, List.of(_attachedImages));

    _controller.clear();
    setState(() {
      _attachedContent = null;
      _attachedImages.clear();
    });
    _previousLength = 0;
  }

  bool get _hasText => _controller.text.trim().isNotEmpty || _attachedContent != null || _attachedImages.isNotEmpty;

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _controller.dispose();
    _focusNode.dispose();
    _voiceInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_attachedImages.isNotEmpty) _buildImageStrip(),
            if (_attachedContent != null) _buildAttachmentChip(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Scrollbar(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        cursorColor: AppColors.accentBlue,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening…'
                              : (_attachedContent != null || _attachedImages.isNotEmpty)
                                  ? 'Add a message (optional)…'
                                  : 'Message CoreBridge…',
                          hintStyle: TextStyle(color: _isListening ? AppColors.accentBlue : AppColors.textMuted),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.textSecondary),
                        tooltip: 'Add files',
                        onPressed: widget.isSending ? null : _showAttachMenu,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: ModelPickerChip(),
                      ),
                      const Spacer(),
                      if (!widget.isSending && !_hasText)
                        IconButton(
                          icon: Icon(
                            _isListening ? Icons.mic_rounded : Icons.graphic_eq_rounded,
                            color: _isListening ? AppColors.accentBlue : AppColors.textSecondary,
                          ),
                          tooltip: 'Voice input',
                          onPressed: _toggleVoiceInput,
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: widget.isSending ? null : AppColors.brandGradient,
                          color: widget.isSending ? AppColors.surfaceRaised : null,
                          shape: BoxShape.circle,
                        ),
                        margin: const EdgeInsets.only(right: 2),
                        child: IconButton(
                          icon: widget.isSending
                              ? const Icon(Icons.stop_rounded, color: AppColors.textPrimary)
                              : const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                          onPressed: widget.isSending ? widget.onStop : (_hasText ? _submit : null),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageStrip() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 72,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _attachedImages.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final image = _attachedImages[index];
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  child: Image.memory(
                    base64Decode(image.base64Data),
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: InkWell(
                    onTap: () => _removeImage(index),
                    child: Container(
                      decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAttachmentChip() {
    final lineCount = _attachedContent!.split('\n').length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(gradient: AppColors.brandGradient, borderRadius: BorderRadius.circular(AppRadii.sm)),
              alignment: Alignment.center,
              child: const Icon(Icons.description_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Text attached', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('$lineCount lines · will send as an artifact', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
              onPressed: _removeAttachment,
            ),
          ],
        ),
      ),
    );
  }
}
