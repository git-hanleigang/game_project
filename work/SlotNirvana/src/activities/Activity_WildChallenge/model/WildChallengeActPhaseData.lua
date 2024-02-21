--[[
Author: cxc
Date: 2022-03-23 16:10:10
LastEditTime: 2022-03-23 16:10:11
LastEditors: cxc
Description: 3日行为付费聚合活动  阶段数据类
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/model/WildChallengeActPhaseData.lua
--]]
local WildChallengeActPhaseData = class("WildChallengeActPhaseData")
local ShopItem = util_require("data.baseDatas.ShopItem")

-- message WildChallengeTask {
--     optional int32 seq = 1; //任务序号
--     optional int32 status = 2; //任务状态 0初始化 1开启 2完成 3已领取
--     optional int64 param = 3; // 参数
--     optional int64 progress = 4; //进度
--     optional int64 coins = 5; //奖励金币
--     repeated ShopItem items = 6; //奖励物品
--     optional string text = 7; //描述
--     optional string navigate = 8; //导航
--     optional string button = 9; //按钮描述
--     optional string extendType = 10; //任务类型:SpinTimes,WinTimes,SpinCoins,WinCoins,BigWin,-1,Any,购买类型
--   }
function WildChallengeActPhaseData:ctor()
    self.m_idx = 0
    self.m_status = 0
    self.m_progressCur = 0
    self.m_progressLimit = 0
    self.m_coins = 0
    self.m_gems = 0
    self.m_itemList = {}
    self.m_tipStr = ""
    self.m_navigateKey = ""
    self.m_btnDescStr = ""
    self.m_extendType = ""
end

function WildChallengeActPhaseData:parseData(_data)
    self.m_idx = _data.seq or 0
    self.m_status = _data.status or 0
    self.m_progressLimit = tonumber(_data.param) or 0
    self.m_progressCur = tonumber(_data.progress) or 0
    self.m_coins = tonumber(_data.coins) or 0
    self:parseItemList(_data.items or {})
    self.m_tipStr = _data.text or ""
    self.m_navigateKey = _data.navigate or ""
    self.m_btnDescStr = _data.button or ""
    self.m_extendType = _data.extendType or ""
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_WILD_CHALLENGE_DATA_UPDATE)
end

function WildChallengeActPhaseData:parseItemList(_items)
    self.m_itemList = {}

    if self.m_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_coins,{p_limit = 3})
        table.insert(self.m_itemList, itemData)
    end

    for i = 1, #_items do
		local itemData = _items[i]
		local rewardItem = ShopItem:create()
		rewardItem:parseData(itemData)
        if rewardItem.p_icon == "Gem" then
            self.m_gems = self.m_gems + rewardItem:getNum()
        end
		table.insert(self.m_itemList, rewardItem)
	end
end

function WildChallengeActPhaseData:getIdx()
    return self.m_idx
end

function WildChallengeActPhaseData:getStatus()
    return self.m_status
end

function WildChallengeActPhaseData:getProgressCur()
    return self.m_progressCur
end
function WildChallengeActPhaseData:getProgressLimit()
    return self.m_progressLimit
end

function WildChallengeActPhaseData:getCoins()
    return self.m_coins
end

function WildChallengeActPhaseData:getGems()
    return self.m_gems or 0
end

function WildChallengeActPhaseData:getItemList()
    return self.m_itemList
end

function WildChallengeActPhaseData:getTipStr()
    return self.m_tipStr
end

function WildChallengeActPhaseData:getNavigateKey()
    return self.m_navigateKey
end

function WildChallengeActPhaseData:getBtnDescStr()
    return self.m_btnDescStr or "COLLECT"
end

function WildChallengeActPhaseData:getExtendType()
    return self.m_extendType
end

function WildChallengeActPhaseData:isFirst()
    return self.m_idx == 1
end

-- free类型
function WildChallengeActPhaseData:isFree()
    if self.m_tipStr and string.len(self.m_tipStr) > 0 and string.lower(self.m_tipStr) == "free" then
        return true
    end
    return false
end

function WildChallengeActPhaseData:isCollectCoins()
    if self.m_extendType == "SpinCoins" or self.m_extendType == "WinCoins" then
        return true
    end
    return false
end

return WildChallengeActPhaseData
