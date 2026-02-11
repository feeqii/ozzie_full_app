import 'package:rive/rive.dart';

enum OzzieGuideState { idle, hint, celebrate, encourage }

class OzzieGuideController {
  OzzieGuideController({
    this.stateMachineName = 'GuideMachine',
    this.idleTriggerName = 'Idle',
    this.hintTriggerName = 'Point',
    this.celebrateTriggerName = 'Celebrate',
    this.encourageTriggerName = 'Encourage',
  });

  final String stateMachineName;
  final String idleTriggerName;
  final String hintTriggerName;
  final String celebrateTriggerName;
  final String encourageTriggerName;

  StateMachineController? _machine;
  SMITrigger? _idleTrigger;
  SMITrigger? _hintTrigger;
  SMITrigger? _celebrateTrigger;
  SMITrigger? _encourageTrigger;
  OzzieGuideState _currentState = OzzieGuideState.idle;

  bool attach(Artboard artboard, {String? overrideStateMachineName}) {
    dispose();

    final machineName = overrideStateMachineName ?? stateMachineName;
    final machine = StateMachineController.fromArtboard(artboard, machineName);
    if (machine == null) {
      return false;
    }

    artboard.addController(machine);
    _machine = machine;
    _idleTrigger = machine.findSMI<SMITrigger>(idleTriggerName);
    _hintTrigger = machine.findSMI<SMITrigger>(hintTriggerName);
    _celebrateTrigger = machine.findSMI<SMITrigger>(celebrateTriggerName);
    _encourageTrigger = machine.findSMI<SMITrigger>(encourageTriggerName);
    setState(_currentState);
    return true;
  }

  void setState(OzzieGuideState state) {
    _currentState = state;
    switch (state) {
      case OzzieGuideState.idle:
        _idleTrigger?.fire();
        break;
      case OzzieGuideState.hint:
        _hintTrigger?.fire();
        break;
      case OzzieGuideState.celebrate:
        _celebrateTrigger?.fire();
        break;
      case OzzieGuideState.encourage:
        _encourageTrigger?.fire();
        break;
    }
  }

  void dispose() {
    _machine?.dispose();
    _machine = null;
    _idleTrigger = null;
    _hintTrigger = null;
    _celebrateTrigger = null;
    _encourageTrigger = null;
  }
}
