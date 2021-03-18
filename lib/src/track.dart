import 'dart:async';
import 'dart:typed_data';

import 'package:path/path.dart';

import '../sounds_common.dart';
import 'media_format/audio.dart';
import 'playback_disposition.dart';
import 'util/file_util.dart' as fm;

typedef TrackAction = void Function(Track current);

///
/// The [Track] class lets you define an audio track
/// either from a path (uri) or a databuffer.
///
//
class Track {
  late final TrackStorageType _storageType;

  /// The title of this track
  String title = '';

  /// The name of the artist of this track
  String artist = '';

  /// The album the track belongs.
  String album = '';

  /// The URL that points to the album art of the track
  String albumArtUrl = '';

  /// The asset that points to the album art of the track
  String albumArtAsset = '';

  /// The file that points to the album art of the track
  String albumArtFile = '';

  ///
  late final Audio _audio;

  /// Returns the length of the audio in bytes.
  int get length => _audio.length;

  MediaFormat get mediaFormat => _audio.mediaFormat;

  @override
  String toString() {
    return '$title  $artist  audio: $_audio';
  }

  /// Creates a Track from a path to a file
  ///
  /// Other classes that use fromFile should also be reviewed.
  ///
  /// Throws [MediaFormatException] if the passed [MediaFormat] is not supported
  /// or if you don't pass the [MediaFormat] and we are unable
  /// to determine the [MediaFormat] from the [path]'s extension.
  Track.fromFile(String path,
      {MediaFormat mediaFormat = const UnknownMedia()}) {
    if (!fm.FileUtil().exists(path)) {
      throw TrackPathException('The given path $path does not exist.');
    }

    if (!fm.FileUtil().isFile(path)) {
      throw TrackPathException('The given path $path is not a file.');
    }

    _storageType = TrackStorageType.file;

    if (mediaFormat == const UnknownMedia()) {
      mediaFormat = MediaFormatManager().getByExtension(extension(path));
    }

    _audio = Audio.fromFile(path, mediaFormat);
  }

  /// Loads a track from an asset
  ///
  /// Throws [MediaFormatException] if the passed [MediaFormat] is not supported
  /// or if you don't pass the [MediaFormat] and we are unable
  /// to determine the [MediaFormat] from the [assetPath]'s extension.
  Track.fromAsset(String assetPath,
      {MediaFormat mediaFormat = const UnknownMedia()}) {
    _storageType = TrackStorageType.asset;

    if (mediaFormat == MediaFormat.unknownMedia) {
      mediaFormat = MediaFormatManager().getByExtension(extension(assetPath));
    }

    _audio = Audio.fromAsset(assetPath, mediaFormat);
  }

  /// Creates a track from a remote URL.
  /// HTTP and HTTPS are supported
  ///
  /// Throws [MediaFormatException] if the passed [MediaFormat] is not supported
  /// or if you don't pass the [MediaFormat] and we are unable
  /// to determine the [MediaFormat] from the [url]'s extension.
  Track.fromURL(String url, {MediaFormat mediaFormat = const UnknownMedia()}) {
    _storageType = TrackStorageType.url;

    if (mediaFormat == UnknownMedia()) {
      mediaFormat = MediaFormatManager().getByExtension(extension(url));
    }

    _audio = Audio.fromURL(url, mediaFormat);
  }

  /// Creates a track from a buffer.
  /// You may pass null for the [buffer] in which case an
  /// empty databuffer will be created.
  /// This is useful if you need to record into a track
  /// backed by a buffer.
  ///
  Track.fromBuffer(Uint8List? buffer, {required MediaFormat mediaFormat}) {
    buffer ??= Uint8List(0);

    _storageType = TrackStorageType.buffer;
    _audio = Audio.fromBuffer(buffer, mediaFormat);
  }

  /// true if the track is a url to the audio data.
  bool get isURL => _storageType == TrackStorageType.url;

  /// True if the track is a local file path
  bool get isFile => _storageType == TrackStorageType.file;

  /// True if the track is stored in a flutter asset.
  bool get isAsset => _storageType == TrackStorageType.file;

