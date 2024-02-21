--[[
    预告中奖
]]
local TripleBingoYuGao = class("TripleBingoYuGao")
local PublicConfig = require "TripleBingoPublicConfig"
function TripleBingoYuGao:initData_(_machine)
    self.m_machine = _machine

    self.m_animName          = "actionframe_yugao"
    self.m_winningNoticeTime = 90/30
	self.m_bPlayWinningNotice = false

    self:initUI()
end
function TripleBingoYuGao:initUI()
    self.m_spine = util_spineCreate("TripleBingo_yugao", true, true)
    self.m_machine:findChild("Node_yugao"):addChild(self.m_spine)
    self.m_spine:setVisible(false)
    self.m_csb   = util_createAnimation("TripleBingo_yugao2.csb")
    self.m_machine:findChild("Node_yugao2"):addChild(self.m_csb)
    self.m_csb:setVisible(false)
end

--[[
    预告状态
]]
function TripleBingoYuGao:setWinningNoticeStatus(_bTrigger)
    self.m_bPlayWinningNotice = _bTrigger
end
function TripleBingoYuGao:getWinningNoticeStatus()
    return self.m_bPlayWinningNotice
end
function TripleBingoYuGao:spinResetData()
    self:setWinningNoticeStatus(false)
end
function TripleBingoYuGao:isTriggerYuGao()
    local features = self.m_machine.m_runSpinResultData.p_features or {} 
    local bFree   = features[2] == SLOTO_FEATURE.FEATURE_FREESPIN and self.m_machine:getCurrSpinMode() ~= FREE_SPIN_MODE
    local bBonus  = self.m_machine:isTriggerBingoLineCommon()
    local bFeature     = bFree or bBonus
    local bProbability = (math.random(1,10) <= 4)
    -- bProbability = true--^^^
    -- bProbability = false--^^^

    local bTrigger = bFeature and bProbability
    return bTrigger
end


function TripleBingoYuGao:playYuGaoAnim(_fun)
    local bTrigger = self:isTriggerYuGao()
    if not bTrigger then
        return _fun()
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.TRIPLEBINGO_SOUND_53)
    self.m_bPlayWinningNotice = bTrigger
    --角色联动
    self.m_machine.m_beerL:playYugaoAnim()
    self.m_machine.m_beerR:playYugaoAnim()

    self.m_spine:setVisible(true)
    self.m_csb:setVisible(true)
    util_spinePlay(self.m_spine, self.m_animName, false)
    util_spineEndCallFunc(self.m_spine, self.m_animName, function()
        self.m_spine:setVisible(false)
    end)
    self.m_csb:runCsbAction(self.m_animName, false, function()
        self.m_csb:setVisible(false)
    end)

    local delayTime = self.m_machine:getRunTimeBeforeReelDown()
    delayTime = math.max(0, self.m_winningNoticeTime - delayTime)
    self.m_machine:levelPerformWithDelay(self.m_machine, delayTime, _fun)
end

return TripleBingoYuGao