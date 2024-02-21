
local HogHustlerDice = class("HogHustlerDice",util_require("Levels.BaseLevelDialog"))
local HogHustlerMusic = util_require("CodeHogHustlerSrc.HogHustlerMusic")

local CLICK_STATUS = {
    NORMAL = 1,
    START = 2,
    NORMAL2AUTO = 3,
    AUTO = 4,
}
local BUTTON_STATUS = {
    NORMAL = 1,
    AUTO = 2,
}

function HogHustlerDice:initUI(_mainMap)
    self:createCsbNode("HogHustler_dafuweng_anniu.csb")

    self.m_guideHands = util_createAnimation("HogHustler_dafuweng_anniu_0.csb")
    self:findChild("shoushi"):addChild(self.m_guideHands)


    self.m_timingNode = cc.Node:create()
    self:addChild(self.m_timingNode)


    self.m_mainMap = _mainMap
    self.m_click_status = CLICK_STATUS.NORMAL
    self.m_button_status = BUTTON_STATUS.NORMAL
    self:setAutoUI(true)
end

function HogHustlerDice:onEnter()
    HogHustlerDice.super.onEnter(self)
end

function HogHustlerDice:onExit()
    self:clearAutoSpinTiming()
    HogHustlerDice.super.onExit(self)
end

--处理dice点击
function HogHustlerDice:processDiceSpin()
    if self.m_mainMap then
        -- print("buttonProcess dice")
        self.m_mainMap:buttonProcess()
    end
end

--开始
function HogHustlerDice:clickStartFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_0" and self.m_mainMap.m_Click == false then
        self.m_click_status = CLICK_STATUS.START

        local Timing = function()
            self.m_click_status = CLICK_STATUS.AUTO
            self.m_button_status = BUTTON_STATUS.AUTO
            self:setAutoUI(true)
            self:clearAutoSpinTiming()

            self:processDiceSpin()
        end

        local Timing2 = function()
            self.m_click_status = CLICK_STATUS.NORMAL2AUTO
            self:runCsbAction("auto", false, function()
                
            end)
            self.longTouchSoundId = gLobalSoundManager:playSound(HogHustlerMusic.sound_HogHustler_long_touch_dice)
        end

        if self.m_button_status == BUTTON_STATUS.NORMAL and self.m_mainMap.m_diceNum and self.m_mainMap.m_diceNum > 0 then --normal时才能长按
            performWithDelay(self.m_timingNode, Timing, 1.5)    --处理
            performWithDelay(self.m_timingNode, Timing2, 0.5)   --效果
        end
        

        
    end
end

--取消
function HogHustlerDice:clickCancelFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_0" and self.m_button_status == BUTTON_STATUS.NORMAL then
        self:resetToNormal()
    end
end

-- function HogHustlerDice:clickEndFunc(sender)
--     local name = sender:getName()
--     local tag = sender:getTag()

--     if name == "Button_0" and self.m_button_status == BUTTON_STATUS.NORMAL then
--         self:resetToNormal()
--     end
-- end


--结束
function HogHustlerDice:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_0" and self.m_mainMap.m_Click == false then  --骰子
        if self.m_click_status == CLICK_STATUS.AUTO then
            return
        end
        if self.m_click_status == CLICK_STATUS.START or self.m_click_status == CLICK_STATUS.NORMAL2AUTO then
            if self.m_button_status == BUTTON_STATUS.NORMAL then
                self:processDiceSpin()
                if self.m_click_status == CLICK_STATUS.NORMAL2AUTO then
                    self:runCsbAction("idle", true)
                    self:setAutoUI(false)
                end
            elseif self.m_button_status == BUTTON_STATUS.AUTO then
                self.m_button_status = BUTTON_STATUS.NORMAL
                self:runCsbAction("idle", true)
                self:setAutoUI(false)
            end
            
            self.m_click_status = CLICK_STATUS.NORMAL
        end

        self:clearAutoSpinTiming()
        if self.longTouchSoundId then
            gLobalSoundManager:stopAudio(self.longTouchSoundId)
            self.longTouchSoundId = nil
        end


    end
end

function HogHustlerDice:clearAutoSpinTiming()
    if self.m_timingNode and not tolua.isnull(self.m_timingNode) then
        self.m_timingNode:stopAllActions()
    end
end

function HogHustlerDice:setAutoUI(_isAuto)
    self:findChild("HogHustlerRespin_dfw_wenzi5_3"):setVisible(not _isAuto)
    self:findChild("aotuzi"):setVisible(_isAuto)
    if _isAuto then
        self:runCsbAction("idle3", true)
    else
        self:runCsbAction("idle", true)
    end
end

function HogHustlerDice:getButtonStatus()
    if self.m_button_status == BUTTON_STATUS.NORMAL then
        return "NORMAL"
    elseif self.m_button_status == BUTTON_STATUS.AUTO then
        return "AUTO"
    end
    return "NORMAL"
end

function HogHustlerDice:resetToNormal()
    self.m_button_status = BUTTON_STATUS.NORMAL
    self.m_click_status = CLICK_STATUS.NORMAL

    self:setAutoUI(false)
    self:clearAutoSpinTiming()
end

--重写
function HogHustlerDice:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:setButtonStatusByBegan(sender)
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:setButtonStatusByMoved(sender)
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickFunc then
            return
        end
        self:setButtonStatusByEnd(sender)
        -- self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = math.abs(endPos.x - beginPos.x)
        local offy = math.abs(endPos.y - beginPos.y)
        if offx < 50 and offy < 50 and globalData.slotRunData.changeFlag == nil then
            self:clickFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        if not self.clickCancelFunc then
            return
        end
        self:clickCancelFunc(sender, eventType)
    end
end

return HogHustlerDice