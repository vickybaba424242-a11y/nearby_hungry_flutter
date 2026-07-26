import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSyncService {
  Future<String> syncChefContacts() async {
    print("========== CONTACT SYNC STARTED ==========");

    // Request permission
    final permission = await FlutterContacts.requestPermission();
    print("📌 Contact Permission: $permission");

    if (!permission) {
      return "Contact permission denied.";
    }

    // Fetch Firestore data
    final snapshot =
    await FirebaseFirestore.instance.collection('posts').get();

    print("📌 Total Firestore documents: ${snapshot.docs.length}");

    final Set<String> processedChefIds = {};

    // Existing contacts
    final List<Contact> existingContacts =
    await FlutterContacts.getContacts(withProperties: true);

    print("📌 Existing phone contacts: ${existingContacts.length}");

    int added = 0;
    int skipped = 0;

    for (final doc in snapshot.docs) {
      print("-----------------------------------");
      print("Processing Document: ${doc.id}");

      try {
        final data = doc.data();

        final String creatorId = data['creatorId'] ?? '';
        final String creatorName = data['creatorName'] ?? '';
        final String phone = data['phone'] ?? '';

        print("Creator ID : $creatorId");
        print("Creator    : $creatorName");
        print("Phone      : $phone");

        if (creatorId.isEmpty ||
            creatorName.isEmpty ||
            phone.isEmpty) {
          print("⚠️ Skipped because data is empty.");
          continue;
        }

        if (processedChefIds.contains(creatorId)) {
          print("⚠️ Duplicate creatorId. Skipping.");
          continue;
        }

        processedChefIds.add(creatorId);

        String normalize(String value) =>
            value.replaceAll(RegExp(r'[^0-9]'), '');

        bool alreadyExists = existingContacts.any(
              (c) => c.phones.any(
                (p) => normalize(p.number) == normalize(phone),
          ),
        );

        print("Already Exists: $alreadyExists");

        if (alreadyExists) {
          skipped++;
          continue;
        }

        final contact = Contact(
          name: Name(
            first: 'Chef',
            last: creatorName,
          ),
          phones: [
            Phone(phone),
          ],
        );

        print("📌 Attempting to insert contact...");

        await contact.insert();

        print("✅ Contact inserted successfully.");

        added++;
        existingContacts.add(contact);
      } catch (e, stack) {
        print("❌ ERROR INSERTING CONTACT");
        print(e);
        print(stack);
      }
    }

    print("========== CONTACT SYNC FINISHED ==========");
    print("Added   : $added");
    print("Skipped : $skipped");

    return "Added: $added\nSkipped: $skipped";
  }
}