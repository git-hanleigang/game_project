--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local BaseView = util_require("base.BaseView")
local CardAlbumCell = class("CardAlbumCell", BaseView)

-- 初始化UI --
function CardAlbumCell:initUI()
    self:createCsbNode(CardResConfig.CardAlbumCell2020Res)
    self:initNode()
end

function CardAlbumCell:initNode()
    -- 初始化node节点
    self.m_wildLayer = self:findChild("layer_wild")
    self.m_normalLayer = self:findChild("layer_normal")
end

function CardAlbumCell:updateCell(cellIndex, startClanIndex, cellType, cellDataList)
    self.m_cellIndex = cellIndex
    self.m_startClanIndex = startClanIndex
    self.m_cellType = cellType
    self.m_cellDataList = cellDataList

    if self.m_cellType == "WILD" then
        self.m_wildLayer:setVisible(true)
        self.m_normalLayer:setVisible(false)
        self:updateWildEffect()
        self:updateWildCell()

    elseif self.m_cellType == "NORMAL" then
        self.m_wildLayer:setVisible(false)
        self.m_normalLayer:setVisible(true)        
        self:updateNormalCell()

    end
end

function CardAlbumCell:updateWildEffect()
    self.m_wildEffectNode = self.m_wildLayer:getChildByName("Node_effect")
    local flyEffect = self.m_wildEffectNode:getChildByName("FlyCard")
    if flyEffect == nil then
        flyEffect = util_createView("GameModule.Card.season201902.CardAlbumCellWildEffect")
        flyEffect:setName("FlyCard")
        self.m_wildEffectNode:addChild(flyEffect)
    end
end

function CardAlbumCell:updateWildCell()
    -- 3列
    for i=1,3 do
        local unitParent = self.m_wildLayer:getChildByName("Node_"..i)
        local unitNode = unitParent:getChildByName("Unit")
        if not unitNode then
            unitNode = util_createView("GameModule.Card.season201902.CardAlbumCellUnitWild")
            unitParent:addChild(unitNode)
            unitNode:setName("Unit")
        end
        local clanIndex = self.m_startClanIndex + i
        local cellData = self.m_cellDataList[i]
        unitNode:updateCell(clanIndex, cellData)
    end
end


function CardAlbumCell:updateNormalCell()
    -- 4列
    for i=1,4 do
        local unitParent = self.m_normalLayer:getChildByName("Node_"..i)
        local unitNode = unitParent:getChildByName("Unit")
        if not unitNode then
            unitNode = util_createView("GameModule.Card.season201902.CardAlbumCellUnitNormal")
            unitParent:addChild(unitNode)
            unitNode:setName("Unit")            
        end
        local clanIndex = self.m_startClanIndex + i
        local cellData = self.m_cellDataList[i]        
        unitNode:updateCell(clanIndex, cellData)
    end
end

return CardAlbumCell