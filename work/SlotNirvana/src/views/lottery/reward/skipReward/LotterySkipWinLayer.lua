--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-08-11 12:15:20
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-08-11 12:15:31
FilePath: /SlotNirvana/src/views/lottery/reward/skipReward/LotterySkipWinLayer.lua
Description: 乐透 按跳过 中奖结算弹板
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotterySkipWinLayer = class("LotterySkipWinLayer", BaseLayer)

function LotterySkipWinLayer:ctor(_coins)
    LotterySkipWinLayer.super.ctor(self)

    self.m_coins = _coins or 0
    self.m_data = G_GetMgr(G_REF.Lottery):getData()

    self:setPauseSlotsEnabled(true) 
    self:setExtendData("LotterySkipWinLayer")
    self:setLandscapeCsbName("Lottery/csd/Drawlottery/Lottery_Drawlottery_rewards2.csb")
end

function LotterySkipWinLayer:initView()
    -- 上一期 头奖玩家信息
    self:initPreGrandPrizeUI()
    -- 本期开奖号码
    self:initHitNumberUI()
    -- 金币
    self:initCoinsUI()

    self:runCsbAction("idle", true)
end

-- 上一期 头奖玩家信息
function LotterySkipWinLayer:initPreGrandPrizeUI()
    local view = util_createView("views.lottery.reward.skipReward.LotteryPerGrandPrizeInfoUI")
    local parent = self:findChild("node_prePrize")
    parent:addChild(view)
end

-- 本期开奖号码
function LotterySkipWinLayer:initHitNumberUI()
    local  numberList = self.m_data:getHitNumberList()
    for i=1, #numberList do
        local node = self:findChild("node_ball" .. i)
        local view = self:createBallItem(numberList[i], i == 6)
        node:addChild(view)
    end
end
function LotterySkipWinLayer:createBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setName("node_show_ball")
    return view
end

-- 金币
function LotterySkipWinLayer:initCoinsUI()
    local lbCoins = self:findChild("lb_coins")
    lbCoins:setString(util_formatCoins(self.m_coins, 20))
    util_scaleCoinLabGameLayerFromBgWidth(lbCoins, 675, 1)
    util_alignCenter(
        {
            {node = self:findChild("sp_coins")},
            {node = lbCoins, alignX = 5, alignY = -3}
        }
    )
end

function LotterySkipWinLayer:clickFunc(sender)
    if self.bFlying then
        return
    end
    
    local name = sender:getName()
    if name == "btn_collect" then
        sender:setTouchEnabled(false)
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalNoticManager:addObserver(self, "checkFlyCoins", LotteryConfig.EVENT_NAME.RECIEVE_COLLECT_REWARD)
        G_GetMgr(G_REF.Lottery):sendCollectReward()
    elseif name == "btn_selfBetList" then
        G_GetMgr(G_REF.Lottery):popYoursNumberListLayer()
    end
end

function LotterySkipWinLayer:checkFlyCoins()
    self.bFlying = true
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

function LotterySkipWinLayer:closeUI()
    local callFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end
    
    LotterySkipWinLayer.super.closeUI(self, callFunc)
end

return LotterySkipWinLayer