--[[
    邮件数据通用基类
    包含所有类型的数据中都必须有的参数
]]
local BaseMailData = class("BaseMailData")

function BaseMailData:ctor()
    -- 服务器邮件
    self.m_isNetMail = false
    -- 分组数据
    self.m_isGroup = false
    -- 有倒计时的
    self.m_isTimeLimit = false
end

function BaseMailData:parseData(_data)
    self.id = _data.id
    self.type = _data.type
end

function BaseMailData:getId()
    return self.id
end

function BaseMailData:getType()
    return self.type
end

function BaseMailData:isNetMail()
    return self.m_isNetMail
end

function BaseMailData:isGroup()
    return self.m_isGroup
end

function BaseMailData:isTimeLimit()
    return self.m_isTimeLimit
end

return BaseMailData
