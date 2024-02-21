--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-13 11:30:18
-- FIX IOS 0225
local ConfigItem = require "data.baseDatas.ConfigItem"
local BuffItem = require "data.baseDatas.BuffItem"
local ShopItem = class("ShopItem")

ShopItem.p_id = nil --道具id
ShopItem.p_description = nil --道具描述
ShopItem.p_icon = nil --道具icon
ShopItem.p_item = nil --道具id
ShopItem.p_num = nil --道具数量
ShopItem.p_activityId = nil --活动id
ShopItem.p_type = nil --类型
ShopItem.p_buff = nil --buffid
ShopItem.p_itemInfo = nil --物品信息
ShopItem.p_buffInfo = nil --buff信息
ShopItem.p_expireAt = nil --有效期时间戳
ShopItem.p_mark = nil --位置类型
ShopItem.p_limit = nil --数量限制位数
ShopItem.p_buyTipDesc = nil --购买成功是提示信息
ShopItem.p_showTempData = nil --因为策划的显示需求强制该更的临时数据
ShopItem.p_fntConfig = nil --修改字体
function ShopItem:ctor()
end

function ShopItem:parseData(data)
    self.p_id = data.id
    self.p_description = data.description
    self.p_icon = data.icon
    self.p_item = data.item
    self.p_num = data.num

    self.p_activityId = data.activityId
    self.p_type = data.type
    self.p_buff = data.buff
    self.p_duration = data.duration

    --item
    if data.itemInfo ~= nil then
        if self.p_itemInfo == nil then
            self.p_itemInfo = ConfigItem:create()
        end
        self.p_itemInfo:parseData(data.itemInfo)
    end
    if data.expireAt then
        self.p_expireAt = data.expireAt
    end
    --buff
    if data.buffInfo ~= nil then
        if self.p_buffInfo == nil then
            self.p_buffInfo = BuffItem:create()
        end

        self.p_buffInfo:parseData(data.buffInfo)
    end
    local strMark = data.mark
    self.p_mark = util_string_split_pro(strMark, ";")
    self.p_limit = 6 --数量显示限制最大为6位

    --vip特殊处理服务器可能没有发icon
    if self.p_id == 10002 and self.p_icon == "" then
        self.p_icon = "Vip"
    end
    self.p_showTempData = nil
    self.p_fntConfig = nil
    
    -- 支持外部自定义格式化方法
    self.p_formatFunc = nil
end

function ShopItem:getId()
    return self.p_id
end

function ShopItem:getNum()
    return self.p_num or 0
end

function ShopItem:setNum(_newNum)
    self.p_num = _newNum
end

function ShopItem:getType()
    return self.p_type
end

function ShopItem:getItemInfo()
    return self.p_itemInfo
end

function ShopItem:getBuffInfo()
    return self.p_buffInfo
end

function ShopItem:getData()
    return clone(self)
end

--是否在保质期
function ShopItem:checkEffective()
    local corrcent = util_getCurrnetTime()
    if corrcent < tonumber(self.p_expireAt) / 1000 then
        return true
    end
    return false
end

--是否是buff
function ShopItem:isBuff()
    if self.p_type and self.p_type == "Buff" and self.p_buffInfo and self.p_buffInfo.buffExpire then
        return true
    end
    return false
end
--获取buff类型
function ShopItem:getBuffType()
    return self.p_buffInfo:getBuffType()
end
--获取buff加成
function ShopItem:getBuffMultiple()
    return self.p_buffInfo:getMultiple()
end
--获得buff持续时间值
function ShopItem:getBuffValue(mul)
    if self:isBuff() then
        mul = mul or 1
        local buffexpire = self.p_buffInfo.buffExpire
        if buffexpire and mul > 1 then
            buffexpire = buffexpire * mul
        end
        return util_switchSecondsToHSM(buffexpire)
    end
end
--获取常规数量值
function ShopItem:getNormalValue(mul)
    local limit = self.p_limit or 6
    local num = self.p_num
    if num and mul > 1 then
        num = num * mul
    end
    if self.p_formatFunc then
        return self.p_formatFunc(num, limit)
    else
        return util_formatCoins(num, limit, nil, nil, true)
    end
end
--获取道具名称
function ShopItem:getItemName()
    if self:isBuff() then
        if self.p_buffInfo.name and self.p_buffInfo.name ~= "" then
            return self.p_buffInfo.name
        end
    else
        if self.p_itemInfo and self.p_itemInfo.p_name and self.p_itemInfo.p_name ~= "" then
            return self.p_itemInfo.p_name
        end
    end
    --未配置显示道具icon
    return self.p_icon
end
--获取描述信息
function ShopItem:getSubtitle(value)
    if not self.p_itemInfo then
        return
    end
    if self.p_icon == "CashBack" then
        --caskback特殊道具特殊处理
        return self:getBuffMultiple() .. "%"
    elseif string.find(self.p_itemInfo.p_subtitle, "%%s") then
        --读取带数量的配置
        return string.format(self.p_itemInfo.p_subtitle, tostring(value))
    elseif self.p_itemInfo.p_subtitle == ITEM_DESC_NODEVALUE.NODE_STAR then
        return ITEM_DESC_NODEVALUE.NODE_STAR
    elseif self.p_itemInfo.p_subtitle == ITEM_DESC_NODEVALUE.NODE_JACKPOT_RETURN then
        return ITEM_DESC_NODEVALUE.NODE_JACKPOT_RETURN
    else
        return self.p_itemInfo.p_subtitle
    end
end
function ShopItem:getBuyTipDesc()
    return self.p_buyTipDesc
end

--支付打点
function ShopItem:getIapLogStr()
    if self:isBuff() then
        local itemBuff = self.p_buffInfo
        local buffMultiple = itemBuff.buffMultiple or "nil"
        local buffExpire = (itemBuff.buffExpire or 1) * 1000
        local itemStr = "Buff|" .. self:getItemName() .. "|" .. buffMultiple .. "|" .. buffExpire
        return itemStr
    else
        --道具类型|道具ID|道具名称|道具数量
        local type = self.p_type or "Item"
        local icon = self.p_icon or "nil"
        local num = self.p_num or 1
        local itemStr = type .. "|" .. icon .. "|" .. self:getItemName() .. "|" .. num
        return itemStr
    end
end

--因为策划的显示需求强制该更的临时数据 tempData需要更新的临时数据,isClear是否清理之前的设置
-- {
--     p_mark = {位置类型,...},
--     p_limit = 金币上线,
--     p_num = 道具数量,
--     p_fntConfig = {path = 字体路径,scale = 字体大小,pos = 位置偏移量},
-- }
function ShopItem:setTempData(tempData, isClear)
    if not self.p_showTempData or isClear then
        self.p_showTempData = tempData
    else
        if tempData then
            for key, value in pairs(tempData) do
                self.p_showTempData[key] = value
            end
        end
    end
end
--更新临时显示数据并且清空
function ShopItem:updateTempData()
    if self.p_showTempData and tolua.type(self.p_showTempData) == "table" then
        for key, value in pairs(self.p_showTempData) do
            self[key] = value
        end
        self.p_showTempData = nil
    end
end

-- 是否是magic卡道具
-- magic卡和quest magic的道具前缀是一样的
function ShopItem:isMagicCardItem()
    if self.p_icon and string.find(self.p_icon, "Card_Magic") then
        return true
    end
    return false
end

return ShopItem
