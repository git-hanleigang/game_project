--[[
    特殊卡册倒计时-购物主题
]]
local ObsidianCardTime = class("ObsidianCardTime", BaseView)

function ObsidianCardTime:initDatas()
    self.m_data = G_GetMgr(G_REF.ObsidianCard):getShortCardYears()
end

function ObsidianCardTime:getCsbName()
    return "CardRes/CardObsidian_2/csb/main/ObsidianAlbum_time.csb"
end

function ObsidianCardTime:initCsbNodes()
    self.m_time = self:findChild("lb_time")
    self:showDownTimer()
end

--显示倒计时
function ObsidianCardTime:showDownTimer()
    self:stopTimerAction()
    self.timerAction = schedule(self, handler(self, self.updateLeftTime), 1)
    self:updateLeftTime()
end

function ObsidianCardTime:updateLeftTime()
    if self.m_data then
        local albumId = G_GetMgr(G_REF.ObsidianCard):getCurAlbumID()
        local day, isOver = util_daysdemaining(self.m_data:getExpireAt(albumId), true)
        if isOver then
            self:stopTimerAction()
        else
            self.m_time:setString("" .. day)
        end
    else
        self:stopTimerAction()
    end
end

function ObsidianCardTime:stopTimerAction()
    if self.timerAction ~= nil then
        self:stopAction(self.timerAction)
        self.timerAction = nil
    end
end

return ObsidianCardTime
