import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextFormFieldPhone extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const CustomTextFormFieldPhone({
    super.key,
    required this.controller,
    required this.label,
    this.readOnly = false,
    this.keyboardType = TextInputType.phone,
    this.validator,
  });

  @override
  State<CustomTextFormFieldPhone> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormFieldPhone> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorBase = Theme.of(context).colorScheme.surface;

    return TextFormField(
      controller: widget.controller,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      maxLength: 10,
      style: TextStyle(color: colorBase),
      cursorColor: colorBase,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: widget.label,

        // 🔹 Label normal
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
        ),
        // 🔹 contador de digitos
        counterStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
        ),
        // 🔹 Label cuando está seleccionado
        floatingLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _isFocused
              ? colorsecundario
              : Theme.of(context).colorScheme.surface.withOpacity(0.45),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.primary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),

        // 🔹 Línea normal
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.08),
            width: 1,
          ),
        ),

        // 🔹 Línea cuando está seleccionado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: colorsecundario.withOpacity(0.5),
            width: 1.5,
          ),
        ),

        // 🔹 Línea cuando hay error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5), width: 1),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),

        // 🔹 Ícono
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(
            Icons.phone,
            size: 18,
            color: _isFocused
                ? colorsecundario
                : Theme.of(context).colorScheme.surface.withOpacity(0.3),
          ),
        ),

        errorStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Colors.red.withOpacity(0.8),
        ),
      ),
      validator: widget.validator,
    );
  }
}

class PhoneDashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.length <= 3) {
      return newValue.copyWith(text: digits);
    } else if (digits.length <= 6) {
      return newValue.copyWith(
        text: '${digits.substring(0, 3)}-${digits.substring(3)}',
      );
    } else {
      return newValue.copyWith(
        text:
            '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6, digits.length)}',
      );
    }
  }
}
