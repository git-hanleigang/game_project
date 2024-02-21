---
--xcyy
--2018年5月23日
--RobinIsHoodSpineRole.lua
local PublicConfig = require "RobinIsHoodPublicConfig"
local NetSpriteLua = require("views.NetSprite")
local RobinIsHoodSpineRole = class("RobinIsHoodSpineRole",util_require("base.BaseView"))


function RobinIsHoodSpineRole:initUI(params)
    self.m_machine = params.machine
    
end

function RobinIsHoodSpineRole:initSpineUI()
    self.m_spine_role = util_spineCreate("RobinIsHood_juese",true,true)
    self:addChild(self.m_spine_role)

    self:runIdleAni()
end

--[[
    idle
]]
function RobinIsHoodSpineRole:runIdleAni(preAniIndex)
    
    local idle_acts = {"idle","idle1","idle2"}
    local aniIndex = 1
    local randIndex = math.random(1,100)
    if randIndex <= 10 then
        aniIndex = 2
    elseif randIndex <= 20 then
        aniIndex = 3
    end

    --前一个idle索引,若第一次播idle或前一次播的不是idle1,则必播idle1
    if not preAniIndex or preAniIndex ~= 1 then
        aniIndex = 1
    end

    local aniName = idle_acts[aniIndex]

    

    util_spinePlay(self.m_spine_role,aniName)
    local aniTime = self.m_spine_role:getAnimationDurationTime(aniName)

    performWithDelay(self,function()
        self:runIdleAni(aniIndex)
    end,aniTime)
end

--[[
    大赢庆祝动作
]]
function RobinIsHoodSpineRole:runBigWinAni(func)
    self:stopAllActions()
    util_spinePlay(self.m_spine_role,"actionframe_bigwin")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_bigwin",function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    free触发
]]
function RobinIsHoodSpineRole:runFreeTriggerAni(func)
    self:stopAllActions()
    util_spinePlay(self.m_spine_role,"actionframe_free")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_free",function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

return RobinIsHoodSpineRole