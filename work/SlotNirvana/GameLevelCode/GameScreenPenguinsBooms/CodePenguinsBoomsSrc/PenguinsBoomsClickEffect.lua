local PenguinsBoomsClickEffect = class("PenguinsBoomsClickEffect",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "PenguinsBoomsPublicConfig"

PenguinsBoomsClickEffect.ClickStatus = {
    Normal = 0,
    Click  = 1,
}

function PenguinsBoomsClickEffect:initUI(_params)
    --[[
        _params = {
            machine = machine,
        }
    ]]
    self.m_machine = _params.machine

    self.m_clickStatus = self.ClickStatus.Normal

    self:createCsbNode("PenguinsBooms_dianji.csb")
    self.m_effectNode = self:findChild("Node_effect")

    self:addClick(self:findChild("Panel_click"))
end

function PenguinsBoomsClickEffect:checkClickStatus()
    -- 短时间内点击
    if self.ClickStatus.Normal ~= self.m_clickStatus then
        return false
    end
    -- 滚轮转动
    if self.m_machine:getGameSpinStage( ) ~= IDLE or self.m_machine:getCurrSpinMode() ~= NORMAL_SPIN_MODE then
        return false
    end
    -- 事件执行
    if self.m_machine.m_isRunningEffect then
        return false
    end
    -- 升行
    if self.m_machine:isPenguinsBoomsUpRow() then
        return false
    end

    return true
end
--默认按钮监听回调
function PenguinsBoomsClickEffect:clickFunc(sender)
    if not self:checkClickStatus() then
        return
    end
    self.m_clickStatus = self.ClickStatus.Click

    local touchEndPos = sender:getTouchEndPosition()
    local nodePos     = self.m_effectNode:getParent():convertToNodeSpace(touchEndPos)
    self.m_effectNode:setPosition(nodePos)
    --点击效果
    self:runCsbAction("actionframe", false, function()
        self.m_clickStatus = self.ClickStatus.Normal
    end)
    --角色反馈
    local roleSpine = self.m_machine:getCurRoleSpine(nil)
    roleSpine:playClickAnim()
    --点击音效
    self:playEffectSound()
end
function PenguinsBoomsClickEffect:playEffectSound()
    gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_role_click)
end

return PenguinsBoomsClickEffect