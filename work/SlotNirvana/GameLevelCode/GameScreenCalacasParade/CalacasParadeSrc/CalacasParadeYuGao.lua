--[[
    -- 预告中奖
    self.m_yugaoAnim = util_createView("CalacasParadeSrc.CalacasParadeYuGao", self)
]]
local CalacasParadeYuGao = class("CalacasParadeYuGao")
local PublicConfig = require "CalacasParadePublicConfig"

function CalacasParadeYuGao:initData_(_machine)
    self.m_machine = _machine

    self:initUI()
end
function CalacasParadeYuGao:initUI()
end

function CalacasParadeYuGao:isTriggerYuGao()
    local triggerType = ""
    local bProbability = (math.random(1,10) <= 4)
    bProbability = true
    if bProbability then
        if "" == triggerType then
            triggerType = self:isTriggerFreeYugaoAnim()
        end
    end

    return triggerType
end

function CalacasParadeYuGao:playYuGaoAnim(_triggerType)
    if "free" == _triggerType then
        return self:playFreeYugaoAnim()
    end
    -- if "free" == _triggerType then
    --     return self:playFreeYugaoAnim()
    -- end
    return 0
end

--free预告
function CalacasParadeYuGao:isTriggerFreeYugaoAnim()
    local features = self.m_machine.m_runSpinResultData.p_features or {} 
    local bFreeSpinMode = self.m_machine:getCurrSpinMode() == FREE_SPIN_MODE
    local bTriggerFree  = features[2] == SLOTO_FEATURE.FEATURE_FREESPIN
    local bFree   = bTriggerFree and not bFreeSpinMode
    local triggerType = bFree and "free" or ""
    return triggerType
end
function CalacasParadeYuGao:playFreeYugaoAnim()
    gLobalSoundManager:playSound(PublicConfig.sound_CalacasParade_Notice_2)
    self:createFreeYugaoAnim()
    util_spinePlay(self.m_freeYugaoSpine, self.m_freeYugaoAnimName, false)
    util_spinePlay(self.m_freeYanhuaSpine, self.m_freeYugaoAnimName, false)
    util_spineEndCallFunc(self.m_freeYugaoSpine, self.m_freeYugaoAnimName, function()
        self.m_freeYugaoSpine:setVisible(false)
        self.m_freeYanhuaSpine:setVisible(false)
    end)
    return self.m_freeYugaoTime
end
function CalacasParadeYuGao:createFreeYugaoAnim()
    if self.m_freeYugaoSpine then
        self.m_freeYugaoSpine:setVisible(true)
        self.m_freeYanhuaSpine:setVisible(true)
        return
    end
    --spine
    self.m_freeYugaoSpine = util_spineCreate("CalacasParade_yugao", true, true)
    self.m_machine:findChild("Node_yugao"):addChild(self.m_freeYugaoSpine)
    self.m_freeYanhuaSpine = util_spineCreate("CalacasParade_yanhua", true, true)
    self.m_machine:findChild("Node_yugao"):addChild(self.m_freeYanhuaSpine, 10)

    --anim
    self.m_freeYugaoAnimName = "actionframe_yugao"
    self.m_freeYugaoTime = self.m_freeYugaoSpine:getAnimationDurationTime(self.m_freeYugaoAnimName)
end



return CalacasParadeYuGao