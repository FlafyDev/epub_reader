import 'package:flutter/material.dart';

class Character {
  final String name;
  final ImageProvider image;
  final String? descriptionMarkdown;

  Character({
    required this.name,
    required this.image,
    required this.descriptionMarkdown,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "image": image.toString(),
        "descriptionMarkdown": descriptionMarkdown,
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        name: json["name"],
        image: NetworkImage(json["image"]),
        descriptionMarkdown: json["descriptionMarkdown"],
      );
}
