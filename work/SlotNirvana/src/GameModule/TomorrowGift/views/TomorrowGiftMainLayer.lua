--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-01 11:31:58
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-01 14:31:59
FilePath: /SlotNirvana/src/GameModule/TomorrowGift/views/TomorrowGiftMainLayer.lua
Description: 次日礼物主界面
--]]
local TomorrowGiftMainLayer = class("TomorrowGiftMainLayer", BaseLayer)
local TomorrowGiftConfig = util_require("GameModule.TomorrowGift.config.TomorrowGiftConfig")

function TomorrowGiftMainLayer:initDatas()
    TomorrowGiftMainLayer.super.initDatas(self)
    
    self.m_data = G_GetMgr(G_REF.TomorrowGift):getRunningData()
    self.m_unlockTime = self.m_data:getUnlockTime()
    self.m_bUnlock = self.m_data:checkIsUnlock()
    self.m_unlockLevelData = self.m_data:getUnlockLevelData()

    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("Activity/TomorrowGift/csb/TomorrowGift_MainLayer.csb")
    self:setPortraitCsbName("Activity/TomorrowGift/csb/TomorrowGift_MainLayer_shu.csb")
end

function TomorrowGiftMainLayer:initCsbNodes()
    TomorrowGiftMainLayer.super.initCsbNodes(self)
    
    self.m_lbCoins = self:findChild("lb_coin")
    self.m_alignUIList = {
        {node = self:findChild("sp_coin")},
        {node = self.m_lbCoins, alignX = 5}
    }
end

function TomorrowGiftMainLayer:initView()
    -- 任务信息
    self:initTaskInfoUI()
    -- 礼包动画
    self:initGiftBoxAniUI()
    -- if self.m_bUnlock then
    --     -- 金币
    --     self:showUnlockCoinsUI() 
    -- else
        -- 金币
        self:initCoinsUI()
        -- 锁 倒计时 动画UI
        self:initUnlockAniUI()
    -- end
    -- 按钮
    self:initBtnUI()
end

-- 任务信息
function TomorrowGiftMainLayer:initTaskInfoUI()
    local parent = self:findChild("node_extraBonus")
    local unlockIdx = 0 
    if self.m_unlockLevelData then
        unlockIdx = self.m_unlockLevelData:getIdx()
    end
    local view = util_createView("GameModule.TomorrowGift.views.TomorrowGiftTaskUI", self.m_data, unlockIdx)
    parent:addChild(view)
    self.m_taskView = view
end

-- 礼包动画
function TomorrowGiftMainLayer:initGiftBoxAniUI()
    local parent = self:findChild("node_gift")
    local aniView = util_createAnimation("Activity/TomorrowGift/csb/TomorrowGift_Gift.csb")
    parent:addChild(aniView)
    aniView:playAction("idle", true)
end

-- 金币 基础值 未解锁
function TomorrowGiftMainLayer:initCoinsUI()
    local coins = self.m_data:getCoins()
    self.m_lbCoins:setString(util_formatCoins(coins, 20))
    self:updateCoinLbSizeScale() 
end
-- 金币 解锁后加成 的最终值
function TomorrowGiftMainLayer:showUnlockCoinsUI()
    local newCoins = self.m_data:getCoins()
    if self.m_unlockLevelData then
        local multi = self.m_unlockLevelData:getMultiple()
        newCoins = math.floor(newCoins * multi)
    end
    self.m_lbCoins:setString(util_formatCoins(newCoins, 20))
    self:updateCoinLbSizeScale() 
    self._rewardCoins = newCoins
end
-- 更新金币size 大小
function TomorrowGiftMainLayer:updateCoinLbSizeScale()
    util_alignCenter(self.m_alignUIList, 0, 1000)
end
-- 解锁播放 金币增长动画
function TomorrowGiftMainLayer:lbWinJumCoinsAni()
    local lbCoins = self:findChild("lb_coin")
    local baseCoins = self.m_data:getCoins()
    local newCoins = self.m_data:getCoins()
    if self.m_unlockLevelData then
        local multi = self.m_unlockLevelData:getMultiple()
        newCoins = math.floor(baseCoins * multi)
    end

    local subV = newCoins - baseCoins
    local addV = subV / (0.5 * 60)
    util_jumpNumExtra(self.m_lbCoins, baseCoins, newCoins, addV, 1/60, util_getFromatMoneyStr, {20}, nil, nil, util_node_handler(self, self.showUnlockCoinsUI), util_node_handler(self, self.updateCoinLbSizeScale))
end

function TomorrowGiftMainLayer:initUnlockAniUI()
    local parent = self:findChild("node_suo")
    local view = util_createView("GameModule.TomorrowGift.views.TomorrowGiftMainLockNode", self)
    parent:addChild(view)
    self.m_unlockAniView = view
end

-- 按钮
function TomorrowGiftMainLayer:initBtnUI()
    local parent = self:findChild("node_button")
    local view = util_createView("GameModule.TomorrowGift.views.TomorrowGiftMainButtonUI", self, self.m_bUnlock)
    parent:addChild(view)
    self.m_btnView = view
end

-- 解锁 礼包权益
function TomorrowGiftMainLayer:unlockGiftBenefit()
    self.m_bUnlock = true
    local startPosW = self.m_taskView:getUnlockFlyPosW()
    if startPosW then
        -- 任务分粒子 到 金币 并解锁
        local flyEf = util_createView("GameModule.TomorrowGift.views.TomorrowGiftMainFlyEftUI", self)
        self:addChild(flyEf)
        local endPosW = self.m_lbCoins:convertToWorldSpaceAR(cc.p(0,0))
        local endCb = function()
            self.m_unlockAniView:playUnlockAni()
            self:lbWinJumCoinsAni()
            self.m_btnView:updateBtnTextUI(self.m_bUnlock)
        end
        flyEf:fly(startPosW, endPosW, endCb)
    else
        self.m_unlockAniView:playUnlockAni()
        self:lbWinJumCoinsAni()
        self.m_btnView:updateBtnTextUI(self.m_bUnlock)   
    end
end

-- 飞金币
function TomorrowGiftMainLayer:flyCurrency(_cb)
    self._rewardCoins = self._rewardCoins or self.m_data:getCoins()
    local btnCollect = self:findChild("node_button")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local curMgr = G_GetMgr(G_REF.Currency)
    if curMgr then
        local flyList = {}
        if self._rewardCoins > 0 then
            table.insert(flyList, {cuyType = FlyType.Coin, addValue = self._rewardCoins, startPos = startPos})
        end
        curMgr:playFlyCurrency(flyList, _cb)
    else
        if self._rewardCoins <= 0 then
            _cb()
            return
        end
        gLobalViewManager:pubPlayFlyCoin(startPos, globalData.flyCoinsEndPos, globalData.topUICoinCount, self._rewardCoins, _cb)
    end
end

-- 次日礼物领取成功
function TomorrowGiftMainLayer:onRecieveColRewardEvt(_rewardData)
    self.m_data:setCompleted(true)
    self:flyCurrency(util_node_handler(self, self.closeUI))
    gLobalNoticManager:postNotification(TomorrowGiftConfig.EVENT_NAME.NOTICE_REMOVE_TOMORROW_GIFT_MACHINE_ENTRY)
end

function TomorrowGiftMainLayer:registerListener()
    TomorrowGiftMainLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onRecieveColRewardEvt", TomorrowGiftConfig.EVENT_NAME.ONRECIEVE_COLLECT_TOMORROW_GIFT_RQE)
end

return TomorrowGiftMainLayer