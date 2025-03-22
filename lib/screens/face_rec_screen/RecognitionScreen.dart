import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({Key? key}) : super(key: key);

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  late ImagePicker imagePicker;
  File? _image;

  late FaceDetector faceDetector;
  late Recognizer recognizer;

  ui.Image? image; // الصورة لعرضها في الواجهة

  List<Face> faces = [];

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    );
    faceDetector = FaceDetector(options: options);

    recognizer = Recognizer();
  }

  // التقاط صورة باستخدام الكاميرا
  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      final data = await _image!.readAsBytes();
      ui.decodeImageFromList(data, (ui.Image img) {
        setState(() {
          image = img; // تهيئة الصورة لعرضها
          doFaceDetection();
        });
      });
    }
  }

  // التقاط صورة من المعرض
  _imgFromGallery() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _image = File(pickedFile.path);
      final data = await _image!.readAsBytes();
      ui.decodeImageFromList(data, (ui.Image img) {
        setState(() {
          image = img; // تهيئة الصورة لعرضها
          doFaceDetection();
        });
      });
    }
  }

  // دالة الكشف عن الوجوه
  doFaceDetection() async {
    // إزالة دوران الصورة قبل الكشف
    await removeRotation(_image!);

    InputImage inputImage = InputImage.fromFile(_image!);

    // تمرير الصورة إلى كاشف الوجوه والحصول على الوجوه المكتشفة
    faces = await faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      for (Face face in faces) {
        cropAndRegisterFace(face.boundingBox);
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("No faces detected")));
    }
  }

  // قص الوجه واستخراج الـ embedding وإظهار النتيجة
  cropAndRegisterFace(Rect boundingBox) {
    num left = boundingBox.left < 0 ? 0 : boundingBox.left;
    num top = boundingBox.top < 0 ? 0 : boundingBox.top;
    num right =
    boundingBox.right > image!.width ? image!.width - 1 : boundingBox.right;
    num bottom = boundingBox.bottom > image!.height
        ? image!.height - 1
        : boundingBox.bottom;
    num width = right - left;
    num height = bottom - top;

    final bytes = _image!.readAsBytesSync();
    img.Image? faceImg = img.decodeImage(bytes);
    img.Image croppedFace = img.copyCrop(
      faceImg!,
      x: left.toInt(),
      y: top.toInt(),
      width: width.toInt(),
      height: height.toInt(),
    );

    // استدعاء الدالة التي تنفذ عملية التعرف على الوجه
    Recognition recognition = recognizer.recognize(croppedFace, boundingBox);

    // عرض النتيجة مع إمكانية إعادة التسجيل في حال النتيجة ضعيفة أو خاطئة
    showRecognitionResultDialog(
      Uint8List.fromList(img.encodeBmp(croppedFace)),
      recognition,
    );
  }

  // دالة إزالة دوران الصورة (تعدل الصورة على الملف)
  removeRotation(File inputImage) async {
    final img.Image? capturedImage =
    img.decodeImage(await File(inputImage.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  // دالة عرض نتيجة التعرف مع إضافة خيار "Register Again" لإعادة التسجيل
  showRecognitionResultDialog(Uint8List croppedFace, Recognition recognition) {
    // يمكن إضافة شرط على التشابه هنا إذا توافرت قيمة عتبة (threshold)
    bool isRecognized = recognition.name.isNotEmpty; // أو إضافة شرط للتأكد من تشابه عالي

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          "Recognition Result",
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(croppedFace, width: 200, height: 200),
            const SizedBox(height: 10),
            Text(
              isRecognized
                  ? "Student: ${recognition.name}\nSimilarity: ${recognition.distance.toStringAsFixed(2)}"
                  : "Face not recognized or similarity is low. Please register again.",
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          // زر "OK" لإغلاق النافذة
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            child: const Text("OK"),
          ),
          // زر "Register Again" لإعادة التسجيل وتصحيح الاسم
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              // فتح نافذة التسجيل مع إرسال الوجه المقصوص
              showFaceRegistrationDialogue(croppedFace, recognition);
            },
            child: const Text("Register Again"),
          ),
        ],
      ),
    );
  }

  // دالة عرض حوار التسجيل لتصحيح الاسم وإعادة التسجيل
  TextEditingController textEditingController = TextEditingController();
  showFaceRegistrationDialogue(Uint8List croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.memory(croppedFace, width: 200, height: 200),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    hintText: "Enter Name",
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  recognizer.registerFaceInDB(
                    textEditingController.text,
                    recognition.embeddings,
                  );
                  textEditingController.text = "";
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Face Registered")),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(200, 40),
                ),
                child: const Text("Register"),
              ),
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _image != null && image != null
              ? Container(
            margin: const EdgeInsets.only(
              top: 60,
              left: 30,
              right: 30,
              bottom: 0,
            ),
            child: FittedBox(
              child: SizedBox(
                width: image!.width.toDouble(),
                height: image!.width.toDouble(),
                child: CustomPaint(
                  painter: FacePainter(facesList: faces, imageFile: image),
                ),
              ),
            ),
          )
              : Container(
            margin: const EdgeInsets.only(top: 100),
            child: Image.asset(
              "images/logo.png",
              width: screenWidth - 100,
              height: screenWidth - 100,
            ),
          ),
          Container(height: 50),
          // قسم عرض أزرار التقاط الصور
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(200)),
                  ),
                  child: InkWell(
                    onTap: () {
                      _imgFromGallery();
                    },
                    child: SizedBox(
                      width: screenWidth / 2 - 70,
                      height: screenWidth / 2 - 70,
                      child: Icon(
                        Icons.image,
                        color: Colors.blue,
                        size: screenWidth / 7,
                      ),
                    ),
                  ),
                ),
                Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(200)),
                  ),
                  child: InkWell(
                    onTap: () {
                      _imgFromCamera();
                    },
                    child: SizedBox(
                      width: screenWidth / 2 - 70,
                      height: screenWidth / 2 - 70,
                      child: Icon(
                        Icons.camera,
                        color: Colors.blue,
                        size: screenWidth / 7,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Face> facesList;
  ui.Image? imageFile;
  FacePainter({required this.facesList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile!, Offset.zero, Paint());
    }
    Paint p = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (Face face in facesList) {
      canvas.drawRect(face.boundingBox, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
