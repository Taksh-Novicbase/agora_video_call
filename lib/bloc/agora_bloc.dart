import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import 'agora_event.dart';
import 'agora_state.dart';

const appId = "070a8a7bfea444c281bbf465503c9ed4";
const token =
    "007eJxTYLh1I9v7/6pVSr6N2gc1nzTM2K9656iOIs+HI6eMpfVfZ5xUYDAzTTMyT0wxSUxNNTAxtUxKtEgyMUk2tzCzTDZJTjFNWzGhIKMhkJFhdeUCVkYGCATxWRk8UnNy8hkYAO5aIZs=";
const channel = "Hello";

class CallBloc extends Bloc<CallEvent, AgoraState> {
  CallBloc() : super(AgoraInitial()) {
    on<InitializeEngineEvent>(_onInit);
    on<JoinChannelEvent>(_onJoin);
    on<LeaveChannelEvent>(_onLeave);
    on<VideoCallEvent>(_videoCallEvent);
  }

  Future<void> _onInit(
    InitializeEngineEvent event,
    Emitter<AgoraState> emit,
  ) async {
    emit(AgoraLoading());
    await [Permission.microphone, Permission.camera].request();

    final engine = createAgoraRtcEngine();
    await engine.initialize(
      const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );

    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await engine.enableVideo();
    await engine.startPreview();
    await engine.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
      ),
    );

    // ✅ Emit first to ensure state is AgoraVideoCallProcess
    final stateToEmit = AgoraVideoCallProcess(
      engine: engine,
      localUserJoined: false,
      remoteUid: null,
      isMicOn: true,
      isSpeakerOn: true,
    );
    emit(stateToEmit);

    // ✅ Now register event handlers
    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          log("✅ Local user joined");
          final current = state;
          if (current is AgoraVideoCallProcess) {
            emit(current.copyWith(localUserJoined: true));
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          log("👥 Remote user $remoteUid joined");
          final current = state;
          if (current is AgoraVideoCallProcess) {
            add(VideoCallEvent(Remoteid: remoteUid));
          } else {
            log("⚠️ State was not AgoraVideoCallProcess when remote joined");
          }
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              log("🚪 Remote user $remoteUid left");
              final current = state;
              if (current is AgoraVideoCallProcess) {
                // emit(current.copyWith(remoteUid: null));
              }
            },
        onError: (ErrorCodeType code, String msg) {
          log("❌ Agora Error: $code - $msg");
          emit(AgoraError(message: msg));
        },
      ),
    );

    // 🔁 Join channel
    add(JoinChannelEvent());
  }

  Future<void> _onJoin(JoinChannelEvent event, Emitter<AgoraState> emit) async {
    final current = state;
    if (current is! AgoraVideoCallProcess) {
      add(InitializeEngineEvent());
      return;
    }
    await current.engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _onLeave(
    LeaveChannelEvent event,
    Emitter<AgoraState> emit,
  ) async {
    final current = state;
    if (current is AgoraVideoCallProcess) {
      await current.engine.leaveChannel();
      await current.engine.release();
    }
    emit(AgoraInitial());
  }

  // Future<void> _onToggleMic(
  //   ToggleMicEvent event,
  //   Emitter<AgoraState> emit,
  // ) async {
  //   final current = state;
  //   if (current is AgoraVideoCallProcess) {
  //     final newMicState = !current.isMicOn;
  //     await current.engine.muteLocalAudioStream(!newMicState);
  //     emit(current.copyWith(isMicOn: newMicState));
  //   }
  // }

  // Future<void> _onToggleSpeaker(
  //   ToggleSpeakerEvent event,
  //   Emitter<AgoraState> emit,
  // ) async {
  //   final current = state;
  //   if (current is AgoraVideoCallProcess) {
  //     final newSpeakerState = !current.isSpeakerOn;
  //     await current.engine.setEnableSpeakerphone(newSpeakerState);
  //     emit(
  //       AgoraVideoCallProcess(
  //         engine: current.engine,
  //         localUserJoined: current.localUserJoined,
  //         remoteUid: current.remoteUid,
  //         isMicOn: current.isMicOn,
  //         isSpeakerOn: newSpeakerState,
  //       ),
  //     );

  FutureOr<void> _videoCallEvent(
    VideoCallEvent event,
    Emitter<AgoraState> emit,
  ) {
    emit((state as AgoraVideoCallProcess).copyWith(remoteUid: event.Remoteid));
  }
}
