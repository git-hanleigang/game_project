--[[
Author: cxc
Date: 2021-11-19 17:13:32
LastEditTime: 2021-11-19 17:14:12
LastEditors: your name
Description: 乐透开奖界面 底部栏
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardBottom.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryOpenRewardBottom = class("LotteryOpenRewardBottom", BaseView)

function LotteryOpenRewardBottom:initUI()
    LotteryOpenRewardBottom.super.initUI(self)
    
    self:initView()

    gLobalNoticManager:addObserver(self, "updateContentVisible", LotteryConfig.EVENT_NAME.MACHINE_GENERATE_NUMBER_OVER)
    gLobalNoticManager:addObserver(self, "resetBCanTouchSignEvt", LotteryConfig.EVENT_NAME.PLAY_REWARD_NUMBER_ACT)
    gLobalNoticManager:addObserver(self, "closeOpenRewardLayerEvt", LotteryConfig.EVENT_NAME.RECIEVE_COLLECT_REWARD)
    gLobalNoticManager:addObserver(self, "updateCoinsLbUIEvt", LotteryConfig.EVENT_NAME.OPEN_ADD_COINS_UI) --开奖中奖cell金币粒子飞完增加底部栏金币数
end

function LotteryOpenRewardBottom:initDatas()
    local data = G_GetMgr(G_REF.Lottery):getData()
    self.m_maxCoins = 0
    self.m_curShowCoins = 0
    local winCoinList = data:getYouWinCoinList()
    for i, coin in ipairs(winCoinList) do
        self.m_maxCoins = self.m_maxCoins + tonumber(coin)
    end

    self.m_bCanTouch = true
end

function LotteryOpenRewardBottom:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_bottom.csb"
end

function LotteryOpenRewardBottom:initCsbNodes()
    self.m_lbCoin = self:findChild("lb_coin")
    G_GetMgr(G_REF.Lottery):setBottomCoinsFlyEndNode(self.m_lbCoin)

    self.m_btnSkip = self:findChild("btn_skip")
    self.m_btnCollect = self:findChild("btn_collect")
    self.m_lbSkipTime = self:findChild("lb_daojishi")
    self.m_nodeSkip = self:findChild("node_skip_parent")
    self.m_nodeNoReward = self:findChild("node_unfortunately")
    self.m_nodeCollect = self:findChild("node_reward")

end

function LotteryOpenRewardBottom:initView()
    self:updateContentVisible(true)

    -- 金币
    self.m_lbCoin:setString(util_formatCoins(self.m_curShowCoins, 20))

    -- 新手隐藏skip按钮
    self:dealBtnSkipVisible()    
end

-- 新手隐藏skip按钮
function LotteryOpenRewardBottom:dealBtnSkipVisible()
    local bNovice = gLobalDataManager:getBoolByField("Lottery_Novice_Skip", true)
    self.m_btnSkip:setVisible(true)
    gLobalDataManager:setBoolByField("Lottery_Novice_Skip", false)
    self.m_bSkipNoviece = bNovice
end

-- 开奖跳过倒计时
function LotteryOpenRewardBottom:checkTime()
    if self.m_canSkip then
        return
    end
    self.m_skipCountTiem = 0
    self:updateLeftTime()
    self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTime), 1)
end

function LotteryOpenRewardBottom:updateLeftTime()
    self.m_skipCountTiem = self.m_skipCountTiem - 1
    if self.m_skipCountTiem <= 0 then
        self.m_lbSkipTime:setString("WAITING FOR THE LOTTERY RESULTS...")
        self:clearScheduler()
        return
    end
    self.m_lbSkipTime:setString("You can click SKIP in "..self.m_skipCountTiem.."S...")
end
--停掉定时器
function LotteryOpenRewardBottom:clearScheduler()
    if self.m_leftTimeScheduler then
        self:stopAction(self.m_leftTimeScheduler)
        self.m_leftTimeScheduler = nil
    end
end


function LotteryOpenRewardBottom:updateContentVisible(_bInit)
    if not _bInit then
        self:runCsbAction("actionframe",false,function ()
            self:runCsbAction("idle", true)
            self.m_bCanTouch = true
        end,60)
        self.m_bCanTouch = false
    end
    -- self:setButtonLabelDisEnabled("btn_skip", not _bInit)
    self.m_nodeSkip:setVisible(_bInit)
    self.m_nodeNoReward:setVisible(not _bInit and self.m_maxCoins <= 0)
    self.m_nodeCollect:setVisible(not _bInit and self.m_maxCoins > 0)
end

function LotteryOpenRewardBottom:clickFunc(sender)
    if not self.m_bCanTouch then
        return
    end

    local name = sender:getName()
    
    if name == "btn_skip" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.SKIP_OPEN_REWARD_STEP) -- 跳过开奖步骤
        self:closeOpenRewardLayerEvt()
    elseif name == "btn_continue" then
        self:clickContinueBtn()
    elseif name == "btn_collect" then
        self:clickCollectBtn() 
    end
end

-- 点击结束 关闭弹板按钮
function LotteryOpenRewardBottom:clickContinueBtn()
    --G_GetMgr(G_REF.Lottery):sendCollectReward()
    self:closeOpenRewardLayerEvt()
end

-- 领取奖励按钮点击
function LotteryOpenRewardBottom:clickCollectBtn()
    self:setButtonLabelDisEnabled("btn_collect",false)
    local delayTime = 0
    if self.m_curShowCoins < self.m_maxCoins then
        self.m_bStopAddCoin = true
        gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.STOP_PLAYER_REWARD_NUMBER_ACT) --停止播放中奖号码特效
        self.m_lbCoin:setString(util_formatCoins(self.m_maxCoins, 20))
        delayTime = 0.5
    end
    performWithDelay(self, function()
        self:closeOpenRewardLayerEvt()
    end, delayTime)
end

function LotteryOpenRewardBottom:closeOpenRewardLayerEvt()
    -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CLOSE_OPEN_REWARD_LAYER) -- 关闭开奖界面
    if self.m_bSkipNoviece then
        G_GetMgr(G_REF.Lottery):popPerGrandPrizeInfoLayer(self.m_maxCoins)
    else
        G_GetMgr(G_REF.Lottery):popSkipSettlementInfoLayer(self.m_maxCoins)    
    end
end

function LotteryOpenRewardBottom:resetBCanTouchSignEvt(_params)
    if not _params or _params.idx == 6 then
        self.m_bCanTouch = true
    end
end

function LotteryOpenRewardBottom:updateCoinsLbUIEvt(_addCoins)
    if self.m_bStopAddCoin then
        return
    end
    
    self.m_curShowCoins = self.m_curShowCoins + (tonumber(_addCoins) or 0)
    self.m_lbCoin:setString(util_formatCoins(math.min(self.m_curShowCoins, self.m_maxCoins) , 20))
end

function LotteryOpenRewardBottom:playShowAct(_cb)
    -- skip倒计时
    self:checkTime()

    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        if _cb then
            _cb()
        end
    end, 60)
end

function LotteryOpenRewardBottom:setSkipBtnStatus(_status)
    self:setButtonLabelDisEnabled("btn_skip", _status)
    self.m_canSkip = _status
end

return LotteryOpenRewardBottom