import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service_locator.dart';
import '../../services/api/file_upload_service.dart';

final fileUploadServiceProvider = Provider<FileUploadService>((ref) {
  return getIt<FileUploadService>();
});

// Provider for profile image upload
final uploadProfileImageProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, imagePath) async {
    final fileUploadService = ref.watch(fileUploadServiceProvider);
    
    try {
      final result = await fileUploadService.uploadProfileImage(imagePath);
      return result['success'] ?? false;
    } catch (e) {
      return false;
    }
  },
);

// Provider for resume upload
final uploadResumeProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, filePath) async {
    final fileUploadService = ref.watch(fileUploadServiceProvider);
    
    try {
      final result = await fileUploadService.uploadResume(filePath);
      return result['success'] ?? false;
    } catch (e) {
      return false;
    }
  },
);

// Provider for ID card upload
final uploadIdCardProvider = FutureProvider.autoDispose.family<bool, String>(
  (ref, imagePath) async {
    final fileUploadService = ref.watch(fileUploadServiceProvider);
    
    try {
      final result = await fileUploadService.uploadIdCard(imagePath);
      return result['success'] ?? false;
    } catch (e) {
      return false;
    }
  },
);