local ZQCoinStoreTipNew = class("ZQCoinStoreTipNew", util_require("base.BaseView"))
local ROW_MAX_COUNT = 3
ZQCoinStoreTipNew.m_shopType = nil

function ZQCoinStoreTipNew:initUI(netShopData,index,shopItemSize, shopItemPos, storeType)
    self.m_netShopData = netShopData
    self.m_isUp = false
    self.m_storeType = storeType

    self:createCsbNode("Shop_Res/ShopBenefits.csb")
 
    if globalData.slotRunData.isPortrait == true then
        local sale = 0.7
        local offX = 0
        self:setScale(sale)
        self.m_csbNode:setPositionX(0)
    end

    self:initView()
    self:addMask()
    self:runCsbAction("start")
    self:setTipPosition(index , shopItemSize, shopItemPos)
end

function ZQCoinStoreTipNew:setTipPosition(index, shopItemSize, shopItemPos)
    local sizeSelf = self:findChild("bg"):getContentSize()
    local posY = sizeSelf.height/ 2 + shopItemSize.height / 2
    if globalData.slotRunData.isPortrait == true then
        posY = index > 3 and -posY or posY - 20
    else
        posY = index > 3 and -posY -20 or posY
    end

    self:setPositionY(shopItemPos.y + posY)
end

function ZQCoinStoreTipNew:getExtraPropList(netShopData)
    if not netShopData then
        return nil
    end
    if netShopData.getExtraPropList ~= nil then
        return netShopData:getExtraPropList()
    end
    local ret = {}
    local itemList = nil
    if netShopData.p_displayList and #netShopData.p_displayList >= 0 then
        --适配老版本
        itemList = netShopData.p_displayList
    elseif netShopData.p_items and #netShopData.p_items >= 0 then
        --适配道具
        itemList = netShopData.p_items
    end
    if itemList and #itemList >= 0 then
        for i=1,#itemList do
            local shopItemData = itemList[i]
            if shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_COIN and shopItemData.p_item ~= ITEMTYPE.ITEMTYPE_SENDCOUPON then
                ret[#ret+1] = shopItemData
            end
        end
    end
    return ret
end

function ZQCoinStoreTipNew:initView()
    local extraPropList = self:getExtraPropList(self.m_netShopData)
    if extraPropList == nil or #extraPropList <= 0 then
        return
    end

    local tipSource = nil
    if self.m_storeType == "COIN" then
        tipSource = "CoinStoreTip"
    elseif self.m_storeType == "GEM" then
        tipSource = "GemStoreTip"
    end
    --获得根据支付金额生成赠送的集卡道具
    local cardItemData = gLobalItemManager:createCardDataForIap(self.m_netShopData.p_keyId, nil, tipSource)
    if cardItemData then    
        table.insert(extraPropList,1,cardItemData)
    end

    --添加通用
    if globalData.saleRunData.checkAddCommonBuyItemTips then
        globalData.saleRunData:checkAddCommonBuyItemTips(extraPropList, tipSource)
    end

    local propDataLen = #extraPropList
    local rowCount =  math.ceil(propDataLen/ROW_MAX_COUNT)
    local diff = 20      --上下补偿的高度

    local getHeight = function(count )
        return  70*count + diff * 2
    end
    
    local height = getHeight(rowCount)
    local width = 960
    if propDataLen < 3 then
        width = (960/3) * propDataLen
    end

    self:findChild("bg"):setContentSize(width,height)
    self.m_rootNode = cc.Node:create()
    self:findChild("buy_tip_1"):addChild(self.m_rootNode)
    local addHeight = 10
    local reduceHeight = - (height - getHeight(1)) / 2
    local beginHeight  = reduceHeight + addHeight

    -- if propDataLen == 1 then
    --     if globalData.slotRunData.isPortrait == true then

    --         if self.m_Boost then
    --             self.m_rootNode:setPositionX(150)
    --         else
    --             self.m_rootNode:setPositionX(500 + 30 )
    --         end

    --     else
    --         self.m_rootNode:setPositionX(250 + 30)
    --     end

    --  elseif propDataLen == 2 then
    --     if globalData.slotRunData.isPortrait == true then
    --         if self.m_Boost then

    --         else
    --             self.m_rootNode:setPositionX(350 + 30 )
    --         end

    --     else
    --         self.m_rootNode:setPositionX(100 + 30)
    --     end
    -- else
    --     if self.m_Boost  then
    --         if globalData.slotRunData.isPortrait == true then
    --             self.m_rootNode:setPositionX(-90)
    --             self:findChild("bg"):setPositionX(-600)
    --         else
    --             self.m_rootNode:setPositionX(130)
    --             self:findChild("bg"):setPositionX(-380)
    --         end

    --     else
    --         self.m_rootNode:setPositionX(30)
    --         self:findChild("bg"):setPositionX(-480)
    --     end

    -- end

    --加载商品
    for i=propDataLen, 1 , -1 do
        local curRow = rowCount -  math.ceil(i/ROW_MAX_COUNT) + 1
        local curCol = math.mod(i,ROW_MAX_COUNT)
        if curCol == 0 then
            curCol = ROW_MAX_COUNT
        end

        local propData = extraPropList[i]
        local propNode = gLobalItemManager:createDescNode(propData)
        if propNode ~= nil then
            -- if self.m_isUp then
            --     propNode:setPosition((curCol-ROW_MAX_COUNT/2-0.5)*300,height - ((curRow * (70/2) ) + ((curRow - 1) * (70/2))) -diff - 2 )
            -- else
                propNode:setPosition((curCol-ROW_MAX_COUNT/2-0.3)*300,beginHeight + (curRow - 1) * 70 )
            -- end

            self.m_rootNode:addChild(propNode, i, 1000 + i)
        end
    end
    local btnClose = self:findChild("btn_close")
    btnClose:setPositionY((height - getHeight(1)) / 2 +getHeight(1)/ 2 -10)

end

function ZQCoinStoreTipNew:addMask()
    local mask =  util_newMaskLayer()
    self:addChild(mask,-1)
    mask:setOpacity(0)
    mask:onTouch(function(event)
        if event.name == "ended" then
            if  self.m_shopType ==  GD.SHOP_BOOSTER.SHOP then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SHOPINFO_POS, {cc.p(event.x,event.y)})
            else
                self:closeUI()
            end
        end
        return true
    end, false, true)
end

function ZQCoinStoreTipNew:onKeyBack()
    self:closeUI()
end

function ZQCoinStoreTipNew:setCallFunc(func )
    self.m_func = func
end

function ZQCoinStoreTipNew:clickFunc(sender)
    if self.isClose then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:closeUI()
    end
end

function ZQCoinStoreTipNew:closeUI()
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

function ZQCoinStoreTipNew:onEnter()
    gLobalNoticManager:addObserver(self,function(params)
        if self.closeUI then
            self:closeUI() 
        end
    end ,ViewEventType.NOTIFY_SHOPINFO_CLOSE)
end

function ZQCoinStoreTipNew:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return ZQCoinStoreTipNew