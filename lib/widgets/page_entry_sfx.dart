import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

/// Plays [asset] once whenever [visible] transitions from `false` to `true`.
///
/// Mounted as an invisible sibling at the top of each screen's widget tree.
/// Uses `PlayerMode.lowLatency` (Android SoundPool) so the sound fires
/// crisp on tab navigation. Re-tapping the same tab while already on it
/// leaves [visible] true → no edge → no replay. Re-entering a tab from
/// elsewhere flips it back to true → one play.
///
/// When [muted] is true, playback is suppressed entirely so the app's
/// global sound toggle can silence every audio source.
class PageEntrySfx extends StatefulWidget {
  final bool visible;
  final bool muted;
  final String asset;
  const PageEntrySfx({
    super.key,
    required this.visible,
    required this.asset,
    this.muted = false,
  });

  @override
  State<PageEntrySfx> createState() => _PageEntrySfxState();
}

class _PageEntrySfxState extends State<PageEntrySfx> {
  AudioPlayer? _player;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final p = AudioPlayer();
    try {
      await p.setReleaseMode(ReleaseMode.stop);
      await p.setPlayerMode(PlayerMode.lowLatency);
      await p.setSource(AssetSource(widget.asset));
      if (!mounted) {
        await p.dispose();
        return;
      }
      _player = p;
      _ready = true;
      // Honour the visibility we mounted with — covers first-launch on
      // the default tab. didUpdateWidget handles every subsequent flip.
      if (widget.visible) _play();
    } catch (_) {
      await p.dispose();
    }
  }

  void _play() {
    if (widget.muted) return;
    final p = _player;
    if (!_ready || p == null) return;
    p.stop().then((_) {
      if (!mounted) return;
      p.resume();
    });
  }

  @override
  void didUpdateWidget(covariant PageEntrySfx old) {
    super.didUpdateWidget(old);
    if (!old.visible && widget.visible) _play();
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
