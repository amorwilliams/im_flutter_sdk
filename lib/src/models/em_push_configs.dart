import 'package:flutter/services.dart';

import '../tools/em_extension.dart';

import 'em_domain_terms.dart';

enum EMImPushStyle{
  Simple,
  Summary
}

class EMImPushConfigs {

  EMImPushConfigs._private();
  static const _channelPrefix = 'com.easemob.im';
  // channel的命名与pushManager中的channel一致，本质上还是一个channel。
  static const MethodChannel _emPushManagerChannel = const MethodChannel('$_channelPrefix/em_push_manager', JSONMethodCodec());
  EMImPushStyle _pushStyle;
  bool _noDisturb;
  int _noDisturbStartHour;
  int _noDisturbEndHour;
  List<EMGroup> _noDisturbGroups = List();

  EMImPushStyle get pushStyle => _pushStyle;
  bool get noDisturb => _noDisturb;
  int get noDisturbStartHour => _noDisturbStartHour;
  int get noDisturbEndHour => _noDisturbEndHour;
  List<EMGroup> get noDisturbGroups => _noDisturbGroups;

  /// 设置是否免打扰[isNoDisturb], [startTime], [endTime]
  Future<bool> setNoDisturb(bool isNoDisturb, [int startTime = 0, int endTime = 24]) async {
    if(startTime < 0) startTime = 0;
    if(endTime > 24) endTime = 24;
    Map req = {'noDisturb': isNoDisturb, 'startTime': startTime, 'endTime': endTime};
    Map result = await _emPushManagerChannel.invokeMethod(EMSDKMethod.imPushNoDisturb, req);
    EMError.hasErrorFromResult(result);
    bool success = result.boolValue(EMSDKMethod.imPushNoDisturb);
    if(success) {
      _noDisturb = isNoDisturb;
      _noDisturbStartHour = startTime;
      _noDisturbEndHour = endTime;
    }
    return success;
  }

  /// 设置消息推送显示样式[pushStyle]
  Future<bool> setPushStyle(EMImPushStyle pushStyle) async {
    Map req = {'pushStyle': pushStyle == EMImPushStyle.Simple ? 0 : 1};
    Map result = await _emPushManagerChannel.invokeMethod(EMSDKMethod.updateImPushStyle, req);
    EMError.hasErrorFromResult(result);
    bool success = result.boolValue(EMSDKMethod.updateImPushStyle);
    if(success) _pushStyle = pushStyle;
    return success;
  }

  /// 通过群id[groupId]设置群组是否免打扰[isNoDisturb]
  Future<EMGroup>setGroupToDisturb(String groupId, bool isNoDisturb) async {
    Map req = {'noDisturb': isNoDisturb, 'group_id': groupId};
    Map result = await _emPushManagerChannel.invokeMethod(EMSDKMethod.updateGroupPushService, req);
    EMError.hasErrorFromResult(result);
    EMGroup group = EMGroup.fromJson(result[EMSDKMethod.updateGroupPushService]);
    _noDisturbGroups.removeWhere((e) => e.groupId == group.groupId);
    if(isNoDisturb) _noDisturbGroups.add(group);
    return group;
  }

  /// 获取免打扰群组列表
  Future<List> noDisturbGroupsFromServer() async {
    Map result = await _emPushManagerChannel.invokeMethod(EMSDKMethod.getNoDisturbGroups);
    EMError.hasErrorFromResult(result);
    List list = List();
    (result[EMSDKMethod.getNoDisturbGroups] as List)?.forEach((element) {
      list.add(EMGroup.fromJson(element));
    });
    _noDisturbGroups = list;
    return list;
  }

  factory EMImPushConfigs.fromJson(Map map) {
    if(map == null) return null;
    return EMImPushConfigs._private()
      .._pushStyle = map['pushStyle'] == 0 ? EMImPushStyle.Simple : EMImPushStyle.Summary
      .._noDisturb = map.boolValue('noDisturb')
      .._noDisturbStartHour = map['noDisturbStartHour']
      .._noDisturbEndHour = map['noDisturbEndHour'];
  }

  Map toJson() {
    Map data = Map();
    data['pushStyle'] = _pushStyle == EMImPushStyle.Simple;
    data['noDisturb'] = _noDisturb;
    data['noDisturbStartHour'] = _noDisturbStartHour;
    data['noDisturbEndHour'] = _noDisturbEndHour;
    return data;
  }
}