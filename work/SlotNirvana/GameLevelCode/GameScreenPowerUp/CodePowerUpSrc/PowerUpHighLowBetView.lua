local PowerUpHighLowBetView = class("PowerUpHighLowBetView",util_require("base.BaseView"))
PowerUpHighLowBetView.m_callback = nil

-- feature 玩法结果界面
function PowerUpHighLowBetView:initUI(data)
    self.m_machine = data
    self:createCsbNode("bet/PowerUp_lower_bet.csb")


    self:findChild("lab_bet"):setString(util_formatCoins(self.m_machine:getMinBet(),20))
    self:runCsbAction("start",false,function()
        if self.m_isClick == nil then
            self:runCsbAction("idle",true)
        end
    end)
end

function PowerUpHighLowBetView:onEnter()

end


function PowerUpHighLowBetView:onExit()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
end

--默认按钮监听回调
function PowerUpHighLowBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    self:findChild(name):setTouchEnabled(false)
    if self.m_isClick  then
        return
    end
    self.m_isClick = true
    if name == "nudgeBtn" then
        self.m_machine:unlockHigherBet()
        self:runCsbAction("over",false,function()
            self:removeFromParent()
        end)
    elseif name == "regularBtn" then
        self:runCsbAction("over",false,function()
            self:removeFromParent()
        end)
    end
end


return PowerUpHighLowBetView

