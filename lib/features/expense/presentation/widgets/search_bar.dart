import 'package:flutter/material.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearchChanged;
  final String? hintText;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearchChanged,
    this.hintText,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Search expenses...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      widget.onSearchChanged('');
                      setState(() {
                        _isSearching = false;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
          onChanged: (value) {
            widget.onSearchChanged(value);
            setState(() {
              _isSearching = value.isNotEmpty;
            });
          },
          onSubmitted: (value) {
            widget.onSearchChanged(value);
            FocusScope.of(context).unfocus();
          },
        ),
      ),
    );
  }
}
