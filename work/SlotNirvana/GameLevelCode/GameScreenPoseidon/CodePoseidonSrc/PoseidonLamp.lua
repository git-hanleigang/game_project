---
--island
--2018年4月12日
--PoseidonLamp.lua
--
-- PoseidonLamp top bar

local PoseidonLamp = class("PoseidonLamp", util_require("base.BaseView"))
-- 构造函数
function PoseidonLamp:initUI(data)
    local resourceFilename="Poseidon_Bg_"..data.."_light.csb"
    self:createCsbNode(resourceFilename)
    self:runAnimByName("idleframe", true)
    self.m_actionName = "idleframe"
end

function PoseidonLamp:onEnter()
    
end

function PoseidonLamp:onExit()
    -- gLobalNoticManager:removeAllObservers(self)
end

function PoseidonLamp:runAnimByName(name, loop, func)
    self.m_actionName = name
    self:runCsbAction(name, loop, func)
end

function PoseidonLamp:runIdleFram()
    if self.m_actionName ~= "idleframe" then
        self:runAnimByName("idleframe", true)
    end
end

return PoseidonLamp