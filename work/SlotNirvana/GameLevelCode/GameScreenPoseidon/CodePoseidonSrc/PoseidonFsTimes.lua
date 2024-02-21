---
--island
--2018年4月12日
--PoseidonFsTimes.lua
--
-- PoseidonFsTimes top bar

local PoseidonFsTimes = class("PoseidonFsTimes", util_require("base.BaseView"))
-- 构造函数
function PoseidonFsTimes:initUI(data)
    local resourceFilename = "Poseidon_Fs_Times.csb"
    self:createCsbNode(resourceFilename)
    self:runAnimByName("idleframe")
end

function PoseidonFsTimes:onEnter()
    
end

function PoseidonFsTimes:onExit()
    -- gLobalNoticManager:removeAllObservers(self)
end

function PoseidonFsTimes:runAnimByName(name, loop, func)
    self:runCsbAction(name, loop, func)
end

return PoseidonFsTimes