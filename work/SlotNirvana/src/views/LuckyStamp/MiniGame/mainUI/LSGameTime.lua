--[[
]]
local LSGameTime = class("LSGameTime", BaseView)

function LSGameTime:getCsbName()
    return LuckyStampCfg.csbPath .. "mainUI/NewLuckyStamp_Main_time.csb"
end

function LSGameTime:initCsbNodes()
    self.m_lbTime = self:findChild("lb_time")
end

function LSGameTime:initUI()
    LSGameTime.super.initUI(self)

    local preTime = nil
    self:onUpdate(
        function(dt)
            local data = G_GetMgr(G_REF.LuckyStamp):getData()
            if data then
                local leftTime = data:getLeftTime()
                if preTime == nil then
                    preTime = leftTime
                else
                    if preTime ~= leftTime then
                        preTime = leftTime
                    else
                        return
                    end
                end
                if leftTime > 0 then
                    self.m_csbNode:setVisible(true)
                    local dayStr = util_daysdemaining(data:getExpireAt() / 1000)
                    self.m_lbTime:setString(dayStr)
                else
                    self.m_csbNode:setVisible(false)
                end
            end
        end
    )
end

function LSGameTime:onEnter()
    LSGameTime.super.onEnter(self)
end

return LSGameTime
