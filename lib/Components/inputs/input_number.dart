import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gixt_worker/config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomTextFormFieldNumber extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool readOnly;
  final IconData icon;
  final String? Function(String?)? validator;

  const CustomTextFormFieldNumber({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.readOnly = false,
    this.validator,
  });

    @override
  State<CustomTextFormFieldNumber> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormFieldNumber> {
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
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: GoogleFonts.poppins(
        fontSize: 14,
        color: Theme.of(context).colorScheme.surface,
      ),
      cursorColor: colorBase,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
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
        // Hint con formato de ejemplo
        hintText: '0',
        hintStyle: TextStyle(
          color: colorBase.withOpacity(0.35),
          fontSize: 13,
        ),

       
       

        // Sufijo con la moneda (puedes cambiar MXN/USD según tu app)
        // suffix: Text(
        //   'Horas',
        //   style: TextStyle(
        //     color: colorBase.withOpacity(0.5),
        //     fontSize: 12,
        //     fontWeight: FontWeight.w600,
        //     letterSpacing: 1,
        //   ),
        // ),

        counterText: '', // Oculta el contador de caracteres

      ),
      validator: widget.validator,
    );
  }
}


/// Formateador que agrega separadores de miles y mantiene 2 decimales
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    // Permitir borrar
    if (text.isEmpty) return newValue;

    // Solo permitir dígitos y un punto decimal
    final regex = RegExp(r'^\d+\.?\d{0,2}$');
    if (!regex.hasMatch(text)) return oldValue;

    return newValue;
  }
}