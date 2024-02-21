--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-08-18 18:08:52
    describe:品质头像框挑战
]]
--[[
    message QualityAvatarFrameChallenge {
        optional string activityId = 1;//活动id
        optional int64 expireAt = 2;//活动过期时间戳
        optional int32 expire = 3;//活动剩余秒数
        optional string frameType = 4;//头像框品质
        optional int64 coins = 5;//金币奖励
        repeated ShopItem itemList = 6;//物品奖励
        optional bool complete = 7;//是否全部完成
    }
]]
local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require "baseActivity.BaseActivityData"
local SpecialFrame_ChallengeData = class("SpecialFrame_ChallengeData", BaseActivityData)

function SpecialFrame_ChallengeData:parseData(_data)
    SpecialFrame_ChallengeData.super.parseData(self, _data)
    self.m_frameType = _data.frameType
    self.m_coins = tonumber(_data.coins)
    self.m_itemList = self:parseItemsData(_data.itemList)
    self.m_complete = _data.complete
    self.m_isPopup = false
end

-- 解析道具数据
function SpecialFrame_ChallengeData:parseItemsData(_data)
    local itemsData = {}
    if _data and #_data > 0 then
        for i, v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

-- 更新spin后的数据
function SpecialFrame_ChallengeData:parseSlotsData(_data)
    if not _data then
        return
    end
    self:parseData(_data)
    self.m_isPopup = true
end

function SpecialFrame_ChallengeData:getReward()
    return self.m_coins, self.m_itemList
end

function SpecialFrame_ChallengeData:getFrameType()
   return self.m_frameType
end

function SpecialFrame_ChallengeData:checkIsPopup()
    if self.m_complete then
        return self.m_isPopup
    end
    return false
 end

 function SpecialFrame_ChallengeData:getComplete()
    return self.m_complete
 end

 function SpecialFrame_ChallengeData:setIsPopup(bool)
    self.m_isPopup = bool
 end

return SpecialFrame_ChallengeData
