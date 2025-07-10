import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

import 'agora_event.dart';
import 'agora_state.dart';

const appId = "070a8a7bfea444c281bbf465503c9ed4";
const token = "007eJxTYFhQWde77..."; // Shortened
const channel = "Hello";

class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc() : super(CallState.initial()) {
    on<InitializeEngineEvent>(_onInit);
    on<JoinChannelEvent>(_onJoin);
    on<LeaveChannelEvent>(_onLeave);
    on<ToggleMicEvent>(_onToggleMic);
    on<ToggleSpeakerEvent>(_onToggleSpeaker);
  }

  Future<void> _onInit(
    InitializeEngineEvent event,
    Emitter<CallState> emit,
  ) async {
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

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          log("Local user joined");
          emit(state.copyWith(localUserJoined: true));
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          log("Remote user $remoteUid joined");
          emit(state.copyWith(remoteUid: remoteUid));
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              log("Remote user $remoteUid left");
              emit(state.copyWith(remoteUid: null));
            },
        onError: (ErrorCodeType err, String msg) {
          log("Agora Error: $err - $msg");
        },
      ),
    );

    emit(state.copyWith(engineInitialized: true, engine: engine));
  }

  Future<void> _onJoin(JoinChannelEvent event, Emitter<CallState> emit) async {
    if (!state.engineInitialized) add(InitializeEngineEvent());
    await state.engine?.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );
  }

  Future<void> _onLeave(
    LeaveChannelEvent event,
    Emitter<CallState> emit,
  ) async {
    await state.engine?.leaveChannel();
    await state.engine?.release();
    emit(CallState.initial());
  }

  Future<void> _onToggleMic(
    ToggleMicEvent event,
    Emitter<CallState> emit,
  ) async {
    final newMicState = !state.isMicOn;
    await state.engine?.muteLocalAudioStream(!newMicState);
    emit(state.copyWith(isMicOn: newMicState));
  }

  Future<void> _onToggleSpeaker(
    ToggleSpeakerEvent event,
    Emitter<CallState> emit,
  ) async {
    final newSpeakerState = !state.isSpeakerOn;
    await state.engine?.setEnableSpeakerphone(newSpeakerState);
    emit(state.copyWith(isSpeakerOn: newSpeakerState));
  }
}
