import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../models/book.dart';
import '../utils/remove_leading_zeros.dart';

class MinimalBookInfoBar extends StatefulWidget {
  const MinimalBookInfoBar({Key? key, required this.book}) : super(key: key);
  final Book book;

  @override
  State<MinimalBookInfoBar> createState() => _MinimalBookInfoBarState();
}

class _MinimalBookInfoBarState extends State<MinimalBookInfoBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.transparent,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: Theme.of(context).primaryColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TextInfo(
            onTap: () async {
              if (widget.book.savedData == null) return;

              // open review popup
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Rate ${widget.book.name}"),
                      const SizedBox(height: 8),
                      RatingBar.builder(
                        glow: false,
                        initialRating: widget.book.savedData!.data.rating ?? 3,
                        minRating: 0,
                        direction: Axis.horizontal,
                        allowHalfRating: true,
                        itemCount: 5,
                        itemPadding:
                            const EdgeInsets.symmetric(horizontal: 4.0),
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onRatingUpdate: (rating) {
                          widget.book.savedData!.data.rating = rating;
                        },
                      )
                    ],
                  ),
                ),
              );

              widget.book.savedData!.saveData();
              setState(() {});
            },
            topic: "Rating",
            value:
                "${removeLeadingZeros(widget.book.savedData?.data.rating?.toString() ?? "none")}/5",
          ),
          const _Separator(),
          _TextInfo(topic: "Pages", value: widget.book.pages.toString()),
          const _Separator(),
          const _TextInfo(topic: "Language", value: "Eng"),
        ],
      ),
    );
  }
}

class _Separator extends StatelessWidget {
  const _Separator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).dividerColor,
      height: 40,
      width: 1,
    );
  }
}

class _TextInfo extends StatelessWidget {
  const _TextInfo({
    Key? key,
    required this.value,
    required this.topic,
    this.onTap,
  }) : super(key: key);

  final String value;
  final String topic;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .merge(const TextStyle(fontWeight: FontWeight.bold))),
            Text(
              topic,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
