import 'package:flutter/material.dart';

class Character {
  final String name;
  final NetworkImage? image;
  final String? descriptionMarkdown;

  Character({
    required this.name,
    this.image,
    required this.descriptionMarkdown,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'image': image?.url,
        'descriptionMarkdown': descriptionMarkdown,
      };

  factory Character.fromJson(Map<String, dynamic> json) => Character(
        name: json["name"],
        image: json["image"] != null ? NetworkImage(json["image"]) : null,
        descriptionMarkdown: json["descriptionMarkdown"],
      );
}
