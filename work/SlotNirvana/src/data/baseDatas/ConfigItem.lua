--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
--
local ConfigItem = class("ConfigItem")

ConfigItem.p_id = nil --物品id
ConfigItem.p_description = nil --物品描述
ConfigItem.p_type1 = nil --类型1
ConfigItem.p_type2 = nil --类型2
ConfigItem.p_linkId = nil --linkid
ConfigItem.p_icon = nil --物品icon
ConfigItem.p_duration = nil --持续时间
ConfigItem.p_name = nil --道具名字
ConfigItem.p_subtitle = nil --数量介绍
function ConfigItem:ctor()
end

function ConfigItem:parseData(data)
    self.p_id = data.id
    self.p_description = data.description
    self.p_type1 = data.type1
    self.p_type2 = data.type2
    self.p_linkId = data.linkId
    self.p_icon = data.icon
    self.p_duration = data.duration
    self.p_name = data.name
    self.p_subtitle = data.subtitle
end

function ConfigItem:getId()
    return self.p_id
end

function ConfigItem:getType1()
    return self.p_type1
end

function ConfigItem:getType2()
    return self.p_type2
end

return ConfigItem
