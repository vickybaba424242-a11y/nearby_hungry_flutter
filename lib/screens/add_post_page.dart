import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../models/post.dart';
import '../utils/location_helper.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import '../screens/admin_post_location_picker.dart';
import '../screens/select_chef_screen.dart';

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

  String? selectedAddress;
  String? selectedChefId;
  String? selectedChefName;
  String? selectedChefPhone;
  String _selectedProvider = "homeChef";

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

    final post = widget.postToEdit;

    if (post != null) {
      // Existing post text
      _textController.text = post.text;

      // Existing phone from post
      _phoneController.text = post.phone ?? '';

      // Existing visibility
      _selectedDuration =
          post.visibilityType ?? _selectedDuration;

      // Existing provider
      _selectedProvider =
          post.providerType;

      // Existing chef
      selectedChefId = post.creatorId;
      selectedChefName = post.creatorName;

      // Existing chef phone
      selectedChefPhone = post.phone;

      // Existing location
      userLat = post.latitude;
      userLng = post.longitude;

      // IMPORTANT:
      // Post currently does not have an address field.
      // We will handle address separately below.
    }

    _loadEditData();
  }

  Future<void> _loadEditData() async {
    final post = widget.postToEdit;

    if (post == null) {
      _fetchUserLocation();
      return;
    }

    try {
      debugPrint("====================================");
      debugPrint("🔎 Loading post: ${post.id}");
      debugPrint("👨‍🍳 Creator ID: ${post.creatorId}");
      debugPrint("👨‍🍳 Creator Name: ${post.creatorName}");
      debugPrint("📞 Post Phone: ${post.phone}");
      debugPrint("📍 Post Address: ${post.address}");
      debugPrint("====================================");

      // -------------------------------------------------------
      // Load latest post data directly from Firestore
      // -------------------------------------------------------

      final postDoc = await _firestore
          .collection('posts')
          .doc(post.id)
          .get();

      if (postDoc.exists) {
        final data = postDoc.data();

        if (data != null && mounted) {
          final firestorePhone =
              data['phone']?.toString().trim() ?? '';

          final firestoreAddress =
              data['address']?.toString().trim() ?? '';

          final firestoreCreatorId =
              data['creatorId']?.toString().trim() ?? '';

          final firestoreCreatorName =
              data['creatorName']?.toString().trim() ?? '';

          setState(() {
            // Phone from POST document
            if (firestorePhone.isNotEmpty) {
              selectedChefPhone = firestorePhone;
              _phoneController.text = firestorePhone;
            }

            // Address from POST document
            if (firestoreAddress.isNotEmpty) {
              selectedAddress = firestoreAddress;
            }

            // Keep latest creator information
            if (firestoreCreatorId.isNotEmpty) {
              selectedChefId = firestoreCreatorId;
            }

            if (firestoreCreatorName.isNotEmpty) {
              selectedChefName = firestoreCreatorName;
            }
          });

          debugPrint("📞 Loaded phone from POST: $firestorePhone");
          debugPrint("📍 Loaded address from POST: $firestoreAddress");
        }
      }

      // -------------------------------------------------------
      // For ADMIN:
      // Try users collection ONLY as fallback.
      // -------------------------------------------------------

      if (isAdmin && selectedChefId != null) {
        debugPrint(
          "🔎 Loading chef from users/$selectedChefId",
        );

        try {
          final chefDoc = await _firestore
              .collection('users')
              .doc(selectedChefId)
              .get();

          if (chefDoc.exists) {
            final data = chefDoc.data();

            debugPrint("========== CHEF DATA ==========");
            debugPrint("$data");
            debugPrint("===============================");

            if (data != null && mounted) {
              final chefPhone =
                  data['phone']?.toString().trim() ?? '';

              // IMPORTANT:
              // Only use users.phone if post.phone was empty.
              if (chefPhone.isNotEmpty &&
                  _phoneController.text.trim().isEmpty) {
                setState(() {
                  selectedChefPhone = chefPhone;
                  _phoneController.text = chefPhone;
                });

                debugPrint(
                  "📞 Phone loaded from users: $chefPhone",
                );
              } else if (chefPhone.isEmpty) {
                debugPrint(
                  "⚠️ No phone field found in users/$selectedChefId",
                );
              }
            }
          }
        } catch (e) {
          debugPrint("❌ Error loading chef: $e");
        }
      }

      // -------------------------------------------------------
      // DO NOT replace admin post location with device location
      // -------------------------------------------------------

      if (!isAdmin) {
        _fetchUserLocation();
      }
    } catch (e) {
      debugPrint("❌ Error loading edit data: $e");
    }
  }

  bool get isAdmin {

    final user =
        FirebaseAuth.instance.currentUser;

    return user?.email ==
        "nearbyhungry@gmail.com";

  }

  Future<void> pickAdminLocation() async {


    final result =
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:(_)=>
        const AdminPostLocationPicker(),
      ),
    );


    if(result!=null){

      setState((){

        userLat =
        result["latitude"];

        userLng =
        result["longitude"];

        selectedAddress =
        result["address"];

      });


    }


  }

  List<MenuItem> _parseMenuItems(String text) {
    final List<MenuItem> items = [];

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    for (final line in lines) {
      String name = '';
      double? price;

      // ₹180
      final rupeeMatch = RegExp(
        r'(.+?)\s*[-:|]?\s*₹\s*(\d+(?:\.\d+)?)',
        caseSensitive: false,
      ).firstMatch(line);

      if (rupeeMatch != null) {
        name = rupeeMatch.group(1)?.trim() ?? '';
        price = double.tryParse(
          rupeeMatch.group(2) ?? '',
        );
      } else {
        // Rs 180 / Rs. 180
        final rsMatch = RegExp(
          r'(.+?)\s*[-:|]?\s*(?:Rs\.?|INR)\s*(\d+(?:\.\d+)?)',
          caseSensitive: false,
        ).firstMatch(line);

        if (rsMatch != null) {
          name = rsMatch.group(1)?.trim() ?? '';
          price = double.tryParse(
            rsMatch.group(2) ?? '',
          );
        } else {
          // Plain 180 at the end
          final numberMatch = RegExp(
            r'(.+?)\s*[-:|]\s*(\d+(?:\.\d+)?)$',
          ).firstMatch(line);

          if (numberMatch != null) {
            name = numberMatch.group(1)?.trim() ?? '';
            price = double.tryParse(
              numberMatch.group(2) ?? '',
            );
          }
        }
      }

      if (name.isNotEmpty && price != null) {
        items.add(
          MenuItem(
            name: name,
            price: price,
          ),
        );
      }
    }

    return items;
  }

  Future<void> pickChef() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SelectChefScreen(),
      ),
    );

    if (result != null) {
      final phone =
      (result["phone"] ?? "").toString().trim();

      setState(() {
        selectedChefId =
            result["id"]?.toString();

        selectedChefName =
            result["name"]?.toString();

        selectedChefPhone =
        phone.isNotEmpty ? phone : null;

        // VERY IMPORTANT
        // Put selected chef phone into the visible
        // Contact Number field.
        _phoneController.text = phone;
      });

      debugPrint("====================================");
      debugPrint("👨‍🍳 ADMIN SELECTED CHEF");
      debugPrint("ID    : $selectedChefId");
      debugPrint("NAME  : $selectedChefName");
      debugPrint("PHONE : $phone");
      debugPrint("====================================");
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {

    if(isAdmin){

      return;

    }


    final pos =
    await LocationHelper.getCurrentLocation(context);


    if(pos!=null && mounted){

      setState((){

        userLat=pos.latitude;
        userLng=pos.longitude;

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

  List<Map<String, dynamic>> _parseRestaurantMenu(String text) {
    final List<Map<String, dynamic>> menuItems = [];

    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String currentCategory = "Other";

    Map<String, dynamic>? currentItem;

    // ==========================================================
    // VARIANT NORMALIZATION
    // ==========================================================

    String normalizeVariantName(String name) {
      final value = name
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');

      switch (value) {
        case 'half':
        case '1/2':
        case 'half plate':
          return 'Half';

        case 'full':
        case 'full plate':
          return 'Full';

        case 'quarter':
        case 'qtr':
        case '1/4':
        case 'quarter plate':
          return 'Quarter';

        case 'small':
          return 'Small';

        case 'medium':
          return 'Medium';

        case 'large':
          return 'Large';

        case 'single':
          return 'Single';

        case 'double':
          return 'Double';

        case 'regular':
          return 'Regular';

        default:
          return name.trim();
      }
    }

    bool isVariantName(String name) {
      final value = name
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');

      const variants = {
        'half',
        '1/2',
        'half plate',
        'full',
        'full plate',
        'quarter',
        'qtr',
        '1/4',
        'quarter plate',
        'small',
        'medium',
        'large',
        'single',
        'double',
        'regular',
        'maharaja',
        '1 pc',
        '2 pc',
        '3 pc',
        '4 pc',
        '5 pc',
        '6 pc',
        '7 pc',
        '8 pc',
        '9 pc',
        '10 pc',
        '11 pc',
        '12 pc',
      };

      return variants.contains(value);
    }

    // ==========================================================
    // ADD CURRENT ITEM
    // ==========================================================

    void saveCurrentItem() {
      if (currentItem == null) {
        return;
      }

      final variants =
      currentItem!["variants"] as List<Map<String, dynamic>>;

      final price =
          (currentItem!["price"] as num?)?.toDouble() ?? 0;

      // Keep item only if it has:
      // 1. A normal price
      // OR
      // 2. At least one variant
      if (price > 0 || variants.isNotEmpty) {
        menuItems.add(currentItem!);
      }

      currentItem = null;
    }

    // ==========================================================
    // PROCESS EACH LINE
    // ==========================================================

    for (final line in lines) {
      final lower = line.toLowerCase().trim();

      // ========================================================
      // CATEGORY
      //
      // Example:
      // Main Course:
      // Starters:
      // Chinese:
      // ========================================================

      if (lower.endsWith(':') &&
          !RegExp(r'\d').hasMatch(line)) {
        saveCurrentItem();

        currentCategory =
            line.substring(0, line.length - 1).trim();

        continue;
      }

      // ========================================================
      // TRY TO EXTRACT NAME + PRICE
      //
      // Examples:
      //
      // Matar Paneer 120
      // Matar Paneer - 120
      // Matar Paneer ₹120
      // Half 120
      // Full - ₹220
      // ========================================================

      final match = RegExp(
        r'^(.*?)\s*(?:-|–|—|:|\|)?\s*(?:₹|Rs\.?|INR)?\s*(\d+(?:\.\d+)?)\s*$',
        caseSensitive: false,
      ).firstMatch(line);

      // ========================================================
      // LINE WITHOUT PRICE
      //
      // Example:
      //
      // Matar Paneer
      //
      // We keep this as a possible menu item because the
      // following lines may be variants.
      // ========================================================

      if (match == null) {
        // If there is already an item waiting,
        // save it before starting a new one.
        saveCurrentItem();

        // Create a pending item with price 0.
        //
        // If Half/Full follows, this item becomes a
        // variant-based menu item.
        currentItem = {
          "name": line,
          "price": 0,
          "category": currentCategory,
          "available": true,
          "variants": <Map<String, dynamic>>[],
        };

        continue;
      }

      final name = match.group(1)?.trim() ?? '';

      final price = double.tryParse(
        match.group(2) ?? '',
      );

      if (name.isEmpty || price == null) {
        continue;
      }

      // ========================================================
      // VARIANT
      //
      // Example:
      //
      // Matar Paneer
      // Half 120
      // Full 220
      //
      // currentItem = Matar Paneer
      // ========================================================

      if (currentItem != null &&
          isVariantName(name)) {
        final variantName =
        normalizeVariantName(name);

        final variants =
        currentItem!["variants"]
        as List<Map<String, dynamic>>;

        variants.add({
          "name": variantName,
          "price": price,
        });

        // Full becomes fallback price.
        //
        // This is useful if some older UI/code still
        // reads menuItem.price.
        if (variantName == "Full") {
          currentItem!["price"] = price;
        }

        continue;
      }

      // ========================================================
      // NORMAL MENU ITEM WITH PRICE
      //
      // Example:
      //
      // Matar Paneer 120
      //
      // If another pending item exists, save it first.
      // ========================================================

      saveCurrentItem();

      currentItem = {
        "name": name,
        "price": price,
        "category": currentCategory,
        "available": true,
        "variants": <Map<String, dynamic>>[],
      };
    }

    // ==========================================================
    // SAVE LAST ITEM
    // ==========================================================

    saveCurrentItem();

    // ==========================================================
    // DEBUG
    // ==========================================================

    debugPrint("========== PARSED MENU ==========");

    for (final item in menuItems) {
      debugPrint(
        "ITEM: ${item["name"]} | "
            "PRICE: ${item["price"]} | "
            "CATEGORY: ${item["category"]} | "
            "VARIANTS: ${item["variants"]}",
      );
    }

    debugPrint("=================================");

    return menuItems;
  }

  Future<void> _savePost() async {
    if (!_formKey.currentState!.validate()) return;

    if (userLat == null || userLng == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select location",
          ),
        ),
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

    if (isAdmin && selectedChefId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select a chef"),
        ),
      );
      return;
    }

    if (widget.postToEdit == null) {

      // Check active posts (not expired)
      final String targetCreatorId =
      isAdmin ? selectedChefId! : user.uid;

      final userPosts = await _firestore
          .collection("posts")
          .where("creatorId", isEqualTo: targetCreatorId)
          .get();

      final activePosts = userPosts.docs.where((doc) {
        final expireAt = doc["expireAt"] as Timestamp?;
        if (expireAt == null) {
          return false;
        }

        return expireAt.toDate().isAfter(DateTime.now());
      }).toList();

      if (activePosts.length >= 3) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Maximum Active Posts Reached"),
              content: const Text(
                "You can have a maximum of 3 active posts at a time. "
                    "Please delete one of your existing posts before creating a new post.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Check today's posts
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      final todayPosts = userPosts.docs.where((doc) {
        final ts = doc["timestamp"] as Timestamp?;

        if (ts == null) {
          return false;
        }

        return ts.toDate().isAfter(startOfDay);
      }).toList();

      if (todayPosts.isNotEmpty) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Daily Post Limit Reached"),
              content: const Text(
                "You have already created a post today. "
                    "Please try again tomorrow.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    setState(() => _isPosting = true);

    try {
      final postText = _textController.text.trim();

      final Map<String, dynamic> postData = {
        "text": postText,
        "content": postText,
        "isEdited": widget.postToEdit != null,

        // Menu will be populated below for restaurants
        "menuItems": <Map<String, dynamic>>[],
      };

      if (_selectedProvider == "restaurant") {
        debugPrint("========== RESTAURANT POST ==========");
        debugPrint("Post Text: $postText");
        debugPrint("======================================");
        final menuItems = _parseRestaurantMenu(postText);

        if (menuItems.isEmpty) {
          if (mounted) {
            setState(() => _isPosting = false);

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Please add menu items with prices.\nExample: Paneer Tikka - ₹220",
                ),
              ),
            );
          }

          return;
        }

        postData["menuItems"] = menuItems;
        postData["menuItemCount"] = menuItems.length;
      }

      if (widget.postToEdit == null) {

        final geo = GeoFirePoint(
          GeoPoint(userLat!, userLng!),
        );

        postData.addAll({

          "creatorId": isAdmin
              ? selectedChefId
              : user.uid,

          "creatorName": isAdmin
              ? selectedChefName
              : (user.displayName ?? "Nearby User"),

          "phone": _phoneController.text.trim(),

          "providerType": _selectedProvider,

          "timestamp": FieldValue.serverTimestamp(),

          "lastRepostedAt":
          FieldValue.serverTimestamp(),


          "latitude":
          userLat!,


          "longitude":
          userLng!,


          "address":
          selectedAddress ?? "",


          "position":
          geo.data,


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
        // ==========================================================
        // UPDATE EXISTING POST
        // ==========================================================

        final geo = GeoFirePoint(
          GeoPoint(userLat!, userLng!),
        );

        postData.addAll({
          "creatorId": isAdmin
              ? selectedChefId
              : widget.postToEdit!.creatorId,

          "creatorName": isAdmin
              ? selectedChefName
              : widget.postToEdit!.creatorName,

          "phone": _phoneController.text.trim(),

          "providerType": _selectedProvider,

          "latitude": userLat!,
          "longitude": userLng!,

          "address": selectedAddress ?? "",

          "position": geo.data,

          "isEdited": true,
        });

        debugPrint("========== UPDATING POST ==========");
        debugPrint("Creator ID   : ${postData["creatorId"]}");
        debugPrint("Creator Name : ${postData["creatorName"]}");
        debugPrint("Phone        : ${postData["phone"]}");
        debugPrint("Latitude     : ${postData["latitude"]}");
        debugPrint("Longitude    : ${postData["longitude"]}");
        debugPrint("Address      : ${postData["address"]}");
        debugPrint("====================================");

        await _firestore
            .collection("posts")
            .doc(widget.postToEdit!.id)
            .update(postData);

        widget.onPostCreated?.call();

        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Post updated successfully!"),
          ),
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
                "Food Provider",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProvider = "homeChef";
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedProvider == "homeChef"
                              ? const Color(0xFF27AE60)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedProvider == "homeChef"
                                ? const Color(0xFF27AE60)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "👨‍🍳",
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Home Chef",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedProvider == "homeChef"
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProvider = "restaurant";
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedProvider == "restaurant"
                              ? const Color(0xFF27AE60)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedProvider == "restaurant"
                                ? const Color(0xFF27AE60)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "🍽️",
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Restaurant",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: _selectedProvider == "restaurant"
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              if (isAdmin)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Choose Chef",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.person,
                          color: Colors.blue,
                        ),
                        label: Text(
                          selectedChefName ?? "Select Chef",
                        ),
                        onPressed: pickChef,
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      "Post Location",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                        ),
                        label: Text(
                          selectedAddress ?? "Select location for post",
                        ),
                        onPressed: pickAdminLocation,
                      ),
                    ),

                    const SizedBox(height: 16),

                  ],
                ),
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

                    dropdownStyleData: DropdownStyleData(
                      maxHeight: dropHeight,
                      offset: Offset(0, -dropHeight - 8),
                      decoration: BoxDecoration(
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
              ),

              const SizedBox(height: 22),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  border: Border.all(color: Colors.amber.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 22,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Service Fee Notice\n\n"
                            "Nearby Hungry charges a 10% service fee on every successfully delivered order, "
                            "No fee is charged for cancelled or unsuccessful orders. "
                            "By posting your menu, you agree to this service fee.",
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

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
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: _isPosting
                      ? null
                      : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(
                      color: Colors.grey.shade400,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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
