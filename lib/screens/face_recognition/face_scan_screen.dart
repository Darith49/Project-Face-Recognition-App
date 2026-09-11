import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance_model.dart';
import '../../services/face_recognition_service.dart';
import '../../widgets/glass_card.dart';

class FaceScanScreen extends StatefulWidget {
  const FaceScanScreen({super.key});

  @override
  State<FaceScanScreen> createState() => _FaceScanScreenState();
}

class _FaceScanScreenState extends State<FaceScanScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isCameraError = false;
  String _statusMessage = 'Position your face in the frame';
  String _selectedType = 'Check-in';
  String? _matchedUserName;
  String? _matchedUserId;
  double? _confidenceScore;
  bool _scanComplete = false;
  final FaceRecognitionService _faceService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _isCameraError = true;
          _statusMessage = 'No camera found on device';
        });
        return;
      }

      // Prefer front camera
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
      setState(() {
        _isCameraError = true;
        _statusMessage = 'Camera initialization failed';
      });
    }
  }

  Future<void> _captureFace() async {
    if (_isProcessing ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyzing face...';
    });

    try {
      final image = await _cameraController!.takePicture();
      final imageBytes = await image.readAsBytes();

      // Generate face embedding
      final embedding = _faceService.generateFaceEmbedding(imageBytes);

      if (embedding.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'No face detected. Please try again.';
        });
        return;
      }

      if (!mounted) return;

      // Load all users with face data
      final userProvider = context.read<UserProvider>();
      await userProvider.loadUsers();
      final usersWithFace =
          userProvider.users.where((u) => u.hasFaceData).toList();

      if (usersWithFace.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage =
              'No registered faces found. Please register first.';
        });
        return;
      }

      // Build face data map
      final faceDataMap = <String, List<String>>{};
      for (final user in usersWithFace) {
        faceDataMap[user.id] = user.faceData;
      }

      // Find best match
      final match = _faceService.findBestMatch(
        embedding,
        faceDataMap,
        AppConstants.faceMatchThreshold,
      );

      if (match != null) {
        HapticFeedback.heavyImpact();
        final matchedUser =
            usersWithFace.firstWhere((u) => u.id == match.key);
        setState(() {
          _matchedUserName = matchedUser.name;
          _matchedUserId = matchedUser.id;
          _confidenceScore = match.value;
          _statusMessage = 'Face matched! ${matchedUser.name}';
          _scanComplete = true;
          _isProcessing = false;
        });
      } else {
        setState(() {
          _isProcessing = false;
          _statusMessage =
              'Face not recognized. Please try again or register.';
        });
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _recordAttendance() async {
    if (_matchedUserId == null) return;

    final userProvider = context.read<UserProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();
    final auth = context.read<AuthProvider>();

    final user = await userProvider.getUserById(_matchedUserId!);
    if (user == null) return;

    final now = DateTime.now();
    final record = AttendanceModel(
      id: const Uuid().v4(),
      odlUserId: user.id,
      userId: user.userId,
      userName: user.name,
      type: _selectedType,
      status:
          _selectedType == 'Check-in' ? _determineStatus(now) : 'Present',
      dateTime: now,
      date: DateFormat('yyyy-MM-dd').format(now),
      time: DateFormat('HH:mm:ss').format(now),
      verified: true,
      confidenceScore: _confidenceScore,
      notes: 'Face recognition verified',
      createdAt: now,
    );

    final success = await attendanceProvider.recordAttendance(
      record,
      recordedBy: auth.currentUser?.id ?? user.id,
    );

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      _showSuccessDialog(user.name, record);
    }
  }

  String _determineStatus(DateTime now) {
    final hour = now.hour;
    final minute = now.minute;

    if (hour < 8 || (hour == 8 && minute <= 15)) {
      return 'Present';
    } else if (hour < 9) {
      return 'Late';
    }
    return 'Present';
  }

  void _showSuccessDialog(String userName, AttendanceModel record) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.cardDark,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Attendance Recorded!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                userName,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${record.type} • ${record.status}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              Text(
                DateFormat('dd MMM yyyy • hh:mm a')
                    .format(record.dateTime),
                style: const TextStyle(
                  color: AppTheme.textTertiary,
                  fontSize: 12,
                ),
              ),
              if (_confidenceScore != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Confidence: ${(_confidenceScore! * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: AppTheme.accentColor,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _resetScan();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                            color: AppTheme.primaryColor, width: 0.5),
                        padding: const EdgeInsets.symmetric(
                            vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Scan Again',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 11),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _resetScan() {
    setState(() {
      _isProcessing = false;
      _scanComplete = false;
      _matchedUserName = null;
      _matchedUserId = null;
      _confidenceScore = null;
      _statusMessage = 'Position your face in the frame';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview
            Positioned.fill(child: _buildCameraView()),

            // Overlay
            Positioned.fill(
              child: RepaintBoundary(child: _buildOverlay()),
            ),

            // Top bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(),
            ),

            // Bottom controls
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildBottomControls(),
            ),
          ],
        ),
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
                  color: AppTheme.textTertiary, size: 56),
              const SizedBox(height: 14),
              Text(
                _statusMessage,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _initCamera,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry', style: TextStyle(fontSize: 13)),
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: AppTheme.primaryColor, strokeWidth: 2.5),
              SizedBox(height: 14),
              Text(
                'Initializing camera...',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }

  Widget _buildOverlay() {
    return CustomPaint(
      painter: FaceOverlayPainter(
        isProcessing: _isProcessing,
        isMatched: _scanComplete,
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Face Scan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          // Type toggle
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: ['Check-in', 'Check-out'].map((type) {
                final isSelected = _selectedType == type;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedType = type);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 5),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      type == 'Check-in' ? 'In' : 'Out',
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.75),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status message
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: _scanComplete
                  ? AppTheme.successColor.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: _scanComplete
                  ? Border.all(
                      color: AppTheme.successColor
                          .withValues(alpha: 0.2))
                  : null,
            ),
            child: Text(
              _statusMessage,
              style: TextStyle(
                color: _scanComplete
                    ? AppTheme.successColor
                    : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 22),

          if (_scanComplete && _matchedUserName != null) ...[
            // Match result card
            GlassCard(
              padding: const EdgeInsets.all(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2A1A), Color(0xFF142014)],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppTheme.successColor
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(Icons.face_rounded,
                        color: AppTheme.successColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          _matchedUserName!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(_confidenceScore! * 100).toStringAsFixed(1)}% match',
                          style: const TextStyle(
                            color: AppTheme.successColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _resetScan,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: Colors.white38, width: 0.5),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: const Text('Retry',
                        style: TextStyle(
                            color: Colors.white, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _recordAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                    child: Text('Confirm $_selectedType',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Capture button
            GestureDetector(
              onTap: _isProcessing ? null : _captureFace,
              child: Container(
                width: 70,
                height: 70,
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
                      color: _isProcessing
                          ? Colors.grey.shade700
                          : AppTheme.primaryColor,
                    ),
                    child: _isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons
                                .face_retouching_natural_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class FaceOverlayPainter extends CustomPainter {
  final bool isProcessing;
  final bool isMatched;

  FaceOverlayPainter({
    required this.isProcessing,
    required this.isMatched,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 40);
    final ovalWidth = size.width * 0.65;
    final ovalHeight = ovalWidth * 1.35;

    // Draw dim background
    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Clear oval area
    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.saveLayer(
        Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    canvas.drawOval(ovalRect, clearPaint);
    canvas.restore();

    // Draw oval border
    final borderColor = isMatched
        ? const Color(0xFF00D4AA)
        : isProcessing
            ? const Color(0xFFFFB946)
            : const Color(0xFF7C6BFF);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawOval(ovalRect, borderPaint);

    // Draw corner guides
    final guidePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final guideLength = 28.0;
    final corners = [
      [
        Offset(center.dx - ovalWidth / 2 + 10,
            center.dy - ovalHeight / 2 + guideLength),
        Offset(center.dx - ovalWidth / 2 + 10,
            center.dy - ovalHeight / 2 + 10),
      ],
      [
        Offset(center.dx + ovalWidth / 2 - 10,
            center.dy - ovalHeight / 2 + guideLength),
        Offset(center.dx + ovalWidth / 2 - 10,
            center.dy - ovalHeight / 2 + 10),
      ],
      [
        Offset(center.dx - ovalWidth / 2 + 10,
            center.dy + ovalHeight / 2 - guideLength),
        Offset(center.dx - ovalWidth / 2 + 10,
            center.dy + ovalHeight / 2 - 10),
      ],
      [
        Offset(center.dx + ovalWidth / 2 - 10,
            center.dy + ovalHeight / 2 - guideLength),
        Offset(center.dx + ovalWidth / 2 - 10,
            center.dy + ovalHeight / 2 - 10),
      ],
    ];

    for (final corner in corners) {
      canvas.drawLine(corner[0], corner[1], guidePaint);
    }
  }

  @override
  bool shouldRepaint(covariant FaceOverlayPainter oldDelegate) {
    return oldDelegate.isProcessing != isProcessing ||
        oldDelegate.isMatched != isMatched;
  }
}
