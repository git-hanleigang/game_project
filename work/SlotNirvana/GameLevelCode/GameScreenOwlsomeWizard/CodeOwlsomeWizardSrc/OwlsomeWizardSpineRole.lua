---
--xcyy
--2018年5月23日
--OwlsomeWizardSpineRole.lua
local PublicConfig = require "OwlsomeWizardPublicConfig"
local NetSpriteLua = require("views.NetSprite")
local OwlsomeWizardSpineRole = class("OwlsomeWizardSpineRole",util_require("base.BaseView"))

local CLIP_SIZE = CCSizeMake(290,290)

function OwlsomeWizardSpineRole:initUI(params)
    self.m_machine = params.machine
    
end

function OwlsomeWizardSpineRole:initSpineUI()
    self.m_spine_role = util_spineCreate("OwlsomeWizard_juese",true,true)
    self:addChild(self.m_spine_role)

    self:runIdleAni()
end

--[[
    idle
]]
function OwlsomeWizardSpineRole:runIdleAni()
    self.m_spine_role:setVisible(true)
    util_spinePlay(self.m_spine_role,"idleframe",true)
end

--[[
    大赢庆祝动作
]]
function OwlsomeWizardSpineRole:runBigWinAni(func)
    util_spinePlay(self.m_spine_role,"actionframe_qingzhu")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_qingzhu",function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    加buff动作
]]
function OwlsomeWizardSpineRole:runAddBuffAni(keyFunc,endFunc)
    util_spinePlay(self.m_spine_role,"actionframe_buff")
    util_spineFrameCallFunc(self.m_spine_role,"actionframe_buff","buff",function()
        if type(keyFunc) == "function" then
            keyFunc()
        end
    end,function()
        self:runIdleAni()
        if type(endFunc) == "function" then
            endFunc()
        end
    end)
end

--[[
    预告中奖动画
]]
function OwlsomeWizardSpineRole:runNoticeAni(func)
    util_spinePlay(self.m_spine_role,"actionframe_xiaoshi")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_xiaoshi",function()
        self.m_spine_role:setVisible(false)
        if type(func) == "function" then
            func()
        end
    end)

    local spine_light = util_spineCreate("OwlsomeWizard_juese_tx",true,true)
    self:addChild(spine_light)
    util_spinePlay(spine_light,"actionframe_xiaoshi")
    util_spineEndCallFunc(spine_light,"actionframe_xiaoshi",function()
        spine_light:setVisible(false)
        performWithDelay(spine_light,function()
            spine_light:removeFromParent()
        end,0.1)
    end)

    local aniTime = self.m_spine_role:getAnimationDurationTime("actionframe_xiaoshi")
    return aniTime
end

--[[
    预告中奖结束后猫头鹰回到转盘上
]]
function OwlsomeWizardSpineRole:runNoticeOverAni(func)
    self.m_spine_role:setVisible(true)
    util_spinePlay(self.m_spine_role,"actionframe_show")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_show",function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)

    local spine_light = util_spineCreate("OwlsomeWizard_juese_tx",true,true)
    self:addChild(spine_light)
    util_spinePlay(spine_light,"actionframe_show")
    util_spineEndCallFunc(spine_light,"actionframe_show",function()
        spine_light:setVisible(false)
        performWithDelay(spine_light,function()
            spine_light:removeFromParent()
        end,0.1)
    end)

    local aniTime = self.m_spine_role:getAnimationDurationTime("actionframe_show")
    return aniTime
end

--[[
    获得jackpot施法动作
]]
function OwlsomeWizardSpineRole:runJackpotAni(keyFunc,endFunc)
    util_spinePlay(self.m_spine_role,"actionframe_shifa2")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_shifa2",function()
        self:runIdleAni()
    end)

    self.m_machine:delayCallBack(30 / 30,keyFunc)

    self.m_machine:delayCallBack(60 / 30,endFunc)
end

--[[
    重置转盘
]]
function OwlsomeWizardSpineRole:resetWheelAni(func)
    util_spinePlay(self.m_spine_role,"actionframe_shifa")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_shifa",function()
        self:runIdleAni()
    end)

    self.m_machine:delayCallBack(20 / 30,func)
end

--[[
    切换背景动作
]]
function OwlsomeWizardSpineRole:runChangeBgAni(func)
    util_spinePlay(self.m_spine_role,"actionframe_shifa4")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_shifa4",function()
        self:runIdleAni()
    end)

    self.m_machine:delayCallBack(30 / 30,func)
end


return OwlsomeWizardSpineRole