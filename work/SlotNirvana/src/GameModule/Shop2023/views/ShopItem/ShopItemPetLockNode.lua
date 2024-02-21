local ShopItemPetLockNode = class("ShopItemPetLockNode", util_require("base.BaseView"))

function ShopItemPetLockNode:initUI()
    self:createCsbNode(self:getCsbName())
    self:initView()
end

function ShopItemPetLockNode:initView(_itemData)
end

-- 子类重写
function ShopItemPetLockNode:getCsbName()
    local res = SHOP_RES_PATH.ItemPetCell_LOCK
    if globalData.slotRunData.isPortrait == true then
        res = SHOP_RES_PATH.ItemPetCell_LOCK_Vertical
    end 
    return res
end

function ShopItemPetLockNode:initCsbNodes()

end

function ShopItemPetLockNode:doShowOrHide()
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

function ShopItemPetLockNode:getIsPet()
    if self.m_canDoHide then
        self:doHide()
    end
end

function ShopItemPetLockNode:doHide()
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

function ShopItemPetLockNode:doShow()
    self.m_isShowing = true
    self.m_doingAct = true
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
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
                2
            )
        end
    )
end


return ShopItemPetLockNode
