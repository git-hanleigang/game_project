local ShopItemPetInfoNode = class("ShopItemPetInfoNode", util_require("base.BaseView"))

function ShopItemPetInfoNode:initUI()
    self:createCsbNode(self:getCsbName())
    self:initView()
end

function ShopItemPetInfoNode:initView(_itemData)
    if globalData.slotRunData.isPortrait == true then
        self:findChild("Sprite_2"):setPositionX(100)
        self:findChild("Text_1"):setPositionX(100)
    end
end

-- 子类重写
function ShopItemPetInfoNode:getCsbName()
    return SHOP_RES_PATH.ItemPetCell_Info
end

function ShopItemPetInfoNode:initCsbNodes()

end
function ShopItemPetInfoNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag() 
    if self.m_doingAct then
        return
    end
    if name == "Button_1" then
        self:doShowOrHide()
    end
end

function ShopItemPetInfoNode:doShowOrHide()
    if self.m_doingAct then
        return
    end
    if not self.m_isShowing then
        self:doShow()
    else
        if self.m_canDoHide then
            self:doHide()
        end
    end
end

function ShopItemPetInfoNode:doHide()
    self.m_canDoHide = false
    self.m_doingAct = true
    self:stopAllActions()
    self:runCsbAction(
        "over",
        false,
        function()
            self.m_isShowing = false
            self.m_doingAct = false
        end
    )
end

function ShopItemPetInfoNode:doShow()
    self.m_isShowing = true
    self.m_doingAct = true
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_doingAct = false 
            self.m_canDoHide = true
            performWithDelay(
                self,
                function()
                    if self.m_canDoHide then
                        self:doHide()
                    end
                end,
                4
            )
        end
    )
end


return ShopItemPetInfoNode
