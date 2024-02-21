
local CatchMonstersPanelSpin = class("CatchMonstersPanelSpin",util_require("Levels.BaseLevelDialog"))

function CatchMonstersPanelSpin:initUI(_data)
    self.m_machine = _data.machine
    -- 点击跳过时的回调
    self.m_skipCallBack = nil

    self:createCsbNode("CatchMonsters_WheelPanel.csb")

    self:addClick(self:findChild("Panel_spin"))
end

--[[
    点击事件
]]
function CatchMonstersPanelSpin:clickFunc(sender)
    self:skipPanelClickCallBack()
end

function CatchMonstersPanelSpin:skipPanelClickCallBack()
    if self.m_skipCallBack then
        self.m_skipCallBack()
    end
end

-- 设置跳过后的回调
function CatchMonstersPanelSpin:setSkipCallBack(_fun)
    self.m_skipCallBack = _fun
end
function CatchMonstersPanelSpin:clearSkipCallBack()
    self.m_skipCallBack = nil
end

return CatchMonstersPanelSpin