---
--island
--2018年4月12日
--PoseidonGameBg.lua
--
-- PoseidonGameBg top bar

local PoseidonGameBg = class("PoseidonGameBg", util_require("base.BaseView"))
-- 构造函数
function PoseidonGameBg:initUI(machine)
    self.m_machine=machine
    local resourceFilename="Poseidon_Bg.csb"
    self:createCsbNode(resourceFilename)
    self:runAnimByName("normal")
end

function PoseidonGameBg:onEnter()
    
end

function PoseidonGameBg:onExit()
    -- gLobalNoticManager:removeAllObservers(self)
end

function PoseidonGameBg:runAnimByName(name, loop, func)
    self:runCsbAction(name, loop, func)
end

return PoseidonGameBg