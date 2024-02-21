---
--xcyy
--2018年5月23日
--OrcaCaptainButtonView.lua
local PublicConfig = require "OrcaCaptainPublicConfig"
local OrcaCaptainButtonView = class("OrcaCaptainButtonView",util_require("Levels.BaseLevelDialog"))


function OrcaCaptainButtonView:initUI(machine)

    self:createCsbNode("OrcaCaptain_xuanzeanniu.csb")
    self.m_machine = machine
    self:runCsbAction("idle",true)
    self.m_allowClick = true
    self.clickCallFunc = nil
end

function OrcaCaptainButtonView:setClick(isClick)
    self.m_allowClick = isClick
end

function OrcaCaptainButtonView:setClickCallFunc(func)
    self.clickCallFunc = func
end

--[[
    点击按钮
]]
function OrcaCaptainButtonView:clickFunc(sender)
    if not self.m_allowClick then
        return
    end
    --弹出选择弹板
    self.m_machine:showChooseView(true)
end

function OrcaCaptainButtonView:setButtonEnabled(isEnabled)
    if isEnabled then
        self:runCsbAction("idle",true)
    else
        self:runCsbAction("idle2")
    end
    self:setClick(isEnabled)
    self:findChild("Button_1"):setEnabled(isEnabled)
end

return OrcaCaptainButtonView