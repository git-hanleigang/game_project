---
--island
--2018年4月12日
--FiveDragonLantern.lua
--
-- FiveDragonLantern top bar

local FiveDragonLantern = class("FiveDragonLantern", util_require("base.BaseView"))
-- 构造函数
function FiveDragonLantern:initUI()
    local resourceFilename="FiveDragon_denglong.csb"
    self:createCsbNode(resourceFilename)
end

function FiveDragonLantern:collect(func)
    self:runCsbAction("actionframeLightenUp", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function FiveDragonLantern:reset()
    self:runCsbAction("actionframeExtinguish")
end

function FiveDragonLantern:initLantern(isLight)
    self:runCsbAction("idleframe2")
    if isLight == true then
        self:runCsbAction("idleframe")
    end
end

function FiveDragonLantern:onEnter()

end

function FiveDragonLantern:onExit()

end

return FiveDragonLantern