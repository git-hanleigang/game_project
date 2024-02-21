--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-11 11:14:01
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-11 11:14:28
FilePath: /SlotNirvana/src/views/lottery/reward/skipReward/LotterySkipNoWinLayer.lua
Description: 乐透 按跳过 未中奖结算弹板
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotterySkipNoWinLayer = class("LotterySkipNoWinLayer", BaseLayer)

function LotterySkipNoWinLayer:ctor()
    LotterySkipNoWinLayer.super.ctor(self)

    self:setPauseSlotsEnabled(true) 
    self:setExtendData("LotterySkipNoWinLayer")
    self:setLandscapeCsbName("Lottery/csd/Drawlottery/Lottery_Drawlottery_rewards_nowin2.csb")
end

function LotterySkipNoWinLayer:initView()
    -- 上一期 头奖玩家信息
    self:initPreGrandPrizeUI()

    self:runCsbAction("idle", true)
end

-- 上一期 头奖玩家信息
function LotterySkipNoWinLayer:initPreGrandPrizeUI()
    local view = util_createView("views.lottery.reward.skipReward.LotteryPerGrandPrizeInfoUI")
    local parent = self:findChild("node_prePrize")
    parent:addChild(view)
end

function LotterySkipNoWinLayer:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_OK" then
        sender:setTouchEnabled(false)
        gLobalNoticManager:addObserver(self, "closeUI", LotteryConfig.EVENT_NAME.RECIEVE_COLLECT_REWARD)

        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        G_GetMgr(G_REF.Lottery):sendCollectReward()
    end
end

function LotterySkipNoWinLayer:closeUI()
    local callFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end
    
    LotterySkipNoWinLayer.super.closeUI(self, callFunc)
end

return LotterySkipNoWinLayer