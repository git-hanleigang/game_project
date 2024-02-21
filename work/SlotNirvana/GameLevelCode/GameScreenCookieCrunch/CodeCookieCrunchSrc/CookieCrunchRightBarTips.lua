local CookieCrunchRightBarTips = class("CookieCrunchRightBarTips",util_require("Levels.BaseLevelDialog"))

--[[
    _data = {
        clickNode = cc.Layout,
        tipList   = {
            {
                index  = 1,
                parent = cc.Node, 

            }
        },
    }
]]
CookieCrunchRightBarTips.TipState = {
    NotShow = 0,            --隐藏
    Start   = 1,            --播start
    Idle    = 2,            --播idle
    Over    = 3,            --播over
}
function CookieCrunchRightBarTips:initDatas(_machine, _data)
    self.m_machine  = _machine
    self.m_initData = _data

    self.m_curState = self.TipState.NotShow
end
function CookieCrunchRightBarTips:initUI()

    self.m_tipsList = {}
    for i,_data in ipairs(self.m_initData.tipList) do
        local tipCsb   = util_createAnimation("CookieCrunch_Tips.csb")
        local nodeName = string.format("Tips_%d", _data.index)
        tipCsb:findChild(nodeName):setVisible(true)
        _data.parent:addChild(tipCsb)
        tipCsb:setVisible(false)
        table.insert(self.m_tipsList, tipCsb)
    end

    self:addClick(self.m_initData.clickNode)
end

--默认按钮监听回调
function CookieCrunchRightBarTips:clickFunc(sender)
    if not self:checkButtonCanClick() then
        return
    end
    gLobalSoundManager:playSound("CookieCrunchSounds/sound_CookieCrunch_click.mp3")
    
    self:onTipBtnClick()
end
function CookieCrunchRightBarTips:checkButtonCanClick()
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
    -- 当前在打开状态
    if self.m_curState ~= self.TipState.NotShow then
        return false
    end

    return true
end


function CookieCrunchRightBarTips:onTipBtnClick()
    self:openTipView()
end


--[[
    start -> idle -> over
]]
function CookieCrunchRightBarTips:openTipView()
    self.m_curState = self.TipState.Start
    for i,_tipAnim in ipairs(self.m_tipsList) do
        local index = i
        _tipAnim:setVisible(true)

        _tipAnim:runCsbAction("show", false, function()

            

        end)
        local startTime = self:getCookieCrunchTipAnimTime(_tipAnim, "show")
        performWithDelay(self, function()
            if 1 == index then
                self.m_curState = self.TipState.Idle
            end
            _tipAnim:runCsbAction("idle", false)

            local idleTime = 5
            performWithDelay(self, function()
                if 1 == index then
                    self.m_curState = self.TipState.Over
                end

                _tipAnim:runCsbAction("over", false)
                local overTime = self:getCookieCrunchTipAnimTime(_tipAnim, "over")
                performWithDelay(self, function()
                    if 1 == index then
                        self.m_curState = self.TipState.NotShow
                    end
                    _tipAnim:setVisible(false)
                end, overTime)
            end, idleTime)

        end, startTime)
    end
end

function CookieCrunchRightBarTips:playOverAnim()
    if self.m_curState == self.TipState.NotShow then
        return 
    end

    self:stopAllActions()
    for i,_tipAnim in ipairs(self.m_tipsList) do
        local index = i
        
        _tipAnim:runCsbAction("over", false)
        local overTime = self:getCookieCrunchTipAnimTime(_tipAnim, "over")
        performWithDelay(self, function()
            if 1 == index then
                self.m_curState = self.TipState.NotShow
            end
            _tipAnim:setVisible(false)
        end, overTime)
    end
end



--[[
    工具
]]
function CookieCrunchRightBarTips:getCookieCrunchTipAnimTime(_tipAnim, _animName)
    return util_csbGetAnimTimes(_tipAnim.m_csbAct, _animName)
end

return CookieCrunchRightBarTips