
local DailyMissionPassCell = class("DailyMissionPassCell", util_require("base.BaseView"))
function DailyMissionPassCell:initUI()
    self:createCsbNode(SHOP_RES_PATH.ItemBenefitBoardCell)
end

function DailyMissionPassCell:initCsbNodes()
    -- 界面上的点
    self.m_nodeBenefit = {}
    for i = 1,2 do
        local node = self:findChild("node_benefit"..i)
        table.insert(self.m_nodeBenefit,node)
    end
end


function DailyMissionPassCell:updateView(_itemData)
    for i = 1 ,#self.m_nodeBenefit do
        local btnefitNode = self.m_nodeBenefit[i]
        local itemData = _itemData[i]
        if itemData then
            local propNode = gLobalItemManager:createDescShopBenefitNode(itemData,ITEM_SIZE_TYPE.REWARD)
            btnefitNode:addChild(propNode)
        end
    end
end

return DailyMissionPassCell
