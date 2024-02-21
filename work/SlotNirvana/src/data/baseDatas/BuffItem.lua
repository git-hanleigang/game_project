--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local BuffItem = class("BuffItem")
BuffItem.buffID = nil -- buff 唯一ID
BuffItem.buffType = nil -- buff 类型
BuffItem.buffDescription = nil -- buff 描述
BuffItem.buffDuration = nil -- buff 持续时间
BuffItem.buffExpire = nil -- buff 剩余时间
BuffItem.buffMultiple = nil -- buff 加成
BuffItem.name = nil -- buff 名字

function BuffItem:ctor()
end

function BuffItem:parseData(data)
    self.buffID = data.id
    self.buffType = data.type
    self.buffDescription = data.description
    self.buffDuration = data.duration
    self.buffExpire = data.expire
    self.buffMultiple = data.multiple
    self.name = data.name
end

function BuffItem:getExpire()
    return self.buffExpire or 0
end

function BuffItem:setExpire(_expire)
    self.buffExpire = _expire
end

function BuffItem:getDuration()
    return self.buffDuration or 0
end

function BuffItem:getMultiple()
    return self.buffMultiple or 0
end

function BuffItem:getBuffType()
    return self.buffType
end

return BuffItem
