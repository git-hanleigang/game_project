--[[
Author: cxc
Date: 2022-03-28 14:36:33
LastEditTime: 2022-03-28 14:36:34
LastEditors: cxc
Description: 3日行为付费聚合活动 领奖弹板
FilePath: /SlotNirvana/src/activities/Activity_WildChallenge/views/rewards/WildChallengeActRewardLayer.lua
--]]
local WildChallengeActRewardLayer = class("WildChallengeActRewardLayer", BaseLayer)

function WildChallengeActRewardLayer:ctor()
    WildChallengeActRewardLayer.super.ctor(self)

    self.m_coins = 0 -- 奖励的金币数
    self.m_gems = 0 -- 奖励的钻石数
    self.m_itemList = {}

    self:setExtendData("WildChallengeActRewardLayer")
    local csbName = self:getCsbName()
    self:setLandscapeCsbName(csbName)
end

function WildChallengeActRewardLayer:getCsbName()
    return ""
end

function WildChallengeActRewardLayer:initDatas(_idx, _cb)
    local actData = G_GetMgr(ACTIVITY_REF.WildChallenge):getData()
    if actData then
        local phaseData = actData:getPhaseListDataByIdx(_idx)
        self.m_coins = phaseData:getCoins()
        self.m_gems = phaseData:getGems()
        self.m_itemList = phaseData:getItemList()
    end
    self.m_closeCb = _cb
end

function WildChallengeActRewardLayer:initView()
    WildChallengeActRewardLayer.super.initView(self)
    
    -- 道具
    local itemNode = gLobalItemManager:addPropNodeList(self.m_itemList, ITEM_SIZE_TYPE.REWARD, 1)
    self:findChild("node_reward"):addChild(itemNode)
end

function WildChallengeActRewardLayer:clickFunc(sender)
    local btnName = sender:getName()
    sender:setTouchEnabled(false)
    self:checkFlyCoins()
end

function WildChallengeActRewardLayer:onClickMask()
    self:checkFlyCoins()
end

function WildChallengeActRewardLayer:checkFlyCoins()
    if self.m_bCollected then
        return
    end
    self.m_bCollected = true
    
    if not self.m_coins or self.m_coins == 0 then
        self:triggerDropCrads()
        return
    end

    local callback = function()
        if tolua.isnull(self) then
            return
        end

        self:triggerDropCrads()
    end

    local btnCollect = self:findChild("btn_go")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local cuyMgr = G_GetMgr(G_REF.Currency)
    if cuyMgr then
        local flyList = {}
        if self.m_coins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos})
        end
        if self.m_gems > 0 then
            table.insert(flyList, {cuyType = FlyType.Gem, addValue = self.m_gems, startPos = startPos})
        end

        cuyMgr:playFlyCurrency(flyList, callback)
    else
        gLobalViewManager:pubPlayFlyCoin(
            startPos, 
            globalData.flyCoinsEndPos, 
            globalData.topUICoinCount, 
            self.m_coins, 
            callback
        )
    end

end

function WildChallengeActRewardLayer:triggerDropCrads()
    if not CardSysManager:needDropCards("Wild Challenge") then
        self:dropDeluxeCard()
        return
    end

    gLobalNoticManager:addObserver(
        self,
        function(sender, func)
            gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
            self:dropDeluxeCard()
        end,
        ViewEventType.NOTIFY_CARD_SYS_OVER
    )
    CardSysManager:doDropCards("Wild Challenge")
end

--同步高倍场体验卡
function WildChallengeActRewardLayer:dropDeluxeCard()
    local cb = function()
        self:closeUI()
    end

    if globalDeluxeManager then
        globalDeluxeManager:dropExperienceCardItemEvt(cb)
    else
        cb()
    end
end

function WildChallengeActRewardLayer:closeUI()
    --第二货币消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)

    WildChallengeActRewardLayer.super.closeUI(self, self.m_closeCb)
end

function WildChallengeActRewardLayer:getLanguageTableKeyPrefix()
    return "WildChallengeActRewardLayer"
end

return WildChallengeActRewardLayer