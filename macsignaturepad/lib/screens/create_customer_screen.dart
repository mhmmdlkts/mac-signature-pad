import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:macsignaturepad/models/service_details.dart';

import 'package:macsignaturepad/services/all_services_service.dart';
import 'package:macsignaturepad/services/customer_service.dart';
import '../models/analysis_details.dart';
import '../models/customer.dart';
import 'package:intl/intl.dart';

class CreateCustomerScreen extends StatefulWidget {
  const CreateCustomerScreen({super.key});

  @override
  State<CreateCustomerScreen> createState() => _CreateCustomerScreenState();
}

class _CreateCustomerScreenState extends State<CreateCustomerScreen> {
  bool _isLoading = false;
  bool isCompany = false;
  bool _sendSms = false;
  bool _sendEmail = true;
  bool _uploadDoc = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();
  final TextEditingController _zipController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _stnrController = TextEditingController();
  final TextEditingController _nextTerminController = TextEditingController();

  Uint8List? bprotokolManuellBytes;
  Uint8List? vollmachtManuelBytes;

  String? _title;
  String? _anrede;
  String _name = '';
  String _surname = '';
  String _countryCode = '+43';
  String _phone = '';
  String _email = '';
  Timestamp? _birthdate;
  Timestamp? _nextTermin;
  String? _uid = '';
  String? _stnr = '';
  String _zip = '';
  String _city = '';
  String _street = '';
  String errorMessage = '';
  final ValueNotifier<String> _notesNotifier = ValueNotifier<String>('');
  final Map<String, List<ServiceDetails>> _insuranceOptions = AllServicesService.getNewMap();
  final List<AnalysisDetails> _analysisOptions = AllServicesService.getNewMapAnalysisDetails();
  final Map<String, Map> _erteilterAuftrag = {
    'ertei-bekan-yes': {
      'title': 'Bekanntgabe Vorversicherer',
      'value': true
    },
    'ertei-einre-yes': {
      'title': 'Einreichung Neuantrag wie besprochen',
      'value': true
    },
    'ertei-einho-yes': {
      'title': 'Einholung Polizzenauskünfte',
      'value': true
    },
    'ertei-kündi-yes': {
      'title': 'Kündigung Vorverträge',
      'value': true
    }
  };

