--[[
    -- 赛季结束倒计时
    --
]]
local CardSeasonTime = class("CardSeasonTime", util_require("base.BaseView"))

function CardSeasonTime:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonTimeRes, "season201903")
end

-- 开始显示赛季倒计时的天数
function CardSeasonTime:getShowTimeDayNum()
    return 7
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

function CardSeasonTime:updateTime()
    local isEnd = self:showTime()
    if not isEnd then
        --倒计时
        if self.m_cardTimer ~= nil  then
            self:stopAction(self.m_cardTimer)
        end
        self.m_cardTimer = util_schedule(self, function()
            local _isEnd = self:showTime()
            if _isEnd then
                if self.m_cardTimer ~= nil  then
                    self:stopAction(self.m_cardTimer)
                end
                self.m_timeNode:setVisible(false)
            end
        end,1)
    end
end

function CardSeasonTime:showTime()
    local expireAt = CardSysManager:getSeasonExpireAt()
    local isEnd, isShow, textStr, isTextPostfix = CardSysManager:updateCardTimeStr(expireAt, self:getShowTimeDayNum())
    if isTextPostfix then
        if tonumber(textStr) == 1 then
            textStr = textStr .. " DAY LEFT"
        elseif tonumber(textStr) > 1 then
            textStr = textStr .. " DAYS LEFT"
        end
    end
    self.m_timeNode:setVisible(isShow)
    self.m_timeStr:setString(textStr)
    return isEnd, isShow
end

return CardSeasonTime