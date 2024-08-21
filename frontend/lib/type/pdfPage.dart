import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

/// complies with PyMuPDF's Json structure.
class PdfPage {
  final double width;
  final double height;
  final List<TextBlock> blocks = [];
  final List<PageImage> images = [];

  /// Create a base object, to be filled with JSON.
  PdfPage.none()
      : width = 0,
        height = 0;

  PdfPage.fromJson(Map<String, dynamic> json)
      : width = json['width'] as double,
        height = json['height'] as double {
    final b = json['blocks'];
    for (var block in b) {
      blocks.add(TextBlock.fromJson(block));
    }

    final imgs = json['imgs'];
    for (var img in imgs) {
      images.add(PageImage.fromJson(img));
    }
  }

  /// Return a page.
  Widget build() {
    final List<Widget> widgets = [];

    // Insert texts
    for (var block in blocks) {
      for (var line in block.lines) {
        List<TextSpan> textSpans = [];

        for (var span in line.spans) {
          // Spans essentially make up a line.
          // Therefore, merge all into one.
          textSpans.add(
            TextSpan(
              text: span.text,
              style: GoogleFonts.getFont("Roboto Condensed",
                  fontSize: span.fontSize),
            ),
          );
        }

        TextSpan span0 = TextSpan(children: textSpans);

        widgets.add(
          Positioned(
            left: line.bBox.min.x,
            top: line.bBox.min.y,
            child: Container(
              width: line.bBox.max.x - line.bBox.min.x,
              height: line.bBox.max.y - line.bBox.min.y,
              //decoration: BoxDecoration(border: Border.all()), // Uncomment to debug
              child: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.cover,
                child: Text.rich(
                  span0,
                ),
              ),
            ),
          ),
        );
      }
    }

    // Insert images
    for (var image in images) {
      widgets.add(
        Positioned(
          top: image.bBox.min.y,
          left: image.bBox.min.x,
          child: Container(
            //decoration: BoxDecoration(border: Border.all()), // Uncomment to debug
            width: image.bBox.max.x - image.bBox.min.x,
            height: image.bBox.max.y - image.bBox.min.y,

            child: Image.memory(
              base64Decode(image.imageB64),
              fit: BoxFit.fill,
            ),
          ),
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(border: Border.all()),
      child: Stack(
        alignment: Alignment.center,
        children: widgets,
      ),
    );
  }
}

class TextBlock {
  final List<Line> lines = [];
  final PageBBox bBox;

  TextBlock.fromJson(Map<String, dynamic> json)
      : bBox = PageBBox.fromJson(json['bbox']) {
    final l = json['lines'];
    for (var line in l) {
      lines.add(Line.fromJson(line));
    }
  }
}

class Line {
  final List<Span> spans = [];
  final PageBBox bBox;
  Line.fromJson(Map<String, dynamic> json)
      : bBox = PageBBox.fromJson(json['bbox']) {
    final s = json['spans'];
    for (var span in s) {
      spans.add(Span.fromJson(span));
    }
  }
}

class Span {
  final String font;
  final double fontSize;
  late PagePoint origin = PagePoint.zero();
  final String text;

  Span.fromJson(Map<String, dynamic> json)
      : font = json['font'] as String,
        fontSize = json['size'] as double,
        text = json['text'] as String {
    origin = PagePoint.fromJson(json['origin']);
  }
}

class PageImage {
  final String imageB64;
  final PageBBox bBox;

  PageImage(this.imageB64, this.bBox);
  PageImage.fromJson(Map<String, dynamic> json)
      : imageB64 = json['img'],
        bBox = PageBBox.fromJson(json['bbox']);
}

/// A point in a PDF page
class PagePoint {
  final double x;
  final double y;

  PagePoint(this.x, this.y);
  PagePoint.zero()
      : x = 0,
        y = 0;

  PagePoint.fromJson(List<dynamic> json)
      : x = json[0] as double,
        y = json[1] as double;
}

/// A bounding box in a PDF page
class PageBBox {
  final PagePoint min;
  final PagePoint max;

  PageBBox(this.min, this.max);

  PageBBox.zero()
      : min = PagePoint.zero(),
        max = PagePoint.zero();

  PageBBox.fromJson(List<dynamic> json)
      : min = PagePoint(json[0] as double, json[1] as double),
        max = PagePoint(json[2] as double, json[3] as double);
}
