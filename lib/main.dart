import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription>? cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MaterialApp(
    home: MainApp(),
  ));
}

class MainApp extends StatefulWidget {
  const MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  bool isWorking = false;
  String result = "";

  initCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) return;
      setState(() {
        cameraController!.startImageStream((image) {
          if (!isWorking) {
            isWorking = true;
            cameraImage = image;
            runModelOnFrame();
          }
        });
      });
    });
  }

  runModelOnFrame() async {
    if (cameraImage != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: cameraImage!.planes.map((e) => e.bytes).toList(),
          imageHeight: cameraImage!.height,
          imageWidth: cameraImage!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 1,
          threshold: 0.1,
          asynch: true);
      result = "";
      recognitions!.forEach((reponose) {
        result += reponose["label"] + "\n";
      });
      setState(() {
        result;
      });
      isWorking = false;
    }
  }

  loadModel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/label.txt");
  }

  @override
  void initState() {
    super.initState();
    initCamera();
    loadModel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(result)),
      body: Column(
        children: [
          //top
          SizedBox(
            height: MediaQuery.of(context).size.height - 80,
            width: MediaQuery.of(context).size.width,
            child: Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: (!cameraController!.value.isInitialized)
                    ? Container()
                    : AspectRatio(
                        aspectRatio: cameraController!.value.aspectRatio,
                        child: CameraPreview(cameraController!),
                      )),
          )
        ],
      ),
    );
  }
}
