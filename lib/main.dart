import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:useness/constants.dart';
import 'package:useness/picture_screen.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final backCamera = cameras.first;
  final frontCamera = cameras.last;
  runApp(
    MaterialApp(
      home: HomePage(
        backCamera: backCamera,
        frontCamera: frontCamera,
      ),
      theme: ThemeData(
        fontFamily: "Work",
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  final CameraDescription frontCamera;
  final CameraDescription backCamera;

  const HomePage({
    Key? key,
    required this.frontCamera,
    required this.backCamera,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  bool isfront = false;

  initCameraControllar(CameraDescription camera) {
    _controller = CameraController(
      camera,
      ResolutionPreset.veryHigh,
    );
    _initializeControllerFuture = _controller.initialize();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    initCameraControllar(widget.backCamera);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int flashmode = 0;
  IconData flashicon = Icons.lightbulb_outline;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary3,
      appBar: AppBar(
        backgroundColor: primary3,
        title: const Text(
          "USENESS",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: primary1,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                SizedBox(
                  child: CameraPreview(_controller),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20.0, 20, 20, 40),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FloatingActionButton(
                          backgroundColor: primary2,
                          onPressed: () {
                            isfront = !isfront;
                            isfront
                                ? initCameraControllar(widget.frontCamera)
                                : initCameraControllar(widget.backCamera);
                          },
                          child: const Icon(
                            Icons.repeat,
                            color: accent,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.all(primary1),
                              shape: MaterialStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25.0),
                                ),
                              ),
                            ),
                            onPressed: () async {
                              try {
                                print(isfront);
                                await _initializeControllerFuture;
                                var image = await _controller.takePicture();
                                if (isfront == true) {
                                  var correctedimage =
                                      await FlutterExifRotation.rotateImage(
                                          path: image.path);
                                  image = XFile(correctedimage.path);
                                }
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (context) {
                                    return DisplayPictureScreen(
                                      imagePath: image.path,
                                    );
                                  }),
                                );
                              } catch (e) {
                                print(e);
                              }
                            },
                            child: const Icon(
                              Icons.camera_alt,
                              size: 35,
                              color: accent,
                            ),
                          ),
                        ),
                        FloatingActionButton(
                          backgroundColor: primary2,
                          onPressed: () async {
                            setState(() {
                              flashmode++;
                              switch (flashmode) {
                                case 0:
                                  _controller.setFlashMode(FlashMode.off);
                                  flashicon = Icons.lightbulb_outline;
                                  break;
                                case 1:
                                  _controller.setFlashMode(FlashMode.always);
                                  flashicon = Icons.lightbulb;
                                  break;
                                case 2:
                                  flashmode = 0;
                                  _controller.setFlashMode(FlashMode.off);
                                  flashicon = Icons.lightbulb_outline;
                                  break;
                              }
                              print(flashmode);
                            });
                          },
                          child: Icon(
                            flashicon,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(
                child: SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                color: primary1,
                strokeWidth: 10,
              ),
            ));
          }
        },
      ),
    );
  }
}
