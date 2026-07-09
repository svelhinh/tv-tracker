import 'package:flutter/material.dart';

class ShowPoster extends StatelessWidget {
  const ShowPoster({
    super.key,
    required this.title,
    this.posterUrl,
    this.width = 56,
    this.height = 84,
  });

  final String title;
  final String? posterUrl;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final placeholder = SizedBox(
      width: width,
      height: height,
      child: CircleAvatar(
        child: Text(title.isNotEmpty ? title[0].toUpperCase() : '?'),
      ),
    );

    if (posterUrl == null) return placeholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        posterUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      ),
    );
  }
}
