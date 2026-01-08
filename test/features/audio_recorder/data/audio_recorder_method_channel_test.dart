import 'package:flutter/services.dart';
import 'package:flutter_audio_recorder/features/audio_recorder/data/datasources/audio_recorder_method_channel.dart';
import 'package:flutter_audio_recorder/features/audio_recorder/domain/entities/recording_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel = MethodChannel(
    'com.example.audio_recorder/methods',
  );
  late AudioRecorderMethodChannel dataSource;
  late List<MethodCall> log;

  setUp(() {
    dataSource = AudioRecorderMethodChannel();
    log = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);

          switch (methodCall.method) {
            case 'requestPermission':
              return true;
            case 'startRecording':
              return null;
            case 'stopRecording':
              return {
                'id': 'test_123',
                'filePath': '/path/to/test_123.m4a',
                'fileName': 'test_123.m4a',
                'durationMs': 5000,
                'sizeBytes': 102400,
                'createdAt': '2026-01-08T12:00:00.000Z',
              };
            case 'getRecordings':
              return [
                {
                  'id': 'test_123',
                  'filePath': '/path/to/test_123.m4a',
                  'fileName': 'test_123.m4a',
                  'durationMs': 5000,
                  'sizeBytes': 102400,
                  'createdAt': '2026-01-08T12:00:00.000Z',
                },
              ];
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('AudioRecorderMethodChannel', () {
    test('requestPermission returns true when granted', () async {
      final result = await dataSource.requestPermission();

      expect(result, true);
      expect(log, <Matcher>[
        isMethodCall('requestPermission', arguments: null),
      ]);
    });

    test('requestPermission throws when platform error occurs', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            throw PlatformException(code: 'ERROR', message: 'Test error');
          });

      expect(() => dataSource.requestPermission(), throwsA(isA<Exception>()));
    });

    test('startRecording calls native method', () async {
      await dataSource.startRecording();

      expect(log, <Matcher>[isMethodCall('startRecording', arguments: null)]);
    });

    test('stopRecording returns RecordingEntity', () async {
      final result = await dataSource.stopRecording();

      expect(result, isA<RecordingEntity>());
      expect(result.id, 'test_123');
      expect(result.fileName, 'test_123.m4a');
      expect(result.durationMs, 5000);
      expect(result.sizeBytes, 102400);
      expect(log, <Matcher>[isMethodCall('stopRecording', arguments: null)]);
    });

    test('getRecordings returns list of RecordingEntity', () async {
      final result = await dataSource.getRecordings();

      expect(result, isA<List<RecordingEntity>>());
      expect(result.length, 1);
      expect(result.first.id, 'test_123');
      expect(log, <Matcher>[isMethodCall('getRecordings', arguments: null)]);
    });

    test('getRecordings returns empty list when null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            return null;
          });

      final result = await dataSource.getRecordings();

      expect(result, isEmpty);
    });
  });
}
