import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/face_recognition_service.dart';


class FaceRegisterScreen extends StatefulWidget {
  final UserModel user;

  const FaceRegisterScreen({super.key, required this.user});

  @override
  State<FaceRegisterScreen> createState() => _FaceRegisterScreenState();
}

class _FaceRegisterScreenState extends State<FaceRegisterScreen> {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isCameraError = false;
  final List<String> _capturedFaceData = [];
  final int _maxCaptures = 3;
  final FaceRecognitionService _faceService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _isCameraError = true);
        return;
      }

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      setState(() => _isCameraError = true);
    }
  }

  Future<void> _captureAndProcess() async {
    if (_isCapturing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      final embedding = _faceService.generateFaceEmbedding(imageBytes);

      if (embedding.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No face detected. Please try again.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        setState(() => _isCapturing = false);
        return;
      }

      final embeddingStr = _faceService.embeddingToString(embedding);
      _capturedFaceData.add(embeddingStr);

      if (mounted) {
        setState(() => _isCapturing = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Face sample ${_capturedFaceData.length}/$_maxCaptures captured',
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _saveFaceData() async {
    if (_capturedFaceData.isEmpty) return;

    final userProvider = context.read<UserProvider>();
    final auth = context.read<AuthProvider>();

    final success = await userProvider.updateFaceData(
      widget.user.id,
      _capturedFaceData,
      updatedBy: auth.currentUser?.id,
    );

    if (success && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppTheme.successColor, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Face Registered!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_capturedFaceData.length} face samples saved for ${widget.user.name}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Dialog
                    Navigator.pop(context); // Screen
                  },
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _buildTopBar(),

            // Camera preview
            Expanded(child: _buildCameraView()),

            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Register Face',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.user.name,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    if (_isCameraError) {
      return Container(
        color: AppTheme.scaffoldDark,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_off_rounded,
                  color: AppTheme.textTertiary, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera not available',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return Container(
        color: AppTheme.scaffoldDark,
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );
    }

    return Stack(
      children: [
        CameraPreview(_cameraController!),
        // Face guide overlay
        CustomPaint(
          size: Size.infinite,
          painter: FaceGuideOverlayPainter(),
        ),
        // Instructions
        Positioned(
          top: 40,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _capturedFaceData.isEmpty
                    ? 'Look straight at the camera'
                    : _capturedFaceData.length < _maxCaptures
                        ? 'Slightly turn your head and capture again'
                        : 'All samples captured!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.black,
      child: Column(
        children: [
          // Progress indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_maxCaptures, (index) {
              final isCaptured = index < _capturedFaceData.length;
              return Container(
                width: 50,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isCaptured
                      ? AppTheme.successColor
                      : Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Text(
            '${_capturedFaceData.length}/$_maxCaptures samples captured',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          if (_capturedFaceData.length >= _maxCaptures)
            // Save button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveFaceData,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Face Data',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Capture button
                GestureDetector(
                  onTap: _isCapturing ? null : _captureAndProcess,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isCapturing
                              ? Colors.grey
                              : AppTheme.primaryColor,
                        ),
                        child: _isCapturing
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          
          if (_capturedFaceData.isNotEmpty && _capturedFaceData.length < _maxCaptures) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: _saveFaceData,
              child: const Text('Save with current samples'),
            ),
          ],
        ],
      ),
    );
  }
}

class FaceGuideOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 20);
    final ovalWidth = size.width * 0.6;
    final ovalHeight = ovalWidth * 1.35;

    final bgPaint = Paint()..color = Colors.black.withValues(alpha: 0.3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    canvas.drawOval(ovalRect, clearPaint);
    canvas.restore();

    final borderPaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawOval(ovalRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
