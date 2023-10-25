import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/models/advisor.dart';
import 'package:macsignaturepad/screens/splash_screen.dart';
import 'package:macsignaturepad/services/advisor_service.dart';
import 'package:macsignaturepad/services/customer_service.dart';
import '../dialogs/add_advisor_dialog.dart';
import '../models/customer.dart';

class AdvisorsScreen extends StatefulWidget {
  const AdvisorsScreen({super.key});

  @override
  State<AdvisorsScreen> createState() => _AdvisorsScreenState();
}

class _AdvisorsScreenState extends State<AdvisorsScreen> {
  List<Advisor> get advisors => AdvisorService.allAdvisors;
  bool _isLoading = true;

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
    AdvisorService.initAllAdvisors().then((value) => {
      setState(() {
        _isLoading = false;
      })
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null || !AdvisorService.isAdmin) {
      return Text('Nicht authentifiziert');
    }
    if (_isLoading) {
      return SplashScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Berater verwalten'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              Advisor? newAdvisor = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Berater Hinzufügen'),
                    content: AddAdvisorDialog(),
                  );
                },
              );
              if (mounted && newAdvisor != null) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: advisors.length,
        itemBuilder: (context, index) {
          final advisor = advisors[index];
          return ListTile(
            title: Text(advisor.name),
            subtitle: Text('Email: ${advisor.email}'),
            trailing: Text('Admin: ${advisor.isAdmin ? 'Ja' : 'Nein'}'),
          );
        },
      ),
    );
  }
}
