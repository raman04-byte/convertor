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

  void _renderText(Canvas canvas, Rect rect, final text, final right,
      final left, final paddedLeft, final top, TextBlock textBlock) {
    double minFontSize = 1;
    double maxFontSize = rect.height;
    double fontSize =
        _findOptimalFontSize(minFontSize, maxFontSize, rect, text, right, left);

    TextStyle textStyle = TextStyle(fontSize: fontSize, color: Colors.black);
    TextSpan textSpan = TextSpan(text: text, style: textStyle);
    TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
    );

    textPainter.layout(maxWidth: right - left);

    final textX = paddedLeft - 4;
    final textY = top;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  double _findOptimalFontSize(double minFontSize, double maxFontSize, Rect rect,
      final text, final right, final left) {
    double epsilon = 0.1;

    while ((maxFontSize - minFontSize) > epsilon) {
      double midFontSize = (minFontSize + maxFontSize) / 2;
      if (_isOverflowing(midFontSize, rect, text, right, left)) {
        maxFontSize = midFontSize;
      } else {
        minFontSize = midFontSize;
      }
    }

    return minFontSize;
  }

  bool _isOverflowing(
      double fontSize, Rect rect, final text, final right, final left) {
    TextStyle textStyle = TextStyle(fontSize: fontSize);
    TextSpan textSpan = TextSpan(text: text, style: textStyle);

    TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
      maxLines: (rect.height / fontSize).floor(),
    );

    textPainter.layout(maxWidth: right - left);

    return textPainter.didExceedMaxLines ||
        textPainter.size.height > rect.height;
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

      _renderText(
          canvas,
          Rect.fromLTRB(left, top, right, bottom),
          convertedBlocks[textBlocks.indexOf(textBlock)],
          right,
          left,
          paddedLeft,
          top,
          textBlock);
    }
  }

  @override
  bool shouldRepaint(TextBlockPainters oldDelegate) {
    return oldDelegate.textBlocks != textBlocks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.convertedBlocks != convertedBlocks;
  }
}

class TextBlockPainter extends CustomPainter {
  final TextBlock textBlock;
  final Size imageSize;

  TextBlockPainter({
    required this.textBlock,
    required this.imageSize,
  });
  @override
  void paint(Canvas canvas, Size size) {
    mypaint(canvas, size);
  }

  void mypaint(Canvas canvas, Size size) async {
    double padding = 4.0;
    final bgcolor = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill;
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
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), bgcolor);
  }

  @override
  bool shouldRepaint(TextBlockPainter oldDelegate) => true;
}

class ImageWithTextLines extends StatefulWidget {
  final String imagePath;
  final List<TextBlock> textBlock;
  List<TextLine> textLines = [];
  ImageWithTextLines(
      {super.key, required this.imagePath, required this.textBlock});
  @override
  State<ImageWithTextLines> createState() => _ImageWithTextLinesState();
}

class _ImageWithTextLinesState extends State<ImageWithTextLines> {
  List<String> convertedLanguageBlockList = [];
  List<TextLine> textLines = [];
  TextLine? _textLine;
  bool isSpeaking = false;
  FlutterTts flutterTts = FlutterTts();
  List<TextBlock> convertedLanguageTextBlock = [];
  TextBlock? currentBlock;
  @override
  void initState() {
    super.initState();
    extractLinesFromBlocks(widget.textBlock);
    textIntoBlockConverter();
    extractLines();
    initTts();
    // // printAvaliableVoices();
    // flutterTts.setLanguage('hi-IN');
    // printAvaliableVoices();
  }
// name: hi-in-x-hic-local, locale: hi-IN
// {name: hi-IN-language, locale: hi-IN}
  // Future<void> printAvaliableVoices() async {
  //   List<dynamic> voices = await flutterTts.getVoices;
  //   if (voices != null) {
  //     print('Available voices:');
  //     voices.forEach((voice) => print(voice));
  //   } else {
  //     print("Nothing to print");
  //   }
  // }

  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();
    _setEngines();

