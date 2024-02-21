-- 翻开bonus图标流程，可以通过点击跳过
local LeprechaunsCrockOpenBonusSkip = class("LeprechaunsCrockOpenBonusSkip",util_require("Levels.BaseLevelDialog"))

function LeprechaunsCrockOpenBonusSkip:initUI(_data)
    self.m_machine = _data.machine
    -- 点击跳过时的回调
    self.m_skipCallBack = nil

    self:createCsbNode("LeprechaunsCrock_BonusOpenSkip.csb")

    self:addClick(self:findChild("Panel_skip"))
end

--[[
    点击事件
]]
function LeprechaunsCrockOpenBonusSkip:clickFunc(sender)
    self:skipPanelClickCallBack()
end

function LeprechaunsCrockOpenBonusSkip:skipPanelClickCallBack()
    if self.m_skipCallBack then
        self.m_skipCallBack()
    end
end

-- 设置跳过后的回调
function LeprechaunsCrockOpenBonusSkip:setSkipCallBack(_fun)
    self.m_skipCallBack = _fun
end
function LeprechaunsCrockOpenBonusSkip:clearSkipCallBack()
    self.m_skipCallBack = nil
end

return LeprechaunsCrockOpenBonusSkip