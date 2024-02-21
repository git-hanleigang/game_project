local PowerUpHighLowBetIcon = class("PowerUpHighLowBetIcon",util_require("base.BaseView"))
-- feature 玩法结果界面
function PowerUpHighLowBetIcon:initUI(data)
    self.m_data = data
    self:createCsbNode("bet/PowerUp_NudgeIcon.csb")
    self.m_Button_1 = self:findChild("Button_1")
    self:runCsbAction("actionframestart",false,function()
        self:runCsbAction("idleframe",true)
    end)
end

function PowerUpHighLowBetIcon:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        local flag = params
        if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
            flag=false
        end
        self.m_Button_1:setBright(flag)
        self.m_Button_1:setTouchEnabled(flag)
    end,"BET_ENABLE")

end


function PowerUpHighLowBetIcon:onExit()
    gLobalNoticManager:removeAllObservers(self)

end

--默认按钮监听回调
function PowerUpHighLowBetIcon:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    if self.m_data.m_clickBet then
        return
    end
    if self.m_data then
        self.m_data:showChoiceBetView()
    end
end


return PowerUpHighLowBetIcon