  /// True if the [Track] media is stored in buffer.
  bool get isBuffer => _storageType == TrackStorageType.buffer;

  /// If the [Track] was created via [Track.fromURL]
  /// then this will be the passed url.
  String? get url => _audio.url;

  /// If the [Track] was created via [Track.fromFile]
  /// then this will be the passed path.
  String? get path => _audio.path;

  /// If the [Track] was created via [Track.fromBuffer]
  /// then this will return the buffer.
  /// This may not be the same buffer you passed in if
  /// we have had to transcode data or you recorded into
  /// the track.
  Uint8List? get buffer => _audio.buffer;

  /// Converts the audio into a buffer
  /// and returns that buffer.
  /// If the audio is already stored in a buffer then
  /// it will be returned.
  Future<Uint8List> get asBuffer => _audio.asBuffer;

  /// returns a unique id for the [Track].
  /// If the [Track] is a path then the path is returned.
  /// If the [Track] is a url then the url.
  /// If the [Track] is a databuffer then its dart hashCode.
  String get identity {
    if (isFile) return path!;
    if (isURL) return url!;

    return '${_audio.buffer.hashCode}';
  }

  /// released any system resources.
  /// Under normal circumstances you don't need to call this
  /// method all of sounds classes manage it for you.
  void _release() => _audio.release();

  /// Used to prepare a audio stream for playing.
  /// You should NOT call this method as it is managed
  /// internally.
  Future _prepareStream(LoadingProgress progress) async =>
      _audio.prepareStream(progress);

  /// Returns the duration of the track.
  ///
  /// This can be an expensive operation as we need to
  /// process the media to determine its duration.
  ///
  /// If this track is being recorded into, the recorder
  /// will update the duration as the recording proceeds.
  ///
  /// The duration should always be considered as an estimate.
  Future<Duration> get duration async => _audio.duration;

  /// This is a convenience method that
  /// creates an empty temporary file in the system temp directory.
  ///
  /// You are responsible for deleting the file once done.
  ///
  /// The temp file name will be <uuid>.<mediaformat>.
  ///
  /// The [MediaFormat] has no affect on this file except to set the file's extension.
  ///
  /// You could still be really stupid and save data in some other format
  /// into this file. But you're not that stupid are you :)
  ///
  /// ```dart
  /// var file = Track.tempfile(MediaFormat.MP3)
  ///
  /// print(file);
  /// > 1230811273109.mp3
  /// ```
  ///
  static String tempFile(MediaFormat mediaFormat) {
    return fm.FileUtil().tempFile(suffix: mediaFormat.extension);
  }

  /// Used by Album to indicate that the first/last track of the Album
  /// has been reached.
  static Track end = Track.fromURL('http://end.mp3');
}

///
/// globl functions to allow us to hide methods from the public api.
///

void trackRelease(Track track) => track._release();

/// Used by the SoundRecorder to update the duration of the
/// track as the track is recorded into.
void setTrackDuration(Track track, Duration duration) =>
    track._audio.setDuration(duration);

///
Future prepareStream(Track track, LoadingProgress progress) =>
    track._prepareStream(progress);

/// Returns the uri where this track is currently stored.
///
String trackStoragePath(Track track) {
  if (track._audio.onDisk) {
    return track._audio.storagePath;
  } else {
    // this path should no longer be used as we are now downloading the track
    assert(track.isURL);
    return track.url!;
  }
}

/// Returns the databuffer which holds the audio.
/// If this Track was created via [Track.fromBuffer].
///
/// This may not be the same buffer you passed in if we had
/// to re-encode the buffer or if you recorded into the track.
///
/// Returns null if
Uint8List? trackBuffer(Track track) => track._audio.buffer;

/// Exception throw in a file path passed to a Track isn't valid.
class TrackPathException implements Exception {
  ///
  String message;

  ///
  TrackPathException(this.message);

  @override
  String toString() => message;
}

/// defines how the underlying audio media is stored.
enum TrackStorageType {
  ///
  asset,

  ///
  buffer,

  ///
  file,

  ///
  url
}
