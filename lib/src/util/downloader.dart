import 'dart:async';
import 'dart:io';

import 'package:completer_ex/completer_ex.dart';
import 'package:pedantic/pedantic.dart';

import '../playback_disposition.dart';
import 'log.dart';

/// Provides methods for downloading files.
class Downloader {
  /// Downloads the [url] to [saveToPath] emmiting progress
  /// updates as the download progresses.
  static Future<void> download(String url, String saveToPath,
      {LoadingProgress progress = noProgress}) async {
    // announce we are starting.
    Log.d('Started downloading: $url');
    var completer = CompleterEx<void>();
    _showProgress(progress, PlaybackDisposition.preload());

    var client = HttpClient();
    unawaited(client.getUrl(Uri.parse(url)).then((request) {
      /// we have connected
      /// we can added headers here if we need.
      /// send the request
      return request.close();
    }).then((response) async {
      // we have a response.
      _showProgress(progress, PlaybackDisposition.loading(progress: 0.0));

      var lengthReceived = 0;

      var contentLength = response.contentLength;

      /// prep the save file.
      var saveFile = File(saveToPath);
      var raf = await saveFile.open(mode: FileMode.append);
      await raf.truncate(0);

      late StreamSubscription<List<int>> subscription;

      subscription = response.listen(
        (newBytes) async {
          /// if we don't pause we get overlapping calls from listen
          /// which causes the [writeFrom] to fail as you can't
          /// do overlapping io.
          subscription.pause();

          /// we have new data to save.
          await raf.writeFrom(newBytes);
          subscription.resume();
          lengthReceived += newBytes.length;

          /// notify the world of our progress
          var percent = 0.0;
          if (contentLength != 0) percent = lengthReceived / contentLength;
          _showProgress(
              progress, PlaybackDisposition.loading(progress: percent));

          Log.d('Download progress: %${percent * 100} ');
        },

        onDone: () async {
          /// down load is complete
          await raf.close();
          _showProgress(progress, PlaybackDisposition.loaded());
          Log.d('Completed downloading: $url');
          completer.complete();
        },

        // ignore: avoid_types_on_closure_parameters
        onError: (Object e, StackTrace st) async {
          // something went wrong.
          _showProgress(progress, PlaybackDisposition.error());
          Log.e('Error downloading: $url', error: e, stackTrace: st);
          await raf.close();
          completer.completeError(e, st);
        },
        cancelOnError: true,
      );
    }));

    return completer.future;
  }

  static void _showProgress(
      LoadingProgress progress, PlaybackDisposition disposition) {
    progress(disposition);
  }
}
