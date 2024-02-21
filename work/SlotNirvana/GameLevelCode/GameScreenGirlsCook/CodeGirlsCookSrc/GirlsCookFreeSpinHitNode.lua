---
--xcyy
--2018年5月23日
--GirlsCookFreeSpinHitNode.lua

local GirlsCookFreeSpinHitNode = class("GirlsCookFreeSpinHitNode",util_require("base.BaseView"))


function GirlsCookFreeSpinHitNode:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("Socre_GirlsCook_jinkuang.csb")
end


function GirlsCookFreeSpinHitNode:onEnter()
 
end

function GirlsCookFreeSpinHitNode:onExit()
 
end

--[[
    中奖动画
]]
function GirlsCookFreeSpinHitNode:hitAni(func)
    self:runCsbAction("actionframe",false,function()
        self:runCsbAction("idleframe")
        if type(func) == "function" then
            func()
        end
    end)
end

return GirlsCookFreeSpinHitNode