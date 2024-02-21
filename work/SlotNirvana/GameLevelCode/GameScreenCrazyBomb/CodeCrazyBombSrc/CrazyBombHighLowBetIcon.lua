
local CrazyBombHighLowBetIcon = class("CrazyBombHighLowBetIcon",util_require("base.BaseView"))
-- feature 玩法结果界面
function CrazyBombHighLowBetIcon:initUI(data)
    self.m_data = data
    self:createCsbNode("CrazyBomb_rotarytable_lock.csb")
    self.m_Button_1 = self:findChild("Button_1")


end
function CrazyBombHighLowBetIcon:getIconWidth()
    local size = self.m_Button_1:getSize()
    return size.width
end


function CrazyBombHighLowBetIcon:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
        local flag = params
        if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
            flag=false
        end
        self.m_Button_1:setBright(flag)
        self.m_Button_1:setTouchEnabled(flag)
    end,"BET_ENABLE")

end

function CrazyBombHighLowBetIcon:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

--默认按钮监听回调
function CrazyBombHighLowBetIcon:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.m_data.m_clickBet then
        return
    end

    gLobalSoundManager:playSound("Sounds/btn_click.mp3")

    if self.m_data then
        self.m_data:showChoiceBetView()
    end
end


return CrazyBombHighLowBetIcon