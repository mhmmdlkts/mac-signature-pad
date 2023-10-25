import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/models/advisor.dart';
import 'package:macsignaturepad/services/advisor_service.dart';
import 'package:macsignaturepad/services/firestore_paths_service.dart';

class AddAdvisorDialog extends StatefulWidget {
  @override
  _AddAdvisorDialogState createState() => _AddAdvisorDialogState();
}

class _AddAdvisorDialogState extends State<AddAdvisorDialog> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _phoneNumber = '';

  String generateRandomPassword(int length) {
    const String chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+';
    Random random = Random();

    return List.generate(length, (index) => chars[random.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: InputDecoration(labelText: 'Name'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte Namen eingeben';
              }
              return null;
            },
            onSaved: (value) {
              _name = value!;
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'E-Mail'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte E-Mail eingeben';
              }
              return null;
            },
            onSaved: (value) {
              _email = value!;
            },
          ),
          TextFormField(
            decoration: InputDecoration(labelText: 'Handynummer'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Bitte Handynummer eingeben';
              }
              return null;
            },
            onSaved: (value) {
              _phoneNumber = value!;
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: _isLoading?null:() async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  try {
                    setState(() {
                      _isLoading = true;
                    });

                    Advisor advisor = Advisor(name: _name, email: _email, phone: _phoneNumber, role: 'advisor');

                    await register(advisor);

                    Navigator.of(context).pop(advisor);
                  } catch (e) {
                    print(e);
                  }
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: Text('Hinzufügen'),
            ),
          ),
        ],
      ),
    );
  }

  Future register(Advisor newAdvisor) async {
    try {
      FirebaseApp app = await Firebase.initializeApp(
          name: 'Secondary', options: Firebase.app().options);
      FirebaseAuth auth = FirebaseAuth.instanceFor(app: app);

      UserCredential userCredential = await auth
          .createUserWithEmailAndPassword(email: newAdvisor.email, password: generateRandomPassword(12));

      await auth.sendPasswordResetEmail(email: newAdvisor.email);
      await auth.signOut();

      String newUid = userCredential.user!.uid;

      Advisor advisor = Advisor(name: _name, email: _email, phone: _phoneNumber, role: 'advisor');
      advisor.id = newUid;

      await AdvisorService.addNewAdvisor(advisor);
      await app.delete();
    }
    on FirebaseAuthException catch (e) {
      print(e);
    }
  }
}
