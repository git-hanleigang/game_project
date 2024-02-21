--[[
    新版商城 道具说明页滑动cell
]]
local ShopItemBenefitBoardCellNode = class("ShopItemBenefitBoardCellNode", util_require("base.BaseView"))
function ShopItemBenefitBoardCellNode:initUI()
    self:createCsbNode(SHOP_RES_PATH.ItemBenefitBoardCell)
end

function ShopItemBenefitBoardCellNode:initCsbNodes()
    -- 界面上的点
    self.m_nodeBenefit = {}
    for i = 1,2 do
        local node = self:findChild("node_benefit"..i)
        table.insert(self.m_nodeBenefit,node)
    end
end


function ShopItemBenefitBoardCellNode:updateView(_itemData)
    for i = 1 ,#self.m_nodeBenefit do
        local btnefitNode = self.m_nodeBenefit[i]
        local itemData = _itemData[i]
        if itemData then
            itemData = G_GetMgr(G_REF.Shop):getDescShopItemData(itemData)
            local propNode = gLobalItemManager:createDescShopBenefitNode(itemData,ITEM_SIZE_TYPE.REWARD)
            if propNode then
                gLobalItemManager:setItemNodeByExtraData(itemData,propNode)
                btnefitNode:addChild(propNode)
                propNode:setIconTouchSwallowed(false)
            end
        end
    end
end

return ShopItemBenefitBoardCellNode
