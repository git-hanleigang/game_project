--[[
    本地自定义数据
]]
local BaseMailData = util_require("GameModule.Inbox.model.mailData.BaseMailData")
local BaseClientMailData = class("BaseClientMailData", BaseMailData)

function BaseClientMailData:ctor()
    BaseClientMailData.super.ctor(self)
    -- 网络邮件
    self.m_isNetMail = false
end

function BaseClientMailData:parseData(_netData)
    BaseClientMailData.super.parseData(self, _netData)
    for k,v in pairs(_netData) do
        if k ~= "class" then
            self[k] = v
        end
    end
    -- 自定义必须字段
    self.type = self.m_type
    self.id = InboxConfig.getClientMailId(self.type)
end

-- 结束时间(单位：秒)
function BaseClientMailData:getExpireTime()
    return 0
end

function BaseClientMailData:getLeftTime()
    local endTime = self:getExpireTime() or 0
    local leftTime  = endTime - util_getCurrnetTime()
    if leftTime > 0 then
        return leftTime
    end
    return 0
end

return BaseClientMailData