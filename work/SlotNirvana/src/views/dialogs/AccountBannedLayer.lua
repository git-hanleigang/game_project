--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-05-17 10:19:18
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-05-17 10:19:32
FilePath: /SlotNirvana/src/views/dialogs/AccountBannedLayer.lua
Description: 用户作弊被警告 或者 封号 弹板。 登录时弹(在线服务器只踢。网络连接错误板子)
--]]
local AccountBannedLayer = class("AccountBannedLayer", BaseLayer)

function AccountBannedLayer:initDatas(_bannedInfo, _ignoreCb)
    AccountBannedLayer.super.initDatas(self)

    _bannedInfo = _bannedInfo or {}
    self.m_code = _bannedInfo.code -- 账号状态code
    self.m_unsealTime = _bannedInfo.unsealTime-- 账号解封时间戳 毫秒
    self.m_ignoreCb = _ignoreCb -- 警告后点击正常登录

    local csbName = "Dialog/BlockPopup_2.csb" -- 警告
    if self.m_code == BaseProto_pb.ACCOUNT_BLOCKED and self.m_unsealTime then
        -- 封号
        csbName = "Dialog/BlockPopup_1.csb"
    end
    self:setLandscapeCsbName(csbName)
end

function AccountBannedLayer:initView(_bannedInfo)
    if self.m_code ~= BaseProto_pb.ACCOUNT_BLOCKED or not self.m_unsealTime then
        return
    end
    local lbUnsealTime = self:findChild("lb_text")
    local timeStr = self:getUnsealTimeStr(lbUnsealTime:getString())
    lbUnsealTime:setString(timeStr)
end

function AccountBannedLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_quit" or name == "btn_ok" then
        if self.m_code == BaseProto_pb.ACCOUNT_WARNING and self.m_ignoreCb then
            self.m_ignoreCb()
            self:closeUI()
            return
        end
        if device.platform == "ios" then
            os.exit()
        else
            local director = cc.Director:getInstance()
            director:endToLua()
        end
    elseif name == "btn_contactus" then
        self:contactUS()
    end
end

function AccountBannedLayer:contactUS()
    globalData.newMessageNums = nil
    globalData.skipForeGround = true
    globalPlatformManager:openAIHelpRobot("AccountClosure")
end

function AccountBannedLayer:getUnsealTimeStr(_formatStr)
    _formatStr = _formatStr or "%s"
    local timeSec = math.ceil(self.m_unsealTime * 0.001)
    local timePst = util_UTC2TZ(timeSec, -8)
    local hour = timePst.hour
    local hourAPStr = hour > 11 and "pm" or "am"
    if hour > 12 then
        hour = hour - 12
    end
    -- This block will expire on Apr 1, 2022 at 12:00 am PST.
    local timeFormat = string.format("%s %s, %s at %02d:%02d %s PST", FormatMonth[timePst.month], timePst.day, timePst.year, hour, timePst.min, hourAPStr)
    return string.format(_formatStr, timeFormat)
end

return AccountBannedLayer