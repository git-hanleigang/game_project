-- 按住时间变autospin
local HOLD_TIME = 2 -- 秒

-- 按钮的状态
local SPIN_BTN_STATE = {
    -- NORMAL = 1,
    -- ENABLED = 2,
    -- DISABLED = 3,
    -- AUTOSPIN = 4,
    SPIN_NORMAL = 1,
    SPIN_ANXIA = 2,
    SPIN_JINYONG = 3,
    STOP_NORMAL = 4,
    STOP_ANXIA = 5
}

local BaseView = util_require("base.BaseView")
local CardNadoWheelSpin = class("CardNadoWheelSpin", BaseView)
function CardNadoWheelSpin:initUI(node)
    self.m_wheelBody = node

    self:createCsbNode(self:getCsbName())

    self:runCsbAction("idle", true)
    self:initNode()
    self:initData()
    self:initView()
end

function CardNadoWheelSpin:initCheckPrize(enabled)
    self.m_wheelBody:initCheckPrize(enabled)
end

function CardNadoWheelSpin:showPrize(hideLater)
    self.m_wheelBody:showPrize(hideLater)
end

function CardNadoWheelSpin:getReward()
    return self.m_wheelBody:getReward()
end

function CardNadoWheelSpin:getLeftCount()
    return self.m_wheelBody:getLeftCount()
end

function CardNadoWheelSpin:initOneSpin()
    self.m_wheelBody:initOneSpin()
end

function CardNadoWheelSpin:getOnOffSpin()
    return self.m_wheelBody:getOnOffSpin()
end

function CardNadoWheelSpin:getCsbName()
    return string.format(CardResConfig.commonRes.CardNadoWheelSpinRes, "common" .. CardSysRuntimeMgr:getCurAlbumID())
end

function CardNadoWheelSpin:initNode()
    self.m_spinNode = self:findChild("Node_spin")
    self.m_spinYes = self:findChild("Node_spinyes")
    self.m_spinNo = self:findChild("Node_spinno")

    self.m_stopNode = self:findChild("Node_stop")

    self.m_LGNode = self:findChild("Node_LG")

    local touch = self:findChild("touch")
    self:addClick(touch)
end

function CardNadoWheelSpin:initData()
    self:initState()
end

function CardNadoWheelSpin:initState()
    -- TODO: 如果剩余次数为0
    if self:getLeftCount() > 0 then
        self:setState(SPIN_BTN_STATE.SPIN_NORMAL)
    else
        self:setState(SPIN_BTN_STATE.SPIN_JINYONG)
    end
end

function CardNadoWheelSpin:setState(state)
    if self.m_state == state then
        return
    end
    self.m_state = state
end

function CardNadoWheelSpin:getState(state)
    return self.m_state
end

function CardNadoWheelSpin:initView()
    self:initLG()
    self:updateBtn()
end

-- 初始化流光
function CardNadoWheelSpin:initLG()
    self.m_LGCsb, self.m_LGAct = util_csbCreate(string.format(CardResConfig.commonRes.CardNadoWheelSpinLGRes, "common" .. CardSysRuntimeMgr:getCurAlbumID()))
    self.m_LGNode:addChild(self.m_LGCsb)
    util_csbPlayForKey(self.m_LGAct, "idle", true)
    self.m_LGNode:setVisible(false)
end

function CardNadoWheelSpin:updateBtn()
    self.m_spinNode:setVisible(false)
    self.m_spinYes:setVisible(false)
    self.m_spinYes:getChildByName("Node_normal"):setVisible(false)
    self.m_spinYes:getChildByName("Node_anxia"):setVisible(false)
    self.m_spinNo:setVisible(false)

    self.m_stopNode:setVisible(false)
    self.m_stopNode:getChildByName("Node_normal"):setVisible(false)
    self.m_stopNode:getChildByName("Node_anxia"):setVisible(false)

    if self.m_state == SPIN_BTN_STATE.SPIN_NORMAL then
        -- 流光
        self.m_LGNode:setVisible(true)
        -- 控制按钮显示
        self.m_spinNode:setVisible(true)
        self.m_spinYes:setVisible(true)
        self.m_spinYes:getChildByName("Node_normal"):setVisible(true)
        self.m_canClick = true
        self:initCheckPrize(true)
    elseif self.m_state == SPIN_BTN_STATE.SPIN_ANXIA then
        -- 流光
        self.m_LGNode:setVisible(false)
        -- 控制按钮显示
        self.m_spinNode:setVisible(true)
        self.m_spinYes:setVisible(true)
        self.m_spinYes:getChildByName("Node_anxia"):setVisible(true)
        self.m_canClick = false
        self:initCheckPrize(false)
    elseif self.m_state == SPIN_BTN_STATE.SPIN_JINYONG then
        -- 流光
        self.m_LGNode:setVisible(false)
        -- 控制按钮显示
        self.m_spinNode:setVisible(true)
        self.m_spinNo:setVisible(true)
        self.m_canClick = false
        self:initCheckPrize(false)
    elseif self.m_state == SPIN_BTN_STATE.STOP_NORMAL then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_ATUO_SPIN_ACTIVE)
        -- 流光
        self.m_LGNode:setVisible(false)
        -- 控制按钮显示
        self.m_stopNode:setVisible(true)
        self.m_stopNode:getChildByName("Node_normal"):setVisible(true)
        self.m_canClick = true
        self:initCheckPrize(false)
    elseif self.m_state == SPIN_BTN_STATE.STOP_ANXIA then
        -- 流光
        self.m_LGNode:setVisible(false)
        -- 控制按钮显示
        self.m_stopNode:setVisible(true)
        self.m_stopNode:getChildByName("Node_anxia"):setVisible(true)
        self.m_canClick = false
        self:initCheckPrize(false)
    end
