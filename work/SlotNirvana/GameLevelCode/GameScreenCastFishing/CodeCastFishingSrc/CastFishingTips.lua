local CastFishingTips = class("CastFishingTips",util_require("Levels.BaseLevelDialog"))

--[[

]]
CastFishingTips.TipState = {
    NotShow = 0,            --隐藏
    Start   = 1,            --播start
    Idle    = 2,            --播idle
    Over    = 3,            --播over
}
function CastFishingTips:initDatas(_data)
    self.m_machine  = _data[1]
    self.m_tipViewParent = _data[2]

    self.m_curState = self.TipState.NotShow
end
function CastFishingTips:initUI()
    self:createCsbNode("CastFishing_btnTip.csb")

    self.m_tipView = util_createAnimation("CastFishing_tishi.csb")
    self.m_tipViewParent:addChild(self.m_tipView)
    self.m_tipView:setVisible(false)
end

--默认按钮监听回调
function CastFishingTips:clickFunc(sender)
    local name = sender:getName()

    if "btn_tip" == name then
        -- gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_click.mp3")
        if not self:checkButtonCanClick() then
            return
        end
        self:onTipBtnClick()
    end
end
function CastFishingTips:checkButtonCanClick()
    local currSpinMode = globalData.slotRunData.currSpinMode
    -- freeSpin 和 auto 直接跳出
    if currSpinMode == FREE_SPIN_MODE or currSpinMode == AUTO_SPIN_MODE then
        return false
    end
    -- 棋盘在滚动
    local curSpinStage = globalData.slotRunData.gameSpinStage
    if IDLE ~= curSpinStage then
        return false
    end
    -- 正在执行事件
    if self.m_machine.m_isRunningEffect then
        return false
    end
    
    

    return true
end


function CastFishingTips:onTipBtnClick()
    -- 当前没有展示
    if self.m_curState == self.TipState.NotShow then
        self:playStartAnim()
    -- 当前正在展示idle状态
    elseif self.m_curState == self.TipState.Idle then
        self:playOverAnim()
    end
end


--[[
    start -> idle -> over
]]
function CastFishingTips:playStartAnim()
    self.m_tipView:setVisible(true)
    self.m_curState = self.TipState.Start
    self.m_tipView:runCsbAction("chuxian", false ,function()
        self.m_curState = self.TipState.Idle
        performWithDelay(self,function()
            self:playOverAnim()
        end, 5)
    end)
end

function CastFishingTips:playOverAnim()
    if self.m_curState == self.TipState.NotShow or  self.m_curState == self.TipState.Over then
        return 
    end
    self:stopAllActions()
    self.m_curState = self.TipState.Over
    self.m_tipView:runCsbAction("xiaoshi", false ,function()
        self.m_tipView:setVisible(false)
        self.m_curState = self.TipState.NotShow
    end)
end

return CastFishingTips