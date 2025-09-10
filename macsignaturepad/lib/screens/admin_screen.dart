import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/enums/required_documents.dart';
import 'package:macsignaturepad/screens/splash_screen.dart';
import 'package:macsignaturepad/services/advisor_service.dart';
import 'package:macsignaturepad/services/csv_service.dart';
import 'package:macsignaturepad/services/customer_service.dart';
import 'package:macsignaturepad/services/init_service.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../models/customer.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool seeAll = false;
  bool _isLoading = true;
  bool _sendSmsLoading = false;
  bool _sendEmailLoading = false;
  ValueNotifier<Customer?> selectedCustomer = ValueNotifier(null);
  String query = '';
  final List years = [];
  int selectedYear = 0;
  int selectedMonth = 0;
  List get months {
    if (selectedYear == DateTime.now().year) {
      return List.generate(DateTime.now().month, (index) => index+1).reversed.toList();
    } else {
      return List.generate(12, (index) => index+1).reversed.toList();
    }
  }

  bool get isSearchResult => query.isNotEmpty && query.length >= 3;

  Future<List<Customer>> getCustomers() async {
    if (isSearchResult) {
      List<Customer> res = await CustomerService.searchCustomers(query);
      print('Found ${res.length} customers');
      return res;
    }
    await CustomerService.initCustomers(year: selectedYear, month: selectedMonth);
    List<Customer> customers = CustomerService.customersMap['$selectedMonth-$selectedYear']??[];

    if (query.isEmpty) {
      return customers;
    }
    List<Customer> res = customers.where((element) {
      if (query.isEmpty) {
        return true;
      }
      return element.name.toLowerCase().contains(query.toLowerCase()) ||
          element.surname.toLowerCase().contains(query.toLowerCase()) ||
          (element.email?.toLowerCase().contains(query.toLowerCase())??false) ||
          element.phone.toLowerCase().contains(query.toLowerCase());
    }).toList();
    return res;
  }

  Future refresh() async {
    setState(() {
      _isLoading = true;
    });
    await CustomerService.initCustomers(year: selectedYear, month: selectedMonth);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
    for (int i = DateTime.now().year; i >= 2023; i--) {
      years.add(i);
    }
    InitService.init(id: context.hashCode, function: () {
      setState(() {});
    }).then((value) => {
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _isLoading = false;
        });
      })
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!InitService.isInited) {
      return SplashScreen();
    }
    if (FirebaseAuth.instance.currentUser == null) {
      return const Text('Nicht authentifiziert');
    }
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          children: [
            appBar(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    query = value.trim();
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Search',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Container(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(width: 10),
                    Expanded(child: ElevatedButton(
                      onPressed: () async {
                        await Navigator.pushNamed(context, '/admin/createCustomer');
                      },
                      child: const Text('Neuen Kunden anlegen +'),
                    ),),
                    Container(width: 10),
                    ElevatedButton(
                        onPressed: _isLoading?null:refresh,
                        child: const Icon(
                            Icons.refresh
                        )
                    ),
                    Container(width: 10),
                  ],
                )
            ),
            if (AdvisorService.isAdmin)
              Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Container(width: 10),
                      Expanded(child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            seeAll = !seeAll;
                          });
                        },
                        child: seeAll?const Text('Nur meine Kunden anzeigen'):const Text('Alle Kunden anzeigen'),
                      ),),
                      Container(width: 10),
                    ],
                  )
              ),
            if (!isSearchResult)
              Row(
              children: [
                Container(
                  height: 70,
                  margin: const EdgeInsets.all(5),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        selectedMonth = 0;
                        selectedYear = 0;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: selectedMonth == 0&&selectedYear ==0?Colors.blue:Colors.grey[300],
                          borderRadius: BorderRadius.circular(8)
                      ),
                      child: const Center(child: Icon(Icons.query_builder)),
                    ),
                  ),
                ),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: years.length,
                          itemBuilder: (context, i) => Container(
                            margin: const EdgeInsets.all(5),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                if (selectedMonth == 0) {
                                  selectedMonth = DateTime.now().month;
                                } else {
                                  selectedMonth = 1;
                                }
                                setState(() {
                                  selectedYear = years[i];
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                    color: selectedYear == years[i]?Colors.blue:Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8)
                                ),
                                child: Center(child: Text(years[i].toString())),
                              ),
                            ),
                          ),
                        )
                    ),
                    SizedBox(
                        height: 30,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          shrinkWrap: true,
                          itemCount: months.length,
                          itemBuilder: (context, i) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                setState(() {
                                  selectedMonth = months[i];
                                  if (selectedYear == 0) {
                                    selectedYear = DateTime.now().year;
                                  }
                                });
                              },
                              child: Container(
                                width: 40,
                                decoration: BoxDecoration(
                                    color: selectedMonth == months[i]?Colors.blue:Colors.grey[300],
                                    borderRadius: BorderRadius.circular(8)
                                ),
                                child: Center(child: Text(months[i].toString())),
                              ),
                            ),
                          ),
                        )
                    ),
                  ],
                ))
              ],
            ),
            Builder(
                builder: (ctx) {
                  return FutureBuilder(
                    future: getCustomers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SplashScreen();
                      }
                      if (snapshot.hasError) {
                        if (kDebugMode) {
                          print(snapshot.error);
                        }
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (snapshot.data == null || (snapshot.data as List<Customer>).isEmpty) {
                        return Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            child: const Text('Keine Kunden vorhanden für diesen Monat'),
                          ),
                        );
                      }
                      List<Customer> customers = snapshot.data as List<Customer>;
                      if (!seeAll) {
                        customers = customers.where((element) => element.advisorId == AdvisorService.advisor!.id).toList();
                      }
                      return ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: customers.length,
                        separatorBuilder: (context, index) => const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Divider(height: 0, color: Colors.black12),),
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
                    },
                  );
                }
            ),
            Container(height: 30),
          ],
        ),
      ),
    );
  }

  Widget trailing(Customer customer, bool isSelected) {
    return Column(
      children: [
        if (isSelected && customer.lastSignature == null)
          Column(
            children: [
              Text('SMS Sent: ${customer.readableSmsSentTime}', style: TextStyle(color: customer.smsSentDateColor)),
              Text('Email Sent: ${customer.readableEmailSentTime}', style: TextStyle(color: customer.emailSentDateColor),),
            ],
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Row(
              children: [
                Column(
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
        )
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
              Opacity(
                opacity: AdvisorService.isAdmin?1:0,
                child: IconButton(
                    icon: const Icon(Icons.list),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Mehr'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView(
                                shrinkWrap: true,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      CSVService.getCSV();
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Kunden exportieren'),
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      Navigator.pushNamed(context, '/admin/emailer');
                                    },
                                    child: const Text('Nachricht Sender'),
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: () {
                                      // Sign out
                                      FirebaseAuth.instance.signOut();
                                      InitService.cleanCache();
                                      Navigator.pushReplacementNamed(context, '/');
                                    },
                                    child: const Text('Abmelden', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    }
                ),
              ),
              const Text('Kundenübersicht', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Opacity(
                opacity: existButton?1:0,
                child: IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: existButton?() {
                    Navigator.pushNamed(context, '/admin/advisors');
                  }:null,
                ),
              )
            ],
          ),
        ),
        Positioned(
          left: 5,
          bottom: 5,
          child: Text(
            InitService.version,
            style: const TextStyle(fontSize: 10),
          )
        ),
      ],
    );
  }

  singleCustomerRow(Customer customer) {
    bool isSelected = selectedCustomer.value?.id == customer.id;
    return Container(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedCustomer.value == customer)
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Material(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[300],
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: (selectedCustomer.value!.email == null || _sendEmailLoading)?null:() async {
                          setState(() {
                            _sendEmailLoading = true;
                          });
                          await customer.sendEmail();
                          _sendEmailLoading = false;
                          await selectedCustomer.value?.refresh();
                          selectedCustomer.notifyListeners();

                        },
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            child:  Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (_sendEmailLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.black,),
                                  ),
                                if (!_sendEmailLoading)
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
                        onTap: _sendSmsLoading?null:() async {
                          setState(() {
                            _sendSmsLoading = true;
                          });
                          await customer.sendSms();
                          _sendSmsLoading = false;
                          await selectedCustomer.value?.refresh();
                          selectedCustomer.notifyListeners();
                        },
                        child: Container(
                            padding: const EdgeInsets.all(8),
                            child:  Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (_sendSmsLoading)
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.black,),
                                  ),
                                if (!_sendSmsLoading)
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
                        await selectedCustomer.value?.refresh();
                        selectedCustomer.notifyListeners();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
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
                  Row(
                    children: [
                      Material(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[300],
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              // parameter with the customer
                              await Navigator.pushNamed(context, '/admin/createCustomer', arguments: customer);
                            },
                            child: Container(
                                padding: const EdgeInsets.all(8),
                                child: const  Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Icon(Icons.copy, size: 20,),
                                  ],
                                )
                            ),
                          )
                      ),
                      SizedBox(width: 10),
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
                                    title: const Text('Kunden löschen'),
                                    content: Text('Soll der Kunde ${customer.readableName} wirklich gelöscht werden?'),
                                    actions: <Widget>[
                                      TextButton(
                                        child: const Text('Abbrechen'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: const Text('Löschen'),
                                        onPressed: () async {
                                          await CustomerService.removeCustomer(customer);
                                          if (mounted) {
                                            Navigator.of(context).pop(true);
                                          }
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
                                padding: const EdgeInsets.all(8),
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
                  )
                ],
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!customer.isDownloaded && !AdvisorService.isOffice)
                        Container(
                          padding: const EdgeInsets.only(right: 5),
                          child: const Icon(Icons.circle, color: Colors.blue, size: 10,),
                        ),
                      Text(customer.readableName, style: const TextStyle(fontSize:16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  if (AdvisorService.isAdmin && !customer.hasBackOfficeDownloaded)
                    const Text('Nicht bearbeitet', style: TextStyle(color: Colors.red, fontSize: 12),),
                  Text(customer.readableCreateTime,),
                ],
              ),
              trailing(customer, isSelected),
            ],
          ),
          if (isSelected)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width*0.6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(customer.id),
                      SelectableText(customer.readableBirthdate),
                      SelectableText(customer.getReadableEmail),
                      SelectableText(customer.getReadablePhone),
                      SelectableText(customer.street),
                      SelectableText('${customer.zip}, ${customer.city}'),
                      SelectableText('Uid: ${customer.getReadableUid}'),
                      SelectableText('Steuernr: ${customer.getReadableStnr}'),
                      SelectableText('Erstellungszeit: ${customer.readableCreateTime}'),
                      SelectableText('Berater: ${customer.advisorName}'),
                      Row(
                        children: [
                          SelectableText('Werbung: ${customer.allowMarketing?'Ja':'Nein'}'),
                          Container(width: 2),
                          if (customer.allowMarketing)
                            InkWell(
                              onTap: () async {
                                // show dialog are you sure
                                bool res = await showConfirmationDialog(context, customer.readableName);
                                if (res) {
                                  await customer.unsubscribeNewsletter();
                                  setState(() {});
                                }
                              },
                              child: const Icon(Icons.remove, color: Colors.red, size: 20,),
                            )
                        ],
                      ),
                      customer.actions.isNotEmpty
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: customer.actions.map((e) {
                          return _linkButtonDocument(e.germanName, customer.documents[e]);
                        }).toList(),
                      ) : const Text('Keine Dokumente erforderlich', style: TextStyle(color: Colors.grey),)
                    ],
                  ),
                ),
                if (customer.lastSignature != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[300],
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            if (customer.lastSignature == null) {
                              return;
                            }
                            await downloadFile(customer.lastSignature!.vollmachtPdfUrl, '${customer.fileName('vollmacht')}.pdf');
                            customer.setIsDownloaded().then((value) async {
                              await selectedCustomer.value?.refresh();
                              selectedCustomer.notifyListeners();
                            });
                          },
                          child: Container(
                              width: 90,
                              height: 50,
                              padding: const EdgeInsets.all(10),
                              child:const  Row (
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('Vollmacht', overflow: TextOverflow.fade,)
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
                          onTap: () async {
                            if (customer.lastSignature == null) {
                              return;
                            }
                            await downloadFile(customer.lastSignature!.bprotokollPdfUrl, '${customer.fileName('bprotokoll')}.pdf');
                            customer.setIsDownloaded().then((value) async {
                              await selectedCustomer.value?.refresh();
                              selectedCustomer.notifyListeners();
                            });
                          },
                          child: Container(
                              width: 90,
                              height: 50,
                              padding: const EdgeInsets.all(10),
                              child: const Row (
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text('Protokoll',),
                                ],
                              )
                          ),
                        ),
                      )
                    ],
                  )
                )
              ],
            )
        ],
      ),
    );
  }

  Future openPdf(String url) async {
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<bool> showConfirmationDialog(BuildContext context, String customerName) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Bestätigung"),
          content: Text(
              "Möchten Sie den Kunden $customerName wirklich aus dem Newsletter abmelden?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text("Ja"),
            ),
          ],
        );
      },
    ) == true;
  }

  Future<String?> getDownloadUrlFromStoragePath(String storagePath) async {
    try {
      final ref = FirebaseStorage.instance.ref(storagePath);
      String url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      print('Fehler beim Holen der Download-URL: $e');
      return null;
    }
  }

  Widget _linkButtonDocument(String text, String? url) {
    final isAvailable = url != null && url.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: isAvailable ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: isAvailable
              ? () async {
            String? realUrl = (url.startsWith('gs://') || url.startsWith('http'))
                ? url
                : await getDownloadUrlFromStoragePath(url);
            if (realUrl != null) {
              html.window.open(realUrl, text);
            }
          } : null,
          child: Text(text, style: TextStyle(color: isAvailable ? Colors.blue : Colors.red)),
        ),
      ),
    );
  }

  Future<void> downloadFile(String url, String fileName) async {
    try {
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var blob = html.Blob([response.bodyBytes]);
        var url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      openPdf(url);
    }
  }
}