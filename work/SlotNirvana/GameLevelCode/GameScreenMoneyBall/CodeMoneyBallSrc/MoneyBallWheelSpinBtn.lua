---
--xcyy
--2018年5月23日
--MoneyBallWheelSpinBtn.lua

local MoneyBallWheelSpinBtn = class("MoneyBallWheelSpinBtn",util_require("base.BaseView"))
local SendDataManager = require "network.SendDataManager"

function MoneyBallWheelSpinBtn:initUI(data)

    self:createCsbNode("MoneyBall_jackpot_Spin.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self:addClick(self:findChild("clickBtn"))
    self.m_clickFlag = false
    self.m_netResultFlag = false
    self.m_stopFlag = false

    self.m_btnSpin = self:findChild("btnSpin")
    self.m_btnSkip = self:findChild("btnSkip")

    util_setCascadeOpacityEnabledRescursion(self, true)
end

function MoneyBallWheelSpinBtn:showBtn()
    self.m_clickFlag = false
    self.m_stopFlag = false
    self.m_btnSpin:setVisible(true)
    self.m_btnSkip:setVisible(false)
    self:runCsbAction("open", false, function()
        self:runCsbAction("idle", true)
        self.m_clickFlag = true
        self.m_netResultFlag = false
        self.m_startAction = performWithDelay(self, function()
            self:startGame()
        end, 4)
    end)
end

function MoneyBallWheelSpinBtn:onEnter()

end

function MoneyBallWheelSpinBtn:onExit()
 
end

function MoneyBallWheelSpinBtn:setStopFlag(flag)
    self.m_stopFlag = flag
    if flag == false then
        self:runCsbAction("idle2")
    end
end

function MoneyBallWheelSpinBtn:setClickFlag(flag)
    self.m_btnSpin:setVisible(flag)
    self.m_btnSkip:setVisible(not flag)
    self:runCsbAction("idle", true)
    self.m_clickFlag = flag
    self.m_stopFlag = not flag
end

--默认按钮监听回调
function MoneyBallWheelSpinBtn:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
    self:startGame()
    if self.m_startAction ~= nil then
        self:stopAction(self.m_startAction)
        self.m_startAction = nil
    end
end

function MoneyBallWheelSpinBtn:startGame()
    if self.m_clickFlag == false then
        if self.m_stopFlag == true then
            self:runCsbAction("start", false, function()
                self.m_btnSpin:setVisible(true)
                self.m_btnSkip:setVisible(false)
            end)
            gLobalNoticManager:postNotification("CLICK_BALL_SPIN")
        end
        return
    end
    self.m_clickFlag = false
    gLobalSoundManager:playSound("MoneyBallSounds/sound_MoneyBall_wheel_spin.mp3")
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_btnSpin:setVisible(false)
        self.m_btnSkip:setVisible(true)
        if self.m_netResultFlag == false then
            self.m_netResultFlag = true
            local httpSendMgr = SendDataManager:getInstance()
            local messageData = nil
            messageData = {msg = MessageDataType.MSG_BONUS_SELECT}

            httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
        else
            gLobalNoticManager:postNotification("CLICK_BALL_SPIN")
        end
    end)
end

return MoneyBallWheelSpinBtn