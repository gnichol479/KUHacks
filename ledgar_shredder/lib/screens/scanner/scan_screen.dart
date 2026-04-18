import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_spacing.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _capturedImage;
  bool _isOpeningCamera = false;

  Future<void> _openCamera() async {
    try {
      setState(() {
        _isOpeningCamera = true;
      });

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open camera: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningCamera = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan Receipt',
                style: AppTextStyles.titleLarge,
              ),

              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: AppSpacing.cardRadius,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _capturedImage == null
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 52,
                                color: AppColors.textSecondary,
                              ),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Point at a receipt or take a photo',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ClipRRect(
                          borderRadius:
                              AppSpacing.cardRadius,
                          child: Image.file(
                            _capturedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isOpeningCamera ? null : _openCamera,
                  icon: _isOpeningCamera
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(
                    _capturedImage == null ? 'Capture' : 'Retake',
                    style: AppTextStyles.button,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.cardRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}