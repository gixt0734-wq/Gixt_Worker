import 'package:flutter/material.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool readOnly;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final String hint;

  const CustomTextFormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.readOnly,
    this.validator,
    this.hint = '',
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
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
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Theme.of(context).colorScheme.surface,
      ),
      cursorColor: Theme.of(context).colorScheme.surface,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
        ),

        // 🔹 Label normal
        labelStyle: GoogleFonts.poppins(
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
