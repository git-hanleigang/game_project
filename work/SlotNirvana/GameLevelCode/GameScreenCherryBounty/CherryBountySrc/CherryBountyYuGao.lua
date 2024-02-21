--[[
    预告中奖
]]
local PublicConfig = require "CherryBountyPublicConfig"
local CherryBountyYuGao = class("CherryBountyYuGao")

function CherryBountyYuGao:initData_(_machine)
    self.m_machine = _machine
end

function CherryBountyYuGao:isTriggerYuGao()
    local triggerType = ""
    local bProbability = (math.random(1,10) <= 4)
    if bProbability then
        if "" == triggerType then
            triggerType = self:isTriggerFreeYugaoAnim()
        end
    end
    return triggerType
end
function CherryBountyYuGao:playYuGaoAnim(_triggerType)
    if "free" == _triggerType then
        return self:playFreeYugaoAnim()
    end
    return 0
end

--free预告-常规选择玩法(特殊选择不播预告)
function CherryBountyYuGao:isTriggerFreeYugaoAnim()
    local features = self.m_machine.m_runSpinResultData.p_features or {} 
    local bFree    = #features > 1 and self.m_machine:isCommonSelectBonusGame()
    local triggerType = bFree and "free" or ""
    return triggerType
end
function CherryBountyYuGao:playFreeYugaoAnim()
    gLobalSoundManager:playSound(PublicConfig.sound_CherryBounty_Notice)
    self:createFreeYugaoAnim()
    util_spinePlay(self.m_freeYugaoSpine1, self.m_freeYugaoAnimName, false)
    util_spinePlay(self.m_freeYugaoSpine2, self.m_freeYugaoAnimName, false)
    util_spineEndCallFunc(self.m_freeYugaoSpine1, self.m_freeYugaoAnimName, function()
        self.m_freeYugaoSpine1:setVisible(false)
        self.m_freeYugaoSpine2:setVisible(false)
    end)
    return self.m_freeYugaoTime
end
function CherryBountyYuGao:createFreeYugaoAnim()
    if self.m_freeYugaoSpine1 then
        self.m_freeYugaoSpine1:setVisible(true)
        self.m_freeYugaoSpine2:setVisible(true)
        return
    end
    --spine
    self.m_freeYugaoSpine1 = util_spineCreate("CherryBounty_yugao1", true, true)
    self.m_machine:findChild("Node_yugao"):addChild(self.m_freeYugaoSpine1, 100)
    self.m_freeYugaoSpine2 = util_spineCreate("CherryBounty_yugao2", true, true)
    self.m_machine:findChild("Node_yugao"):addChild(self.m_freeYugaoSpine2, 10)
    --anim
    self.m_freeYugaoAnimName = "actionframe_yugao"
    self.m_freeYugaoTime = self.m_freeYugaoSpine1:getAnimationDurationTime(self.m_freeYugaoAnimName)
end

return CherryBountyYuGao