import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:io';
import 'dart:io' as Io;
import 'dart:ui';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart'; // For File Upload To Firestore
import 'package:path/path.dart' as Path;


class DetailScreen extends StatefulWidget {
  final String imagePath;
  DetailScreen(this.imagePath);

  @override
  _DetailScreenState createState() => new _DetailScreenState(imagePath);
}

class _DetailScreenState extends State<DetailScreen> {
  _DetailScreenState(this.path);

  final String path;
  String _imageString;
  Size _imageSize;
  List<TextElement> _elements = [];
  String recognizedText = "Your order is being processed. You will recieve an email with a link to your order in a moment!";
  String _uploadedFileURL;

  void _initializeVision() async {
    final File imageFile = File(path);

    if (imageFile != null) {
      await _getImageSize(imageFile);
      await uploadFile(imageFile);
    }

    print(_uploadedFileURL);

    String body = """{
                        "requests": [
                          {
                            "image": {
                              "source":{
                                "imageUri":
                                  "${_uploadedFileURL}"
                              }
                            },
                            "features": [
                              {
                                "type": "DOCUMENT_TEXT_DETECTION",
                                "maxResults": 1
                              }
                            ]
                          }
                        ]
                      }""";

    http.Response res = await http.post(
        "https://vision.googleapis.com/v1/images:annotate?key=PUBLIC_API_KEY_HERE",
        body: body
    );

    var data = json.decode(res.body);

    var myResponse = data["responses"][0]["textAnnotations"][0]["description"];

    String groceryList = "${myResponse}";
    print(myResponse);



    List items = [];
    List quantities = [];
    LineSplitter ls = new LineSplitter();
    List<String> lines = ls.convert(groceryList);
    for (var i = 0; i < lines.length; i++) {
      var string = "${lines[i]}";
      var mine = string.split(" ");
      items.add(mine[1]);
      quantities.add(mine[0]);
    }

    String im = "";
    String done = "";
    for (var j = 0; j < items.length; j++){
      if(j==items.length-1){
        im+="${items[j]}";
        done+="${quantities[j]}";
      }
      else{
        im+="${items[j]}"+"~";
        done+="${quantities[j]}"+"~";
      }
    }

    String bodyFlask = """{"item_list" : "${im}","quantity_list" : "${done}"}""";

    String flask_url = "LINK_TO_SERVER_HERE";
    // Our other post request goes here
    http.Response resFlask = await http.post(
        flask_url,
        headers: {"Content-Type": "application/json"},
        body: bodyFlask
    );

    var dataFlask = json.decode(resFlask.body);
    print("${dataFlask}");

    if (this.mounted) {
      setState(() {
        recognizedText = groceryList;
      });
    }
  }

  Future uploadFile(File imageFile) async {
    StorageReference storageReference = FirebaseStorage.instance
        .ref()
        .child('groceryLists/${Path.basename(imageFile.path)}}');
    StorageUploadTask uploadTask = storageReference.putFile(imageFile);
    await uploadTask.onComplete;
    print('File Uploaded');
    StorageTaskSnapshot taskSnapshot = await uploadTask.onComplete;
    String downloadUrl = await taskSnapshot.ref.getDownloadURL();

    setState(() {
      _uploadedFileURL = downloadUrl;
    });

  }

  Future<void> _getImageSize(File imageFile) async {
    final Completer<Size> completer = Completer<Size>();

    final Image image = Image.file(imageFile);
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(Size(
          info.image.width.toDouble(),
          info.image.height.toDouble(),
        ));
      }),
    );

    final bytes = await Io.File(path).readAsBytesSync();
    String img64 = base64Encode(bytes);
    print(path);

    final Size imageSize = await completer.future;
    setState(() {
      _imageSize = imageSize;
      _imageString = img64;
    });
  }

  @override
  void initState() {
    _initializeVision();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Auto Grocer"),
      ),
      body: _imageSize != null
          ? Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: double.maxFinite,
              color: Colors.black,
              child: CustomPaint(
                foregroundPainter:
                TextDetectorPainter(_imageSize, _elements),
                child: AspectRatio(
                  aspectRatio: _imageSize.aspectRatio,
                  child: Image.file(
                    File(path),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Card(
              elevation:20,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "Grocery List",
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      height: 140,
                      child: SingleChildScrollView(
                        child: Text(
                          recognizedText,
                          style: TextStyle(
                            fontSize: 25,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      )
          : Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class TextDetectorPainter extends CustomPainter {
  TextDetectorPainter(this.absoluteImageSize, this.elements);

  final Size absoluteImageSize;
  final List<TextElement> elements;

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / absoluteImageSize.width;
    final double scaleY = size.height / absoluteImageSize.height;

    Rect scaleRect(TextContainer container) {
      return Rect.fromLTRB(
        container.boundingBox.left * scaleX,
        container.boundingBox.top * scaleY,
        container.boundingBox.right * scaleX,
        container.boundingBox.bottom * scaleY,
      );
    }

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = 2.0;

    for (TextElement element in elements) {
      canvas.drawRect(scaleRect(element), paint);
    }
  }

  @override
  bool shouldRepaint(TextDetectorPainter oldDelegate) {
    return true;
  }
}
