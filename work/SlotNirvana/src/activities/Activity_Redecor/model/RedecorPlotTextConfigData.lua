--[[--
    对话配置数据
]]
local RedecorPlotTextConfigData = class("RedecorPlotTextConfigData")

function RedecorPlotTextConfigData:parseData(_netData)
    self.p_id = _netData[1]
    self.p_plotText = _netData[2]
    self:gsubContent()
end

function RedecorPlotTextConfigData:getId()
    return self.p_id
end

function RedecorPlotTextConfigData:getPlotTexts()
    -- if string.find(self.p_plotText, "%[player name%]") then
    --     local userName = globalData.userRunData.fbName and globalData.userRunData.fbName or globalData.userRunData.nickName
    --     self.p_plotText = string.gsub(self.p_plotText, "%[player name%]", userName)
    -- end
    return self.p_plotTexts
end

function RedecorPlotTextConfigData:gsubContent()
    if self.p_plotText then
        self.p_plotText = string.gsub(self.p_plotText, "=", ",")
        self.p_plotTexts = string.split(self.p_plotText, ";")
    end
end

return RedecorPlotTextConfigData
