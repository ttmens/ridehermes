import "dart:async";
import "package:flutter/material.dart";
import "package:ride_hermes_passenger/config/theme.dart";
import "package:ride_hermes_passenger/core/location/amap_service.dart";

class AddressInput extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final Color iconColor;
  final TextEditingController controller;
  final ValueChanged<String>? onAddressResolved;
  final ValueChanged<Map<String, dynamic>>? onPlaceSelected;
  final String? city;

  const AddressInput({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.iconColor,
    required this.controller,
    this.onAddressResolved,
    this.onPlaceSelected,
    this.city,
  });

  @override
  State<AddressInput> createState() => _AddressInputState();
}

class _AddressInputState extends State<AddressInput> {
  Timer? _debounce;
  final _amapService = AmapService();
  final _focusNode = FocusNode();
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    if (text.trim().length < 2) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      setState(() => _loading = true);
      final suggestions = await _amapService.placeSuggestion(text, city: widget.city);
      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = suggestions.isNotEmpty;
          _loading = false;
        });
      }
    });
  }

  void _selectPlace(Map<String, dynamic> place) {
    widget.controller.text = place["name"] as String;
    setState(() => _showSuggestions = false);
    
    final location = place["location"] as String?;
    if (location != null && location.contains(",")) {
      final parts = location.split(",");
      if (parts.length == 2) {
        final lng = parts[0];
        final lat = parts[1];
        widget.onAddressResolved?.call("$lat,$lng");
        widget.onPlaceSelected?.call(place);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: _onChanged,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon, color: widget.iconColor),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            hintText: widget.hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ),
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                final place = _suggestions[index];
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.place, color: widget.iconColor, size: 20),
                  title: Text(
                    place["name"] as String? ?? "",
                    style: const TextStyle(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    place["district"] as String? ?? "",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectPlace(place),
                );
              },
            ),
          ),
      ],
    );
  }
}
