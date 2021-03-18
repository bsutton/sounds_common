/*
 * This file is part of Sounds.
 *
 *   Sounds is free software: you can redistribute it and/or modify
 *   it under the terms of the Lesser GNU General Public License
 *   version 3 (LGPL3) as published by the Free Software Foundation.
 *
 *   Sounds is distributed in the hope that it will be useful,
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *   GNU General Public License for more details.
 *
 *   You should have received a copy of the Lesser GNU General Public License
 *   along with Sounds.  If not, see <https://www.gnu.org/licenses/>.
 */

/// Callback function used by internal methods indicate the loading progress.
/// The value of [PlaybackDisposition.progress] should be between [0.0 - 1.0].
/// If [PlaybackDisposition.progress] is complete its value MUST be 1.0.
/// If loading has not yet commenced [PlaybackDisposition.progress]] value MUST be 1.0.
///
typedef LoadingProgress = void Function(PlaybackDisposition disposition);

void noProgress(PlaybackDisposition disposition) {}

/// Used to stream data about the position of the
/// playback as playback proceeds.
class PlaybackDisposition {
  /// The current state of playback.
  final PlaybackDispositionState state;

  /// When the state is [PlaybackDispositionState.loading],
  /// [progress] indicates how far threw the loading we are.
  /// The valid range is [0.0 - 1.0].
  /// [progress] will have a value of 1.0 when in
  /// any other state.
  final double progress;

  /// The duration of the media.
  final Duration duration;

  /// The current position within the media
  /// that we are playing.
  final Duration position;

  /// A convenience ctor. If you are using a stream builder
  /// you can use this to set initialData with both duration
  /// and postion as 0.
  PlaybackDisposition.zero()
      : state = PlaybackDispositionState.init,
        progress = 1.0,
        position = Duration(seconds: 0),
        duration = Duration(seconds: 0);

  ///
  PlaybackDisposition(
    this.state, {
    this.progress = 1.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  /// Creates a disposition in the [PlaybackDisposition.init] state.
  PlaybackDisposition.init()
      : state = PlaybackDispositionState.init,
        progress = 0.0,
        position = Duration.zero,
        duration = Duration.zero;

  /// Creates a disposition in the [PlaybackDisposition.preload] state.
  PlaybackDisposition.preload()
      : state = PlaybackDispositionState.preload,
        progress = 0.0,
        position = Duration.zero,
        duration = Duration.zero;

  /// Creates a disposition in the [PlaybackDisposition.loading] state.
  PlaybackDisposition.loading({required this.progress})
      : state = PlaybackDispositionState.loading,
        position = Duration.zero,
        duration = Duration.zero;

  /// Creates a disposition in the [PlaybackDisposition.loaded] state.
  PlaybackDisposition.loaded()
      : state = PlaybackDispositionState.loaded,
        progress = 1.0,
        position = Duration.zero,
        duration = Duration.zero;

  /// Creates a disposition in the [PlaybackDisposition.error] state.
  PlaybackDisposition.error()
      : state = PlaybackDispositionState.error,
        progress = 1.0,
        position = Duration.zero,
        duration = Duration.zero;

  /// Creates a disposition in the [PlaybackDisposition.recording] state.
  PlaybackDisposition.recording({required this.duration})
      : state = PlaybackDispositionState.recording,
        progress = 1.0,
        position = Duration.zero;

  @override
  String toString() {
    return 'duration: $duration, '
        'position: $position';
  }
}

/// Indicates the current state of the Playback.

enum PlaybackDispositionState {
  /// When playback is ready to start you will first
  /// see a stream item with a state of [init]
  /// You should only ever see this state once.
  init,

  /// This state indicates that we are are attempting to start the load.
  /// We typically enter this state when we first send an http request
  /// to begin streaming audio. Until we get the first response
  /// we don't know how long the media is so we can't really indicate progress.
  /// In this start you might display a progress indicator with no % or
  /// zero percenetage.
  preload,

  /// Once we commencing loading the audio the state will
  /// change to [loading]. This can indicate that we are downloading
  /// the audio, saving it to disk for playback or transcoding it
  /// for playback. You may never see this state if no prepartory work
  /// is required. When loading the [PlaybackDisposition.progress] property will have a value
  /// of between 0.0 and 1.0. At all other times it will be 1.0.
  ///
  /// If we are unable to determine the length or duration of the audio then
  /// the [PlaybackDisposition.duration] and the [PlaybackDisposition.progress] will be [0.0]. In this case
  /// you should not show a % progress as [PlaybackDisposition.progress] will always be zero.
  ///
  /// If we are able to determine the length (in bytes) of the audio
  /// (but not the duration) then the [PlaybackDisposition.duration] will be zero
  /// but the progress will be non-zero.
  ///
  /// My daughter says:
  /// hi ;)
  loading,

  /// The  media has finished loading.
  loaded,

  /// The media load failed due to an error.
  error,

  /// Once loading has completed the state will change to [playing] and
  /// you should see a stream of [PlaybackDisposition] items as playing
  /// occurs.
  playing,

  /// When playback is stopped, for whatever reason, you will see a single
  /// [stopped] state.
  /// If the starts/stops playback you may see the state switch between
  /// [stopped] and [playing] multiple times with multiple [playing] items
  /// each time.

  stopped,

  /// The [recording] state is used when a RecorderPlaybackController is being
  /// used to attach a SoundRecorderUI and a SoundPlayerUI. As the recording
  /// progresses the [PlaybackDispositionState] events are generated by
  /// SoundRecorderUI with a state of [recording]. The position will always be
  /// zero and the duration will reflect the length of the recording so far.
  recording
}
