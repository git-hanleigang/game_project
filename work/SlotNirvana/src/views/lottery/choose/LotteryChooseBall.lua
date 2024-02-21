--[[
Author: your name
Date: 2021-11-23 20:21:00
LastEditTime: 2021-11-23 20:21:38
LastEditors: your name
Description: 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
FilePath: /SlotNirvana/src/views/lottery/choose/LotteryChooseBall.lua
--]]
local LotteryConfig = util_require("GameModule.Lottery.config.LotteryConfig")
local LotteryBall = util_require("views.lottery.base.LotteryBall")
local LotteryChooseBall = class("LotteryChooseBall", LotteryBall)

function LotteryChooseBall:getCsbName()
    return "Lottery/csd/Choose/node_ball_choose.csb"
end

function LotteryChooseBall:initDatas(_params)
    LotteryChooseBall.super.initDatas(self, _params)

    self.m_bChoose = false
end

-- 初始化节点
function LotteryChooseBall:initCsbNodes()
    LotteryChooseBall.super.initCsbNodes(self)

    self.m_btnTouch = self:findChild("btn_touch")
    self:addClick(self.m_btnTouch)
end

function LotteryChooseBall:initUI(_params)
    LotteryChooseBall.super.initUI(self, _params)

    gLobalNoticManager:addObserver(self, "generateRanNumberEvt", LotteryConfig.EVENT_NAME.RECIEVE_GENERATE_RANDOM_NUMBER)
end

function LotteryChooseBall:updateChooseState(_bAni)
    if _bAni then
        self:runCsbAction(self.m_bChoose and "start" or "over", nil, function()
            self.m_btnTouch:setTouchEnabled(true)
            self:runCsbAction(self.m_bChoose and "choose" or "idle")
        end, 60) 
    else
        self:runCsbAction(self.m_bChoose and "choose" or "idle")
    end

    if self.m_bChoose then
        gLobalNoticManager:addObserver(self, "cancelChooseNumberEvt", LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_UPDATE_BALL_CHOOSE_STATE) --选择号码 _取消选择
    end
end

function LotteryChooseBall:clickFunc(sender)
    local name = sender:getName()

    local bChooseEnabled = self:isChooseEnbaled()
    if not bChooseEnabled then
        return
    end

    if name == "btn_touch" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self.m_bChoose = not self.m_bChoose
        if self.m_bChoose then
            if self.m_bRed then
                --红球 有就替换
                local chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList()
                local showRedNumber = chooseNumberList[#chooseNumberList]
                if showRedNumber ~= self.m_number then 
                    gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_UPDATE_BALL_CHOOSE_STATE, {number = showRedNumber, bRed = true}) -- 更新球库里的球选取状态
                end
            end
            
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_SELECT, {number = self.m_number, bRed = self.m_bRed}) --选择号码 _选择
        else
            gLobalNoticManager:postNotification(LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_CANCEL, {number = self.m_number, bRed = self.m_bRed}) --选择号码 _取消选择
        end

        self:updateChooseState(true)
        sender:setTouchEnabled(false)
    end
end

-- 取消 选择球
-- _params = {number=int, bRed=bool}
function LotteryChooseBall:cancelChooseNumberEvt(_params)
    if _params.bRed ~= self.m_bRed or _params.number ~= self.m_number then
        return
    end

    self.m_bChoose = false
    self:updateChooseState(true)

    gLobalNoticManager:removeObserver(self, LotteryConfig.EVENT_NAME.CHOOSE_NUMBER_CANCEL) --选择号码 _取消选择
end

-- 是否可以点击
function LotteryChooseBall:isChooseEnbaled()
    local bChooseEnabled = self.m_bRed  --红球触摸不屏蔽

    if not bChooseEnabled then
        local chooseNumberList = G_GetMgr(G_REF.Lottery):getChooseNumberList()
        for i=1, #chooseNumberList-1 do
            local number = chooseNumberList[i]
            if number == 0 or number == self.m_number then
                return true
            end
        end
    end

    return bChooseEnabled
end

-- 机选号码成功
function LotteryChooseBall:generateRanNumberEvt(_number)
    if self.m_bChoose then
        if not _number then
            self.m_bChoose = false
            self:updateChooseState()
        end
        return
    end

    self.m_bChoose = _number == self.m_number
    self:updateChooseState()
end

return LotteryChooseBall