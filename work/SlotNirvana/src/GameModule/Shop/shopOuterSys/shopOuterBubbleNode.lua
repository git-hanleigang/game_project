--[[
    外部关联系统展示
    气泡
]]

local BaseView = util_require("base.BaseView")
local shopOuterBubbleNode = class("shopOuterBubbleNode", BaseView)
function shopOuterBubbleNode:initUI(btnType, clickCallBack)
    self.m_btnType = btnType
    self.m_clickCallBack = clickCallBack
    if self.m_btnType == "LUCKY_CHALLENGE" then
        if globalData.slotRunData.isPortrait == true then
            self:createCsbNode("Shop_Res/Gem/GemBubble/Node_missionBubble_0.csb")
        else
            self:createCsbNode("Shop_Res/Gem/GemBubble/Node_missionBubble.csb")
        end
    elseif self.m_btnType == "DAILY_MISSION" then
        if globalData.slotRunData.isPortrait == true then
            self:createCsbNode("Shop_Res/Gem/GemBubble/Node_missionBubble_0.csb")
        else
            self:createCsbNode("Shop_Res/Gem/GemBubble/Node_missionBubble.csb")
        end
    elseif self.m_btnType == "BATTLE_PASS" then
    elseif self.m_btnType == "QUEST" then
        self:createCsbNode("Shop_Res/Gem/GemBubble/Node_questBubble.csb")
    end

    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true, nil, 60)
        self:initAutoClose()
    end, 60)
end

function shopOuterBubbleNode:initAutoClose()
    performWithDelay(self, function()
        self:closeUI()
    end, 5)
end

function shopOuterBubbleNode:updateNum(num)
    self:findChild("BitmapFontLabel_3"):setString(num)
end

function shopOuterBubbleNode:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        local view = util_createView("GameModule.Shop.shopOuterSys.shopOuterPopUI", self.m_btnType, self.m_clickCallBack)
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        self:closeUI()
    end
end

function shopOuterBubbleNode:closeUI()
    if self.m_closed then
        return 
    end
    self.m_closed = true
    self:runCsbAction("over", false, nil, 60)
end

return shopOuterBubbleNode