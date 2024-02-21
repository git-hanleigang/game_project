local CrazyBombHighLowBetView = class("CrazyBombHighLowBetView",util_require("base.BaseView"))
CrazyBombHighLowBetView.m_callback = nil

-- feature 玩法结果界面
function CrazyBombHighLowBetView:initUI(data)
    self.m_machine = data
    self:createCsbNode("CrazyBomb_ower_betchoose.csb")

    self:findChild("lbs_betNum"):setString(util_formatCoins(self.m_machine:getMinBet(),6))
    self:runCsbAction("start",false,function()
        if self.m_click == nil then
            self:runCsbAction("idle",true)
        end
    end)
end

function CrazyBombHighLowBetView:onEnter()

end


function CrazyBombHighLowBetView:onExit()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
end

--默认按钮监听回调
function CrazyBombHighLowBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_click then
        return
    end
    self.m_click = true
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    self:findChild(name):setTouchEnabled(false)
    if name == "Button_1" then
        gLobalSoundManager:playSound("CrazyBombSounds/crazybomb_lowHighBetChange.mp3")

        self.m_machine:unlockHigherBet()

        self:runCsbAction("over",false,function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

            self:removeFromParent()
        end)
    elseif name == "Button_2" then
        self:runCsbAction("over",false,function()
            self:removeFromParent()
        end)
    end
end


return CrazyBombHighLowBetView

