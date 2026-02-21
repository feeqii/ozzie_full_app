import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/models/child_profile.dart';
import '../../child/providers/child_providers.dart';
import '../models/quiz_models.dart';
import '../models/quiz_recitation_state.dart';
import '../repo/quiz_recitation_repository.dart';

final quizRecitationRepositoryProvider = Provider<QuizRecitationRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return QuizRecitationRepository(client);
});

final quizRecitationControllerProvider =
    StateNotifierProvider.family<
      QuizRecitationController,
      QuizRecitationState,
      QuizRecitationParams
    >((ref, params) {
      final repo = ref.watch(quizRecitationRepositoryProvider);
      ChildProfile? selectedChildGetter() => ref.read(selectedChildProvider);
      final childId = params.childId ?? selectedChildGetter()?.id ?? '';
      return QuizRecitationController(
        repo,
        params.copyWith(childId: childId),
        selectedChildGetter,
      );
    });

class QuizRecitationParams {
  const QuizRecitationParams({
    required this.surahId,
    required this.quizType,
    this.childId,
  });

  final String? childId;
  final int surahId;
  final QuizType quizType;

  QuizRecitationParams copyWith({
    String? childId,
    int? surahId,
    QuizType? quizType,
  }) {
    return QuizRecitationParams(
      childId: childId ?? this.childId,
      surahId: surahId ?? this.surahId,
      quizType: quizType ?? this.quizType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is QuizRecitationParams &&
        other.childId == childId &&
        other.surahId == surahId &&
        other.quizType == quizType;
  }

  @override
  int get hashCode => Object.hash(childId, surahId, quizType);
}

typedef SelectedChildGetter = ChildProfile? Function();

class QuizRecitationController extends StateNotifier<QuizRecitationState> {
  QuizRecitationController(
    this._repo,
    QuizRecitationParams params,
    this._selectedChild,
  ) : _recorder = AudioRecorder(),
      _player = AudioPlayer(),
      super(
        QuizRecitationState(
          childId: params.childId ?? '',
          surahId: params.surahId,
          quizType: params.quizType,
        ),
      );

  final QuizRecitationRepository _repo;
  final AudioRecorder _recorder;
  final AudioPlayer _player;
  final SelectedChildGetter _selectedChild;
  static const String _logTag = '[QuizRecitation]';
  bool _recordingTransitionInFlight = false;
  bool _playbackInFlight = false;

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

  void reset() {
    state = state.copyWith(
      stage: QuizRecitationStage.idle,
      localPath: null,
      durationLabel: '0:00',
      isBusy: false,
      score: null,
      passed: null,
      clearAttemptsLeftToday: true,
      clearLockedUntil: true,
      clearError: true,
      clearTranscript: true,
    );
  }

  Future<void> setRecording() async {
    if (state.isBusy) {
      return;
    }
    if (_recordingTransitionInFlight) {
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

    _recordingTransitionInFlight = true;
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/quiz_recitation_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );

      state = state.copyWith(
        stage: QuizRecitationStage.recording,
        localPath: filePath,
        durationLabel: '0:00',
        clearError: true,
        clearTranscript: true,
      );
    } catch (error) {
      debugPrint('$_logTag startRecording failed: $error');
      state = state.copyWith(
        stage: QuizRecitationStage.idle,
        errorMessage: 'Unable to start recording. Please try again.',
      );
    } finally {
      _recordingTransitionInFlight = false;
    }
  }

  Future<void> stopRecording() async {
    if (_recordingTransitionInFlight) {
      return;
    }

    _recordingTransitionInFlight = true;
    try {
      final path = await _recorder.stop();
      if (path == null) {
        state = state.copyWith(
          stage: QuizRecitationStage.idle,
          errorMessage: 'Recording failed. Try again.',
        );
        return;
      }

      state = state.copyWith(
        stage: QuizRecitationStage.review,
        localPath: path,
        durationLabel: '0:06',
        clearError: true,
      );
    } catch (error) {
      debugPrint('$_logTag stopRecording failed: $error');
      state = state.copyWith(
        stage: QuizRecitationStage.idle,
        errorMessage: 'Recording failed. Try again.',
      );
    } finally {
      _recordingTransitionInFlight = false;
    }
  }

