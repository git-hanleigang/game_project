---
--xcyy
--2018年5月23日
--BunnysLockTopDollarItem.lua

local BunnysLockTopDollarItem = class("BunnysLockTopDollarItem",util_require("Levels.BaseLevelDialog"))

--倍数类型对应
local MUTIPLE_TYPE = {
    [1] = 0,
    [2] = 1,
    [3] = 2,
    [4] = 2,
    [5] = 3,
    [6] = 3,
    [7] = 4,
    [8] = 4,
    [9] = 5,
    [10] = 5
}

function BunnysLockTopDollarItem:initUI(params)
    self.m_index = params.index
    self:createCsbNode("Topdollar_dan.csb")
    
end

function BunnysLockTopDollarItem:updateMutilple(coins,isHit)
    local egg_type = MUTIPLE_TYPE[self.m_index]
    for index = 1,6 do
        self:findChild("dan_"..(index - 1)):setVisible(index - 1 == egg_type)
    end
    self:findChild("shuzi"):setString(coins)
    self:findChild("shuzi_dark"):setString(coins)

    if isHit then
        self:runIdleAni()
    else
        self:runDarkAni()
    end
end

function BunnysLockTopDollarItem:runDarkAni()
    self:runCsbAction("dark",true)
end

function BunnysLockTopDollarItem:runIdleAni()
    self:runCsbAction("idleframe",true)
end

--[[
    播放闪烁动画
]]
function BunnysLockTopDollarItem:runTwinkleAni(func)
    self:runCsbAction("actionframe",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    先亮起后压暗
]]
function BunnysLockTopDollarItem:runLightToDarkAni(func)
    self:runCsbAction("actionframe3",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    亮起动画
]]
function BunnysLockTopDollarItem:runLightAni(func)
    self:runCsbAction("actionframe1",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    亮起动画
]]
function BunnysLockTopDollarItem:runSpecialLightAni(func)
    self:runCsbAction("actionframe2",false,function()
        if type(func) == "function" then
            func()
        end
    end)
end

return BunnysLockTopDollarItem