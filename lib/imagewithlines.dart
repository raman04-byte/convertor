import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextBlockPainters extends CustomPainter {
  final List<TextBlock> textBlocks;
  final Size imageSize;
  final List<String> convertedBlocks;

  TextBlockPainters({
    required this.textBlocks,
    required this.imageSize,
    required this.convertedBlocks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    mypaint(canvas, size);
  }

  void mypaint(Canvas canvas, Size size) async {
    double padding = 4.0;
    final bgcolor = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (var textBlock in textBlocks) {
      final rect = Rect.fromLTRB(
        textBlock.boundingBox.left,
        textBlock.boundingBox.top,
        textBlock.boundingBox.right,
        textBlock.boundingBox.bottom,
      );

      final left = rect.left * size.width / imageSize.width;
      final top = rect.top * size.height / imageSize.height;
      final right = rect.right * size.width / imageSize.width;
      final bottom = rect.bottom * size.height / imageSize.height;

      final paddedLeft = left + padding;
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), bgcolor);
      final textPainter = TextPainter(
        text: TextSpan(
          text: convertedBlocks[textBlocks.indexOf(textBlock)],
          style: const TextStyle(
              fontSize: 8.5,
              fontStyle: FontStyle.normal,
              backgroundColor: Color.fromRGBO(248, 248, 248, 255),
              color: Colors.black),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.justify,
      );
      textPainter.layout(maxWidth: right - left);
      final textX = paddedLeft;
      final textY = top;
      textPainter.paint(canvas, Offset(textX, textY));
    }
  }

  @override
  bool shouldRepaint(TextBlockPainters oldDelegate) {
    return oldDelegate.textBlocks != textBlocks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.convertedBlocks != convertedBlocks;
  }
}

class ImageWithTextLines extends StatefulWidget {
  final String imagePath;
  final List<TextBlock> textBlock;
  late List<TextLine> textLine;
  ImageWithTextLines(
      {super.key, required this.imagePath, required this.textBlock});
  @override
  State<ImageWithTextLines> createState() => _ImageWithTextLinesState();
}

class _ImageWithTextLinesState extends State<ImageWithTextLines> {
  TextLine? _textLine;
  List<String> convertedTextBlockList = [];
  List<TextLine> textLines = [];
  @override
  void initState() {
    super.initState();
    extractLinesFromBlocks(widget.textBlock);
    textIntoBlockConverter();
  }

  FlutterTts flutterTts = FlutterTts();
  void textIntoBlockConverter() async {
    for (var textBB in widget.textBlock) {
      OnDeviceTranslator onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: TranslateLanguage.hindi);
      var response = await onDeviceTranslator.translateText(textBB.text);
      convertedTextBlockList.add(response);
      if (kDebugMode) {
        print(response);
      }
      setState(() {});
    }
  }

  void extractLinesFromBlocks(List<TextBlock> textBlock) {
    textLines =
        textBlock.expand((block) => block.lines).map((line) => line).toList();
  }

  TextBlock? currentBlock;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Size>(
      future: _getImageSize(widget.imagePath),
      builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
        if (snapshot.hasData) {
          return SizedBox(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.fill,
                ),
                if (convertedTextBlockList.length == widget.textBlock.length)
                  CustomPaint(
                    painter: TextBlockPainters(
                        textBlocks: widget.textBlock,
                        imageSize: snapshot.data!,
                        convertedBlocks: convertedTextBlockList),
                  ),
              ],
            ),
          );
        } else {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }

  Future<Size> _getImageSize(String imagePath) {
    final completer = Completer<Size>();
    final image = Image.file(File(imagePath));
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          final size =
              Size(image.image.width.toDouble(), image.image.height.toDouble());
          completer.complete(size);
        },
      ),
    );
    return completer.future;
  }
}

class OnDeviceTranslator {
  static const MethodChannel _channel =
      MethodChannel('google_mlkit_on_device_translator');

  final TranslateLanguage sourceLanguage;

  final TranslateLanguage targetLanguage;

  final id = DateTime.now().microsecondsSinceEpoch.toString();

  OnDeviceTranslator(
      {required this.sourceLanguage, required this.targetLanguage});

  Future<String> translateText(String text) async {
    final result = await _channel
        .invokeMethod('nlp#startLanguageTranslator', <String, dynamic>{
      'id': id,
      'text': text,
      'source': sourceLanguage.bcpCode,
      'target': targetLanguage.bcpCode
    });

    return result.toString();
  }

  Future<void> close() =>
      _channel.invokeMethod('nlp#closeLanguageTranslator', {'id': id});
}

class OnDeviceTranslatorModelManager extends ModelManager {
  OnDeviceTranslatorModelManager()
      : super(
            channel: OnDeviceTranslator._channel,
            method: 'nlp#manageLanguageModelModels');
}

