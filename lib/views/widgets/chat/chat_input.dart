import 'package:flutter/material.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;

  const ChatInput({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _showAttachMenu = false;
  bool _isTyping = false;

  void _onTextChanged(String text) {
    setState(() {
      _isTyping = text.isNotEmpty;
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSendMessage(_controller.text);
      _controller.clear();
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showAttachMenu = !_showAttachMenu;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Icon(
                      Icons.add,
                      size: 26,
                      color: _showAttachMenu
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF9E9E9E),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 6,
                    keyboardType: TextInputType.multiline,
                    onChanged: _onTextChanged,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: const BorderSide(
                          color: Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 134, 134, 134),
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(
                          color: Color(0xFF4CAF50),
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      hintText: 'Message...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9E9E9E),
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                if (!_isTyping) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Icon(Icons.mic, color: Color(0xFF9E9E9E)),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Icon(Icons.camera_alt, color: Color(0xFF9E9E9E)),
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: GestureDetector(
                      onTap: _sendMessage,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.black,
                          BlendMode.srcIn,
                        ),
                        child: Image.asset(
                          AppAssets.send,
                          width: 35,
                          height: 35,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_showAttachMenu)
              Positioned(
                bottom: 60,
                left: 0,
                child: _AttachMenu(
                  onClose: () => setState(() => _showAttachMenu = false),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AttachMenu extends StatelessWidget {
  final VoidCallback onClose;

  const _AttachMenu({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AttachItem(
              icon: AppAssets.file,
              label: 'Document',
              onTap: () {
                onClose();
                // TODO: Ouvrir le sélecteur de fichiers
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _AttachItem(
              icon: AppAssets.imgBox,
              label: 'Image',
              onTap: () {
                onClose();
                // TODO: Ouvrir la galerie
              },
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
            _AttachItem(
              icon: AppAssets.userCircle,
              label: 'Contact',
              onTap: () {
                onClose();
                // TODO: Ouvrir les contacts
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachItem extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _AttachItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Image.asset(icon, width: 25),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
