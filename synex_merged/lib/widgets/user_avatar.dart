import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/helpers.dart';

class UserAvatar extends StatelessWidget {
  final String name;
  final String? photoUrl;
  final double size;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key, required this.name, this.photoUrl,
    this.size = 44, this.showBorder = false, this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      avatar = CachedNetworkImage(
        imageUrl: photoUrl!,
        imageBuilder: (_, img) => Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
            image: DecorationImage(image: img, fit: BoxFit.cover))),
        placeholder: (_, __) => _placeholder(),
        errorWidget: (_, __, ___) => _placeholder(),
      );
    } else {
      avatar = _placeholder();
    }
    if (showBorder) {
      return Container(
        width: size + 4, height: size + 4,
        decoration: BoxDecoration(shape: BoxShape.circle,
          border: Border.all(color: borderColor ?? const Color(0xFF00E5FF), width: 2)),
        child: avatar,
      );
    }
    return avatar;
  }

  Widget _placeholder() => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle,
      color: AppHelpers.getAvatarColor(name)),
    child: Center(child: Text(AppHelpers.getInitials(name),
      style: TextStyle(color: Colors.white, fontSize: size * 0.35, fontWeight: FontWeight.w700))),
  );
}