enum TranslateLanguage {
  afrikaans,
  albanian,
  arabic,
  belarusian,
  bengali,
  bulgarian,
  catalan,
  chinese,
  croatian,
  czech,
  danish,
  dutch,
  english,
  esperanto,
  estonian,
  finnish,
  french,
  galician,
  georgian,
  german,
  greek,
  gujarati,
  haitian,
  hebrew,
  hindi,
  hungarian,
  icelandic,
  indonesian,
  irish,
  italian,
  japanese,
  kannada,
  korean,
  latvian,
  lithuanian,
  macedonian,
  malay,
  maltese,
  marathi,
  norwegian,
  persian,
  polish,
  portuguese,
  romanian,
  russian,
  slovak,
  slovenian,
  spanish,
  swahili,
  swedish,
  tagalog,
  tamil,
  telugu,
  thai,
  turkish,
  ukrainian,
  urdu,
  vietnamese,
  welsh,
}

extension BCP47Code on TranslateLanguage {
  String get bcpCode {
    switch (this) {
      case TranslateLanguage.afrikaans:
        return 'af';
      case TranslateLanguage.albanian:
        return 'sq';
      case TranslateLanguage.arabic:
        return 'ar';
      case TranslateLanguage.belarusian:
        return 'be';
      case TranslateLanguage.bengali:
        return 'bn';
      case TranslateLanguage.bulgarian:
        return 'bg';
      case TranslateLanguage.catalan:
        return 'ca';
      case TranslateLanguage.chinese:
        return 'zh';
      case TranslateLanguage.croatian:
        return 'hr';
      case TranslateLanguage.czech:
        return 'cs';
      case TranslateLanguage.danish:
        return 'da';
      case TranslateLanguage.dutch:
        return 'nl';
      case TranslateLanguage.english:
        return 'en';
      case TranslateLanguage.esperanto:
        return 'eo';
      case TranslateLanguage.estonian:
        return 'et';
      case TranslateLanguage.finnish:
        return 'fi';
      case TranslateLanguage.french:
        return 'fr';
      case TranslateLanguage.galician:
        return 'gl';
      case TranslateLanguage.georgian:
        return 'ka';
      case TranslateLanguage.german:
        return 'de';
      case TranslateLanguage.greek:
        return 'el';
      case TranslateLanguage.gujarati:
        return 'gu';
      case TranslateLanguage.haitian:
        return 'ht';
      case TranslateLanguage.hebrew:
        return 'he';
      case TranslateLanguage.hindi:
        return 'hi';
      case TranslateLanguage.hungarian:
        return 'hu';
      case TranslateLanguage.icelandic:
        return 'is';
      case TranslateLanguage.indonesian:
        return 'id';
      case TranslateLanguage.irish:
        return 'ga';
      case TranslateLanguage.italian:
        return 'it';
      case TranslateLanguage.japanese:
        return 'ja';
      case TranslateLanguage.kannada:
        return 'kn';
      case TranslateLanguage.korean:
        return 'ko';
      case TranslateLanguage.latvian:
        return 'lv';
      case TranslateLanguage.lithuanian:
        return 'lt';
      case TranslateLanguage.macedonian:
        return 'mk';
      case TranslateLanguage.malay:
        return 'ms';
      case TranslateLanguage.maltese:
        return 'mt';
      case TranslateLanguage.marathi:
        return 'mr';
      case TranslateLanguage.norwegian:
        return 'no';
      case TranslateLanguage.persian:
        return 'fa';
      case TranslateLanguage.polish:
        return 'pl';
      case TranslateLanguage.portuguese:
        return 'pt';
      case TranslateLanguage.romanian:
        return 'ro';
      case TranslateLanguage.russian:
        return 'ru';
      case TranslateLanguage.slovak:
        return 'sk';
      case TranslateLanguage.slovenian:
        return 'sl';
      case TranslateLanguage.spanish:
        return 'es';
      case TranslateLanguage.swahili:
        return 'sw';
      case TranslateLanguage.swedish:
        return 'sv';
      case TranslateLanguage.tagalog:
        return 'tl';
      case TranslateLanguage.tamil:
        return 'ta';
      case TranslateLanguage.telugu:
        return 'te';
      case TranslateLanguage.thai:
        return 'th';
      case TranslateLanguage.turkish:
        return 'tr';
      case TranslateLanguage.ukrainian:
        return 'uk';
      case TranslateLanguage.urdu:
        return 'ur';
      case TranslateLanguage.vietnamese:
        return 'vi';
      case TranslateLanguage.welsh:
        return 'cy';
    }
  }

  static TranslateLanguage? fromRawValue(String bcpCode) {
    try {
      return TranslateLanguage.values
          .firstWhere((element) => element.bcpCode == bcpCode);
    } catch (_) {
      return null;
    }
  }
}
