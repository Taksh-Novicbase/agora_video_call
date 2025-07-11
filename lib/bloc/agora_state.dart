import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

@immutable
sealed class AgoraState {
  const AgoraState();
}

final class AgoraInitial extends AgoraState {}

final class AgoraLoading extends AgoraState {}

final class AgoraVideoCallProcess extends AgoraState {
  final RtcEngine engine;
  final bool localUserJoined;
  final int? remoteUid;
  final bool isMicOn;
  final bool isSpeakerOn;

  const AgoraVideoCallProcess({
    required this.engine,
    required this.localUserJoined,
    required this.remoteUid,
    required this.isMicOn,
    required this.isSpeakerOn,
  });

  AgoraVideoCallProcess copyWith({
    RtcEngine? engine,
    bool? localUserJoined,
    int? remoteUid,
    bool? isMicOn,
    bool? isSpeakerOn,
  }) {
    return AgoraVideoCallProcess(
      engine: engine ?? this.engine,
      localUserJoined: localUserJoined ?? this.localUserJoined,
      remoteUid: remoteUid ?? this.remoteUid,
      isMicOn: isMicOn ?? this.isMicOn,
      isSpeakerOn: isSpeakerOn ?? this.isSpeakerOn,
    );
  }
}

final class AgoraVideoCallEnded extends AgoraState {}

final class AgoraError extends AgoraState {
  final String message;
  const AgoraError({required this.message});
}
