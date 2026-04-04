import 'package:flutter/material.dart';
import 'package:gixt_worker/Config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomDescriptionFormField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int minLines;
  final int maxLines;
  final bool enabled;
  final String hint;
  final String? Function(String?)? validator;

  const CustomDescriptionFormField({
    super.key,
    required this.controller,
    this.label = 'Descripción del problema',
    this.icon = Icons.description,
    this.minLines = 1,
    this.maxLines = 1,
    this.enabled = true,
    this.validator,
    this.hint = '',
  });

  @override
  State<CustomDescriptionFormField> createState() =>
      _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomDescriptionFormField> {
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
      enabled: widget.enabled,
      keyboardType: TextInputType.multiline,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Theme.of(context).colorScheme.surface,
      ),
      cursorColor: Theme.of(context).colorScheme.surface,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        // 🔹 Label normal
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.45),
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 11,
          color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
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
