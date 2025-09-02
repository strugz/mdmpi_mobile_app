import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/sizes.dart';
import 'package:signature/signature.dart';
import 'package:mdmpi_mobile_app/base/utils/constants/colors.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(Uint8List? signatureBytes) onSave;

  const SignaturePadWidget({super.key, required this.onSave});

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black, // Or use your app's theme color
    exportBackgroundColor: Colors.white, // Or transparent if you prefer
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSignature() async {
    if (_controller.isNotEmpty) {
      final Uint8List? data = await _controller.toPngBytes();
      widget.onSave(data);
    } else {
      widget.onSave(null); // No signature drawn
    }
  }

  void _clearSignature() {
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(BSizes.defaultSpace),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Important for Dialogs
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(BSizes.xxs),
            child: Text(
              "Receiver's Signature",
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: BSizes.sm),
          // THE SIGNATURE PAD
          Container(
            height: 200, // Adjust as needed
            decoration: BoxDecoration(
              border: Border.all(color: BColors.grey, width: 1),
              color: BColors.lightGrey, // Or any background you prefer
            ),
            child: Signature(
              controller: _controller,
              backgroundColor: Colors.transparent, // Pad background
            ),
          ),
          // ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(
                vertical: BSizes.sm, horizontal: BSizes.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TextButton(
                  onPressed: _clearSignature,
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: _saveSignature,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: BSizes.xs),
                    child: const Text('Save Signature'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
