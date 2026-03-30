import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';

class OtpBoxclass extends StatefulWidget {
  final Function(String)? onChanged;
  final bool isError;
  final bool iscorrect;

  const OtpBoxclass({
    super.key,
    this.onChanged,
    this.isError = false,
    this.iscorrect = false
  });

  @override
  State<OtpBoxclass> createState() => _OtpBoxclassState();
}

class _OtpBoxclassState extends State<OtpBoxclass> {
  final List<TextEditingController> _controllers =
      List.generate(5, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
      List.generate(5, (_) => FocusNode());

  String get codigo => _controllers.map((e) => e.text).join();

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Widget _box(int index) {
    Color borderColor =
        widget.isError ? Colors.red : Colors.grey;

    Color focusColor =
        widget.isError ? Colors.red : colorsecundario;

    return SizedBox(
      width: 55,
      height: 65,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor:
              widget.isError ? Colors.red.withOpacity(0.08) : Colors.grey.shade100,
              
          // 🔥 BORDE NORMAL
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),

          // 🔥 BORDE SIN FOCUS
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: borderColor),
          ),

          // 🔥 BORDE FOCUS
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: focusColor, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < _focusNodes.length - 1) {
            FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
          }

          if (value.isEmpty && index > 0) {
            FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
          }

          widget.onChanged?.call(codigo);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: _box(i),
        ),
      ),
    );
  }
}
