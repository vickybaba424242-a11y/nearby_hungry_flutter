import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/post.dart';
import '../utils/location_helper.dart';

class AddPostBottomSheet extends StatefulWidget {
  final Post? postToEdit;
  final VoidCallback? onPostCreated;

  const AddPostBottomSheet({
    super.key,
    this.postToEdit,
    this.onPostCreated,
  });

  @override
  State<AddPostBottomSheet> createState() => _AddPostBottomSheetState();
}

class _AddPostBottomSheetState extends State<AddPostBottomSheet> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedDuration = "1 Day";
  bool _isPosting = false;

  double? userLat;
  double? userLng;

  final List<String> _durationOptions = [
    "1 Day",
    "7 Days",
    "1 Month",
    "Always"
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();

    if (widget.postToEdit != null) {
      _textController.text = widget.postToEdit!.text ?? '';
      _phoneController.text = widget.postToEdit!.phone ?? '';
      _selectedDuration =
          widget.postToEdit!.visibilityType ?? _selectedDuration;
    }

    _fetchUserLocation();
  }

  @override
  void dispose() {
    _textController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    final pos = await LocationHelper.getCurrentLocation(context);
    if (pos != null && mounted) {
      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
      });
    }
  }

  Timestamp _getExpiryTimestamp() {
    final now = DateTime.now();

    switch (_selectedDuration) {
      case "1 Day":
        return Timestamp.fromDate(now.add(const Duration(days: 1)));
      case "7 Days":
        return Timestamp.fromDate(now.add(const Duration(days: 7)));
      case "1 Month":
        return Timestamp.fromDate(now.add(const Duration(days: 30)));
      case "Always":
        return Timestamp.fromDate(DateTime(2100));
      default:
        return Timestamp.fromDate(now.add(const Duration(days: 1)));
    }
  }

  // ✅ block phone numbers inside post text
  bool _containsPhoneNumber(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), '');
    return RegExp(r'\d{10,}').hasMatch(normalized);
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    if (userLat == null || userLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location required")),
      );
      return;
    }

    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in")),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final postText = _textController.text.trim();

      final Map<String, dynamic> postData = {
        "text": postText,
        "content": postText,
        "phone": _phoneController.text.trim(),
        "isEdited": widget.postToEdit != null,
      };

      if (widget.postToEdit == null) {
        postData.addAll({
          "creatorId": user.uid,
          "creatorName": user.displayName ?? "Nearby User",
          "timestamp": FieldValue.serverTimestamp(),
          "latitude": userLat,
          "longitude": userLng,
          "views": 0,
          "visibilityType": _selectedDuration,
          "expireAt": _getExpiryTimestamp(),
        });

        await _firestore.collection("posts").add(postData);

        if (!mounted) return;

        Navigator.pop(context);
        widget.onPostCreated?.call();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Post created successfully!")),
        );
      } else {
        await _firestore
            .collection("posts")
            .doc(widget.postToEdit!.id)
            .update(postData);

        widget.onPostCreated?.call();

        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Post updated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to save post: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: icon == null ? null : Icon(icon, color: Colors.grey.shade600),
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: Color(0xFF27AE60),
          width: 1.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double dropItemHeight = 48;
    final double dropHeight = _durationOptions.length * dropItemHeight;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF2F0EE),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      "What are you cooking today?",
                      style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              const Text(
                "Post description",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),

              TextFormField(
                controller: _textController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  hint: "What's cooking today?",
                  icon: Icons.edit_note,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter some text";
                  }

                  if (_containsPhoneNumber(value)) {
                    return "Sharing phone number is not allowed here";
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              const Text(
                "Contact number",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),

              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: _inputDecoration(
                  hint: "Enter 10 digit mobile number",
                  icon: Icons.phone,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter your phone number";
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value.trim())) {
                    return "Phone number must be 10 digits";
                  }
                  return null;
                },
              ),

              const SizedBox(height: 6),

              const Text(
                "Post visibility",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),

              Opacity(
                opacity: widget.postToEdit != null ? 0.5 : 1,
                child: IgnorePointer(
                  ignoring: widget.postToEdit != null,
                  child: DropdownButtonFormField2<String>(
                    value: _selectedDuration,
                    decoration: _inputDecoration(
                      hint: "Select duration",
                      icon: Icons.schedule,
                    ),
                    isExpanded: true,
                    items: _durationOptions
                        .map(
                          (e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e),
                      ),
                    )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedDuration = val);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select a duration";
                      }
                      return null;
                    },
                    dropdownMaxHeight: dropHeight,
                    offset: Offset(0, -dropHeight - 8),
                    dropdownDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _savePost,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isPosting
                        ? "Posting..."
                        : (widget.postToEdit != null ? "Update" : "Post"),
                    style:
                    const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