  @override
  void initState() {
    if (FirebaseAuth.instance.currentUser == null) {
      Navigator.pushReplacementNamed(context, '/login');
    }
    super.initState();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_uploadDoc && (bprotokolManuellBytes == null || vollmachtManuelBytes == null)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte laden Sie die Dokumente hoch'),
          ),
        );
        return;
      }
      if (!isInsuranceOptionsValid()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte wählen Sie mindestens eine Versicherungsoption aus'),
          ),
        );
        return;
      }
      if (!isCompany && _anrede == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte wählen Sie eine Anrede aus'),
          ),
        );
        return;
      }
      _formKey.currentState!.save();

      setState(() {
        _isLoading = true;
      });
      for (var element in _insuranceOptions.values) {
        for (var e in element) {
          e.notes = e.getNotes;
        }
      }
      try {
        await CustomerService.addNewCustomer(
          Customer.create(
            title: _title,
            anrede: _anrede,
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
            nextTermin: _nextTermin,
            details: _insuranceOptions.values.expand((element) => element).toList(),
            analysisOptions: _analysisOptions,
            extraInfo: _erteilterAuftrag
          ),
          sms: _sendSms,
          email: _sendEmail,
          bprotokolManuellBytes: bprotokolManuellBytes,
          vollmachtManuelBytes: vollmachtManuelBytes,
        );

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/admin');
        }
      } catch (error) {
        setState(() {
          _isLoading = false;
          errorMessage = error.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    tryParseOldCustomer();
    if (FirebaseAuth.instance.currentUser == null) {
      return const Text('Nicht authentifiziert');
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neukunde anlegen'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.max,
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

                  if (!isCompany)
                    Row(
                      children: [
                        Radio<String>(
                          value: 'Herr',
                          groupValue: _anrede,
                          onChanged: (String? value) {
                            setState(() {
                              _anrede = value;
                            });
                          },
                        ),
                        Text('Herr'),
                        Container(width: 10),
                        Radio<String>(
                          value: 'Frau',
                          groupValue: _anrede,
                          onChanged: (String? value) {
                            setState(() {
                              _anrede = value;
                            });
                          },
                        ),
                        Text('Frau'),
                      ],
                    ),

                  if (!isCompany)
                    TextFormField(
                      controller: _titleController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      decoration: InputDecoration(labelText: 'Titel'),
                      onSaved: (value) {
                        _title = value!;
                      },
                    ),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(labelText: isCompany?'Firmenname':'Vorname'),
                    onSaved: (value) {
                      _name = value!;
                    },
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Bitte einen ${isCompany?'Firmenname':'Vorname'} eingeben';
                      }
                      return null;
                    },
                  ),
                  if (!isCompany)
                    TextFormField(
                      controller: _surnameController,
                      textCapitalization: TextCapitalization.words,
                      keyboardType: TextInputType.name,
                      decoration: const InputDecoration(labelText: 'Nachname'),
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
                  Row(
                    children: [
                      CountryCodePicker(
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
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Telefonnummer'),
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
                            if (_countryCode == '+43' && value.split('').first == '0') {
                              return 'Telefonnummer darf nicht mit 0 beginnen';
                            }
                            return null;
                          },
                        ),
                      )
                    ],
                  ),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-Mail'),
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
                    controller: _birthdateController,
                    keyboardType: TextInputType.datetime,
                    decoration: const InputDecoration(labelText: 'Geburtsdatum'),
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
                    controller: _zipController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Postleitzahl'),
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
                    controller: _cityController,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(labelText: 'Stadt'),
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
                    controller: _streetController,
                    textCapitalization: TextCapitalization.words,
                    keyboardType: TextInputType.streetAddress,
                    decoration: const InputDecoration(labelText: 'Straße'),
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
                      controller: _uidController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'UID'),
                      onSaved: (value) {
                        _uid = value;
                      }
                    ),
                  if (isCompany)
                    TextFormField(
                      controller: _stnrController,
                      decoration: const InputDecoration(labelText: 'Steuer Nummer'),
                      onSaved: (value) {
                        _stnr = value;
                      }
                    ),
                ],
              ),
            ),
            Container(height: 20),
            ..._erteilterAuftrag.keys.map((e) => Row(
              children: [
                Checkbox(value: _erteilterAuftrag[e]!['value'], onChanged: (val) {
                  setState(() {
                    _erteilterAuftrag[e]!['value'] = !_erteilterAuftrag[e]!['value'];
                  });
                }),
                Text(_erteilterAuftrag[e]!['title'])
              ],
            )),
            Container(height: 20),
            ..._analysisOptions.map((e) => Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.name, style: TextStyle(fontSize: 20),),
                Wrap(
                  children: e.options.keys.map((key) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: e.options[key],
                        onChanged: (val) {
                          setState(() {
                            e.options[key] = val??false;
                          });
                        },
                      ),
                      Text(key),
                      Container(width: 20,)
                    ],
                  )).toList(),
                ),
                Divider()
              ],
            )),
            Container(height: 20),
            ..._insuranceOptions.keys.map((option) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 20),
                  if (!duplicateCustomer)
                    Text('$option:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (!duplicateCustomer)
                    Container(height: 10),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      return singleInsuraceOption(
                          service: _insuranceOptions[option]![index]
                      );
                    },
                    separatorBuilder: (context, index) => const Divider(height: 0),
                    itemCount: _insuranceOptions[option]!.length,
                  ),
                ]
              );
            }).toList(),
            const Divider(height: 0,),
            Container(height: 10,),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _insuranceOptions.forEach((key, value) {
                        setState(() {
                          for (var element in value) {
                            element.status ??= 0;
                          }
                        });
                      });
                    });
                  },
                  child: const Text('Rest Ja'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _insuranceOptions.forEach((key, value) {
                        setState(() {
                          for (var element in value) {
                            element.status ??= 1;
                          }
                        });
                      });
                    });
                  },
                  child: const Text('Rest Nein'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _insuranceOptions.forEach((key, value) {
                        setState(() {
                          for (var element in value) {
                            element.status ??= 2;
                          }
                        });
                      });
                    });
                  },
                  child: const Text('Rest Ändern'),
                ),
              ],
            ),
            Container(height: 10),
            Text('Nächster Termin: ${_nextTermin==null?'-':DateFormat('dd.MM.yyyy').format(_nextTermin!.toDate())}'),
            Container(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () {
                  setState(() {
                    _nextTermin = null;
                  });
                }, child: const Text('X')),
                ElevatedButton(onPressed: () {
                  setState(() {
                    _nextTermin = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365)));
                  });
                }, child: const Text('1 Jahr')),
                ElevatedButton(onPressed: () {
                  setState(() {
                    _nextTermin = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365 * 2)));
                  });
                }, child: const Text('2 Jahr')),
                ElevatedButton(onPressed: () {
                  setState(() {
                    _nextTermin = Timestamp.fromDate(DateTime.now().add(const Duration(days: 365 * 3)));
                  });
                }, child: const Text('3 Jahr')),
              ],
            ),
            Container(height: 10),
            Row(
              children: [
                Container(height: 10,),
                Row(
                  children: [
                    Checkbox(
                        value: _sendEmail,
                        onChanged: _uploadDoc?null:(val) {
                          setState(() {
                            _sendEmail = val??false;
                          });
                        }
                    ),
                    const Icon(Icons.email),
                  ],
                ),
                Container(width: 30,),
                Row(
                  children: [
                    Checkbox(
                        value: _sendSms,
                        onChanged: _uploadDoc?null:(val) {
                          setState(() {
                            _sendSms = val??false;
                          });
                        }
                    ),
                    const Icon(Icons.perm_phone_msg),
                  ],
                ),
                Container(width: 30,),
                Row(
                  children: [
                    Checkbox(
                        value: _uploadDoc,
                        onChanged: (val) {
                          if (val??false) {
                            _sendEmail = false;
                            _sendSms = false;
                          }
                          setState(() {
                            _uploadDoc = val??false;
                          });
                        }
                    ),
                    const Icon(Icons.upload_file),
                  ],
                ),
              ],
            ),
            if (errorMessage.isNotEmpty)
              Text(errorMessage, style: const TextStyle(color: Colors.red)),
            if (_uploadDoc)
              Column(
                children: [
                  Column(
                    children: [
                      if (bprotokolManuellBytes != null)
                        Row(
                          children: [
                            Text('Beratungsprotokoll.pdf'),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  bprotokolManuellBytes = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          ],
                        ),
                      Container(height: 10),
                      if (bprotokolManuellBytes == null)
                        ElevatedButton(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles();
                            if (result != null) {
                              setState(() {
                                bprotokolManuellBytes = result.files.single.bytes!;
                              });
                            }
                          },
                          child: const Text('Beratungsprtokoll hochladen'),
                        ),
                    ],
                  ),
                  Column(
                    children: [
                      if (vollmachtManuelBytes != null)
                        Row(
                          children: [
                            Text('Vollmacht.pdf'),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  vollmachtManuelBytes = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                            )
                          ],
                        ),
                      Container(height: 10),
                      if (vollmachtManuelBytes == null)
                        ElevatedButton(
                          onPressed: () async {
                            FilePickerResult? result = await FilePicker.platform.pickFiles();
                            if (result != null) {
                              setState(() {
                                vollmachtManuelBytes = result.files.single.bytes!;
                              });
                            }
                          },
                          child: const Text('Vollmacht hochladen'),
                        ),
                    ],
                  ),
                ],
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading?null:_saveForm,
              child: const Text('Speichern'),
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
      padding: const EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(service.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ValueListenableBuilder(
            valueListenable: _notesNotifier,
            builder: (context, _, __) {
              return Text(service.notes??'', style: const TextStyle(fontSize: 12, color: Colors.grey));
            },
          ),
          Row(
            children: [
              Radio(
                value: 0,
                groupValue: service.status,
                onChanged: (int? value) {
                  setState(() {
                    service.status = value!;
                    service.notes = 'Neuerlicher Termin gewünscht';
                  });
                },
              ),
              const Text('Ja'),
              Container(width: 10),
              Radio(
                value: 1,
                groupValue: service.status,
                onChanged: (int? value) {
                  setState(() {
                    service.status = value!;
                    service.notes = 'Nicht gewünscht';
                  });
                },
              ),
              const Text('Nein'),
              Container(width: 10),
              Radio(
                value: 2,
                groupValue: service.status,
                onChanged: (int? value) {
                  setState(() {
                    service.status = value!;
                    service.notes = 'Zurzeit kein Interesse';
                  });
                },
              ),
              const Text('Ändern'),
            ],
          ),
          Row(
            children: [
              Expanded(child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Notizen',
                  border: OutlineInputBorder(),
                ),
                controller: TextEditingController(text: service.notes),
                onChanged: (value) {
                  service.notes = value;
                  _notesNotifier.notifyListeners();
                },
              )),
              IconButton(onPressed: () {
                setState(() {
                  service.notes = '';
                });
              }, icon: const Icon(Icons.clear))
            ],
          )
        ],
      ),
    );
  }

  bool isInsuranceOptionsValid() {
    bool isValid = false;
    _insuranceOptions.forEach((key, value) {
      for (var element in value) {
        if (element.status == 0 || element.status == 2) {
          isValid = true;
        }
      }
    });
    return isValid;
  }

  bool triedParsing = false;
  bool duplicateCustomer = false;
  void tryParseOldCustomer() {
    if (triedParsing) {
      return;
    }
    Customer? customer = ModalRoute.of(context)!.settings.arguments as Customer?;
    if (customer != null) {
      duplicateCustomer = true;
      _title = customer.title;
      _titleController.text = customer.title??'';
      _anrede = customer.anrede;
      _name = customer.name;
      _nameController.text = customer.name;
      _surname = customer.surname;
      _surnameController.text = customer.surname;
      _countryCode = customer.phone.split('').first == '+'?customer.phone.split('').sublist(0, 3).join():'+43';
      _phone = customer.phone.split('').sublist(3).join();
      _phoneController.text = customer.phone.split('').sublist(3).join();
      _email = customer.email??'';
      _emailController.text = customer.email??'';
      _birthdate = customer.birthdate;
      _birthdateController.text = DateFormat('dd.MM.yyyy').format(customer.birthdate!.toDate());
      _zip = customer.zip;
      _zipController.text = customer.zip;
      _city = customer.city;
      _cityController.text = customer.city;
      _street = customer.street;
      _streetController.text = customer.street;
      _uid = customer.uid;
      _uidController.text = customer.uid??'';
      _stnr = customer.stnr;
      _stnrController.text = customer.stnr??'';
      _nextTermin = customer.nextTermin;
      _nextTerminController.text = customer.nextTermin == null?'':DateFormat('dd.MM.yyyy').format(customer.nextTermin!.toDate());
      _insuranceOptions.clear();
      for (ServiceDetails element in customer.details??[]) {
        _insuranceOptions[element.code] ??= [];
        _insuranceOptions[element.code]!.add(element);
      }
      if (customer.analysisOptions != null) {
        for (AnalysisDetails element in customer.analysisOptions!) {
          for (var key in element.options.keys) {
            _analysisOptions.firstWhere((e) => e.code == element.code).options[key] = element.options[key]??false;
          }
        }
      }
      setState(() {});
    }
    triedParsing = true;
  }
}
