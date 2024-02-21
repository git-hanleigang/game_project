--[[
    本地自定义的分组数据
]]
local BaseMailData = util_require("GameModule.Inbox.model.mailData.BaseMailData")
local BaseGroupMailData = class("BaseGroupMailData", BaseMailData)

function BaseGroupMailData:ctor()
    BaseGroupMailData.super.ctor(self)
    self.m_isGroup = true
end

function BaseGroupMailData:parseData(_data)
    BaseGroupMailData.super.parseData(self, _data)
    self.groupName = _data.groupName
    self.mailDatas = {}
    if _data.mailDatas and #_data.mailDatas > 0 then
        for i=1,#_data.mailDatas do
            table.insert(self.mailDatas, _data.mailDatas[i])
        end
    end
    
    -- 自定义必须字段
    self.type = InboxConfig.TYPE_LOCAL.group
end

function BaseGroupMailData:insertMailData(_mailData)
    if not self.mailDatas then
        self.mailDatas = {}
    end
    table.insert(self.mailDatas, _mailData)
end

function BaseGroupMailData:getGroupName()
    return self.groupName
end

function BaseGroupMailData:getMailDatas()
    return self.mailDatas
end

function BaseGroupMailData:removeMailDataById(_id)
    if self.mailDatas and #self.mailDatas > 0 then
        for i=1,#self.mailDatas do
            local mData = self.mailDatas[i]
            if tonumber(mData:getId()) == tonumber(_id) then
                table.remove(self.mailDatas, i)
            end
        end
    end
end

function BaseGroupMailData:getMailDataById(_id)
    if self.mailDatas and #self.mailDatas > 0 then
        for i=1,#self.mailDatas do
            local mData = self.mailDatas[i]
            if tonumber(mData:getId()) == tonumber(_id) then
                return mData
            end
        end
    end
    return nil
end

return BaseGroupMailData