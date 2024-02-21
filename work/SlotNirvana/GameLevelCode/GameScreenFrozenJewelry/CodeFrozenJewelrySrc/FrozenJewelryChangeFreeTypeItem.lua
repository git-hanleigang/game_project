---
--xcyy
--2018年5月23日
--FrozenJewelryChangeFreeTypeItem.lua

local FrozenJewelryChangeFreeTypeItem = class("FrozenJewelryChangeFreeTypeItem",util_require("Levels.BaseLevelDialog"))

local BTN_TAG_TIP       =       1001
local BTN_TAG_CHANGE    =       1002

function FrozenJewelryChangeFreeTypeItem:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("FrozenJewelry_Free_Button.csb")

    self.m_isAutoShow = false

    self:findChild("Button_balance"):setTag(BTN_TAG_CHANGE)
    self:findChild("Button_tips"):setTag(BTN_TAG_TIP)

    self.m_tip = util_createAnimation("FrozenJewelry_Free_Button_Tips.csb")
    self:findChild("Node_tips"):addChild(self.m_tip)
    self.m_tip:setVisible(false)

    self.m_node_wait = cc.Node:create()
    self:addChild(self.m_node_wait)
end


--默认按钮监听回调
function FrozenJewelryChangeFreeTypeItem:clickFunc(sender)
    local tag = sender:getTag()
    if tag == BTN_TAG_CHANGE then
        self.m_machine:clickChangeFreeType()
    else
        if self.m_isWaiting then
            return
        end
        
        self.m_isWaiting = true
        if self.m_tip:isVisible() then
            self:hideTip()
        else
            self:showTip()
        end
    end
end

function FrozenJewelryChangeFreeTypeItem:showTip()
    self.m_tip:setVisible(true)
    self.m_tip:runCsbAction("start")
    performWithDelay(self.m_tip,function()
        self.m_isWaiting = false
    end,30 / 60)

    self.m_node_wait:stopAllActions()
    performWithDelay(self.m_node_wait,function()
        if self.m_tip:isVisible() then
            self:clickFunc(self:findChild("Button_tips"))
        end
    end,4)
end

function FrozenJewelryChangeFreeTypeItem:hideTip()
    self.m_tip:stopAllActions()
    self.m_node_wait:stopAllActions()
    self.m_tip:runCsbAction("over",false,function()
        self.m_isWaiting = false
        self.m_tip:setVisible(false)
    end)
end

function FrozenJewelryChangeFreeTypeItem:showItem()
    self:setVisible(true)
    
end

function FrozenJewelryChangeFreeTypeItem:autoShowTip()
    if not self.m_tip:isVisible() and not self.m_isAutoShow then
        self.m_isAutoShow = true
        self:clickFunc(self:findChild("Button_tips"))
    end
end

function FrozenJewelryChangeFreeTypeItem:hideItem()
    self:setVisible(false)
    self.m_isAutoShow = false
    self:hideTip()
end

return FrozenJewelryChangeFreeTypeItem