import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectChefScreen extends StatefulWidget {
  const SelectChefScreen({super.key});

  @override
  State<SelectChefScreen> createState() => _SelectChefScreenState();
}

class _SelectChefScreenState extends State<SelectChefScreen> {
  final TextEditingController searchController =
  TextEditingController();

  List<QueryDocumentSnapshot> allChefs = [];
  List<QueryDocumentSnapshot> filteredChefs = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadChefs();
  }

  Future<void> loadChefs() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .get();

      // Only show actual chefs/providers.
      // If you want restaurants too, we can change this later.
      allChefs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;

        final username =
        (data["username"] ?? "").toString().trim();

        return username.isNotEmpty;
      }).toList();

      filteredChefs = List.from(allChefs);

      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading chefs: $e");

      if (mounted) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load chefs: $e"),
          ),
        );
      }
    }
  }

  void searchChef(String value) {
    value = value.toLowerCase().trim();

    setState(() {
      filteredChefs = allChefs.where((doc) {
        final data =
        doc.data() as Map<String, dynamic>;

        final name =
        (data["username"] ?? "")
            .toString()
            .toLowerCase();

        final phone =
        (data["phone"] ?? "")
            .toString()
            .toLowerCase();

        final email =
        (data["email"] ?? "")
            .toString()
            .toLowerCase();

        return name.contains(value) ||
            phone.contains(value) ||
            email.contains(value);
      }).toList();
    });
  }

  Future<void> selectChef(
      QueryDocumentSnapshot doc,
      ) async {
    final data =
    doc.data() as Map<String, dynamic>;

    final chefId = doc.id;

    final chefName =
    (data["username"] ?? "Unknown").toString();

    final chefEmail =
    (data["email"] ?? "").toString();

    final chefPhone =
    (data["phone"] ?? "").toString().trim();

    debugPrint("====================================");
    debugPrint("👨‍🍳 CHEF SELECTED");
    debugPrint("ID    : $chefId");
    debugPrint("NAME  : $chefName");
    debugPrint("EMAIL : $chefEmail");
    debugPrint("PHONE : $chefPhone");
    debugPrint("DATA  : $data");
    debugPrint("====================================");

    Navigator.pop(context, {
      "id": chefId,
      "name": chefName,
      "phone": chefPhone,
      "email": chefEmail,
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Chef"),
        backgroundColor: const Color(0xFFF94449),
      ),

      body: loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: searchChef,
              decoration: InputDecoration(
                hintText: "Search chef",
                prefixIcon:
                const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          Expanded(
            child: filteredChefs.isEmpty
                ? const Center(
              child: Text(
                "No chefs found",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            )
                : ListView.builder(
              itemCount:
              filteredChefs.length,
              itemBuilder:
                  (context, index) {
                final doc =
                filteredChefs[index];

                final data =
                doc.data()
                as Map<String, dynamic>;

                final name =
                (data["username"] ??
                    "Unknown")
                    .toString();

                final email =
                (data["email"] ??
                    "No email")
                    .toString();

                final phone =
                (data["phone"] ??
                    "No phone")
                    .toString();

                return ListTile(
                  leading:
                  const CircleAvatar(
                    child:
                    Icon(Icons.person),
                  ),

                  title: Text(name),

                  subtitle: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                    children: [
                      Text(
                        email,
                        style:
                        const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        phone,
                        style:
                        const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  onTap: () =>
                      selectChef(doc),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}