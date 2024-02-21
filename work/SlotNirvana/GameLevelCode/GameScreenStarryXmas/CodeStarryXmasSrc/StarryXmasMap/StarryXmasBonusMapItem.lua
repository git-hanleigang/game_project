local PublicConfig = require "StarryXmasPublicConfig"
local StarryXmasBonusMapItem = class("StarryXmasBonusMapItem", util_require("base.BaseView"))
-- 构造函数
function StarryXmasBonusMapItem:initUI(data)
    local resourceFilename = "StarryXmas_xiaoguan.csb"
    self:createCsbNode(resourceFilename)
end

function StarryXmasBonusMapItem:idle()
    local random = math.random(1,2)
    if random == 1 then
        self:runCsbAction("idleframe", true)
    else
        self:runCsbAction("idleframe2", true)
    end
end

function StarryXmasBonusMapItem:showParticle()

end

function StarryXmasBonusMapItem:click(func, LitterGameWin, machine)
    self:runCsbAction("actionframe", false, function()
        
    end)
    machine:waitWithDelay(30/60, function()
        if func ~= nil then
            func()
        end
    end)
end

--[[
    对钩动效
]]
function StarryXmasBonusMapItem:playGou()
    self:runCsbAction("gou_start", false, function()
        gLobalSoundManager:playSound(PublicConfig.Music_Check_Appear)
    end)
end

function StarryXmasBonusMapItem:completed()
    self:runCsbAction("idle", true)
end

function StarryXmasBonusMapItem:onEnter()

end

function StarryXmasBonusMapItem:onExit()

end

return StarryXmasBonusMapItem