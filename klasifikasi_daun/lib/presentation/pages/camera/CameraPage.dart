import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:klasifikasi_daun/presentation/pages/home/preview/preview_page.dart';
import 'package:klasifikasi_daun/presentation/widgets/custom_Loading_widget.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key, required this.cameras}) : super(key: key);

  final List<CameraDescription> cameras;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  bool _isRearCameraSelected = true;
  final ImagePicker _picker = ImagePicker(); 
  bool _isLoading = false;

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Menginisialisasi kamera pertama
    initCamera(widget.cameras[0]);
  }

  Future takePicture() async {
    if (!_cameraController.value.isInitialized) {
      return null;
    }
    if (_cameraController.value.isTakingPicture) {
      return null;
    }
    try {
      setState((){
        _isLoading = true;
      });
      await _cameraController.setFlashMode(FlashMode.off);
      XFile picture = await _cameraController.takePicture();
      // Setelah foto diambil, navigasi ke halaman preview
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewPage(picture: picture),
        ),
      ).then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    } on CameraException catch (e) {
      debugPrint('Error occured while taking picture: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal ambil gambar: ${e.description}'))
      );
    }
  }

  Future initCamera(CameraDescription cameraDescription) async {
    _cameraController =
        CameraController(cameraDescription, ResolutionPreset.high);
    try {
      await _cameraController.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      });
    } on CameraException catch (e) {
      debugPrint("camera error $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal Inisialisasi camera: ${e.description}'))
      );
    }
  }

  // Fungsi untuk memilih gambar dari galeri
  Future pickImageFromGallery() async {
    setState(() {
      _isLoading = true;
    });
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewPage(picture: pickedFile),
        ),
      ).then((_){
        setState(() {
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            (_cameraController.value.isInitialized)
                ? CameraPreview(_cameraController)
                : Container(
                    color: Colors.black,
                    child: const Center(child: CircularProgressIndicator())),
            Align(
              alignment: Alignment.center,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withOpacity(0.8),
                    width: 2,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.20,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  color: Colors.black,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 40,
                      icon: Icon(
                        _isRearCameraSelected
                            ? Icons.switch_camera
                            : Icons.switch_camera_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() =>
                            _isRearCameraSelected = !_isRearCameraSelected);
                        initCamera(
                            widget.cameras![_isRearCameraSelected ? 0 : 1]);
                      },
                    ),
                    IconButton(
                      onPressed: takePicture,
                      iconSize: 80,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.circle, color: Colors.white),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 40,
                      icon: Icon(
                        _isRearCameraSelected
                            ? Icons.image
                            : Icons.image_outlined,
                        color: Colors.white,
                      ),
                      onPressed:
                          pickImageFromGallery, // Panggil fungsi untuk memilih gambar dari galeri
                    ),
                  ],
                ),
              ),
            ),
            if(_isLoading)
            const LoadingWidget(
              message: "Menganalisa daun, Mohon tunggu..",
            )
          ],
        ),
      ),
    );
  }
}
