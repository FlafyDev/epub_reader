import 'package:flutter/material.dart';
import '../epub_renderer/epub_renderer.dart';

class BookPlayerCustomizer extends StatefulWidget {
  const BookPlayerCustomizer({
    Key? key,
    required this.styleProperties,
    required this.onUpdateStyle,
  }) : super(key: key);

  final EpubStyleProperties styleProperties;
  final void Function() onUpdateStyle;

  @override
  _BookPlayerCustomizerState createState() => _BookPlayerCustomizerState();
}

class _BookPlayerCustomizerState extends State<BookPlayerCustomizer> {
  final fonts = [
    "Default",
    "Arial",
    "RobotoMono",
    "Literata",
    "Merriweather",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        borderRadius: const BorderRadius.all(Radius.circular(15)),
      ),
      child: PageView(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Wrap(
              runSpacing: 15,
              children: [
                _Scaler(
                  decrease: Icon(
                    Icons.format_size,
                    size: 17,
                    color: theme.iconTheme.color,
                  ),
                  increase: Icon(
                    Icons.format_size,
                    color: theme.iconTheme.color,
                  ),
                  valueDisplay:
                      "${(widget.styleProperties.fontSizeMultiplier * 100).round()}%",
                  onDecrease: () {
                    widget.styleProperties.fontSizeMultiplier -= 0.1;
                    widget.onUpdateStyle();
                  },
                  onIncrease: () {
                    widget.styleProperties.fontSizeMultiplier += 0.1;
                    widget.onUpdateStyle();
                  },
                ),
                _Scaler(
                  decrease: Icon(
                    Icons.format_line_spacing,
                    size: 17,
                    color: theme.iconTheme.color,
                  ),
                  increase: Icon(
                    Icons.format_line_spacing,
                    color: theme.iconTheme.color,
                  ),
                  valueDisplay:
                      "${(widget.styleProperties.lineHeightMultiplier * 100).round()}%",
                  onDecrease: () {
                    widget.styleProperties.lineHeightMultiplier -= 0.1;
                    widget.onUpdateStyle();
                  },
                  onIncrease: () {
                    widget.styleProperties.lineHeightMultiplier += 0.1;
                    widget.onUpdateStyle();
                  },
                ),
                Material(
                  color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _AlignmentButton(
                        icon: Icons.format_align_left,
                        alignment: "left",
                        updateStyle: widget.onUpdateStyle,
                        style: widget.styleProperties,
                      ),
                      _AlignmentButton(
                        icon: Icons.format_align_center,
                        alignment: "center",
                        updateStyle: widget.onUpdateStyle,
                        style: widget.styleProperties,
                      ),
                      _AlignmentButton(
                        icon: Icons.format_align_right,
                        alignment: "right",
                        updateStyle: widget.onUpdateStyle,
                        style: widget.styleProperties,
                      ),
                      _AlignmentButton(
                        icon: Icons.format_align_justify,
                        alignment: "justify",
                        updateStyle: widget.onUpdateStyle,
                        style: widget.styleProperties,
                      ),
                    ],
                  ),
                ),
                DropdownButton<String>(
                  value: fonts.contains(widget.styleProperties.fontFamily)
                      ? widget.styleProperties.fontFamily
                      : fonts.first,
                  dropdownColor: theme.backgroundColor,
                  onChanged: (String? newFont) {
                    if (newFont == null) {
                      return;
                    }

                    widget.styleProperties.fontFamily = newFont;
                    widget.onUpdateStyle();
                  },
                  icon: const Icon(Icons.title),
                  focusColor: Colors.transparent,
                  iconEnabledColor: theme.iconTheme.color,
                  items: fonts.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          value,
                          style: theme.textTheme.bodyText2,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Wrap(
              runSpacing: 15,
              children: [
                _Scaler(
                  decrease: Icon(
                    Icons.space_bar,
                    size: 17,
                    color: theme.iconTheme.color,
                  ),
                  increase: Icon(
                    Icons.space_bar,
                    color: theme.iconTheme.color,
                  ),
                  valueDisplay: "+${widget.styleProperties.wordSpacingAdder}px",
                  onDecrease: () {
                    widget.styleProperties.wordSpacingAdder -= 1;
                    widget.onUpdateStyle();
                  },
                  onIncrease: () {
                    widget.styleProperties.wordSpacingAdder += 1;
                    widget.onUpdateStyle();
                  },
                ),
                _Scaler(
                  decrease: Icon(
                    Icons.text_format_outlined,
                    size: 17,
                    color: theme.iconTheme.color,
                  ),
                  increase: Icon(
                    Icons.text_format_outlined,
                    color: theme.iconTheme.color,
                  ),
                  valueDisplay:
                      "+${widget.styleProperties.letterSpacingAdder}px",
                  onDecrease: () {
                    widget.styleProperties.letterSpacingAdder -= 1;
                    widget.onUpdateStyle();
                  },
                  onIncrease: () {
                    widget.styleProperties.letterSpacingAdder += 1;
                    widget.onUpdateStyle();
                  },
                ),
                _Scaler(
                  decrease: Icon(
                    Icons.format_bold,
                    size: 17,
                    color: theme.iconTheme.color,
                  ),
                  increase: Icon(
                    Icons.format_bold,
                    color: theme.iconTheme.color,
                  ),
                  valueDisplay:
                      "${(widget.styleProperties.weightMultiplier * 100).round()}%",
                  onDecrease: () {
                    widget.styleProperties.weightMultiplier -= 0.1;
                    widget.onUpdateStyle();
                  },
                  onIncrease: () {
                    widget.styleProperties.weightMultiplier += 0.1;
                    widget.onUpdateStyle();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Wrap(
              runSpacing: 15,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _ScalerButton(
                      child: Container(),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        widget.styleProperties.theme = EpubStyleThemes.light;
                        widget.onUpdateStyle();
                      },
                    ),
                    _ScalerButton(
                      child: Container(),
                      backgroundColor: Colors.black,
                      onPressed: () {
                        widget.styleProperties.theme = EpubStyleThemes.dark;
                        widget.onUpdateStyle();
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Scaler extends StatelessWidget {
  const _Scaler({
    Key? key,
    required this.valueDisplay,
    required this.decrease,
    required this.increase,
    required this.onDecrease,
    required this.onIncrease,
  }) : super(key: key);

  final String valueDisplay;
  final Widget decrease;
  final Widget increase;
  final void Function() onDecrease;
  final void Function() onIncrease;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ScalerButton(
            child: decrease,
            onPressed: onDecrease,
          ),
        ),
        Expanded(
          child: Center(
            child: Text(valueDisplay,
                style: Theme.of(context).textTheme.bodyText2),
          ),
        ),
        Expanded(
          child: _ScalerButton(
            child: increase,
            onPressed: onIncrease,
          ),
        ),
      ],
    );
  }
}

class _ScalerButton extends StatelessWidget {
  const _ScalerButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.backgroundColor,
  }) : super(key: key);

  final Widget child;
  final void Function() onPressed;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 110,
        minHeight: 40.0,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            backgroundColor ?? Theme.of(context).dialogBackgroundColor,
          ),
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: BorderSide(
                color: Theme.of(context).iconTheme.color!,
              ),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _AlignmentButton extends StatelessWidget {
  const _AlignmentButton({
    Key? key,
    required this.icon,
    required this.alignment,
    required this.style,
    required this.updateStyle,
  }) : super(key: key);

  final IconData icon;
  final String alignment;
  final EpubStyleProperties style;
  final void Function() updateStyle;

  @override
  Widget build(BuildContext context) {
    final active = style.align == alignment;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color:
              active ? Theme.of(context).iconTheme.color! : Colors.transparent,
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon),
        splashRadius: 23,
        iconSize: 32,
        onPressed: () {
          style.align = alignment;
          updateStyle();
        },
      ),
    );
  }
}
