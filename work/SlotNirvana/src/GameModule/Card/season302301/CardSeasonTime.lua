--[[
    -- 赛季结束倒计时
    --
]]
local CardSeasonTime201903 = util_require("GameModule.Card.season201903.CardSeasonTime")
local CardSeasonTime = class("CardSeasonTime", CardSeasonTime201903)

function CardSeasonTime:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonTimeRes, "season302301")
end

function CardSeasonTime:initUI()

    self:createCsbNode(self:getCsbName())

    self.m_timeNode = self:findChild("Node_time")
    self.m_timeNode:setVisible(false)

    self.m_timeBg = self:findChild("timeBg")
    self.m_timeStr = self:findChild("timeStr")

    -- 只有当前赛季显示
    if CardSysRuntimeMgr:getCurAlbumID() == CardSysRuntimeMgr:getSelAlbumID() then
        self:updateTime()
    end
end

return CardSeasonTime