  Future<void> playRecording() async {
    final localPath = state.localPath;
    if (localPath == null || localPath.isEmpty) {
      return;
    }
    if (_playbackInFlight) {
      return;
    }

    _playbackInFlight = true;
    try {
      await _player.setFilePath(localPath);
      await _player.play();
    } catch (error) {
      debugPrint('$_logTag playRecording failed: $error');
      state = state.copyWith(
        errorMessage: 'Unable to play recording. Please record again.',
      );
    } finally {
      _playbackInFlight = false;
    }
  }

  Future<void> submitRecording() async {
    if (state.localPath == null || state.localPath!.isEmpty) {
      state = state.copyWith(errorMessage: 'Record your recitation first.');
      return;
    }
    final effectiveChildId = state.childId.isNotEmpty
        ? state.childId
        : _selectedChild()?.id ?? '';
    if (effectiveChildId.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Select a child profile to continue.',
      );
      return;
    }

    state = state.copyWith(
      stage: QuizRecitationStage.submitting,
      isBusy: true,
      clearError: true,
    );

    try {
      final client = Supabase.instance.client;
      final session = await _ensureActiveSession(client);
      if (session == null) {
        throw const AuthException('Session expired. Please sign in again.');
      }

      final storagePath = _repo.buildStoragePath(
        surahId: state.surahId,
        quizType: state.quizType,
      );

      await _repo.uploadRecitation(
        localPath: state.localPath!,
        storagePath: storagePath,
      );

      final payload = await _repo.submitLevelRecitation(
        childId: effectiveChildId,
        surahId: state.surahId,
        quizType: state.quizType,
        audioPath: storagePath,
        meta: null,
      );

      final lockedUntil = payload['locked_until'] as String?;
      if (lockedUntil != null) {
        state = state.copyWith(
          stage: QuizRecitationStage.lockedOut,
          lockedUntil: DateTime.tryParse(lockedUntil),
          attemptsLeftToday: 0,
          isBusy: false,
        );
        return;
      }

      final passed = payload['passed'] == true;
      state = state.copyWith(
        stage: passed ? QuizRecitationStage.success : QuizRecitationStage.fail,
        score: (payload['score'] as num?)?.toInt(),
        passed: passed,
        attemptsLeftToday: (payload['attemptsLeftToday'] as num?)?.toInt(),
        transcript: payload['transcript'] as String?,
        isBusy: false,
      );
    } on FileSystemException catch (_) {
      state = state.copyWith(
        stage: QuizRecitationStage.review,
        isBusy: false,
        errorMessage: 'Audio file missing. Please record again.',
      );
    } on FunctionException catch (error) {
      final message = error.status == 401
          ? 'Session invalid. Please sign out and sign in again.'
          : error.toString();
      debugPrint(
        '$_logTag FunctionException status=${error.status} details=${error.details}',
      );
      state = state.copyWith(
        stage: QuizRecitationStage.review,
        isBusy: false,
        errorMessage: message,
      );
    } on AuthException catch (error) {
      state = state.copyWith(
        stage: QuizRecitationStage.review,
        isBusy: false,
        errorMessage: error.message,
      );
    } catch (error) {
      state = state.copyWith(
        stage: QuizRecitationStage.review,
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

  Future<Session?> _ensureActiveSession(SupabaseClient client) async {
    final session = client.auth.currentSession;
    if (session == null) {
      return null;
    }

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final expiresAt = session.expiresAt;
    final shouldRefresh = expiresAt == null || expiresAt <= (nowSeconds + 90);

    if (!shouldRefresh) {
      return session;
    }

    try {
      final refreshed = await client.auth.refreshSession();
      if (refreshed.session != null) {
        return refreshed.session;
      }
    } catch (error) {
      debugPrint('$_logTag refreshSession failed: $error');
    }

    if (expiresAt != null && expiresAt > nowSeconds) {
      return session;
    }
    return null;
  }
}
