

local BaseView = require("base.BaseView")
local AdsChallengeTaskProgressNode = class("AdsChallengeTaskProgressNode",BaseView)

function AdsChallengeTaskProgressNode:initDatas(isPortrait,isSpecial)
    self.m_isPortrait = isPortrait
    self.m_isSpecial = isSpecial
end

function AdsChallengeTaskProgressNode:getCsbName()
    if self.m_isPortrait then
        return  "Ad_Challenge/csb/Ad_ProgressCell_Shu.csb"
    else
        return "Ad_Challenge/csb/Ad_ProgressCell.csb"
    end
end

function AdsChallengeTaskProgressNode:initCsbNodes()
    self.m_sp_progressCell1 = self:findChild("sp_progressCell1")
    self.m_sp_progressCell2 = self:findChild("sp_progressCell2")
    if self.m_isSpecial and not self.m_isPortrait then
        util_changeTexture(self.m_sp_progressCell1, "Ad_Challenge/img/ui_mainUi/Ad_progress_cell4.png")
        util_changeTexture(self.m_sp_progressCell2, "Ad_Challenge/img/ui_mainUi/Ad_progress_cell3.png")
    end
    self.m_txt_num = self:findChild("txt_num")
end

function AdsChallengeTaskProgressNode:updateData(_rewardTask)

    self.m_sp_progressCell2:setVisible(_rewardTask.collected and not gLobalAdChallengeManager:willDoComplete(_rewardTask.targetWatchCount))
    self.m_sp_progressCell1:setVisible( not _rewardTask.collected or gLobalAdChallengeManager:willDoComplete(_rewardTask.targetWatchCount))
    self.m_txt_num:setString("" .._rewardTask.targetWatchCount)
end

function AdsChallengeTaskProgressNode:doTaskComplete(_rewardTask)
    self.m_sp_progressCell2:setVisible(_rewardTask.collected)
    self.m_sp_progressCell1:setVisible( not _rewardTask.collected)
end

return AdsChallengeTaskProgressNode
