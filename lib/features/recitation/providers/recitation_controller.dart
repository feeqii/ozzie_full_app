import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase_client_provider.dart';
import '../../child/models/child_profile.dart';
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
    final selectedChildGetter = () => ref.read(selectedChildProvider);
    final childId = params.childId ?? selectedChildGetter()?.id ?? '';
    return RecitationController(
      repo,
      params.copyWith(childId: childId),
      selectedChildGetter,
    );
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

typedef SelectedChildGetter = ChildProfile? Function();

class RecitationController extends StateNotifier<RecitationState> {
  RecitationController(this._repo, RecitationParams params, this._selectedChild)
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
  final SelectedChildGetter _selectedChild;
  final ContentRepository _contentRepository = const ContentRepository();
  final OpenAiTranscriptionService _transcriptionService = const OpenAiTranscriptionService();
  static const String _openAiModel = 'gpt-4o-transcribe';
  static const String _logTag = '[RecitationSubmit]';

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
    final effectiveChildId = state.childId.isNotEmpty ? state.childId : _selectedChild()?.id ?? '';
    if (effectiveChildId.isEmpty) {
      state = state.copyWith(errorMessage: 'Select a child profile to continue.');
      return;
    }

    state = state.copyWith(stage: RecitationStage.uploading, isBusy: true, clearError: true);

    try {
      final client = Supabase.instance.client;
      final session = client.auth.currentSession;
      if (session == null) {
        debugPrint('$_logTag No session. childId=${state.childId} surah=${state.surahId} ayah=${state.ayahId}');
        throw const AuthException('Session expired. Please sign in again.');
      }
      _logSessionState(session);
      final refreshed = await client.auth.refreshSession();
      if (refreshed.session == null) {
        await client.auth.signOut();
        debugPrint('$_logTag Refresh failed. Forcing sign out.');
        throw const AuthException('Session expired. Please sign in again.');
      }
      _logAccessTokenClaims(refreshed.session?.accessToken, label: 'refreshed');

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
        prompt: 'Quran recitation (Arabic). Expected verse: $targetArabic',
      );
      final score = computeSimilarityScore(transcript, targetArabic);
      final storagePath = _repo.buildStoragePath(
        surahId: state.surahId,
        ayahId: state.ayahId,
      );

      final ageYears = _resolveChildAgeYears();
      final meta = <String, dynamic>{
        if (ageYears != null && ageYears > 0) 'age_years': ageYears,
      };

      final payload = await _repo.submitRecitation(
        childId: effectiveChildId,
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
      debugPrint('$_logTag FunctionException status=${error.status} details=${error.details}');
      final message = error.status == 401
          ? 'Session invalid. Please sign out and sign in again.'
          : error.toString();
      state = state.copyWith(
        stage: RecitationStage.review,
        isBusy: false,
        errorMessage: message,
      );
    } on AuthException catch (error) {
      debugPrint('$_logTag AuthException message=${error.message}');
      state = state.copyWith(
        stage: RecitationStage.review,
        isBusy: false,
        errorMessage: error.message,
      );
    } catch (error) {
      debugPrint('$_logTag Unexpected error: $error');
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

  void _logAccessTokenClaims(String? token, {required String label}) {
    if (token == null || token.isEmpty) {
      debugPrint('$_logTag token($label)=missing');
      return;
    }
    final parts = token.split('.');
    if (parts.length != 3) {
      debugPrint('$_logTag token($label)=malformed parts=${parts.length}');
      return;
    }
    try {
      final payload = _decodeJwtPayload(parts[1]);
      final iss = payload['iss'];
      final aud = payload['aud'];
      final exp = payload['exp'];
      final iat = payload['iat'];
      final sub = payload['sub'];
      debugPrint('$_logTag token($label) iss=$iss aud=$aud exp=$exp iat=$iat sub=${_maskId(sub?.toString())}');
    } catch (error) {
      debugPrint('$_logTag token($label) decodeError=$error');
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String payload) {
    final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    final padded = normalized.padRight((normalized.length + 3) ~/ 4 * 4, '=');
    final decoded = utf8.decode(base64.decode(padded));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  String _maskId(String? value) {
    if (value == null || value.length < 6) {
      return value ?? '';
    }
    return '${value.substring(0, 3)}...${value.substring(value.length - 3)}';
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

  int? _resolveChildAgeYears() {
    final child = _selectedChild();
    final birthYear = child?.birthYear;
    if (birthYear == null) {
      return null;
    }
    final age = DateTime.now().year - birthYear;
    return age > 0 ? age : null;
  }

  void _logSessionState(Session session) {
    final userId = session.user.id;
    final expiresAt = session.expiresAt;
    final aud = session.user.aud;
    final hasRefresh = session.refreshToken != null && session.refreshToken!.isNotEmpty;
    final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
    debugPrint(
      '$_logTag session user=${_mask(userId)} aud=$aud expiresAt=$expiresAt refresh=$hasRefresh url=$supabaseUrl',
    );
  }

  String _mask(String value) {
    if (value.length <= 6) return value;
    return '${value.substring(0, 3)}...${value.substring(value.length - 3)}';
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
