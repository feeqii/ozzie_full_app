import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/providers/child_providers.dart';
import '../../content/repo/content_repository.dart';
import '../../rewards/models/reward_event.dart';
import '../models/recitation_state.dart';
import '../repo/recitation_repository.dart';
import '../services/arabic_similarity.dart';
import '../services/openai_transcription_service.dart';

final recitationRepositoryProvider = Provider<RecitationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RecitationRepository(client);
});

final recitationControllerProvider = StateNotifierProvider.family<RecitationController, RecitationState, RecitationParams>(
  (ref, params) {
    final repo = ref.watch(recitationRepositoryProvider);
    final selectedChild = ref.watch(selectedChildProvider);
    final childId = params.childId ?? selectedChild?.id ?? '';
    return RecitationController(
      repo,
      params.copyWith(childId: childId, birthYear: selectedChild?.birthYear),
    );
  },
);

class RecitationParams {
  const RecitationParams({
    required this.surahId,
    required this.ayahId,
    this.childId,
    this.birthYear,
  });

  final String? childId;
  final int surahId;
  final int ayahId;
  final int? birthYear;

  RecitationParams copyWith({
    String? childId,
    int? surahId,
    int? ayahId,
    int? birthYear,
  }) {
    return RecitationParams(
      childId: childId ?? this.childId,
      surahId: surahId ?? this.surahId,
      ayahId: ayahId ?? this.ayahId,
      birthYear: birthYear ?? this.birthYear,
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
        other.ayahId == ayahId &&
        other.birthYear == birthYear;
  }

  @override
  int get hashCode => Object.hash(childId, surahId, ayahId, birthYear);
}

class RecitationController extends StateNotifier<RecitationState> {
  RecitationController(this._repo, RecitationParams params)
      : _recorder = AudioRecorder(),
        _player = AudioPlayer(),
        _birthYear = params.birthYear,
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
  final int? _birthYear;
  final ContentRepository _contentRepository = const ContentRepository();
  final OpenAiTranscriptionService _transcriptionService = const OpenAiTranscriptionService();
  static const String _openAiModel = 'gpt-4o-transcribe';

  Future<bool> ensureMicPermission({bool requestIfNeeded = true}) async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      state = state.copyWith(showMicSettingsPrompt: true);
      return false;
    }

    if (!requestIfNeeded) {
      return false;
    }

    final requested = await Permission.microphone.request();
    if (requested.isGranted) {
      return true;
    }

    if (requested.isPermanentlyDenied || requested.isRestricted) {
      state = state.copyWith(showMicSettingsPrompt: true);
    }
    return false;
  }

  void clearMicPermissionPrompt() {
    if (!state.showMicSettingsPrompt) {
      return;
    }
    state = state.copyWith(showMicSettingsPrompt: false);
  }

  Future<void> setRecording() async {
    if (state.isBusy) {
      return;
    }

    final hasPermission = await ensureMicPermission();
    if (!hasPermission) {
      return;
    }

    if (!await _recorder.hasPermission()) {
      state = state.copyWith(showMicSettingsPrompt: true);
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
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session == null) {
        throw const AuthException('Session expired. Please sign in again.');
      }
      final refreshed = await client.auth.refreshSession();
      if (refreshed.session == null) {
        await client.auth.signOut();
        throw const AuthException('Session expired. Please sign in again.');
      }

      final apiKey = dotenv.env['OPENAI_API_KEY']?.trim();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Missing OPENAI_API_KEY. Add it to your .env file.');
      }

      final targetArabic = await _loadArabicTarget();
      if (targetArabic == null || targetArabic.isEmpty) {
        throw Exception('Missing target ayah text for scoring.');
      }

      final transcript = await _transcriptionService.transcribe(
        apiKey: apiKey,
        localPath: state.localPath!,
        model: _openAiModel,
      );
      final score = computeSimilarityScore(transcript, targetArabic);
      final storagePath = _repo.buildStoragePath(
        surahId: state.surahId,
        ayahId: state.ayahId,
      );

      final ageYears = _birthYear == null ? null : DateTime.now().year - _birthYear!;
      final meta = <String, dynamic>{
        if (ageYears != null && ageYears > 0) 'age_years': ageYears,
      };

      final payload = await _repo.submitRecitation(
        childId: state.childId,
        surahId: state.surahId,
        ayahId: state.ayahId,
        audioPath: storagePath,
        score: score,
        transcript: transcript,
        model: _openAiModel,
        meta: meta.isEmpty ? null : meta,
      );

      unawaited(
        _repo
            .uploadRecitation(localPath: state.localPath!, storagePath: storagePath)
            .catchError((_) {}),
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
    } on FunctionException catch (error) {
      final message = error.status == 401
          ? 'Session invalid. Please sign out and sign in again.'
          : error.toString();
      state = state.copyWith(
        stage: RecitationStage.review,
        isBusy: false,
        errorMessage: message,
      );
    } on AuthException catch (error) {
      state = state.copyWith(
        stage: RecitationStage.review,
        isBusy: false,
        errorMessage: error.message,
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

  Future<String?> _loadArabicTarget() async {
    final content = await _contentRepository.fetchSurahContent(state.surahId);
    for (final ayah in content.ayahs) {
      if (ayah.id == state.ayahId) {
        return ayah.arabic;
      }
    }
    return null;
  }
}
