import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/widgets/app_empty_view.dart';
import '../../../../core/widgets/app_loading_view.dart';
import '../../../../core/widgets/app_primary_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/profile_providers.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});
  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _township = TextEditingController();
  bool _notifications = true;
  bool _init = false;
  File? _avatar;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _township.dispose();
    super.dispose();
  }

  // ── Camera / Gallery source picker ──────────────────────────────────────
  Future<void> _pickImage(BuildContext context, bool isMy) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                isMy ? 'ဓာတ်ပုံ ရွေးချယ်ရန်' : 'Choose Photo Source',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text(isMy ? 'ကင်မရာ' : 'Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text(isMy ? 'ဓာတ်ပုံ မှတ်တမ်း' : 'Photo Library'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    final img = await _picker.pickImage(source: source, imageQuality: 85);
    if (img != null) setState(() => _avatar = File(img.path));
  }

  Future<void> _save(bool isMy) async {
    final ctrl = ref.read(profileControllerProvider.notifier);
    if (_avatar != null) await ctrl.uploadAvatar(_avatar!);
    await ctrl.updateProfile(
      displayName: _name.text,
      city: _city.text,
      township: _township.text,
      notificationEnabled: _notifications,
    );
    if (!mounted) return;
    AppSnackbar.success(
        context, isMy ? 'ပရိုဖိုင် အပ်ဒိတ်လုပ်ပြီးပြီ' : 'Profile updated');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(currentUserProfileProvider);
    final state = ref.watch(profileControllerProvider);
    final locale = ref.watch(languageProvider);
    final isMy = locale.languageCode == 'my';

    return Scaffold(
      appBar: AppBar(
        title: Text(isMy ? 'ပရိုဖိုင် ပြင်ဆင်ရန်\nEdit Profile' : 'Edit Profile'),
        centerTitle: true,
      ),
      body: async.when(
        loading: () => const AppLoadingView(),
        error: (e, _) => AppEmptyView(
          title: isMy ? 'အမှားဖြစ်ပွားသည်' : 'Error',
          message: isMy ? 'ထပ်မံကြိုးစားပါ' : 'Please try again',
        ),
        data: (p) {
          if (p == null) {
            return AppEmptyView(
              title: isMy ? 'ပရိုဖိုင် မတွေ့ပါ' : 'Profile not found',
            );
          }
          if (!_init) {
            _init = true;
            _name.text = p.displayName ?? '';
            _city.text = p.city ?? '';
            _township.text = p.township ?? '';
            _notifications = p.notificationEnabled;
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar picker ──────────────────────────────────────
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      child: _avatar != null
                          ? ClipOval(
                              child: Image.file(
                                _avatar!,
                                width: 112,
                                height: 112,
                                fit: BoxFit.cover,
                              ),
                            )
                          : p.photoUrl != null
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: p.photoUrl!,
                                    width: 112,
                                    height: 112,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) =>
                                        const CircularProgressIndicator(),
                                    errorWidget: (_, __, ___) =>
                                        const Icon(Icons.person, size: 56),
                                  ),
                                )
                              : const Icon(Icons.person, size: 56),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        onPressed: () => _pickImage(context, isMy),
                        icon: const Icon(Icons.camera_alt),
                        tooltip: isMy ? 'ဓာတ်ပုံ ပြောင်းရန်' : 'Change photo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Name field ─────────────────────────────────────────
              TextField(
                controller: _name,
                decoration: InputDecoration(
                  labelText: isMy ? 'အမည် / Name' : 'Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ── City field ─────────────────────────────────────────
              TextField(
                controller: _city,
                decoration: InputDecoration(
                  labelText: isMy ? 'မြို့ / City' : 'City',
                  prefixIcon: const Icon(Icons.location_city_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Township field ─────────────────────────────────────
              TextField(
                controller: _township,
                decoration: InputDecoration(
                  labelText: isMy ? 'မြို့နယ် / Township' : 'Township',
                  prefixIcon: const Icon(Icons.map_outlined),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // ── Notifications toggle ───────────────────────────────
              Card(
                child: SwitchListTile(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                  title: Text(
                    isMy
                        ? 'အကြောင်းကြားချက်များ ဖွင့်ရန်'
                        : 'Enable Notifications',
                  ),
                  secondary: const Icon(Icons.notifications_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // ── Save button ────────────────────────────────────────
              AppPrimaryButton(
                label: isMy ? 'သိမ်းဆည်းရန် / Save' : 'Save',
                isLoading: state.isLoading,
                onPressed: () => _save(isMy),
              ),
            ],
          );
        },
      ),
    );
  }
}
