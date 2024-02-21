--[[--
    说明按钮弹出的气泡
]]
local CFG_TEXT = {
    Normal = {
        "Earn VIP POINTS by playing &",
        "purchases for VIP Benefits."
    },
    December = {
        {
            "TOTAL VIP PTS: %s", -- [registterPoints]
            "%s VIP PTS: %s" -- [thisYear], [thisYearPoints]
        },
        "Dec. VIP PTS: %s" -- [thisDecemberPoints]
    },
    January = {
        {
            "TOTAL VIP PTS x%s: %s", -- [percent] [registterPoints]
            "%s VIP PTS x%s: %s" -- [lastYear] [percent] [lastYearPoints]
        },
        "%s Dec. VIP PTS: %s", -- [lastYear][lastDecemberPoints]
        "%s VIP PTS: %s" -- [thisYear] [thisYearPoints]
    }
}

local VipMainResetBubble = class("VipMainResetBubble", BaseView)

function VipMainResetBubble:getCsbName()
    return "VipNew/csd/mainUI/VIPMain_reset_Qipao.csb"
end

function VipMainResetBubble:initCsbNodes()
    self.m_lbDes = self:findChild("lb_dec")
end

function VipMainResetBubble:initUI()
    VipMainResetBubble.super.initUI(self)
    self:initText()
    self:playStart(
        function()
            if not tolua.isnull(self) then
                self:playIdle()
            end
        end
    )
end

function VipMainResetBubble:initText()
    local resetData = self:getResetData()
    if not resetData then
        return
    end
    local thisYear = resetData:getYear()
    local onlineYear = resetData:getOnlineYear()
    local thisYearPoints = util_formatCoins(resetData:getThisYearVipPoints(), 30)
    local thisYearDecPoints = util_formatCoins(resetData:getThisYearDecVipPoints(), 30)
    local percent = resetData:getScale() * 100
    local lastYeardPoints = util_formatCoins(resetData:getLastYearVipPoints(), 30)
    local lastYeardDecPoints = util_formatCoins(resetData:getLastYearDecVipPoints(), 30)
    local registterPoints = util_formatCoins(resetData:getRegisterTotalVipPoints(), 30)
    local texts = {}
    if resetData:getMonth() == 12 then
        if thisYear == onlineYear then
            texts[#texts + 1] = string.format(CFG_TEXT.December[1][1], registterPoints)
        else
            texts[#texts + 1] = string.format(CFG_TEXT.December[1][2], tostring(thisYear), thisYearPoints)
        end
        texts[#texts + 1] = string.format(CFG_TEXT.December[2], thisYearDecPoints)
    elseif resetData:getMonth() == 1 then
        if thisYear == onlineYear + 1 then
            texts[#texts + 1] = string.format(CFG_TEXT.January[1][1], percent .. "%", registterPoints)
        else
            texts[#texts + 1] = string.format(CFG_TEXT.January[1][2], tostring(thisYear - 1), percent .. "%", lastYeardPoints)
        end
        texts[#texts + 1] = string.format(CFG_TEXT.January[2], tostring(thisYear - 1), lastYeardDecPoints)
        texts[#texts + 1] = string.format(CFG_TEXT.January[3], tostring(thisYear), thisYearPoints)
    else
        texts = CFG_TEXT.Normal
    end
    local str = table.concat(texts, "\n")
    self.m_lbDes:setString(str)
end

function VipMainResetBubble:initTouchLayer()
    local touchLayer = self:createLayout()
    self:addChild(touchLayer)
    local lPos = touchLayer:getParent():convertToNodeSpace(cc.p(display.cx, display.cy))
    touchLayer:setPosition(lPos)
    self:addClick(touchLayer)
end

function VipMainResetBubble:playStart(_over)
    self:runCsbAction("start", false, _over, 60)
end

function VipMainResetBubble:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function VipMainResetBubble:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

function VipMainResetBubble:createLayout()
    local tLayout = ccui.Layout:create()
    tLayout:setName("touch")
    tLayout:setTouchEnabled(true)
    tLayout:setSwallowTouches(true)
    tLayout:setAnchorPoint(cc.p(0.5, 0.5))
    tLayout:setContentSize(cc.size(2048, 2048))
    tLayout:setClippingEnabled(false)
    tLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    tLayout:setBackGroundColor(cc.c3b(0, 0, 0))
    tLayout:setBackGroundColorOpacity(0)
    return tLayout
end

function VipMainResetBubble:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        self:closeUI()
    end
end

function VipMainResetBubble:closeUI()
    if self.m_closed then
        return
    end
    self.m_closed = true
    self:playOver(
        function()
            if not tolua.isnull(self) then
                self:removeFromParent()
            end
        end
    )
end

function VipMainResetBubble:onEnter()
    VipMainResetBubble.super.onEnter(self)
    self:initTouchLayer()
end

function VipMainResetBubble:getResetData()
    local vipData = G_GetMgr(G_REF.Vip):getData()
    if vipData then
        return vipData:getResetData()
    end
    return nil
end

return VipMainResetBubble
