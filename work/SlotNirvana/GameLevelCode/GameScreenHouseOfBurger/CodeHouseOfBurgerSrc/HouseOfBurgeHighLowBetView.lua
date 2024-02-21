local HouseOfBurgeHighLowBetView = class("HouseOfBurgeHighLowBetView",util_require("base.BaseView"))
HouseOfBurgeHighLowBetView.m_callback = nil

-- feature 玩法结果界面
function HouseOfBurgeHighLowBetView:initUI(data)
    self.m_machine = data
    self:createCsbNode("bet/ChilliFiesta_bet.csb")


    -- self:findChild("lab_bet"):setString(util_formatCoins(self.m_machine:getMinBet(),20))
    self:runCsbAction("start",false,function()
        if self.m_isClick == nil then
            self:runCsbAction("idle",true)
        end
    end)
end

function HouseOfBurgeHighLowBetView:onEnter()

end


function HouseOfBurgeHighLowBetView:onExit()

end

--默认按钮监听回调
function HouseOfBurgeHighLowBetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound("Sounds/btn_click.mp3")
    self:findChild(name):setTouchEnabled(false)
    if self.m_isClick  then
        return
    end
    self.m_isClick = true
    if name == "Button_1" then
        self.m_machine:unlockHigherBet()
        self:runCsbAction("over",false,function()
            self:removeFromParent()
        end)
    elseif name == "Button_2" then
        self:runCsbAction("over",false,function()
            self:removeFromParent()
        end)
    end
end


return HouseOfBurgeHighLowBetView

