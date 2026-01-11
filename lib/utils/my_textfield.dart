import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final int? maxLines; 

  const MyTextField({
    super.key,
    required this.hintText,
    required this.obscureText,
    required this.controller,
    this.focusNode,
    this.keyboardType,
    this.maxLines = 1, 
  });

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    // --- HARDCODED EARTHY PALETTE ---
    const Color colorPrimary = Color(0xFF6B705C);    
    const Color colorSecondary = Color(0xFFA2A595);  
    const Color colorTertiary = Color(0xFFB4A284);   
    const Color colorTextDark = Color(0xFF3F4238);   

    IconData prefixIcon;
    if (widget.hintText.toLowerCase().contains("email")) {
      prefixIcon = Icons.email_outlined;
    } else if (widget.hintText.toLowerCase().contains("password")) {
      prefixIcon = Icons.lock_outline_rounded;
    } else {
      prefixIcon = Icons.edit_note_rounded;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: TextField(
        controller: widget.controller,
        obscureText: _isObscured,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        
        // --- NEW MULTI-LINE LOGIC ---
        // If it's a password, it must be 1 line. Otherwise, use passed value.
        // We set both max and min to the same value so the box remains a consistent size.
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        minLines: widget.obscureText ? 1 : widget.maxLines, 
        
        cursorColor: colorPrimary,
        style: const TextStyle(color: colorTextDark),
        decoration: InputDecoration(
          labelText: widget.hintText,
          labelStyle: const TextStyle(color: colorPrimary),
          floatingLabelStyle:
              const TextStyle(color: colorPrimary, fontWeight: FontWeight.bold),

          hintText: "Enter ${widget.hintText}...",
          hintStyle: const TextStyle(color: colorSecondary, fontSize: 14),

          prefixIcon: Icon(prefixIcon, color: colorPrimary),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscured ? Icons.visibility_off : Icons.visibility,
                    color: colorSecondary,
                  ),
                  onPressed: () => setState(() => _isObscured = !_isObscured),
                )
              : null,

          filled: true,
          fillColor: Colors.white,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: colorTertiary, width: 1),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: colorPrimary, width: 2),
          ),

          // Adjusting contentPadding slightly for multiline to look centered
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        ),
      ),
    );
  }
}