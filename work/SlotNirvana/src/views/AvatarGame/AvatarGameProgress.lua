--[[
    
]]

local AvatarGameProgress = class("AvatarGameProgress", BaseView)

function AvatarGameProgress:getCsbName()
    return "Activity/csb/Cash_dice/CashDice_upgrade.csb"
end

function AvatarGameProgress:initCsbNodes()
    self.m_progress = self:findChild("progress")
    self.m_lb_pro = self:findChild("txt_upgrade")
    self.m_node_lizi = self:findChild("jindu")
    self.m_node_lizi:setVisible(false)
end

function AvatarGameProgress:initUI()
    AvatarGameProgress.super.initUI(self)

    self.m_count = 10
    self:updateProgress(true)
end

function AvatarGameProgress:updateProgress(_isFirst)
    local gameData = globalData.avatarFrameData:getMiniGameData()
    local playTimes = gameData:getPlayTimes()
    local progressTime = playTimes % (self.m_count + 1)
    self.m_progress:setPercent(progressTime / self.m_count * 100)
    self.m_lb_pro:setString(progressTime .. "/" .. self.m_count)

    if playTimes > 0 and progressTime == 10 then 
        self:runCsbAction("faguang", true)
        if _isFirst then
            self:setVisible(false)
        end
    else
        util_csbPauseForIndex(self.m_csbAct, 0)
    end
end

return AvatarGameProgress