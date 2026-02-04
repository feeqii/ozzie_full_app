import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/providers/child_providers.dart';
import '../../rewards/models/reward_event.dart';
import '../models/recitation_state.dart';
import '../repo/recitation_repository.dart';

final recitationRepositoryProvider = Provider<RecitationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RecitationRepository(client);
});

final recitationControllerProvider = StateNotifierProvider.family<RecitationController, RecitationState, RecitationParams>(
  (ref, params) {
    final repo = ref.watch(recitationRepositoryProvider);
    final childId = params.childId ?? ref.watch(selectedChildProvider)?.id ?? '';
    return RecitationController(repo, params.copyWith(childId: childId));
  },
);

class RecitationParams {
  const RecitationParams({
    required this.surahId,
    required this.ayahId,
    this.childId,
  });

  final String? childId;
  final int surahId;
  final int ayahId;

  RecitationParams copyWith({
    String? childId,
    int? surahId,
    int? ayahId,
  }) {
    return RecitationParams(
      childId: childId ?? this.childId,
      surahId: surahId ?? this.surahId,
      ayahId: ayahId ?? this.ayahId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is RecitationParams &&
        other.childId == childId &&
        other.surahId == surahId &&
        other.ayahId == ayahId;
  }

  @override
  int get hashCode => Object.hash(childId, surahId, ayahId);
}

class RecitationController extends StateNotifier<RecitationState> {
  RecitationController(this._repo, RecitationParams params)
      : _recorder = AudioRecorder(),
        _player = AudioPlayer(),
        super(
          RecitationState(
            childId: params.childId ?? '',
            surahId: params.surahId,
            ayahId: params.ayahId,
          ),
        );

  final RecitationRepository _repo;
  final AudioRecorder _recorder;
  final AudioPlayer _player;

  Future<void> setRecording() async {
    if (state.isBusy) {
      return;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      state = state.copyWith(errorMessage: 'Microphone permission is required.');
      return;
    }

    if (!await _recorder.hasPermission()) {
      state = state.copyWith(errorMessage: 'Microphone permission is required.');
      return;
    }

    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: filePath,
    );

    state = state.copyWith(
      stage: RecitationStage.recording,
      localPath: filePath,
      durationLabel: '0:00',
      clearError: true,
    );
  }

  void setIdle() {
    state = state.copyWith(stage: RecitationStage.idle, clearError: true);
  }

  Future<void> stopRecording() async {
    final path = await _recorder.stop();
    if (path == null) {
      state = state.copyWith(
        stage: RecitationStage.idle,
        errorMessage: 'Recording failed. Try again.',
      );
      return;
    }

    state = state.copyWith(
      stage: RecitationStage.review,
      localPath: path,
      durationLabel: '0:06',
      clearError: true,
    );
  }

  Future<void> playRecording() async {
    if (state.localPath == null) {
      return;
    }
    await _player.setFilePath(state.localPath!);
    await _player.play();
  }

  Future<void> submitRecording() async {
    if (state.localPath == null || state.localPath!.isEmpty) {
      state = state.copyWith(errorMessage: 'Record your recitation first.');
      return;
    }
    if (state.childId.isEmpty) {
      state = state.copyWith(errorMessage: 'Select a child profile to continue.');
      return;
    }

    state = state.copyWith(stage: RecitationStage.uploading, isBusy: true, clearError: true);

    try {
      final audioPath = await _repo.uploadRecitation(
        localPath: state.localPath!,
        childId: state.childId,
        surahId: state.surahId,
        ayahId: state.ayahId,
      );

      final payload = await _repo.submitRecitation(
        childId: state.childId,
        surahId: state.surahId,
        ayahId: state.ayahId,
        audioPath: audioPath,
      );

      final lockedUntil = payload['locked_until'] as String?;
      if (lockedUntil != null) {
        state = state.copyWith(
          stage: RecitationStage.lockedOut,
          lockedUntil: DateTime.tryParse(lockedUntil),
          attemptsLeftToday: 0,
          isBusy: false,
        );
        return;
      }

      final passed = payload['passed'] == true;
      final mustReplay = payload['mustReplayLearnStep'] == true;
      final nextGate = payload['nextGate'] as String?;
      final rewardEvent = _buildRewardEvent(payload, nextGate: nextGate);

      state = state.copyWith(
        stage: nextGate != null
            ? RecitationStage.gateToQuiz
            : mustReplay
                ? RecitationStage.interventionRequired
                : passed
                    ? RecitationStage.feedbackSuccess
                    : RecitationStage.feedbackFail,
        score: (payload['score'] as num?)?.toInt(),
        passesRemaining: (payload['passesRemaining'] as num?)?.toInt(),
        attemptsLeftToday: (payload['attemptsLeftToday'] as num?)?.toInt(),
        mustReplayLearnStep: mustReplay,
        showDetailedFeedback: payload['showDetailedFeedback'] == true,
        shouldBlurVerse: payload['shouldBlurVerse'] == true,
        nextGate: nextGate,
        lastResultMessage: payload['passed'] == true
            ? 'Nice work!'
            : 'Let\'s try again.',
        rewardEvent: rewardEvent,
        isBusy: false,
      );
    } on FileSystemException catch (_) {
      state = state.copyWith(
        stage: RecitationStage.review,
        isBusy: false,
        errorMessage: 'Audio file missing. Please record again.',
      );
    } catch (error) {
      state = state.copyWith(
        stage: RecitationStage.review,
        isBusy: false,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  RewardEvent? _buildRewardEvent(Map<String, dynamic> payload, {String? nextGate}) {
    final mastered = payload['ayahMasteredNow'] == true;
    if (!mastered || nextGate != null) {
      return null;
    }
    return RewardEvent(
      type: RewardType.hasanat,
      title: 'Ayah mastered!',
      message: 'You earned hasanat for this verse.',
      score: (payload['score'] as num?)?.toInt(),
    );
  }

  void clearReward() {
    state = state.copyWith(clearReward: true);
  }
}
