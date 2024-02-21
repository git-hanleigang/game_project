--[[
Author: cxc
Date: 2021-11-19 16:36:11
LastEditTime: 2021-11-19 16:39:20
LastEditors: your name
Description: 乐透开奖 头奖号码 显示区域
FilePath: /SlotNirvana/src/views/lottery/reward/LotteryOpenRewardRewardNum.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryOpenRewardRewardNum = class("LotteryOpenRewardRewardNum", BaseView)

function LotteryOpenRewardRewardNum:initDatas()
    LotteryOpenRewardRewardNum.super.initDatas(self)

    self.m_hadShowIdx = 0
    local data = G_GetMgr(G_REF.Lottery):getData()
    self.m_numberList = data:getHitNumberList()
end

function LotteryOpenRewardRewardNum:initUI()
    LotteryOpenRewardRewardNum.super.initUI(self)
    
    self:initView()

    gLobalNoticManager:addObserver(self, "showBallByIdx", LotteryConfig.EVENT_NAME.SHOW_OPEN_NUMBER_UI)
end

function LotteryOpenRewardRewardNum:getCsbName()
    return "Lottery/csd/Drawlottery/Lottery_Drawlottery_show.csb"
end

function LotteryOpenRewardRewardNum:initView()
    -- 初始化 中奖号码
    self.m_resultBallNodeList = {} 
    for i=1, #self.m_numberList do
        local number = self.m_numberList[i]
        local parent = self:findChild("node_ball_" .. i)
        local nodeBall = self:createBallItem(number, i == #self.m_numberList)
        parent:addChild(nodeBall)
        nodeBall:setVisible(false)
        table.insert(self.m_resultBallNodeList, nodeBall)
    end
    
end

function LotteryOpenRewardRewardNum:createBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    return view
end

function LotteryOpenRewardRewardNum:playShowAct(_cb)
    if self.m_bShow then
        return
    end
    self.m_bShow = true
    
    self:runCsbAction("start", false, _cb, 60)
end

function LotteryOpenRewardRewardNum:showBallByIdx(_idx)
    local delayTime = 0
    for i= self.m_hadShowIdx + 1, _idx do
        local nodeBall = self.m_resultBallNodeList[i]
        performWithDelay(self, function()
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.NPC_SAY_NUMBER_AUDIO_EVT, {idx = i, number = self.m_numberList[i]}) -- 摇号机器摇号完毕播放中奖号码特效
        end, delayTime)
        performWithDelay(self, function()
            nodeBall:setVisible(true)
            nodeBall:playShowAct()
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.PLAY_REWARD_NUMBER_ACT, {idx = i, number = self.m_numberList[i]}) -- 摇号机器摇号完毕播放中奖号码特效
            gLobalSoundManager:playSound("Lottery/sounds/Lottery_reward_number_show.mp3")
        end, delayTime + 1)

        delayTime = delayTime + 2
    end 

   self.m_hadShowIdx = _idx
end

return LotteryOpenRewardRewardNum