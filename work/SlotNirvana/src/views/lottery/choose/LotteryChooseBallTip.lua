--[[
Author: your name
Date: 2021-11-23 10:26:37
LastEditTime: 2022-05-25 17:44:06
LastEditors: bogon
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/choose/LotteryChooseBallTip.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryChooseBallTip = class("LotteryChooseBallTip", BaseLayer)

function LotteryChooseBallTip:ctor()
    LotteryChooseBallTip.super.ctor(self)
    
    self:setPauseSlotsEnabled(true) 

    self:setExtendData("LotteryChooseBallTip")
    self:setLandscapeCsbName("Lottery/csd/Lottery_choose_tanban1.csb")
end

function LotteryChooseBallTip:initDatas(_bRandom)
    LotteryChooseBallTip.super.initDatas(self)

    self.m_numberList = G_GetMgr(G_REF.Lottery):getChooseNumberList()
    self.m_bRandom = _bRandom
end

-- 初始化节点
function LotteryChooseBallTip:initCsbNodes()
    -- 不选号 自动选号提示UI
    self.m_chooseTipNode = self:findChild("node_nochoose")
    -- 选择的号码UI
    self.m_chooseNumberShowNode = self:findChild("node_choose")
end

function LotteryChooseBallTip:initView()
    LotteryChooseBallTip.super.initView(self)
    self:runCsbAction("idle") 
    self:updateUI()
end

function LotteryChooseBallTip:updateUI()
    self.m_bShowNumber = G_GetMgr(G_REF.Lottery):checkCanSyncNumberList()

    self.m_chooseTipNode:setVisible(not self.m_bShowNumber)
    self.m_chooseNumberShowNode:setVisible(self.m_bShowNumber)

    if self.m_bShowNumber then
        for idx, number in pairs(self.m_numberList) do
            local parent = self:findChild("node_ball_" .. idx)
            local item = parent:getChildByName("node_ball_item")
            if not item then
                item = self:createBallItem(number, idx == #self.m_numberList)
            else
                item:updateNumberUI(number)
            end
            parent:addChild(item)
        end
    end
end

function LotteryChooseBallTip:createBallItem(_number, _bRed)
    local view = util_createView("views.lottery.base.LotteryBall", {number = _number, bRed = _bRed})
    view:setName("node_ball_item")
    return view
end

function LotteryChooseBallTip:updateRandomNumberState(_state)
    self.m_bRandom = _state
end

function LotteryChooseBallTip:clickFunc(sender)
    local name = sender:getName()
    
    if name == "btn_no" then
        self:closeUI()
    elseif name == "btn_yes" then
        if self.m_bShowNumber then
            G_GetMgr(G_REF.Lottery):sendSyncChooseNumber(self.m_bRandom,false)
        else
            G_GetMgr(G_REF.Lottery):sendGenerateRanNumber()
        end
        
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    end
end

-- 机选号码成功
function LotteryChooseBallTip:generateRanNumberEvt()
    self.m_numberList = G_GetMgr(G_REF.Lottery):getChooseNumberList() -- 选择的号码
    self:updateUI()
    self:updateRandomNumberState(true)
end

-- 注册消息事件
function LotteryChooseBallTip:registerListener()
    LotteryChooseBallTip.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "closeUI", LotteryConfig.EVENT_NAME.RECIEVE_SYNC_CHOOSE_NUMBER)
    gLobalNoticManager:addObserver(self, "closeUI", LotteryConfig.EVENT_NAME.TIME_END_CLOSE_CHOOSE_NUMBER_CODE) --选号时间结束关闭选号功能
    gLobalNoticManager:addObserver(self, "closeUI", LotteryConfig.EVENT_NAME.CLOSE_CHOOSE_NUMBER_OTHER_LAYER)
    gLobalNoticManager:addObserver(self, "generateRanNumberEvt", LotteryConfig.EVENT_NAME.RECIEVE_GENERATE_RANDOM_NUMBER)
    
end

return LotteryChooseBallTip