--[[
    Proto协议配置
    author:{author}
    time:2020-07-10 18:08:27
]]
GD.ProtoConfig = {}

-- 添加公会协议
require("net.ClanProtoConfig")

-- 全局配置协议
ProtoConfig.GAME_GLOBAL_CONFIG = {
    protoType = "GAME_GLOBAL_CONFIG",
    sign = "TIME",
    url = "/v1/game/config/activity",
    request = GameProto_pb.GameGlobalConfigRequest,
    response = BaseProto_pb.GameGlobalConfig
}

-- 苹果登陆
ProtoConfig.APPLE_LOGIN = {
    protoType = "APPLE_LOGIN",
    sign = "TIME",
    url = "/v1.2/connect/appleid",
    request = LoginProto_pb.ConnectAppleIdRequest,
    response = LoginProto_pb.ConnectResponse
}

-- Facebook登陆
ProtoConfig.FACEBOOK_LOGIN = {
    protoType = "FACEBOOK_LOGIN",
    sign = "TIME",
    url = "/v1.2/connect/facebook",
    request = LoginProto_pb.ConnectRequestV11,
    response = LoginProto_pb.ConnectResponse
}

-- 登陆协议
ProtoConfig.LOGIN = {
    protoType = "LOGIN",
    sign = "TIME",
    url = "/v1.2/login",
    request = LoginProto_pb.LoginRequest,
    response = LoginProto_pb.LoginResponse
}

-- Action数据协议
ProtoConfig.DATA_ACITON = {
    protoType = "DATA_ACITON",
    sign = "TOKEN",
    url = "/v1/game/action",
    request = GameProto_pb.ActionRequest,
    response = GameProto_pb.ActionResponse 
}
