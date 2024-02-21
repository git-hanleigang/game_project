--FortuneCatsLockSymbolEffect.lua

local FortuneCatsLockSymbolEffect = class("FortuneCatsLockSymbolEffect", util_require("base.BaseView"))

function FortuneCatsLockSymbolEffect:initUI()
    self:createCsbNode("WinFrameFortuneCats_suoding.csb")
end

function FortuneCatsLockSymbolEffect:playLock()
    self:runCsbAction("actionframe", false,function (  )
        self:runCsbAction("idleframe", true)
    end)
end

function FortuneCatsLockSymbolEffect:playLockIdle()
    self:runCsbAction("idleframe", true)
end

function FortuneCatsLockSymbolEffect:onEnter()
end

function FortuneCatsLockSymbolEffect:onExit()
end

return FortuneCatsLockSymbolEffect
