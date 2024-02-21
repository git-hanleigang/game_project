--[[
    author:JohnnyFred
    time:2019-11-05 10:23:40
]]
local BaseRankCellUI3 = class("BaseRankCellUI3", util_require("base.BaseView"))

function BaseRankCellUI3:initUI(data)
    self:createCsbNode(self:getCsbName())

    --rank
    self.m_rankValue = self:findChild("BitmapFontLabel_4")

    --season
    self.m_seasonValue = self:findChild("BitmapFontLabel_3")

    util_setCascadeOpacityEnabledRescursion(self,true)
    self:initView(data)
end

function BaseRankCellUI3:initView(data)
    if data == nil then
        return
    end
    self.m_rankValue:setString("#" .. data.p_rank)
    self.m_seasonValue:setString("SEASON " .. (data.p_season or ""))
end

------------------------------------------子类重写---------------------------------------
function BaseRankCellUI3:getCsbName()
    return nil
end
------------------------------------------子类重写---------------------------------------

return BaseRankCellUI3