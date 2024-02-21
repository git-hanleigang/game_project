--[[
    author:{author}
    time:2023-10-26 21:39:02
]]

-- 协议
ProtoConfig.APP_CHARGE_COLLECT = {
    protoType = "APP_CHARGE_COLLECT",
    sign = "TOKEN",
    url = "/v1/game/appcharge/collect",
    request = GameProto_pb.AppChargeCollectRequest,
    response = GameProto_pb.PurchaseResponseV2
}

-- 事件
ViewEventType.NOTIFY_APP_CHARGE_COLLECTED = "NOTIFY_APP_CHARGE_COLLECTED"