import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:hand_signature/signature.dart';
// import 'package:syncfusion_flutter_signaturepad/signaturepad.dart';
import 'package:macsignaturepad/decoration/colors.dart';
import 'package:macsignaturepad/enums/required_documents.dart';
import 'package:macsignaturepad/models/customer.dart';
import 'package:macsignaturepad/screens/pdf_viewer_screen.dart';
import 'package:macsignaturepad/services/firebase_service.dart';
import 'package:macsignaturepad/services/firestore_paths_service.dart';

import '../services/init_service.dart';
import '../services/pdf_service.dart';


class SignScreen extends StatefulWidget {
  const SignScreen({super.key});
  static const backgroundColor = Color(0xFFDCDFE5);

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> with SingleTickerProviderStateMixin{

  ValueNotifier<Map<RequiredDocument, bool>> requiredDocsStatus = ValueNotifier({});

  late final AnimationController doneController;

  bool showDone = false;
  bool get isDrowen => control.isFilled;
  double padding = 20;
  double paddingBetweenPdfs = 40;
  ValueNotifier<String> errorMessage = ValueNotifier<String>('');
  ValueNotifier<bool> isSigning = ValueNotifier<bool>(false);
  ValueNotifier<ByteData?> rawImageFit = ValueNotifier<ByteData?>(null);
  ValueNotifier<bool> signLoading = ValueNotifier<bool>(false);
  Customer? customer;
  String? token;

  Map<String, ValueNotifier<int>> showBadge = {
    'vollmacht': ValueNotifier<int>(0),
    'beratungsprotokoll': ValueNotifier<int>(0)
  };

  List<String> pdfs = [
    'Vollmacht', 'Beratungsprotokoll'
  ];

  Map<String, bool> isPdfButtonDisabled = {
    'Vollmacht': false,
    'Beratungsprotokoll': false
  };

  final control = HandSignatureControl(
    threshold: 3.0,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  @override
  void initState() {
    super.initState();

    try {
      token = Uri.base.queryParameters["token"];
    } catch (e) {
      token = null;
    }
    // token ??= "1735364710597000gQxGZechpnFitNhXrVfziEIv";
    if (token == null) {
      showDone = true;
      Navigator.pushReplacementNamed(context, '/');
      return;
    } else {
      initToken(token!);
    }

    doneController = AnimationController(vsync: this);

  }

  Future initToken(String token) async {
    try {
      Response response = await Dio().get(
        FirebaseService.getUri('getUserData').toString(),
        queryParameters: {'token': token},
      );
      if (response.statusCode == 200) {
        customer = Customer.fromJson(response.data, response.data['id']);

        try {
          requiredDocsStatus.value = Map.fromEntries(
            customer!.actions.map(
              (e) => MapEntry<RequiredDocument, bool>(e, customer!.documents.containsKey(e) && customer!.documents[e] != null && customer!.documents[e]!.isNotEmpty)
            ),
          );
          setState(() {});
        } catch (e) {
          requiredDocsStatus.value = {};
          print('Fehler beim Laden der erforderlichen Dokumente: $e');
        }
        setState(() {});
      } else {
        setState(() {
          showDone = true;
        });
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e) {
      setState(() {
        showDone = true;
      });
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future sendSignature() async {
    int counter = 0;
    String signature = const Base64Encoder().convert(rawImageFit.value!.buffer.asUint8List());
    counter = 1;
    try {

      Response response = await Dio().post(
        FirebaseService.getUri('signPdfs').toString(),
        data: {
          'token': token,
          'userId': customer!.id,
          'signature': signature
        },
      );

      if (kDebugMode) {
        print(response);
      }

      if (response.statusCode == 200) {
        setState(() {
          showDone = true;
        });
      } else {
        errorMessage.value = 'Fehler beim Unterschreiben: ${response.data} [f37-$counter]';
      }

    } catch (e) {
      errorMessage.value = 'Fehler beim Unterschreiben: $e [f36-$counter]';
    }
  }

  @override
  void dispose() {
    doneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Orientation currentOrientation = MediaQuery
        .of(context)
        .orientation;
    if (currentOrientation == Orientation.landscape) {
      return Scaffold(
        backgroundColor: SignScreen.backgroundColor,
        body: SafeArea(
            minimum: EdgeInsets.all(padding),
            child: Center(
              child: _signPad(),
            )
        ),
      );
    }
    return Scaffold(
      backgroundColor: SignScreen.backgroundColor,
      body: WillPopScope(
          onWillPop: () async => false,
          child: showDone ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset('assets/done.json', width: 200,
                  controller: doneController,
                  repeat: false,
                  onLoaded: (composition) {
                    doneController
                      ..duration = composition.duration
                      ..forward().whenComplete(() {
                        doneController.reset();
                        Navigator.pushReplacementNamed(context, '/');
                      });
                  },),
                Container(height: 20),
                const Text('Vielen Dank',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ],
            ),
          ) : ValueListenableBuilder(
            valueListenable: signLoading,
            builder: (context, data, child) {
              return Stack(
                children: [
                  SafeArea(
                    minimum: EdgeInsets.all(padding),
                    child:   Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: getWidth),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Stack(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'MAC Agentur',
                                        style: TextStyle(
                                          color: Colors.black.withOpacity(0.85),
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Positioned(
                                    right: 0,
                                    child: Text(
                                      InitService.version,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  )
                                ],
                              ),
                              Container(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: pdfs.map((e) => _pdfWidget(e, bottom: 7, right: 7)).toList(),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              ValueListenableBuilder(
                                valueListenable: errorMessage,
                                builder: (context, value, child) {
                                  if (errorMessage.value.isEmpty) {
                                    return Container();
                                  }
                                  return
                                    Padding(
                                      padding: const EdgeInsets.only(left: 5, right: 5, bottom: 5),
                                      child: Text(
                                        errorMessage.value,
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    );
                                },
                              ),
                              if (requiredDocsStatus.value.isNotEmpty)
                                actionsWidget(),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Text(
                                  "* Mit Ihrer Unterschrift bestätigen und akzeptieren Sie, dass die Angaben in den Dokumenten Vollmacht und Beratungsprotokoll korrekt und vollständig sind.",
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ),
                              Container(height: 15),
                              _signPad(),
                              Container(height: 20),
                              _customSignButton(),
                            ],
                          ),
                        ),
                      )
                  ),
                  if (signLoading.value)
                    Positioned.fill(
                      child: Container(
                        color: SignScreen.backgroundColor.withOpacity(0.2),
                        child: const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: CircularProgressIndicator(color: firstColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              );
            },
          )
      ),
    );
  }

  Widget actionsWidget() {

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: Card(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Dokumente Übersicht'),
                content: ValueListenableBuilder(
                  valueListenable: requiredDocsStatus,
                  builder: (context, docs, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: docs.entries.map((entry) {
                      final bool ok = entry.value;
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            _onAddTicket(entry.key);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: ok ? Colors.green.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: ok ? Colors.green : Colors.grey),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  ok ? Icons.check_circle : Icons.cancel,
                                  color: ok ? Colors.green : Colors.redAccent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.key.germanName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: ok ? Colors.green : Colors.black87,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black45),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Schließen"),
                  )
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    if (requiredDocsStatus.value.isEmpty)
                      const Icon(Icons.info_outline, color: Colors.blueAccent)
                    else
                      requiredDocsStatus.value.values.any((e) => !e)
                        ? const Icon(Icons.warning_amber_rounded, color: Colors.redAccent)
                        : const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Erforderliche Dokumente:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: requiredDocsStatus,
                        builder: (context, docs, _) => Text(
                          docs.keys.map((e) => e.germanName).join(', '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontWeight: FontWeight.normal,
                          ),
                        )
                      )
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool allDocsDone() {
    return requiredDocsStatus.value.values.every((e) => e);
  }

  Widget _customSignButton() {
    BorderRadius radius = BorderRadius.circular(10);
    return ValueListenableBuilder(
      valueListenable: rawImageFit,
      builder: (context, value, child) => ValueListenableBuilder(
        valueListenable: signLoading,
        builder: (context, data, child) {
          bool isDisabled = rawImageFit.value==null||signLoading.value||!allDocsDone();
          return SizedBox(
              width: double.infinity,
              child: Material(
                  borderRadius: radius,
                  color: firstColor.withOpacity(isDisabled?0.4:1),
                  child: InkWell(
                      borderRadius: radius,
                      onTap: isDisabled?null:() async {
                        signLoading.value = true;
                        await sendSignature();
                        signLoading.value = false;
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: const Text('Unterschreiben', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      )
                  )
              )
          );
        },
      )
    );
  }

  Widget _pdfWidget(String name, {double right = 0, double bottom = 0}) {
    double width = ((MediaQuery.of(context).size.width - ((pdfs.length+1) * paddingBetweenPdfs)) / pdfs.length).floorToDouble();
    width = min(width, 180);
    BorderRadius radius = BorderRadius.circular(9);

    TextStyle style = TextStyle(color: Colors.black.withOpacity(0.75), fontSize: 16, fontWeight: FontWeight.bold);
    double cornerLength = width * (249/674);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: (paddingBetweenPdfs - padding) / 2),
      width: width,
      child: Column (
        children: [
          Stack(
            children: [
              Image.asset('assets/${name.toLowerCase()}_preview.png', width:  width),
              Positioned(
                right: right,
                bottom: bottom,
                child: _buildScaledImageView(),
              ),

              ValueListenableBuilder(
                valueListenable: showBadge[name.toLowerCase()]!,
                builder: (context, value, child) {
                  int badgeVal = showBadge[name.toLowerCase()]!.value;
                  if (badgeVal != 0) {
                    return Positioned(
                      bottom: -5,
                      right: 40,
                      child: Lottie.asset(badgeVal==1?'assets/badge_grey.json':'assets/badge.json', width: 50),
                    );
                  }
                  return Container();
                },
              ),
              Positioned.fill(
                  child: Material(
                    borderRadius: radius,
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: radius,
                      onTap: (isPdfButtonDisabled[name]==null?false:(isPdfButtonDisabled[name]!))?null:() async {
                        setState(() {
                          isPdfButtonDisabled[name] = true;
                        });
                        await openPdf(name);
                        setState(() {
                          isPdfButtonDisabled[name] = false;
                        });
                      },
                    ),
                  )
              ),
              Positioned(
                  top: 0,
                  right: 0,
                  child: CustomPaint(
                    size: Size(cornerLength, cornerLength),
                    painter: TrianglePainter(),
                  )
              )
            ],
          ),
          Container(height: 10),
          Stack(
              alignment: Alignment.center,
              children: pdfs.map((e) => Opacity(opacity: e==name?1:0, child: Text(e, style: style, textAlign: TextAlign.center),)).toList()
          )
        ],
      ),
    );
  }

  double get getWidth => min(MediaQuery.of(context).size.width - (padding * 2), 600);

  Widget _signPad() {
    return ValueListenableBuilder(
        valueListenable: signLoading,
        builder: (context, data, child) => IgnorePointer(
          ignoring: signLoading.value,
          child: AspectRatio(
            aspectRatio: 2,
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.black.withOpacity(0.5), width: 0.6),
                ),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Stack(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: isSigning,
                      builder: (context, value, child) {
                        if (isSigning.value || isDrowen) {
                          return Container();
                        }
                        return Center(
                            child: Opacity(
                              opacity: 0.5,
                              child: Lottie.asset('assets/sign.json'),
                            )
                        );
                      },
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: <Widget>[
                          Container(
                            constraints: const BoxConstraints.expand(),
                            child: HandSignature(
                              control: control,
                              width: 2,
                              maxWidth: 4,
                              onPointerDown: () {
                                isSigning.value = true;
                              },
                              onPointerUp: () async {
                                rawImageFit.value = await control.toImage(
                                  border: 0,
                                );

                                showBadge.forEach((key, value) {
                                  value.value = 1;
                                });
                              },
                              type: SignatureDrawType.shape,
                            ),
                          ),
                        ],
                      ),
                    ),

                    ValueListenableBuilder(
                      valueListenable: rawImageFit,
                      builder: (context, data, child) {
                        if (data == null) {
                          return Container();
                        } else {
                          return Positioned(
                              top: 0,
                              left: 0,
                              child: IconButton(
                                onPressed: () {
                                  control.clear();

                                  isSigning.value = false;
                                  rawImageFit.value = null;
                                  showBadge.forEach((key, value) {
                                    value.value = 0;
                                  });
                                },
                                icon: const Icon(Icons.clear),
                              )
                          );
                        }
                      },
                    )
                  ],
                )
            ),
          ),
        )
    );
  }

  Widget _buildScaledImageView() => Container(
    width: 50.0,
    height: 25.0,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Colors.black, width: 0.25),
    ),
    child: ValueListenableBuilder<ByteData?>(
      valueListenable: rawImageFit,
      builder: (context, data, child) {
        if (data == null) {
          return Container();
        } else {
          return Image.memory(data.buffer.asUint8List());
        }
      },
    ),
  );

  Future openPdf(String name) async {
    if (customer == null) {
      return;
    }
    try {
      String? signature = rawImageFit.value!=null? (const Base64Encoder().convert(rawImageFit.value!.buffer.asUint8List())):null;
      Uint8List? pdf;

      signLoading.value = true;
      if (name.toLowerCase() == 'vollmacht') {
        Map<String, dynamic> vollmachtPdfResult = await PdfService.createVollmachtPDF(customer: customer!, signature: signature, version: currentVollmachtVersion);
        if (!vollmachtPdfResult["success"]) {
          errorMessage.value = 'Fehler beim createVollmachtPDF: $e [f23-${vollmachtPdfResult["error"]}-${vollmachtPdfResult["counter"]}';
          return;
        }
        pdf = vollmachtPdfResult["data"];
      } else if (name.toLowerCase() == 'beratungsprotokoll') {
        Map<String, dynamic> bprotokollPdfResult = await PdfService.createBeratungsprotokolPDF(customer: customer!, signature: signature, version: currentBprotokollVersion);
        if (!bprotokollPdfResult["success"]) {
          errorMessage.value = 'Fehler beim createBeratungsprotokolPDF: $e [f24-${bprotokollPdfResult["error"]}-${bprotokollPdfResult["counter"]}';
          return;
        }
        pdf = bprotokollPdfResult["data"];
      }
      signLoading.value = false;
      if (pdf == null) {
        return;
      }
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(pdfBytes: pdf!),
          ),
        );
      }
    } catch (e) {
      errorMessage.value = 'Fehler beim Öffnen des PDFs: $e [f36]';
    }
  }


  void _onAddTicket(RequiredDocument docType) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Foto aufnehmen'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(docType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Foto hochladen'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadPhoto(docType);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Dokument hochladen'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadDocument(docType);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadDocument(RequiredDocument docType) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'], // Erlaubte Dateitypen
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final extension = file.extension != null ? '.${file.extension}' : '';
      final Uint8List fileData = file.bytes ?? await File(file.path!).readAsBytes();
      final downloadUrl = await uploadFileToStorage(fileData, extension, docType);
      if (downloadUrl != null) {
        requiredDocsStatus.value = {
          ...requiredDocsStatus.value,
          docType: true
        };
      }
    }
  }

  Future<void> _takePhoto(RequiredDocument docType) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final downloadUrl = await uploadFileToStorage(bytes, '.jpg', docType);
        if (downloadUrl != null) {
          requiredDocsStatus.value = {
            ...requiredDocsStatus.value,
            docType: true
          };
        }

        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fotoaufnahme abgebrochen.')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Aufnehmen des Fotos: $e')),
      );
    }
  }

  Future<void> _uploadPhoto(RequiredDocument docType) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final extension = file.extension != null ? '.${file.extension}' : '';
        final Uint8List fileData = file.bytes ?? await File(file.path!).readAsBytes();
        final downloadUrl = await uploadFileToStorage(fileData, extension, docType);
        if (downloadUrl != null) {
          requiredDocsStatus.value = {
            ...requiredDocsStatus.value,
            docType: true
          };
        }
        if (allDocsDone()) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kein Bild ausgewählt.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hochladen des Bildes: $e')),
      );
    }
  }

  Future<String?> uploadFileToStorage(Uint8List fileData, String extension, RequiredDocument document) async {
    if (customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kunde nicht gefunden.')),
      );
      return null;
    }

    try {
      final storagePath = 'documents/${customer!.id}/${document.name}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = await storageRef.putData(fileData);

      customer!.documents[document] = storagePath;
      requiredDocsStatus.value[document] = true;

      await FirestorePathsService.getCustomerDoc(customerId: customer!.id).update({
        'documents': customer!.documents.map((key, value) => MapEntry(key.name, value)),
      });

      setState(() {});

      return storagePath;
    } catch (e) {
      print('Fehler beim Hochladen der Datei: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Upload: $e')),
      );
      return null;
    }
  }

}


class TrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = SignScreen.backgroundColor
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, 0); // Start
    path.lineTo(size.width, 0); // Top right
    path.lineTo(size.width, size.height); // Bottom right
    path.close(); // Returns to start

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}