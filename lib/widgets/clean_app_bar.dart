import 'package:flutter/material.dart';

class CleanAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CleanAppBar({
    Key? key,
    required this.title,
    this.canBack = true,
    this.onBackPressed,
    this.actions,
    this.color,
  }) : super(key: key);

  final String title;
  final bool canBack;
  final void Function()? onBackPressed;
  final List<Widget>? actions;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: color ?? Theme.of(context).backgroundColor,
      leading: canBack
          ? IconButton(
              splashRadius: 20,
              icon: const Icon(Icons.arrow_back),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge!
            .merge(const TextStyle(fontWeight: FontWeight.bold)),
      ),
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size(double.infinity, kToolbarHeight);
}
