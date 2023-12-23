import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/models/advisor.dart';
import 'package:macsignaturepad/screens/splash_screen.dart';
import 'package:macsignaturepad/services/advisor_service.dart';
import '../dialogs/add_advisor_dialog.dart';

class AdvisorsScreen extends StatefulWidget {
  const AdvisorsScreen({super.key});

  @override
  State<AdvisorsScreen> createState() => _AdvisorsScreenState();
}

class _AdvisorsScreenState extends State<AdvisorsScreen> {
  List<Advisor> get advisors => AdvisorService.allAdvisors;
  bool _isLoading = true;
  bool isRemoving = false;

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
      return const Text('Nicht authentifiziert');
    }
    if (_isLoading) {
      return SplashScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Berater verwalten'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              Advisor? newAdvisor = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AlertDialog(
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
            subtitle: Text(advisor.email),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Admin: ${advisor.isAdmin ? 'Ja' : 'Nein'}'),
                IconButton(
                onPressed: isRemoving?null:() async {
                  setState(() {
                    isRemoving = true;
                  });
                  await AdvisorService.removeAdvisor(advisor);
                  setState(() {
                    isRemoving = false;
                  });
                },
                icon: const Icon(Icons.delete))
            ],
            ),
          );
        },
      ),
    );
  }
}
