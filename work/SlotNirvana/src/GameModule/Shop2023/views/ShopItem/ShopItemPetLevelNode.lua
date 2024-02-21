local ShopItemPetLevelNode = class("ShopItemPetLevelNode", util_require("base.BaseView"))

function ShopItemPetLevelNode:initUI()
    self:createCsbNode(self:getCsbName())
    self:initView()
end

function ShopItemPetLevelNode:initView()
    local petData = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if not petData then
        return
    end
    local curHonorLv = petData:getHonorLv()
    local iconPath = "Sidekicks_Common/rank_icon/rank_icon_" .. curHonorLv .. ".png"
    local namePath = "Sidekicks_Common/rank_name/rank_name_" .. curHonorLv .. ".png"
    local spIcon = util_createSprite(iconPath)
    spIcon:setAnchorPoint(0.5,0.5)
    spIcon:setPositionY(-3)
    spIcon:setScale(0.18)
    self:findChild("Node_logo"):addChild(spIcon)

    local spName = util_createSprite(namePath)
    spName:setScale(0.5)
    spName:setAnchorPoint(0.5,0.5)
    self:findChild("Node_name"):addChild(spName)
end

-- 子类重写
function ShopItemPetLevelNode:getCsbName()
    return SHOP_RES_PATH.ItemPetCell_Level
end

function ShopItemPetLevelNode:initCsbNodes()

end

return ShopItemPetLevelNode
