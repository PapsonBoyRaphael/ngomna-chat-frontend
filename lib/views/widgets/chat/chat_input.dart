import 'package:flutter/material.dart';
import 'package:ngomna_chat/core/constants/app_assets.dart';
import 'package:ngomna_chat/controllers/chat_input_controller.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final ChatInputStateController controller;
  final Function(String)? onTextChanged; // Nouveau paramètre
  final TextEditingController? textController; // Nouveau paramètre
  final Function()? onFileSelected; // Nouveau paramètre

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.controller,
    this.onTextChanged,
    this.textController,
    this.onFileSelected,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late final TextEditingController _controller;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.textController ?? TextEditingController();
    widget.controller.addListener(_updateState);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateState);
    if (widget.textController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String text) {
    setState(() {
      _isTyping = text.isNotEmpty;
    });
    widget.onTextChanged?.call(text);
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

  void _updateState() {
    debugPrint(
        'ChatInput: _updateState called. showAttachMenu = \\${widget.controller.showAttachMenu}');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.controller.showAttachMenu) {
          widget.controller.closeAttachMenu();
          debugPrint('Clic détecté en dehors du menu attaché (ChatInput)');
        } else {
          debugPrint('Clic ignoré car le menu est déjà fermé (ChatInput)');
        }
      },
      child: SafeArea(
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
                      widget.controller.toggleAttachMenu();
                      widget.onFileSelected?.call();
                      debugPrint('Clic sur le bouton + (ChatInput)');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Icon(
                        Icons.add,
                        size: 26,
                        color: widget.controller.showAttachMenu
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
                      onTap: () {
                        if (widget.controller.showAttachMenu) {
                          widget.controller.closeAttachMenu();
                          debugPrint(
                              'Menu attaché fermé lors du clic sur le TextField');
                        }
                      },
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
              if (widget.controller.showAttachMenu)
                Positioned(
                  bottom: 60,
                  left: 0,
                  child: _AttachMenu(
                    onClose: () => widget.controller.closeAttachMenu(),
                  ),
                ),
            ],
          ),
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
