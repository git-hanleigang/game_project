local FivePandeHighLowBetView = class("FivePandeHighLowBetView",util_require("base.BaseView"))
FivePandeHighLowBetView.m_isClick = nil
FivePandeHighLowBetView.m_clickHigh = nil

-- feature 玩法结果界面
function FivePandeHighLowBetView:initUI(data)
    self.m_machine = data
    self:createCsbNode("bet/FivePande_lower_betchoose.csb")
    self:findChild("lbs_betNum"):setString(util_formatCoins(self.m_machine:getMinBet(),20))
    self:runCsbAction("start",false,function()
        if self.m_isClick == nil then
            self:runCsbAction("idle",true)
        end
    end)
end

function FivePandeHighLowBetView:onEnter()

end


function FivePandeHighLowBetView:onExit()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
end
--默认按钮监听回调
function FivePandeHighLowBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_isClick  then
        return
    end
    self.m_isClick = true
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    self:findChild(name):setTouchEnabled(false)
    if name == "Button_1" then
        self.m_machine:unlockHigherBet()

        self:runCsbAction("over",false,function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
            self:removeFromParent()
        end)
    elseif name == "Button_2" then
        self:runCsbAction("over",false,function()
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
            self:removeFromParent()
        end)
    end
end


return FivePandeHighLowBetView

