--[[
    author:{author}
    time:2019-04-18 21:53:40
]]

local JackpotPushData = class("JackpotPushData")

JackpotPushData.p_udid = nil
JackpotPushData.p_nickname = nil
JackpotPushData.p_gameId = nil         -- 关卡id
JackpotPushData.p_winCoins = nil
JackpotPushData.p_time = nil
JackpotPushData.p_facebookId = nil
JackpotPushData.p_isPushed = nil
JackpotPushData.p_head = nil
JackpotPushData.p_frameId = nil

function JackpotPushData:ctor( )

end

function JackpotPushData:parseData( data )
    self.p_udid = data.udid         -- 价格
    self.p_nickname = data.nickname        -- 商品 Key
    self.p_gameId = data.gameId         -- 基础金币
    self.p_winCoins = data.winCoins          -- pay table
    self.p_time = data.time
    self.p_facebookId = data.facebookId
    self.p_isPushed = false
    self.p_head = data.head or 0 -- 头像
    self.p_frameId = data.frame  -- 头像框

    if data.udid == globalData.userRunData.userUdid then
        if not gLobalSendDataManager:getIsFbLogin() then
            -- 如果是我自己 并且 我没有登录facebook那么置空的facebookid (服务器不知道你退出了facebook)
            self.p_fbid = ""
        end
        self.p_head = globalData.userRunData.HeadName or 1
    end
end

function JackpotPushData:resetData()

end

return JackpotPushData