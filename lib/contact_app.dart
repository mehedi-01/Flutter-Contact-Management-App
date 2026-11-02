import 'package:flutter/material.dart';
import 'database_helper.dart';

const Color primaryColor = Color(0xFF5B5FEF);
const Color backgroundColor = Color(0xFFF6F7FB);

class ContactApp extends StatelessWidget {
  const ContactApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Contact Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryColor,

        ),
        scaffoldBackgroundColor:  backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
      ),
      home: const ContactHomePage(),
    );
  }
}

class ContactHomePage extends StatefulWidget {
  const ContactHomePage({super.key});

  @override
  State<ContactHomePage> createState() => _ContactHomePageState();
}

class _ContactHomePageState extends State<ContactHomePage> {
  final DatabaseHelper db = DatabaseHelper.instance;
  final TextEditingController searchController =
      TextEditingController();
  List<Map<String, dynamic>> contacts = [];
  bool favoritesOnly = true;
  bool isLoading = true;

  @override
  void initState(){
    super.initState();
    loadContacts();
    searchController.addListener(loadContacts);
  }
  @override
  void dispose() {
    searchController.removeListener(loadContacts);
    searchController.dispose();
    super.dispose();
  }
  Future<void>loadContacts()async{
    final result = await db.getContacts(
      search: searchController.text,
      favoritesOnly: favoritesOnly,
    );

    if (!mounted) return;

    setState(() {
      contacts = result;
      isLoading = false;
    });
  }

