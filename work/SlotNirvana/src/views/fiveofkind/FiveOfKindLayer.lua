local FiveOfKindLayer = class("FiveOfKindLayer",util_require("base.BaseView"))
function FiveOfKindLayer:initUI(func)
    self:createCsbNode("FiveOfKind/FiveOfKind.csb")
    self:runCsbAction("show",false,function()
        if func then
            func()
        end
        self:removeFromParent()
    end,20)
    self:setPosition(display.width,display.height-150)
    if globalData.slotRunData.isPortrait then
        self:setPosition(display.width,display.height-250)
    end
end
function FiveOfKindLayer:onEnter()
    -- gLobalSoundManager:playSound("Sounds/five_of_kind.mp3")
end

function FiveOfKindLayer:onExit()

end
return FiveOfKindLayer