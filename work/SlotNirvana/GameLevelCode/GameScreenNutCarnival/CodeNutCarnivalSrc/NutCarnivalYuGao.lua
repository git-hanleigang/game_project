--[[
    预告中奖
]]
local NutCarnivalYuGao = class("NutCarnivalYuGao", cc.Node)
local PublicConfig = require "NutCarnivalPublicConfig"

function NutCarnivalYuGao:initData_(_machine)
    self.m_machine = _machine

    self.m_winningNoticeTime   = 60/30
	self.m_bPlayWinningNotice = false

    self:initUI()
end
function NutCarnivalYuGao:initUI()
    self.m_spine    = util_spineCreate("Socre_NutCarnival_Wild",true,true)
    self:addChild(self.m_spine)
end

--[[
    预告状态
]]
function NutCarnivalYuGao:setWinningNoticeStatus(_bTrigger)
    self.m_bPlayWinningNotice = _bTrigger
end
function NutCarnivalYuGao:getWinningNoticeStatus()
    return self.m_bPlayWinningNotice
end
function NutCarnivalYuGao:spinResetData()
    self:setWinningNoticeStatus(false)
end
function NutCarnivalYuGao:isTriggerYuGao()
    local bFeature     = self.m_machine:isTriggerPickGame()
    local bProbability = (math.random(1,10) <= 4)
    -- bProbability = true--^^^
    local bTrigger = bFeature and bProbability

    return bTrigger
end


function NutCarnivalYuGao:playYuGaoAnim()
    local bTrigger = self:isTriggerYuGao()
    if not bTrigger then
        return
    end
    self.m_bPlayWinningNotice = bTrigger
    gLobalSoundManager:playSound(PublicConfig.sound_NutCarnival_notice_1)
    self:setVisible(true)
    util_spinePlay(self.m_spine, "yugao", false)
    performWithDelay(self,function()
        self:setVisible(false)
    end, self.m_winningNoticeTime)
end

return NutCarnivalYuGao