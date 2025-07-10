import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

String id = "070a8a7bfea444c281bbf465503c9ed4";
String token =
    "007eJxTYFhQWde77OFcCzu7m/9d527V+5Kx8uXL/RMN1qUIBq7I8pqrwGBmmmZknphikpiaamBiapmUaJFkYpJsbmFmmWySnGKaVjUnP6MhkJFh4a0uRkYGCATxWRk8UnNy8hkYACfcImE=";
int? remoteUid;
String channel = "Hello";
bool isMicOn = true;
bool isSpeakerOn = true;
bool engineInitialized = false;

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  RtcEngine? _engine;
  bool _localUserJoined = false;
  int? _remoteUid;
  Future<void> _initializeAgoraVoiceSDK() async {
    log("Requesting permissions...");
    await _requestPermissions();

    log("Creating RTC engine...");
    _engine = createAgoraRtcEngine();

    await _engine?.initialize(
      RtcEngineContext(
        appId: id,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ),
    );
    await _engine?.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    await _engine?.enableVideo();

    await _engine?.startPreview();

    await _engine?.setVideoEncoderConfiguration(
      const VideoEncoderConfiguration(
        dimensions: VideoDimensions(width: 640, height: 360),
      ),
    );

    _setupEventHandlers();

    engineInitialized = true;
    log("Initialization complete ✅");
  }

  // Register an event handler for Agora RTC
  void _setupEventHandlers() {
    log("Event handlers registered");
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          log("Local user ${connection.localUid} joined the channel.");
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          log("Remote user $remoteUid joined the channel.");
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              log("Remote user $remoteUid went offline. Reason: $reason");
              setState(() => _remoteUid = null);
            },
        onError: (ErrorCodeType err, String msg) {
          log("Error Code: $err - Message: $msg");
        },
      ),
    );
  }

  // Join a channel
  Future<void> _joinChannel() async {
    log("Attempting to join channel...");

    if (!engineInitialized) {
      log("Engine not initialized yet. Initializing now...");
      await _initializeAgoraVoiceSDK();
      log("Engine initialized successfully.");
    }

    try {
      await _engine!.joinChannel(
        token: token,
        channelId: channel,
        options: const ChannelMediaOptions(
          autoSubscribeVideo: true,
          autoSubscribeAudio: true,
          publishCameraTrack: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
        uid: 0,
      );
      log("joinChannel() call completed");
    } catch (e) {
      log("[ERROR] Failed to join channel: $e");
    }
  }

  Widget _remoteVideo() {
    log("Remote UID: $_remoteUid");
    if (_remoteUid != null) {
      log("Displaying remote video for UID: $_remoteUid");
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: channel),
        ),
      );
    } else {
      log("No remote user yet. Showing placeholder...");
      return Container(
        decoration: BoxDecoration(color: Colors.grey[900]),
        child: Center(
          child: Text(
            'Waiting for remote user to join...',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.camera].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Agora Video Call",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Remote video with dark overlay when no connection
          Positioned.fill(child: _remoteVideo()),
          // Local video preview with border
          if (_localUserJoined)
            Positioned(
              top: 20,
              right: 20,
              width: 100,
              height: 140,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: _engine!,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            ),
          // Top action bar (camera switch)
          Positioned(
            top: 20,
            left: 20,
            child: (_localUserJoined)
                ? CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      icon: Icon(
                        Icons.switch_camera_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () async => await _engine!.switchCamera(),
                    ),
                  )
                : Container(),
          ),
          // Bottom control panel
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                (_localUserJoined)
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue.withOpacity(0.2),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blueAccent,
                              child: IconButton(
                                icon: Icon(
                                  isMicOn ? Icons.mic : Icons.mic_off,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () {
                                  isMicOn = !isMicOn;
                                  _engine!.muteLocalAudioStream(isMicOn);
                                  setState(() {});
                                  log("Microphone toggle: $isMicOn");
                                },
                              ),
                            ),
                          ),
                          SizedBox(width: 30),
                          // Speaker toggle
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.green.withOpacity(0.2),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.blueAccent,
                              child: IconButton(
                                icon: Icon(
                                  isSpeakerOn
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                  size: 26,
                                ),
                                onPressed: () {
                                  isSpeakerOn = !isSpeakerOn;
                                  _engine!.setEnableSpeakerphone(isSpeakerOn);
                                  setState(() {});
                                  log("Speaker toggle: $isSpeakerOn");
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(),

                SizedBox(height: 30),
                // Start/End call buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Start call button
                    if (!_localUserJoined)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          await _joinChannel();
                          setState(() {
                            _localUserJoined = true;
                            _remoteUid = null;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "Start Call",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // End call button
                    if (_localUserJoined)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () async {
                          await _engine!.leaveChannel();
                          await _engine!.release();
                          setState(() {
                            _localUserJoined = false;
                            _remoteUid = null;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.call_end, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              "End Call",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
