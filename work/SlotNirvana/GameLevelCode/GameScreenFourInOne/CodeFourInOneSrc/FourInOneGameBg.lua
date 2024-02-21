---
--island
--2018年4月12日
--FourInOneGameBg.lua
--
-- FourInOneGameBg top bar

local FourInOneGameBg = class("FourInOneGameBg", util_require("base.BaseView"))
-- 构造函数
function FourInOneGameBg:initUI(machine)
    self.m_machine=machine
    local resourceFilename="FourInOne_bg_guang.csb"
    self:createCsbNode(resourceFilename)
    self:runAnimByName("normal")

    self:runBgWheelImg( )
end

function FourInOneGameBg:onEnter()
    
end

function FourInOneGameBg:onExit()
    -- gLobalNoticManager:removeAllObservers(self)
end

function FourInOneGameBg:runAnimByName(name, loop, func)
    self:runCsbAction(name, loop, func)
end

function FourInOneGameBg:runBgWheelImg( )
    
    self:findChild("Node_1"):runAction(cc.RepeatForever:create(cc.RotateBy:create(20, 36)))

end

function FourInOneGameBg:stopBgWheelImg( )
    self:findChild("Node_1"):stopAllActions()
end

return FourInOneGameBg