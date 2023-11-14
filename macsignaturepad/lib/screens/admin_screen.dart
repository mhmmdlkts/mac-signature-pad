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
    if (query.isEmpty) {
      return CustomerService.customers;
    }
    return CustomerService.customers.where((element) {
      if (query.isEmpty) {
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
      Future.delayed(Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
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
      body: ListView(
        children: [
          appBar(),
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
                  physics: NeverScrollableScrollPhysics(),
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

  Widget appBar() {
    bool existButton = AdvisorService.isAdmin;
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row (
            mainAxisAlignment: existButton?MainAxisAlignment.spaceBetween:MainAxisAlignment.center,
            children: [
              if (existButton)
                const Opacity(
                  opacity: 0,
                  child: IconButton(
                      icon: Icon(Icons.arrow_back),
                      onPressed: null
                  ),
                ),
              Text('Kundenübersicht', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              if (existButton)
                IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    Navigator.pushNamed(context, '/admin/advisors');
                  },
                )
            ],
          ),
        ),
        Positioned(
          left: 5,
          bottom: 5,
          child: Text(
            '${InitService.version}',
            style: TextStyle(fontSize: 10),
          )
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
          if (selectedCustomer.value == customer)
            Container(
              padding: EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Material(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: selectedCustomer.value!.email == null?null:() async {
                          await customer.sendEmail();
                          selectedCustomer.notifyListeners();
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
                  Expanded(child: Container()),
                  Material(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () async {
                          bool? val = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Kunden löschen'),
                                content: Text('Soll der Kunde ${customer.name} ${customer.surname} wirklich gelöscht werden?'),
                                actions: <Widget>[
                                  TextButton(
                                    child: Text('Abbrechen'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Löschen'),
                                    onPressed: () async {
                                      await CustomerService.removeCustomer(customer);
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          if (val == true) {
                            setState(() {});
                          }
                        },
                        child: Container(
                            padding: EdgeInsets.all(8),
                            child: const  Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(Icons.delete, size: 20,),
                              ],
                            )
                        ),
                      )
                  ),
                ],
              ),
            ),
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
                Column(
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
                            width: 120,
                            height: 50,
                            padding: EdgeInsets.all(10),
                            child:const  Row (
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text('Vollmacht', overflow: TextOverflow.fade,),
                                Icon(Icons.download),
                              ],
                            )
                        ),
                      ),
                    ),
                    Container(height: 10),
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
                            width: 120,
                            height: 50,
                            padding: EdgeInsets.all(10),
                            child: const Row (
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