end

function CardNadoWheelSpin:startSpin()
    self:setState(SPIN_BTN_STATE.SPIN_ANXIA)
    self:updateBtn()
    self.m_wheelBody:beginWheel()
end

function CardNadoWheelSpin:overSpin()
    self:initState()
    self:updateBtn()
    self:setItemTouchEnabled(true)
end

function CardNadoWheelSpin:setItemTouchEnabled(_enabled)
    self.m_wheelBody:setItemTouchEnabled(_enabled)
end

function CardNadoWheelSpin:startAutoSpin()
    print("-- startAutoSpin --")
    self:setState(SPIN_BTN_STATE.STOP_NORMAL)
    self:updateBtn()
    self.m_wheelBody:beginWheel()
end

function CardNadoWheelSpin:overAutoSpin()
    print("-- overAutoSpin --")
    if self.m_wheelRolling then
        self:setState(SPIN_BTN_STATE.SPIN_ANXIA)
        self:updateBtn()
    else
        self:initState()
        self:updateBtn()
    end
end

function CardNadoWheelSpin:initHoldTimer()
    self:removeHoldTimer()
    local curTime = 0
    self.m_holdTimer =
        schedule(
        self,
        function()
            curTime = curTime + 1
            if curTime >= HOLD_TIME then
                self:removeHoldTimer()
                self:startAutoSpin()
            end
        end,
        1
    )
end

function CardNadoWheelSpin:removeHoldTimer()
    if self.m_holdTimer ~= nil then
        self:stopAction(self.m_holdTimer)
        self.m_holdTimer = nil
    end
end

function CardNadoWheelSpin:beginWheel()
    self.m_wheelRolling = true
end

function CardNadoWheelSpin:overWheel()
    self.m_wheelRolling = false
    if self.m_state == SPIN_BTN_STATE.SPIN_ANXIA then
        self:overSpin()

        -- 播放奖励动效
        self.m_showWinAction = true
        self.m_wheelBody:playWheelWinAction(
            function()
                self.m_showWinAction = false
                -- 如果没有次数，自动弹出结算界面
                if self:getLeftCount() == 0 and self:getReward() ~= nil then
                    self:showPrize(true)
                end
                self:initOneSpin()
            end
        )
    elseif self.m_state == SPIN_BTN_STATE.STOP_NORMAL or self.m_state == SPIN_BTN_STATE.STOP_ANXIA then
        self.m_wheelBody:playWheelWinAction(
            function()
                if self:getLeftCount() > 0 then
                    self.m_wheelBody:beginWheel()
                else
                    self:overAutoSpin()
                    self:showPrize(true)
                    self:initOneSpin()
                end
            end
        )
    end
end

--[[
]]
function CardNadoWheelSpin:clickStartFunc(sender)
    if not self.m_canClick then
        return
    end
    print("---- clickStartFunc --", self.m_state)

    if self.m_state == SPIN_BTN_STATE.SPIN_NORMAL then
        if self.m_wheelRolling then
            return
        end
        if self.m_showWinAction then
            return
        end
        if self:getOnOffSpin() == true then
            return
        end
        self.m_preState = self.m_state
        self:initHoldTimer()
        self:setState(SPIN_BTN_STATE.SPIN_ANXIA)
        self:updateBtn()
    elseif self.m_state == SPIN_BTN_STATE.STOP_NORMAL then
        self.m_preState = self.m_state
        self:setState(SPIN_BTN_STATE.STOP_ANXIA)
        self:updateBtn()
    end
end

function CardNadoWheelSpin:clickEndFunc(sender)
    self:removeHoldTimer()
    print("--- clickEndFunc ---", self.m_state, self.m_preState)

    if self.m_state == SPIN_BTN_STATE.SPIN_ANXIA then
        if self.m_wheelRolling then
            return
        end
        if self.m_showWinAction then
            return
        end
        if self:getOnOffSpin() == true then
            return
        end
        self:startSpin()
    elseif self.m_state == SPIN_BTN_STATE.STOP_ANXIA then
        -- 如果点击过快看不见stop的按下状态， 直接变成了spin
        performWithDelay(
            self,
            function()
                self:overAutoSpin()
            end,
            0.1
        )
    end
end

function CardNadoWheelSpin:clickCancelFunc(sender)
    print("--- clickCancelFunc ---", self.m_state, self.m_preState)
    self:removeHoldTimer()

    if self.m_state == SPIN_BTN_STATE.SPIN_ANXIA then
        if self.m_wheelRolling then
            return
        end
        if self.m_showWinAction then
            return
        end
        self:setState(SPIN_BTN_STATE.SPIN_NORMAL)
        self:updateBtn()
    elseif self.m_state == SPIN_BTN_STATE.STOP_ANXIA then
        self:setState(SPIN_BTN_STATE.STOP_NORMAL)
        self:updateBtn()
    elseif self.m_state == SPIN_BTN_STATE.STOP_NORMAL then
    -- 已经开始autospin了 不作处理
    end
end

function CardNadoWheelSpin:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickEndFunc then
            return
        end
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()
        local offx = math.abs(endPos.x - beginPos.x)
        if offx < 50 then
            self:clickEndFunc(sender)
        else
            self:clickCancelFunc(sender)
        end
    elseif eventType == ccui.TouchEventType.canceled then
        if not self.clickCancelFunc then
            return
        end
        self:clickCancelFunc(sender)
    end
end

return CardNadoWheelSpin