  Future<void> openContactFrom({
    Map<String, dynamic>? contact,
}) async {
    final result = await showDialog<Map<String, dynamic>>(context: context,

        builder: (_) => ContactFormDialog(contact: contact),
    );

    if (result == null) return;

    try {
      if (contact == null) {
        await db.insertContact(result);
      } else {
        await db.updateContact(
          contact['id'] as int,
          result,
        );
      }

      await loadContacts();
    } catch (e) {
      debugPrint('Database Error: $e');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
            contact == null
                ? 'Contact added successfully!'
                : 'Contact updated successfully!',
          ),
      ),
    );
  }

  Future<void> deleteContact(
      Map<String, dynamic> contact,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const Icon(
          Icons.delete_outline,
          color: Colors.red,
          size: 40,
        ),
        title: const Text('Delete Contact?'),
        content: Text(
          'Are you sure you want to delete '
              '${contact['name']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await db.deleteContact(contact['id'] as int);
    await loadContacts();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact deleted successfully!'),
      ),
    );
  }
  Future<void> toggleFavorite(
      Map<String, dynamic> contact,
      ) async {
    final currentFavorite = contact['isFavorite'] == 1;

    await db.toggleFavorite(
      contact['id'] as int,
      !currentFavorite,
    );

    await loadContacts();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact List App',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Manage your contacts easily',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),

      ),
      body: SafeArea(child: Column(
        children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(
                  16, 18, 16, 12,
              ),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: () => searchController.clear(),
                    icon: const Icon(Icons.close),
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ) ,
            child: Row(
              children: [
                Expanded(
                    child: _filterButton(
                      label : 'All Contacts',
                      icon: Icons.people_alt_outlined,
                      selected: !favoritesOnly,
                      onTap: (){
                        setState(() {
                          favoritesOnly = false;
                        });
                        loadContacts();
                      },
                    ),
                ),
              ],
            ),
          ),
          Padding(
              padding:const EdgeInsets.fromLTRB(
                18, 22, 18, 12,
              ) ,
            child: Row(
              children: [
                Text(
                  favoritesOnly
                  ? 'Favorite Contacts'
                      : 'My Contacts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,

                  ),

                ),
                const Spacer(),
                  Text(
                    '${contacts.length}contacts',
                    style: TextStyle(
                      color:  Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
              child: isLoading
                  ? const Center(
                child: CircularProgressIndicator(),
              )
                  : contacts.isEmpty
                  ? _emptyState()
                  : ListView.builder(
                itemCount: contacts.length,
                padding: const EdgeInsets.fromLTRB(
                  16, 0, 16, 100,
                ),
                itemBuilder: (context, index){
                  final contact = contacts[index];
                  final  favorite = contact['isFavorite'] == 1;

                  return _contactCard(
                    contact,
                    favorite,
                  );
                },
              ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () => openContactFrom(),
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Add Contact'),
      ),
    );
  }
  Widget _filterButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,

}) {
    return OutlinedButton.icon(
        onPressed: onTap, 
        icon: Icon(icon,size: 18),
        
        label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: selected ? const Color(0xFFE9E9FF) : Colors.white,
        foregroundColor:
        selected ? primaryColor : Colors.black87,
        side: BorderSide(
          color: selected ? primaryColor : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
      ),
    );
  }
  Widget _contactCard(
      Map<String, dynamic> contact,
      bool favorite,

      ) {
    final name = contact['name'] as String;
    return Card(
      color: Colors.white,
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
          padding:  const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFE9E9FF),
                  child: Text(
                    name.trim().isEmpty
                        ? '?'
                        :name.trim()[0].toUpperCase(),
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,

                    ),
                  ),
                ),
                const SizedBox(
                  width: 12,
                ),
                Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ),
                IconButton(
                  tooltip: 'Favorite',
                  onPressed: () => toggleFavorite(contact),
                    icon: Icon(
                      favorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: favorite ? Colors.red : Colors.grey,

                    ),

                ),
                PopupMenuButton<String>(
                  onSelected: (value){
                    if (value == 'edit'){
                      openContactFrom(contact: contact);

                    }else if (value == 'delete'){
                      deleteContact(contact);
                    }
                  },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              SizedBox(width: 10),
                              Text('Delete'),
                            ],
                          ),
                      ),
                    ],
                ),
              ],
            ),
            const Divider(
              height: 24
            ),
            _contactInfo(
              Icons.phone_outlined,
              contact['phone'] ?? '',
            ),
            if ((contact['email'] ?? '')
                .toString().isNotEmpty)
              _contactInfo(
                Icons.email_outlined,
                contact['email'],
              ),
            if ((contact['address'] ?? '')
                .toString().isNotEmpty)
              _contactInfo(
                Icons.location_on_outlined,
                contact['address'],
              ),
          ],
        ),
      ),

    );
  }
  Widget _contactInfo(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.contacts_outlined,
              size: 70,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            const Text(
              'No contacts found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              favoritesOnly
                  ? 'Mark a contact as favorite to see it here.'
                  : 'Add your first contact to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
class ContactFormDialog extends StatefulWidget{
  final Map<String, dynamic>? contact;
  const ContactFormDialog({
    super.key,
    this.contact,
  });
  @override
  State<ContactFormDialog> createState() =>
      _ContactFormDialogState();
}
class _ContactFormDialogState extends State<ContactFormDialog>{
  final formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController addressController;

  @override
  void initState(){
    super.initState();

    nameController = TextEditingController(
      text: widget.contact?['name'] ?? '',
    );
    phoneController = TextEditingController(
      text: widget.contact?['phone'] ?? '',
    );
    emailController = TextEditingController(
      text: widget.contact?['email'] ?? '',
    );
    addressController = TextEditingController(
      text: widget.contact?['address'] ?? '',
    );
  }
  @override
  void dispose(){
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context){
    final editing = widget.contact != null;

    return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      title: Text(
        editing ? 'Edit Contact' : 'Add New Contact',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _inputField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    requiredField: true,
                  ),
                  _inputField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    requiredField: true,
                  ),
                  _inputField(
                    controller: emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isNotEmpty &&
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                        return 'Enter a valid email address';
                      }

                      return null;
                    },
                  ),
                  _inputField(
                    controller: addressController,
                    label: 'Address',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                  ),

                ],
              ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
        ),
    FilledButton.icon(
    onPressed: (){
    if (!formKey.currentState!.validate()) return;

    Navigator.pop(context, {
    'name': nameController.text.trim(),
    'phone': phoneController.text.trim(),
    'email': emailController.text.trim(),
    'address': addressController.text.trim(),
    'isFavorite':
    widget.contact?['isFavorite'] ?? 0,
    });
    },
        icon: Icon(editing ? Icons.save : Icons.add),
    label:Text(editing ? 'Update' : 'Save Contact'),

    ),
      ],

    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool requiredField = false,
    String? Function(String?)? validator,
}) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator ??
            (value) {
              if (requiredField &&
                  (value == null || value.trim().isEmpty)) {
                return '$label is required';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
        ),
      ),
      ),
    );
  }



}


