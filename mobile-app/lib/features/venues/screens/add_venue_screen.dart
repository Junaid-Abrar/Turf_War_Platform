import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/widgets.dart';
import '../providers/venue_provider.dart';
import '../widgets/amenity_icons.dart';

class AddVenueScreen extends StatefulWidget {
  const AddVenueScreen({super.key});

  @override
  State<AddVenueScreen> createState() => _AddVenueScreenState();
}

class _AddVenueScreenState extends State<AddVenueScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isSubmitting = false;
  final Set<String> _selectedAmenities = <String>{};

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        // Caps the upload size; phone cameras produce files large enough to
        // time out the multipart request on a slow connection.
        maxWidth: 1920,
      );
      if (picked == null || !mounted) return;
      setState(() => _imageFile = File(picked.path));
    } on Exception catch (_) {
      // Almost always a denied gallery permission.
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not open the gallery. Check app permissions.'),
        ),
      );
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (_imageFile == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add a photo of the venue first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await context.read<VenueProvider>().createVenue(
            name: _nameController.text.trim(),
            description: _descController.text.trim(),
            location: _locController.text.trim(),
            pricePerHour: double.parse(_priceController.text),
            imageFile: _imageFile!,
            amenities: _selectedAmenities.toList(),
          );
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Venue listed.')),
      );
      context.goNamed(AppRoutes.home);
    } on ApiException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('List a venue'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => context.goNamed(AppRoutes.home),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ImagePickerField(
                  imageFile: _imageFile,
                  onTap: _isSubmitting ? null : _pickImage,
                ),
                AppSpacing.gapXl,
                AppTextField(
                  controller: _nameController,
                  label: 'Venue name',
                  prefixIcon: Icons.stadium_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  enabled: !_isSubmitting,
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapLg,
                AppTextField(
                  controller: _locController,
                  label: 'Location',
                  hint: 'Neighbourhood or address',
                  prefixIcon: Icons.location_on_outlined,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  enabled: !_isSubmitting,
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapLg,
                AppTextField(
                  controller: _priceController,
                  label: 'Price per hour (\$)',
                  prefixIcon: Icons.payments_outlined,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.next,
                  enabled: !_isSubmitting,
                  validator: (String? v) {
                    final double? price = double.tryParse(v ?? '');
                    if (price == null) return 'Enter a number';
                    if (price <= 0) return 'Must be greater than 0';
                    return null;
                  },
                ),
                AppSpacing.gapLg,
                AppTextField(
                  controller: _descController,
                  label: 'Description',
                  hint: 'Surface, size, floodlights, anything worth knowing',
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSubmitting,
                  validator: (String? v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                AppSpacing.gapXxl,
                Text('Amenities', style: theme.textTheme.titleMedium),
                AppSpacing.gapMd,
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: <Widget>[
                    for (final String amenity in kAmenityOptions)
                      FilterChip(
                        label: Text(amenity),
                        avatar: Icon(iconForAmenity(amenity), size: 16),
                        selected: _selectedAmenities.contains(amenity),
                        showCheckmark: false,
                        onSelected: _isSubmitting
                            ? null
                            : (bool selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedAmenities.add(amenity);
                                  } else {
                                    _selectedAmenities.remove(amenity);
                                  }
                                });
                              },
                      ),
                  ],
                ),
                AppSpacing.gapXxxl,
                AppButton(
                  label: 'Publish venue',
                  expand: true,
                  isLoading: _isSubmitting,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The tap-to-choose photo well.
class _ImagePickerField extends StatelessWidget {
  final File? imageFile;
  final VoidCallback? onTap;

  const _ImagePickerField({required this.imageFile, this.onTap});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: imageFile != null
            ? Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(imageFile!, fit: BoxFit.cover),
                  Positioned(
                    right: AppSpacing.sm,
                    bottom: AppSpacing.sm,
                    child: Material(
                      color: theme.colorScheme.surface,
                      borderRadius: AppRadius.pillAll,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(Icons.edit_outlined, size: 16),
                            AppSpacing.hGapXs,
                            Text(
                              'Change photo',
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.add_a_photo_outlined,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.gapMd,
                  Text('Add a photo', style: theme.textTheme.titleSmall),
                  AppSpacing.gapXs,
                  Text(
                    'The first thing players see',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
