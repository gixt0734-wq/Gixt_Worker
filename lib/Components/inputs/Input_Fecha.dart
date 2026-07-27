import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gixt_worker/config/colors.dart';

class CustomTextFormFieldfecha extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final bool readOnly;

  const CustomTextFormFieldfecha({
    super.key,
    required this.controller,
    this.label = 'Fecha de nacimiento',
    this.hint = 'DD/MM/AAAA',
    this.icon = Icons.cake,
    this.validator,
    this.readOnly = false,
  });

  @override
  State<CustomTextFormFieldfecha> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormFieldfecha> {
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
      keyboardType: TextInputType.number,
      style: TextStyle(color: colorBase),
      cursorColor: colorBase,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(8),
        FechaNacimientoFormatter(),
      ],
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        // 🔹 Label normal
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
        ),

        hintStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
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
            widget.icon,
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

class FechaNacimientoFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length > 8) return oldValue;

    String newText = text;

    if (text.length >= 5) {
      newText =
          '${text.substring(0, 2)}/${text.substring(2, 4)}/${text.substring(4)}';
    } else if (text.length >= 3) {
      newText = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
