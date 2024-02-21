---
--xcyy
--2018年5月23日
--OwlsomeWizardSpineMagicBook.lua
local PublicConfig = require "OwlsomeWizardPublicConfig"
local OwlsomeWizardSpineMagicBook = class("OwlsomeWizardSpineMagicBook",util_require("base.BaseView"))


function OwlsomeWizardSpineMagicBook:initUI()
    
end

function OwlsomeWizardSpineMagicBook:initSpineUI()
    self.m_spine_magic_book = util_spineCreate("OwlsomeWizard_mofashu",true,true)
    self:addChild(self.m_spine_magic_book)

    self:runIdleAni()
end

--[[
    idle
]]
function OwlsomeWizardSpineMagicBook:runIdleAni()
    util_spinePlay(self.m_spine_magic_book,"idle",true)
end

--[[
    执行时间线
]]
function OwlsomeWizardSpineMagicBook:runSpineAnim(aniName,loop,func)
    if not loop then
        loop = false
    end
    util_spinePlay(self.m_spine_magic_book,aniName,loop)
    if type(func) == "function" then
        util_spineEndCallFunc(self.m_spine_magic_book,aniName,func)
    end
end


return OwlsomeWizardSpineMagicBook