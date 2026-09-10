import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class FaceRecognitionService {
  static final FaceRecognitionService _instance = FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  /// Generate a simple face embedding from image bytes.
  /// This uses pixel sampling as a lightweight face descriptor.
  /// In production, you would use ML Kit or TFLite for real embeddings.
  List<double> generateFaceEmbedding(Uint8List imageBytes) {
    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) return [];

      // Resize to a standard size for consistent embeddings
      final resized = img.copyResize(image, width: 64, height: 64);

      // Generate a 128-dimensional embedding by sampling pixel values
      final embedding = <double>[];
      final step = (64 * 64) ~/ 128;

      for (int i = 0; i < 128; i++) {
        final pixelIndex = (i * step) % (64 * 64);
        final x = pixelIndex % 64;
        final y = pixelIndex ~/ 64;
        final pixel = resized.getPixel(x, y);

        // Normalize pixel values to 0-1 range
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;

        // Create a combined value
        embedding.add((r * 0.3 + g * 0.59 + b * 0.11));
      }

      // Normalize the embedding vector
      final norm = sqrt(embedding.fold(0.0, (sum, v) => sum + v * v));
      if (norm > 0) {
        for (int i = 0; i < embedding.length; i++) {
          embedding[i] /= norm;
        }
      }

      return embedding;
    } catch (e) {
      return [];
    }
  }

  /// Compare two face embeddings and return a similarity score (0-1)
  double compareFaces(List<double> embedding1, List<double> embedding2) {
    if (embedding1.isEmpty || embedding2.isEmpty) return 0.0;
    if (embedding1.length != embedding2.length) return 0.0;

    // Cosine similarity
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    if (norm1 == 0 || norm2 == 0) return 0.0;

    final similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));
    return similarity.clamp(0.0, 1.0);
  }

  /// Convert face embedding to a storable string
  String embeddingToString(List<double> embedding) {
    return base64Encode(
      Float64List.fromList(embedding).buffer.asUint8List(),
    );
  }

  /// Convert stored string back to face embedding
  List<double> stringToEmbedding(String data) {
    try {
      final bytes = base64Decode(data);
      return Float64List.view(bytes.buffer).toList();
    } catch (e) {
      return [];
    }
  }

  /// Find the best matching user from a list of stored face data
  MapEntry<String, double>? findBestMatch(
    List<double> targetEmbedding,
    Map<String, List<String>> userFaceData,
    double threshold,
  ) {
    String? bestUserId;
    double bestScore = 0.0;

    for (final entry in userFaceData.entries) {
      for (final faceStr in entry.value) {
        final storedEmbedding = stringToEmbedding(faceStr);
        final score = compareFaces(targetEmbedding, storedEmbedding);
        if (score > bestScore && score >= threshold) {
          bestScore = score;
          bestUserId = entry.key;
        }
      }
    }

    if (bestUserId != null) {
      return MapEntry(bestUserId, bestScore);
    }
    return null;
  }
}
