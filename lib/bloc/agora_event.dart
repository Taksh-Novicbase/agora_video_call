abstract class CallEvent {}

class InitializeEngineEvent extends CallEvent {}

class JoinChannelEvent extends CallEvent {}

class LeaveChannelEvent extends CallEvent {}

class ToggleMicEvent extends CallEvent {}

class ToggleSpeakerEvent extends CallEvent {}
