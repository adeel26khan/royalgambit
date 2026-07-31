import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:royalgambit/domain/models/piece.dart';
import 'package:royalgambit/presentation/providers/game_provider.dart';

class PlayerTimer {
  final int remainingSeconds;
  final bool isActive;
  final bool isWarning; // < 60 sec
  final bool isCritical; // < 30 sec

  const PlayerTimer({
    this.remainingSeconds = 600,
    this.isActive = false,
    this.isWarning = false,
    this.isCritical = false,
  });

  PlayerTimer copyWith({int? remainingSeconds, bool? isActive}) {
    final s = remainingSeconds ?? this.remainingSeconds;
    return PlayerTimer(
      remainingSeconds: s,
      isActive: isActive ?? this.isActive,
      isWarning: s < 60,
      isCritical: s < 30,
    );
  }

  String get display {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class TimerState {
  final PlayerTimer whiteTimer;
  final PlayerTimer blackTimer;
  final bool enabled;

  const TimerState({
    this.whiteTimer = const PlayerTimer(),
    this.blackTimer = const PlayerTimer(),
    this.enabled = false,
  });

  TimerState copyWith({
    PlayerTimer? whiteTimer,
    PlayerTimer? blackTimer,
    bool? enabled,
  }) =>
      TimerState(
        whiteTimer: whiteTimer ?? this.whiteTimer,
        blackTimer: blackTimer ?? this.blackTimer,
        enabled: enabled ?? this.enabled,
      );
}

class TimerNotifier extends StateNotifier<TimerState> {
  Timer? _ticker;
  final Ref _ref;

  TimerNotifier(this._ref) : super(const TimerState());

  void initialize({required int seconds, required bool enabled}) {
    _ticker?.cancel();
    state = TimerState(
      whiteTimer: PlayerTimer(remainingSeconds: seconds),
      blackTimer: PlayerTimer(remainingSeconds: seconds),
      enabled: enabled,
    );
  }

  void start(PieceColor activeSide) {
    if (!state.enabled) return;
    _ticker?.cancel();

    state = state.copyWith(
      whiteTimer: state.whiteTimer.copyWith(
        isActive: activeSide == PieceColor.white,
      ),
      blackTimer: state.blackTimer.copyWith(
        isActive: activeSide == PieceColor.black,
      ),
    );

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _ticker?.cancel();
    state = state.copyWith(
      whiteTimer: state.whiteTimer.copyWith(isActive: false),
      blackTimer: state.blackTimer.copyWith(isActive: false),
    );
  }

  void reset(int seconds) {
    initialize(seconds: seconds, enabled: state.enabled);
  }

  void _tick() {
    if (state.whiteTimer.isActive) {
      final newSeconds = state.whiteTimer.remainingSeconds - 1;
      if (newSeconds <= 0) {
        stop();
        _ref.read(gameProvider.notifier).onTimeOut(PieceColor.white);
        return;
      }
      state = state.copyWith(
        whiteTimer: state.whiteTimer.copyWith(remainingSeconds: newSeconds),
      );
    } else if (state.blackTimer.isActive) {
      final newSeconds = state.blackTimer.remainingSeconds - 1;
      if (newSeconds <= 0) {
        stop();
        _ref.read(gameProvider.notifier).onTimeOut(PieceColor.black);
        return;
      }
      state = state.copyWith(
        blackTimer: state.blackTimer.copyWith(remainingSeconds: newSeconds),
      );
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref);
});
