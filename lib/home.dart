import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'bloc/agora_bloc.dart';
import 'bloc/agora_event.dart';
import 'bloc/agora_state.dart';

final _callBloc = CallBloc();

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Agora Video Call",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<CallBloc, AgoraState>(
        bloc: _callBloc,
        listener: (context, state) {
          if (state is AgoraError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Error: ${state.message}")));
          } else if (state is AgoraVideoCallProcess) {
            log("Video Call State: ${state.runtimeType}");
          }
        },
        builder: (context, state) {
          if (state is AgoraInitial) {
            return Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  _callBloc.add(InitializeEngineEvent());
                  // _callBloc.add(JoinChannelEvent());
                },
                icon: const Icon(Icons.call, color: Colors.white),
                label: const Text(
                  "Start Call",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            );
          } else if (state is AgoraLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is AgoraVideoCallProcess) {
            log("Video Call State: ${state.runtimeType}");
            log("remote user id: ${state.remoteUid}");
            return Stack(
              children: [
                Positioned.fill(
                  child: (state.remoteUid != null)
                      ? AgoraVideoView(
                          controller: VideoViewController.remote(
                            rtcEngine: state.engine,
                            canvas: VideoCanvas(uid: state.remoteUid),
                            connection: RtcConnection(channelId: "Hello"),
                          ),
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: const Center(
                            child: Text(
                              'Waiting for remote user to join...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  width: 100,
                  height: 150,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: state.engine,

                          canvas: const VideoCanvas(uid: 0),
                        ),
                      ),
                    ),
                  ),
                ),

                Positioned(
                  top: 30,
                  left: 20,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(
                        Icons.switch_camera_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () async {
                        await state.engine.switchCamera();
                      },
                    ),
                  ),
                ),

                // 🎛 Bottom controls
                Positioned(
                  bottom: 30,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🔴 End Call
                      ElevatedButton.icon(
                        onPressed: () {
                          _callBloc.add(LeaveChannelEvent());
                        },
                        icon: const Icon(Icons.call_end, color: Colors.white),
                        label: const Text(
                          "End Call",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(
              child: Text(
                "Unknown state",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
        },
      ),
    );
  }
}
