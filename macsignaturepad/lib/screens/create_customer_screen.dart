import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/models/service_details.dart';

import 'package:macsignaturepad/services/advisor_service.dart';
import 'package:macsignaturepad/services/all_services_service.dart';
import 'package:macsignaturepad/services/customer_service.dart';
import '../models/customer.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  List<Customer> get customers => CustomerService.customers;
  bool _isLoading = false ;
  bool isCompany = false;
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _surname = '';
  String _countryCode = '+43';
  String _phone = '';
  String _email = '';
  Timestamp? _birthdate;
  String? _uid = '';
  String? _stnr = '';
  String _zip = '';
  String _city = '';
  String _street = '';
  final Map<String, List<ServiceDetails>> _insuranceOptions = AllServicesService.getNewMap();

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
    super.initState();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (!isInsuranceOptionsValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bitte wählen Sie mindestens eine Versicherungsoption aus'),
          ),
        );
        return;
      }
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });
      await CustomerService.addNewCustomer(
        Customer.create(
          name: _name,
          surname: _surname,
          phone: _countryCode + _phone,
          email: _email,
          birthdate: _birthdate!,
          zip: _zip,
          city: _city,
          street: _street,
          uid: _uid,
          stnr: _stnr,
          details: _insuranceOptions.values.expand((element) => element).toList(),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      return Text('Nicht authentifiziert');
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Neukunde anlegen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  ListTile(
                    title: const Text('Privatkunde'),
                    leading: Radio<bool>(
                      value: false,
                      groupValue: isCompany,
                      onChanged: (bool? value) {
                        setState(() {
                          isCompany = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('Business'),
                    leading: Radio<bool>(
                      value: true,
                      groupValue: isCompany,
                      onChanged: (bool? value) {
                        setState(() {
                          isCompany = value ?? true;
                        });
                      },
                    ),
                  ),

                  TextFormField(
                    decoration: InputDecoration(labelText: isCompany?'Firmenname':'Name'),
                    onSaved: (value) {
                      _name = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte einen Namen eingeben';
                      }
                      return null;
                    },
                  ),
                  if (!isCompany)
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Nachname'),
                      onSaved: (value) {
                        _surname = value!;
                      },
                      validator: (value) {
                        if (!isCompany && value!.isEmpty) {
                          return 'Bitte einen Nachnamen eingeben';
                        }
                        return null;
                      },
                    ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Telefonnummer',
                      prefix: CountryCodePicker(
                        onChanged: (CountryCode countryCode) {
                          _countryCode = countryCode.code??'+43';
                        },
                        initialSelection: _countryCode,
                        padding: EdgeInsets.zero,
                        favorite: const ['AT','DE','TR'],
                        showFlag: false,
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                      ),
                    ),
                    onSaved: (value) {
                      _phone = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte eine Telefonnummer eingeben';
                      }
                      if (_countryCode.isEmpty) {
                        return 'Bitte ein Land auswählen';
                      }
                      if (_countryCode == '+43' && value!.split('').first == '0') {
                        return 'Telefonnummer darf nicht mit 0 beginnen';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'E-Mail'),
                    onSaved: (value) {
                      _email = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte eine E-Mail-Adresse eingeben';
                      }
                      if (!value.contains('@')) {
                        return 'Bitte eine gültige E-Mail-Adresse eingeben';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Geburtsdatum'),
                    onSaved: (value) {
                      _birthdate = parseDateTime(value!);
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte den Geburtsdatum eingeben';
                      }
                      if (parseDateTime(value) == null) {
                        return 'Bitte den Geburtsdatum im Format dd.mm.yyyy eingeben';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Postleitzahl'),
                    onSaved: (value) {
                      _zip = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte eine Postleitzahl eingeben';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Stadt'),
                    onSaved: (value) {
                      _city = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte eine Stadt eingeben';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Straße'),
                    onSaved: (value) {
                      _street = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte eine Straße eingeben';
                      }
                      return null;
                    },
                  ),
                  if (isCompany)
                    TextFormField(
                      decoration: InputDecoration(labelText: 'UID'),
                      onSaved: (value) {
                        _uid = value;
                      }
                    ),
                  if (isCompany)
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Steuer Nummer'),
                      onSaved: (value) {
                        _stnr = value;
                      }
                    ),
                ],
              ),
            ),
            Container(height: 20),
            ..._insuranceOptions.keys.map((option) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 20),
                    Text(option + ':', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        return singleInsuraceOption(
                            service: _insuranceOptions[option]![index]
                        );
                      },
                      separatorBuilder: (context, index) => Divider(height: 0),
                      itemCount: _insuranceOptions[option]!.length,
                    ),
                  ]
              );
            }).toList(),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  Random rnd = Random();
                  _insuranceOptions.forEach((key, value) {
                    value.forEach((element) {
                      // set random status (0,2)
                      element.status = rnd.nextInt(3);
                    });
                  });
                });
              },
              child: Text('RandomClick'),
            ),
            ElevatedButton(
              onPressed: _isLoading?null:_saveForm,
              child: Text('Speichern'),
            ),
          ],
        ),
      ),
    );
  }

  Timestamp? parseDateTime(String value) {
    try {
      value = value.replaceAll('-', '.');
      value = value.replaceAll('/', '.');
      String day = value.split('.')[0];
      String month = value.split('.')[1];
      String year = value.split('.')[2];
      
      return Timestamp.fromDate(DateTime.parse('$year-$month-$day'));
    } catch (e) {
      return null;
    }
  }

  Widget singleInsuraceOption({required ServiceDetails service}) {
    return Container(
      padding: EdgeInsets.all(5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(service.name),
              if (service.notes != null && service.notes!.isNotEmpty)
                Text('(${service.notes})'),
              Row(
                children: [
                  Radio(
                    value: 0,
                    groupValue: service.status,
                    onChanged: (int? value) {
                      setState(() {
                        service.status = value!;
                      });
                    },
                  ),
                  Text('Ja'),
                  Container(width: 10),
                  Radio(
                    value: 1,
                    groupValue: service.status,
                    onChanged: (int? value) {
                      setState(() {
                        service.status = value!;
                      });
                    },
                  ),
                  Text('Nein'),
                  Container(width: 10),
                  Radio(
                    value: 2,
                    groupValue: service.status,
                    onChanged: (int? value) {
                      setState(() {
                        service.status = value!;
                      });
                    },
                  ),
                  Text('Ändern'),
                ],
              ),
            ],
          ),
          Text(service.getNotes),
        ],
      ),
    );
  }

  bool isInsuranceOptionsValid() {
    bool isValid = false;
    _insuranceOptions.forEach((key, value) {
      value.forEach((element) {
        if (element.status == 0 || element.status == 2) {
          isValid = true;
        }
      });
    });
    return isValid;
  }
}