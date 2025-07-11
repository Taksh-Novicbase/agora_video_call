abstract class CallEvent {}

class InitializeEngineEvent extends CallEvent {}

class JoinChannelEvent extends CallEvent {}

class LeaveChannelEvent extends CallEvent {}

class VideoCallEvent extends CallEvent {
  final int Remoteid;
  VideoCallEvent({required this.Remoteid});
}

// class ToggleMicEvent extends CallEvent {}
//
// class ToggleSpeakerEvent extends CallEvent {}
