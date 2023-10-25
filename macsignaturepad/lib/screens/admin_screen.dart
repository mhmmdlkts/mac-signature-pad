import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/models/advisor.dart';
import 'package:macsignaturepad/screens/splash_screen.dart';
import 'package:macsignaturepad/services/advisor_service.dart';
import 'package:macsignaturepad/services/customer_service.dart';
import 'package:macsignaturepad/services/init_service.dart';
import 'package:macsignaturepad/services/pdf_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/customer.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isLoading = true;
  ValueNotifier<Customer?> selectedCustomer = ValueNotifier(null);
  String query = '';

  List<Customer> getCustomers() {
    return CustomerService.customers.where((element) {
      if (query == '') {
        return true;
      }
      return element.name.toLowerCase().contains(query.toLowerCase()) ||
          element.surname.toLowerCase().contains(query.toLowerCase()) ||
          (element.email?.toLowerCase()?.contains(query.toLowerCase())??false) ||
          element.phone.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
    InitService.init(id: context.hashCode, function: () {
      setState(() {});
    }).then((value) => {
      setState(() {
        _isLoading = false;
      })
    });
    super.initState();

  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Text('Nicht authentifiziert');
    }
    if (_isLoading) {
      return SplashScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Kundenübersicht'),

        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/admin/advisors');
            },
          ),
        ],
      ),
      body: WillPopScope(
        onWillPop: () async => false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      query = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              if (AdvisorService.isAdmin)
                Container(
                  padding: EdgeInsets.only(bottom: 10),
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/admin/createCustomer');
                    },
                    child: Text('Neuen Kunden anlegen +'),
                  ),
                ),
              Builder(
                builder: (ctx) {
                  List<Customer> customers = getCustomers();
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: customers.length,
                    separatorBuilder: (context, index) => Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Divider(height: 0, color: Colors.black12),),
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ValueListenableBuilder(
                        valueListenable: selectedCustomer,
                        builder: (context, value, child) {
                          return InkWell(
                              onTap: selectedCustomer.value==customer?null:() {
                                selectedCustomer.value = customer;
                              },
                              child: singleCustomerRow(customer)
                          );
                        },
                      );
                    },
                  );
                }
              ),
              Container(height: 30),
            ],
          ),
        ),
      )
    );
  }

  Widget trailing(Customer customer) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
         children: [
           if (selectedCustomer.value == customer)
             Row(
               children: [
                 Material(
                     borderRadius: BorderRadius.circular(8),
                     color: Colors.grey[300],
                     child: InkWell(
                       borderRadius: BorderRadius.circular(8),
                       onTap: selectedCustomer.value!.email == null?null:() {
                         customer.sendEmail();
                       },
                       child: Container(
                           padding: EdgeInsets.all(8),
                           child: const  Column(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: [
                               Icon(Icons.email, size: 20,),
                             ],
                           )
                       ),
                     )
                 ),
                 Container(width: 10),

                 Material(
                     borderRadius: BorderRadius.circular(8),
                     color: Colors.grey[300],
                     child: InkWell(
                       borderRadius: BorderRadius.circular(8),
                       onTap: selectedCustomer.value!.phone == null?null:() {
                         customer.sendSms();
                       },
                       child: Container(
                           padding: EdgeInsets.all(8),
                           child: const  Column(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: [
                               Icon(Icons.perm_phone_msg, size: 20,),
                             ],
                           )
                       ),
                     )
                 ),
                 Container(width: 10),
                 Material(
                     borderRadius: BorderRadius.circular(8),
                     color: Colors.grey[300],
                     child: InkWell(
                       borderRadius: BorderRadius.circular(8),
                       onTap: () async {
                         await customer.initLastSignature();
                         selectedCustomer.notifyListeners();
                       },
                       child: Container(
                           padding: EdgeInsets.all(8),
                           child: const  Column(
                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                             children: [
                               Icon(Icons.refresh, size: 20,),
                             ],
                           )
                       ),
                     )
                 ),
                 Container(width: 10)
               ],
             ),
           const Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text('Vollmacht: '),
               Text('Protokoll: '),
             ],
           )
         ],
       ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(customer.readableExpVollmacht, style: TextStyle(color: customer.vollmachtExpiresDateColor),),
            Text(customer.readableExpBprotokoll, style: TextStyle(color: customer.bprotokollExpiresDateColor),),
          ],
        ),
      ],
    );
  }

  singleCustomerRow(Customer customer) {
    bool isSelected = selectedCustomer.value?.id == customer.id;
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${customer.name} ${customer.surname}', style: TextStyle(fontSize:16, fontWeight: FontWeight.bold)),
                  Text(customer.readableBirthdate,),
                ],
              ),
              trailing(customer),
            ],
          ),
          if (isSelected )
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.getReadableEmail),
                    Text(customer.getReadablePhone),
                    Text(customer.readableAddress),
                    Text('Uid: ${customer.getReadableUid}'),
                    Text('Steuernr: ${customer.getReadableStnr}'),
                    Text('Erstellungszeit: ${customer.readableCreateTime}'),
                    Text('Berater: ${customer.advisorName}'),
                  ],
                ),
                if (customer.lastSignature != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (customer.lastSignature == null) {
                            return;
                          }
                          openPdf(customer.lastSignature!.vollmachtPdfUrl);
                        },
                        child: Container(
                            width: 100,
                            height: 80,
                            padding: EdgeInsets.all(10),
                            child:const  Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Vollmacht', overflow: TextOverflow.fade,),
                                Icon(Icons.download),
                              ],
                            )
                        ),
                      ),
                    ),
                    Container(width: 10),
                    Material(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          if (customer.lastSignature == null) {
                            return;
                          }
                          openPdf(customer.lastSignature!.bprotokollPdfUrl);
                        },
                        child: Container(
                            width: 100,
                            height: 80,
                            padding: EdgeInsets.all(10),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Protokoll',),
                                Icon(Icons.download),
                              ],
                            )
                        ),
                      ),
                    )
                  ],
                )
              ],
            )
        ],
      ),
    );
  }

  void openPdf(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
