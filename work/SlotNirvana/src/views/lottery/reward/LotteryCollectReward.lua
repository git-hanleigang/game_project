--[[
Author: cxc
Date: 2021-11-23 16:11:08
LastEditTime: 2021-11-23 16:11:09
LastEditors: your name
Description: 乐透开奖后 领取奖励界面
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryCollectReward.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryCollectReward = class("LotteryCollectReward", BaseLayer)

function LotteryCollectReward:ctor()
    LotteryCollectReward.super.ctor(self)
    self:setPauseSlotsEnabled(true) 

    self:setExtendData("LotteryCollectReward")
    self:setLandscapeCsbName("Lottery/csd/Drawlottery/Lottery_Drawlottery_rewards.csb")
end

function LotteryCollectReward:initDatas(_coins)
    self.m_coins = _coins or 0
end

function LotteryCollectReward:initView()
    -- 金币
    local lbCoins = self:findChild("lb_coin") 
    lbCoins:setString(util_formatCoins(self.m_coins, 20))
    util_scaleCoinLabGameLayerFromBgWidth(lbCoins, 700)
    --spine
    -- local parent = self:findChild("spine")
    -- local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true)
    -- parent:addChild(spineNode)
    -- util_spinePlay(spineNode, "idle2", true)
end

function LotteryCollectReward:initSpineUI()
    LotteryCollectReward.super.initSpineUI(self)

    --spine
    local parent = self:findChild("spine")
    local spineNode = util_spineCreate("Lottery/spine/chaopiaoren/chaopiaoren", true, true, 1)
    parent:addChild(spineNode)
    util_spinePlay(spineNode, "idle2", true)
end

function LotteryCollectReward:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_collect" then
        sender:setTouchEnabled(false)
        gLobalNoticManager:addObserver(self, "checkFlyCoins", LotteryConfig.EVENT_NAME.RECIEVE_COLLECT_REWARD)

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.Lottery):sendCollectReward()
    end
end

function LotteryCollectReward:checkFlyCoins()
    if not self.m_coins or self.m_coins == 0 then
        self:closeUI()
        return
    end

    local btnCollect = self:findChild("btn_collect")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    gLobalViewManager:pubPlayFlyCoin(
        startPos, 
        globalData.flyCoinsEndPos, 
        globalData.topUICoinCount, 
        self.m_coins, 
        function()
            self:closeUI()
        end
    )
end

function LotteryCollectReward:onShowedCallFunc()
    gLobalSoundManager:playSound("Lottery/sounds/Lottery_pop_collect_reward_layer.mp3")
    self:runCsbAction("idle", true)
    LotteryCollectReward.super.onShowedCallFunc(self)
end

function LotteryCollectReward:closeUI()
    local callFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        -- 弹出 中头奖信息面板
        -- G_GetMgr(G_REF.Lottery):popPerGrandPrizeInfoLayer()
    end
    
    LotteryCollectReward.super.closeUI(self, callFunc)
end

return LotteryCollectReward