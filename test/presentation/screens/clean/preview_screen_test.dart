import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xclean/presentation/providers/dashboard_provider.dart';

void main() {
  group('Video file detection', () {
    test('isVideoFile returns true for mp4', () {
      expect(_isVideoFile('movie.mp4'), isTrue);
    });

    test('isVideoFile returns true for mkv', () {
      expect(_isVideoFile('movie.mkv'), isTrue);
    });

    test('isVideoFile returns true for avi', () {
      expect(_isVideoFile('movie.avi'), isTrue);
    });

    test('isVideoFile returns true for mov', () {
      expect(_isVideoFile('movie.mov'), isTrue);
    });

    test('isVideoFile returns true for wmv', () {
      expect(_isVideoFile('movie.wmv'), isTrue);
    });

    test('isVideoFile returns true for flv', () {
      expect(_isVideoFile('movie.flv'), isTrue);
    });

    test('isVideoFile returns true for 3gp', () {
      expect(_isVideoFile('movie.3gp'), isTrue);
    });

    test('isVideoFile returns true for m4v', () {
      expect(_isVideoFile('movie.m4v'), isTrue);
    });

    test('isVideoFile returns true for ts', () {
      expect(_isVideoFile('movie.ts'), isTrue);
    });

    test('isVideoFile returns false for jpg', () {
      expect(_isVideoFile('photo.jpg'), isFalse);
    });

    test('isVideoFile returns false for pdf', () {
      expect(_isVideoFile('doc.pdf'), isFalse);
    });

    test('isVideoFile is case insensitive', () {
      expect(_isVideoFile('movie.MP4'), isTrue);
      expect(_isVideoFile('movie.Mp4'), isTrue);
    });
  });

  group('Image file detection', () {
    test('isImageFile returns true for jpg', () {
      expect(_isImageFile('photo.jpg'), isTrue);
    });

    test('isImageFile returns true for jpeg', () {
      expect(_isImageFile('photo.jpeg'), isTrue);
    });

    test('isImageFile returns true for png', () {
      expect(_isImageFile('photo.png'), isTrue);
    });

    test('isImageFile returns true for gif', () {
      expect(_isImageFile('photo.gif'), isTrue);
    });

    test('isImageFile returns true for webp', () {
      expect(_isImageFile('photo.webp'), isTrue);
    });

    test('isImageFile returns true for bmp', () {
      expect(_isImageFile('photo.bmp'), isTrue);
    });

    test('isImageFile returns true for heic', () {
      expect(_isImageFile('photo.heic'), isTrue);
    });

    test('isImageFile returns true for heif', () {
      expect(_isImageFile('photo.heif'), isTrue);
    });

    test('isImageFile returns false for mp4', () {
      expect(_isImageFile('movie.mp4'), isFalse);
    });

    test('isImageFile is case insensitive', () {
      expect(_isImageFile('photo.JPG'), isTrue);
      expect(_isImageFile('photo.Jpg'), isTrue);
    });
  });
}

bool _isVideoFile(String name) {
  final ext = name.split('.').last.toLowerCase();
  return const {'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', '3gp', 'm4v', 'ts'}.contains(ext);
}

bool _isImageFile(String name) {
  final ext = name.split('.').last.toLowerCase();
  return const {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif'}.contains(ext);
}