    flutterTts.setStartHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Playing");
        }
      });
    });

    flutterTts.setInitHandler(() {
      setState(() {
        if (kDebugMode) {
          print("TTS Initialized");
        }
      });
    });
    flutterTts.setCompletionHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Complete");
        }
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Canceling");
        }
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Paused");
        }
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Continued");
        }
      });
    });

    flutterTts.setLanguage('hi-IN');
    flutterTts.setVoice({"name": "hi-in-x-hic-local", "locale": "hi-IN"});

    flutterTts.setErrorHandler((msg) {
      setState(() {
        if (kDebugMode) {
          print("error: $msg");
        }
      });
    });
    flutterTts.setProgressHandler((text, start, end, word) {
      if (kDebugMode) {
        print(word);
      }
      // setState(() {});
    });
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
    if (kDebugMode) {
      print("Await Completion");
    }
  }

  Future<dynamic> _setEngines() async {
    String engine = await flutterTts.getDefaultEngine;
    flutterTts.setEngine(engine);
  }

  void textIntoBlockConverter() async {
    for (var textBB in widget.textBlock) {
      OnDeviceTranslator onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: TranslateLanguage.hindi);
      String response = await onDeviceTranslator.translateText(textBB.text);
      convertedLanguageBlockList.add(response);
      if (kDebugMode) {
        print(response);
      }
      setState(() {});
    }
  }

  Future<void> speaklines(
    int currentindex,
  ) async {
    if (currentindex >= widget.textBlock.length) {
      return;
    }
    setState(() {
      if (kDebugMode) {
        print("state changes");
      }
      currentBlock = widget.textBlock[currentindex];
    });
    flutterTts.speak(convertedLanguageBlockList[currentindex]).whenComplete(() {
      if (isSpeaking) {
        // flutterTts.stop();
        // isSpeaking = false;
        speaklines(currentindex + 1);
      } else {
        if (kDebugMode) {
          print('not run+${_textLine!.text}');
        }
        isSpeaking = false;
        return;
      }
    });
  }

  void extractLines() {
    for (var textBB in widget.textBlock) {
      List<TextLine> lines = textBB.lines;
      for (var ll in lines) {
        widget.textLines.add(ll);
      }
    }
  }

  void extractLinesFromBlocks(List<TextBlock> textBlock) {
    textLines =
        textBlock.expand((block) => block.lines).map((line) => line).toList();
  }

  TextBlock? _findTappedTextBlock(Offset localPath, Size size, Size imageSize) {
    for (var textblock in widget.textBlock) {
      final rect = Rect.fromLTRB(
          textblock.boundingBox.left * size.width / imageSize.width,
          textblock.boundingBox.top * size.height / imageSize.height,
          textblock.boundingBox.right * size.width / imageSize.width,
          textblock.boundingBox.bottom * size.height / imageSize.height);
      if (rect.contains(localPath)) {
        return textblock;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appbar")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          flutterTts.stop();
          isSpeaking = false;
        },
      ),
      body: FutureBuilder<Size>(
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
                if (convertedLanguageBlockList.length ==
                    widget.textBlock.length)
                  CustomPaint(
                    painter: TextBlockPainters(
                      textBlocks: widget.textBlock,
                      imageSize: snapshot.data!,
                      convertedBlocks: convertedLanguageBlockList,
                    ),
                  ),
                if (currentBlock != null)
                  CustomPaint(
                    painter: TextBlockPainter(
                        imageSize: snapshot.data!, textBlock: currentBlock!),
                  ),
                GestureDetector(
                  onTapUp: (TapUpDetails details) async {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final Offset localPosition =
                        box.globalToLocal(details.globalPosition);
                    final Size size = box.size;
                    final tappedTextBlock = _findTappedTextBlock(
                        localPosition, size, snapshot.data!);
                    if (tappedTextBlock != null) {
                      if (isSpeaking) {
                        flutterTts.stop().then((value) => speaklines(
                            widget.textBlock.indexOf(tappedTextBlock)));
                      } else {
                        isSpeaking = true;
                        speaklines(widget.textBlock.indexOf(tappedTextBlock));
                      }
                    } else {
                      if (kDebugMode) {
                        print('null');
                      }
                    }
                  },
                ),
              ],
            ));
          } else {
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 238, 87),
              ),
            );
          }
        },
      ),
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
