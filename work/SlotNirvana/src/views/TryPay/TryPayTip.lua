local TryPayTip = class("TryPayTip", util_require("base.BaseView"))
local ROW_MAX_COUNT = 2

function TryPayTip:initUI(netShopData)
    self:createCsbNode("Shop_Res/shop_tishi1.csb")
    self.m_netShopData = netShopData
    if globalData.slotRunData.isPortrait == true then
        self:setScale(0.7)
        self.m_csbNode:setPositionX(0)
        self:findChild("sp_sanjiao"):setPositionX(-55)
    else
        self:findChild("sp_sanjiao"):setPositionX(-55)
    end
    self:initView()
    self:addMask()
    self:runCsbAction("start")
end

function TryPayTip:initView()
    local itemList = gLobalItemManager:checkAddLocalItemList(self.m_netShopData,self.m_netShopData.p_items)
    local propDataLen = #itemList
    local rowCount =  math.ceil(propDataLen/ROW_MAX_COUNT)
    local height = 94*rowCount
    local width = 600
    if propDataLen == 1 then
        width = 320
    end
    self:findChild("bg"):setContentSize(width,height)
    self.m_rootNode = cc.Node:create()
    self:findChild("buy_tip_1"):addChild(self.m_rootNode)
    local sanjiaoPosX = self:findChild("sp_sanjiao"):getPositionX()
    if propDataLen == 1 then
        if globalData.slotRunData.isPortrait == true then
            self.m_rootNode:setPositionX(500 + 30 )
        else
            self.m_rootNode:setPositionX(250 + 30)
        end

        self:findChild("bg"):setPositionX(-160 + sanjiaoPosX)
    else
        if globalData.slotRunData.isPortrait == true then
            self.m_rootNode:setPositionX(350 + 30 )
        else
            self.m_rootNode:setPositionX(100 + 30)
        end
        self:findChild("bg"):setPositionX(-305+ sanjiaoPosX)
    end

    --加载商品
    for i=1,propDataLen do
        local curRow = math.ceil(i/ROW_MAX_COUNT)
        local curCol = math.mod(i,ROW_MAX_COUNT)
        if curCol == 0 then
            curCol = ROW_MAX_COUNT
        end

        local propData = itemList[i]
        local propNode = gLobalItemManager:createDescNode(propData)
        if propNode ~= nil then
            propNode:setPosition((curCol-ROW_MAX_COUNT/2-1)*300,height - ((curRow * (94/2) ) + ((curRow - 1) * (94/2) )  ) )
            self.m_rootNode:addChild(propNode, i, 1000 + i)
        end
    end

end

function TryPayTip:addMask()
    local mask =  util_newMaskLayer()
    self:addChild(mask,-1)
    mask:setOpacity(0)
    mask:onTouch(function(event)
        if event.name == "ended" then
            self:closeUI()
        end
        return true
    end, false, true)
end

function TryPayTip:onKeyBack()
    self:closeUI()
end

function TryPayTip:setCallFunc(func )
    self.m_func = func
end
function TryPayTip:closeUI()
    if self.isClose then
        return
    end
    self.isClose=true
    if self.m_func then
        self.m_func()
    end
    -- self:runCsbAction("over",false,function()
        self:removeFromParent()
    -- end,60)
end
return TryPayTip