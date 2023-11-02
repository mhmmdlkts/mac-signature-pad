import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:hand_signature/signature.dart';
import 'package:macsignaturepad/decoration/colors.dart';
import 'package:macsignaturepad/models/customer.dart';
import 'package:macsignaturepad/screens/pdf_viewer_screen.dart';
import 'package:macsignaturepad/services/firebase_service.dart';
import 'package:macsignaturepad/services/storage_service.dart';

import '../services/pdf_service.dart';


class SignScreen extends StatefulWidget {
  const SignScreen({super.key});
  static const backgroundColor = Color(0xFFDCDFE5);

  @override
  State<SignScreen> createState() => _SignScreenState();
}

class _SignScreenState extends State<SignScreen> with SingleTickerProviderStateMixin{

  late final AnimationController doneController;
  bool showDone = false;
  bool get isDrowen => control.isFilled;
  double padding = 20;
  double paddingBetweenPdfs = 40;
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

    token = Uri.base.queryParameters["token"];
    if (token == null) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    } else {
      initToken(token!);
    }

    doneController = AnimationController(vsync: this);
  }

  Future initToken(String token) async {
    Response response = await Dio().get(
      FirebaseService.getUri('getUserData').toString(),
      queryParameters: {'token': token},
    );
    if (response.statusCode == 200) {
      customer = Customer.fromJson(response.data, response.data['id']);
    } else {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  Future sendSignature() async {
    String signature = const Base64Encoder().convert(rawImageFit.value!.buffer.asUint8List());

    Uint8List vollmachtPdf = await PdfService.createVollmachtPDF(customer: customer!, signature: signature, version: currentVollmachtVersion);
    String vollmachtPdfUrl = await StorageService.uploadPdf(vollmachtPdf, customer!.id, 'vollmacht_$currentVollmachtVersion.pdf');
    showBadge['vollmacht']!.value = 2;
    Uint8List bprotokollPdf = await PdfService.createBeratungsprotokolPDF(customer: customer!, signature: signature, version: currentBprotokollVersion);
    String bprotokollPdfUrl = await StorageService.uploadPdf(bprotokollPdf, customer!.id, 'bprotokoll_$currentBprotokollVersion.pdf');
    showBadge['beratungsprotokoll']!.value = 2;


    Response response = await Dio().post(
      FirebaseService.getUri('signPds').toString(),
      data: {
        'token': token,
        'userId': customer!.id,
        'signature': signature,
        'vollmachtVersion': currentVollmachtVersion,
        'bprotokollVersion': currentBprotokollVersion,
        'bprotokollPdfUrl': bprotokollPdfUrl,
        'vollmachtPdfUrl': vollmachtPdfUrl,
        'advisorId': customer!.advisorId,
        'advisorName': customer!.advisorName,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        showDone = true;
      });
    } else {
      print('Error: ${response.statusCode}');
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
                Text('Vielen Dank',
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
                              Text(
                                'MAC Agentur',
                                style: TextStyle(
                                  color: Colors.black.withOpacity(0.85),
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: pdfs.map((e) => _pdfWidget(e, bottom: 7, right: 7)).toList(),
                              ),
                              Expanded(
                                child: Container(),
                              ),
                              Padding(
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
                  if (signLoading.value || true)
                    Positioned.fill(
                      child: Container(
                        color: SignScreen.backgroundColor.withOpacity(0.2),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Center(
                                child: CircularProgressIndicator(color: firstColor),
                              ),
                              Container(width:20),
                              Text('Bitte warten...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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

  Widget _customSignButton() {
    BorderRadius radius = BorderRadius.circular(10);
    return ValueListenableBuilder(
      valueListenable: rawImageFit,
      builder: (context, value, child) => ValueListenableBuilder(
        valueListenable: signLoading,
        builder: (context, data, child) {
          bool isDisabled = rawImageFit.value==null||signLoading.value;
          return Container(
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
                        padding: EdgeInsets.all(10),
                        child: Text('Unterschreiben', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
    double offset = 1;
    double margin = 10;
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
                      child: Lottie.asset(badgeVal==1?'assets/badge_grey.json':'assets/badge.json', width: 50),
                      bottom: -5,
                      right: 40,
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
                            constraints: BoxConstraints.expand(),
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
                                icon: Icon(Icons.clear),
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

  Widget _getSignatureImage() => Container(
      width: 50,
      height: 25,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black, width: 0.25),
      ),
      child: Center(
          child: CustomPaint(
            painter: DebugSignaturePainterCP(
              control: control,
            ),
          ),
      )
  );

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
          return Container(
            child: Image.memory(data.buffer.asUint8List()),
          );
        }
      },
    ),
  );

  Future openPdf(String name) async {
    if (customer == null) {
      return;
    }
    String? signature = rawImageFit?.value!=null? (Base64Encoder().convert(rawImageFit.value!.buffer.asUint8List())):null;
    Uint8List? pdf;
    if (name.toLowerCase() == 'vollmacht') {
      pdf = await PdfService.createVollmachtPDF(customer: customer!, signature: signature, version: currentVollmachtVersion);
    } else if (name.toLowerCase() == 'beratungsprotokoll') {
      pdf = await PdfService.createBeratungsprotokolPDF(customer: customer!, signature: signature, version: currentBprotokollVersion);
    }



    if (pdf == null) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(pdfBytes: pdf!),
      ),
    );
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