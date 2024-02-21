--[[
    跨年重置界面
    一年只有一次
]]
local VipResetUI = class("VipResetUI", BaseLayer)

function VipResetUI:initDatas(_over)
    self.m_over = _over
    self:setLandscapeCsbName("VipNew/csd/mainUI/VipMainUI_NewYear.csb")
end

function VipResetUI:initCsbNodes()
    self.m_lbTitle1 = self:findChild("lb_title_1")
    self.m_lbTitle2 = self:findChild("lb_title_2")

    self.m_lbThisYearHead = self:findChild("lb_thisYear_head")
    self.m_lbThisYear = self:findChild("lb_thisYear")

    self.m_lbLastYear = self:findChild("lb_lastYear_head")

    self.m_lbLastDecember = self:findChild("lb_lastDecember")

    self.m_lbBtnLaunch = self:findChild("lb_btnLaunch")
end

function VipResetUI:initView()
    local resetData = self:getResetData()
    if not resetData then
        return
    end

    local thisYear = resetData:getYear()
    local onlineYear = resetData:getOnlineYear()
    local percent = resetData:getScale() * 100
    local thisYearPoints = util_formatCoins(resetData:getThisYearRewardVipPoints(), 30)
    local lastYearPoints = util_formatCoins(resetData:getLastYearVipPoints(), 30)
    local lastDecemberPoints = util_formatCoins(resetData:getLastYearDecVipPoints(), 30)
    local registerPoints = util_formatCoins(resetData:getRegisterTotalVipPoints(), 30)
    
    -- 一级标题
    self.m_lbTitle1:setString(string.format("LET'S LAUNCH VIP %d", thisYear))
    -- 二级标题
    self.m_lbTitle2:setString(string.format("%d VIP POINTS ARE GENERATED.", thisYear))
    -- 今年积分
    self.m_lbThisYearHead:setString(string.format("%s VIP POINTS:", tostring(thisYear)))
    self.m_lbThisYear:setString(thisYearPoints)
    -- 去年积分
    local lastYearStr = ""
    if thisYear == (onlineYear + 1) then
        lastYearStr = string.format("TOTAL VIP POINTS x%s: %s", percent .. "%", registerPoints)
    else
        lastYearStr = string.format("%s VIP POINTS x%s: %s", tostring(thisYear - 1), percent .. "%", lastYearPoints)
    end
    self.m_lbLastYear:setString(lastYearStr)
    -- 去年12月积分
    self.m_lbLastDecember:setString(string.format("DECEMBER VIP POINT: %s", lastDecemberPoints))

    -- 按钮文字
    self.m_lbBtnLaunch:setString(string.format("LAUNCH %d!", thisYear))
end

function VipResetUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_launch" then
        self:closeUI(
            function()
                -- 只能跳转到VIP界面，不用调用exitVipSys
                G_GetMgr(G_REF.Vip):showMainLayer(self.m_over)
            end
        )
    end
end

function VipResetUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function VipResetUI:onEnter()
    VipResetUI.super.onEnter(self)
end

function VipResetUI:getResetData()
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if vipData then
        return vipData:getResetData()
    end
    return nil
end

return VipResetUI
