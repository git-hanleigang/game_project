--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:31:23
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/TrillionChallengeRewardLayer.lua
Description: 亿万赢钱挑战 领奖弹板
--]]
local TrillionChallengeRewardLayer = class("TrillionChallengeRewardLayer", BaseLayer)

function TrillionChallengeRewardLayer:initDatas(_itemList, _coins)
    TrillionChallengeRewardLayer.super.initDatas(self)

    self._coins = _coins or 0
    self._itemList = _itemList or {}
    self._gems = 0
    self._propsBagist = {}
    for _, shopItem in pairs(_itemList) do
        if string.find(shopItem.p_icon, "Pouch") then
            table.insert(self._propsBagist, shopItem)
        elseif string.find(shopItem.p_icon, "Gem") then
            self._gems = tonumber(shopItem.p_num) or 0
        end
    end
    self:initDropList()
    self:setLandscapeCsbName("Activity/Activity_TrillionChallenge/csb/reward/TrillionChallenge_Reward.csb")
    self:setPortraitCsbName("Activity/Activity_TrillionChallenge/csb/reward/TrillionChallenge_Reward_shu.csb")
    self:setName("TrillionChallengeRewardLayer")
end

-- 初始化 list
function TrillionChallengeRewardLayer:initDropList()
    local _dropFuncList = {}

    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerDeluxeCard)
    _dropFuncList[#_dropFuncList + 1] = util_node_handler(self, self.triggerPropsBagView)

    self._dropFuncList = _dropFuncList
end

function TrillionChallengeRewardLayer:initView()
    TrillionChallengeRewardLayer.super.initView(self)
    
    -- 奖励
    local parent = self:findChild("node_reward")
    local itemNode = gLobalItemManager:addPropNodeList(self._itemList, ITEM_SIZE_TYPE.REWARD)
    parent:addChild(itemNode)
end

function TrillionChallengeRewardLayer:onClickMask()
    self:collectReward()
end
function TrillionChallengeRewardLayer:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:collectReward()
end

-- 领取奖励
function TrillionChallengeRewardLayer:collectReward()
    if self._bCollected then
        return
    end
    self._bCollected = true

    -- 领取 奖励
    if self._coins > 0 or self._gems > 0 then
        local btnCollect = self:findChild("btn_collect")
        local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
        local cuyMgr = G_GetMgr(G_REF.Currency)
        local flyList = {}
        if self._coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self._coins, startPos = startPos})
        end
        if self._gems > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = self._gems, startPos = startPos})
        end
        cuyMgr:playFlyCurrency(flyList, util_node_handler(self, self.triggerDropFuncNext))
    else
        self:triggerDropFuncNext()
    end
end

-- 检测 list 调用方法
function TrillionChallengeRewardLayer:triggerDropFuncNext()
    if not self._dropFuncList or #self._dropFuncList <= 0 then
        if tolua.isnull(self) then
            return
        end
        self:closeUI()
        return
    end

    local func = table.remove(self._dropFuncList, 1)
    func()
end

-- 检测高倍场体验卡
function TrillionChallengeRewardLayer:triggerDeluxeCard()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DROP_DELUXE_CARD_ITEM, util_node_handler(self, self.triggerDropFuncNext))
end

-- 检测掉落 合成福袋
function TrillionChallengeRewardLayer:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self._propsBagist, util_node_handler(self, self.triggerDropFuncNext))
end

return TrillionChallengeRewardLayer