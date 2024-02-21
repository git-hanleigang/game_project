---
--xcyy
--2018年5月23日
--FishManiaFishBoxItemProgress.lua

local FishManiaFishBoxItemProgress = class("FishManiaFishBoxItemProgress",util_require("base.BaseView"))

function FishManiaFishBoxItemProgress:initUI()

    self:createCsbNode("FishMania_LittleLogo_progress.csb")

    self.m_bar = self:findChild("LoadingBar")
    self.m_percentLab = self:findChild("m_lb_num")

    self:setProgress(0)
end 

function FishManiaFishBoxItemProgress:onExit()
    gLobalNoticManager:removeAllObservers(self)
    FishManiaFishBoxItemProgress.super.onExit(self)
end

function FishManiaFishBoxItemProgress:setProgress(_progressValue)
    local value = _progressValue*100
    local progressStr = string.format("%d%s", value, "%")

    self.m_bar:setPercent(value)
    self.m_percentLab:setString(progressStr)
end

return FishManiaFishBoxItemProgress