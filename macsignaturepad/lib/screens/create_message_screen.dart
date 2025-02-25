import 'package:flutter/material.dart';
import 'package:macsignaturepad/services/message_service.dart';
import 'package:macsignaturepad/models/customer.dart';

class CreateMessageScreen extends StatefulWidget {
  const CreateMessageScreen({super.key});

  @override
  State<CreateMessageScreen> createState() => _CreateMessageScreenState();
}

class _CreateMessageScreenState extends State<CreateMessageScreen> {
  bool _isInitialized = false;
  bool _isSending = false;

  // Map mit Customer => bool (ausgewählt oder nicht)
  late Map<Customer, bool> _customerSelection;

  // Controller für den Titel
  final TextEditingController _titleController = TextEditingController();
  // Controller für den Nachrichtentext
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Beispiel: Falls init() im MessageService das Map befüllt
    MessageService.init().then((_) {
      setState(() {
        _isInitialized = true;
        // Hier holen wir uns das Map aus dem Service
        _customerSelection = MessageService.allCustomers;
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _isSending) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nachricht erstellen'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final int totalCustomers = _customerSelection.length;
    final int selectedCount =
        _customerSelection.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nachricht erstellen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Anzeige, wie viele Kunden ausgewählt wurden
            Text('Ausgewählt: $selectedCount / $totalCustomers'),

            const SizedBox(height: 16),

            // Liste mit Checkboxen für die Kunden
            Expanded(
              child: ListView.builder(
                itemCount: _customerSelection.length,
                itemBuilder: (context, index) {
                  final entry = _customerSelection.entries.elementAt(index);
                  final customer = entry.key;
                  final isSelected = entry.value;

                  return CheckboxListTile(
                    title: Text(customer.readableName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.email ?? 'keine E-Mail',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                        Text(
                          customer.phone,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        _customerSelection[customer] = value ?? false;
                      });
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Textfeld für den Titel / Betreff
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Titel',
              ),
            ),

            const SizedBox(height: 16),

            // Textfeld für den Nachrichtentext
            TextField(
              controller: _messageController,
              maxLines: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nachricht',
              ),
            ),

            const SizedBox(height: 16),

            // Button zum Versenden
            ElevatedButton(
              onPressed: selectedCount == 0 || _isSending ? null
                  : () async {
                String message = _messageController.text.trim();
                String title = _titleController.text.trim();
                bool res = await _showConfirmationDialog(
                  context,
                  selectedCount,
                  title,
                  message,
                );

                if (res) {
                  setState(() {
                    _isSending = true;
                  });
                  String? res = await MessageService.createMessageRequest(
                    customerIds: _getSelectedCustomers().map((e) => e.id.trim()).toList(),
                    messageTitle: title,
                    messageContent: message,
                    sendType: SendType.email,
                  );
                  if (res == null) {
                    res = 'Fehler beim Senden der Nachricht!';
                  }
                  SnackBar snackBar = SnackBar(
                    content: Text(res),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  Future.delayed(const Duration(seconds: 2), () {
                    Navigator.of(context).pop();
                  });
                }
              },
              child: const Text('Senden'),
            ),
          ],
        ),
      ),
    );
  }

  /// Hilfsmethode für den Bestätigungsdialog
  Future<bool> _showConfirmationDialog(
      BuildContext context,
      int selectedCount,
      String title,
      String message,
      ) async {
    return await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Nachricht an $selectedCount Empfänger senden?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: 16),
              Text(message),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Senden'),
            ),
          ],
        );
      },
    ) == true;
  }

  /// Beispiel-Hilfsmethode, um die ausgewählten Kunden zu bekommen.
  List<Customer> _getSelectedCustomers() {
    return _customerSelection.entries
        .where((element) => element.value == true)
        .map((e) => e.key)
        .toList();
  }
}