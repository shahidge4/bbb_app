import 'package:bbb_app/src/connect/meeting/main_websocket/voice/voice_module.dart';
import 'package:bbb_app/src/connect/meeting/meeting_info.dart';
import 'package:bbb_app/src/connect/meeting/voice/voice_manager.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:sip_ua/sip_ua.dart';

class VoiceConnection extends VoiceManager implements SipUaHelperListener {
  MeetingInfo info;
  VoiceModule _module;
  Call _call;
  bool _audioMuted = false;
  bool _secondStream = false;

  VoiceConnection(this.info, this._module) : super(null) {
    helper.addSipUaHelperListener(this);
  }

  void connect() {
    helper.start(super.buildSettings());
  }

  void disconnect() {
    helper.stop();
  }

  void toggleMute(Call call) {
    if (_audioMuted) {
      call.unmute(true, false);
    } else {
      call.mute(true, false);
    }
    _audioMuted = !_audioMuted;
  }

  @override
  void callStateChanged(Call call, CallState state) {
    Log.info("[VoiceConnection] SIP call state changed to ${state.state}");

    _call = call;
    switch (state.state) {
      case CallStateEnum.CONFIRMED:
        _call.unmute(true, false);
        break;
      case CallStateEnum.STREAM:
        if (!_secondStream) {
          _secondStream = true;
        } else {
          _call.sendDTMF("1", {"duration": 2000});
        }
        break;
      default:
    }
  }

  @override
  void onNewMessage(SIPMessageRequest msg) {
    Log.info("[VoiceConnection] New message: '$msg'");
  }

  /// Probably useless, as we dont use registration
  @override
  void registrationStateChanged(RegistrationState state) {
    Log.info("[VoiceConnection] Registration changed to '${state.state}'");
  }

  @override
  void transportStateChanged(TransportState state) {
    Log.info("[VoiceConnection] Transport state changed to '${state.state}'");

    if (state.state == TransportStateEnum.CONNECTED) {
      helper.call(super.buildEcho(), true);
    }
  }
}
