--
-- 袋鼠商店中的页面
--
local SUPER_FREESPIN_DELAY_CLOSEUI = 1.7
local WheelOfRomanceShopPage = class("WheelOfRomanceShopPage", util_require("base.BaseView"))
WheelOfRomanceShopPage.TOY_NAME  = {"Puppy","Bunny","King","Beer"}


WheelOfRomanceShopPage.TOY_NUM = 4 

WheelOfRomanceShopPage.LOCK_LEVEL_1 = 2 
WheelOfRomanceShopPage.LOCK_LEVEL_2 = 4
WheelOfRomanceShopPage.m_cellNum = 9

function WheelOfRomanceShopPage:initUI(pageIndex)
    local resourceFilename = "WheelOfRomance_shop_Page.csb"
    self:createCsbNode(resourceFilename)

    local ToyNode  = self:findChild("Node_Toy")
    self.m_Toy = util_createAnimation("WheelOfRomance_shop_idle_"..self.TOY_NAME[pageIndex]..".csb")
    ToyNode:addChild(self.m_Toy)
    self.m_Toy:runCsbAction("idleframe",true)

    self.m_lock_1 = util_createAnimation("WheelOfRomance_shop_unlock.csb")
    self:findChild("Node_lock_1"):addChild(self.m_lock_1)
    self.m_lock_1:findChild("Wheel_of_Romance_unlock_3"):setVisible(false)

    self.m_lock_2 = util_createAnimation("WheelOfRomance_shop_unlock.csb")
    self:findChild("Node_lock_2"):addChild(self.m_lock_2)
    self.m_lock_2:findChild("Wheel_of_Romance_unlock_2"):setVisible(false)

    util_setCascadeOpacityEnabledRescursion(self, true)

    self:initData(pageIndex)
    self.m_WinCoins = 0
end

function WheelOfRomanceShopPage:onEnter()
end

function WheelOfRomanceShopPage:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
end

-- 数据处理
function WheelOfRomanceShopPage:initData(pageIndex)
    self.m_pageIndex = pageIndex
end

function WheelOfRomanceShopPage:updateLockUI( )

    self.m_lock_1:setVisible(true)
    self.m_lock_2:setVisible(true)

    local level =  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getCellPageLevel( self.m_pageIndex )
    if level >= self.LOCK_LEVEL_1 then
        self.m_lock_1:setVisible(false)
    end

    if level >= self.LOCK_LEVEL_2 then
        self.m_lock_2:setVisible(false)
    end



end

function WheelOfRomanceShopPage:initToyUi( )


    self:hideAllToyUi( )
    local level =  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getCellPageLevel( self.m_pageIndex )
    self.m_Toy:findChild("Wheel_of_Romance_Toy_"..level):setVisible(true)
   
end



function WheelOfRomanceShopPage:showAllToyUi( )
    for i = 1,self.TOY_NUM do
        self.m_Toy:findChild("Wheel_of_Romance_Toy_"..i):setVisible(true)
    end
end

function WheelOfRomanceShopPage:hideAllToyUi( )
    for i = 1,self.TOY_NUM do
        self.m_Toy:findChild("Wheel_of_Romance_Toy_"..i):setVisible(false)
    end
end

function WheelOfRomanceShopPage:initPageCellView()
    for i = 1, self.m_cellNum do
        self:updatePageCell(i)
    end
end

function WheelOfRomanceShopPage:getPageCellName(_pageIndex,_cellIndex )
    return _pageIndex * 10 + _cellIndex
end

function WheelOfRomanceShopPage:createOldAniItem( _cellIndex )

    local needPoins = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageNeedPoints( self.m_pageIndex )

    local states = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_IDLE
    local node = self:findChild("kuang" .. _cellIndex)
    local view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageItemIdle", self.m_pageIndex, _cellIndex,states)
    view:updateUI(needPoins)
    node:addChild(view , 10)

    return view
end

function WheelOfRomanceShopPage:createOldPageCell(cellIndex,pageCellStatus )

    local needPoins = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getRequestPageNeedPoints( self.m_pageIndex )

    local node = self:findChild("kuang" .. cellIndex)
    local child = node:getChildByName(self:getPageCellName(self.m_pageIndex,cellIndex ))
    local view

    if pageCellStatus == globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_LOCK then
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageItemLock", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    elseif pageCellStatus ==  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_IDLE then

        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageItemIdle", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI(needPoins)

    elseif pageCellStatus ==  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_PORTRAIT_WHEEL then
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPagePortraitWheel", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    elseif pageCellStatus ==  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_CIRCULAR_WHEEL then
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageCircularWheel", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    else
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageCoin", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    end

    view:setName(self:getPageCellName(self.m_pageIndex,cellIndex ))
    
    node:removeAllChildren()
    node:addChild(view)

    return view
end

function WheelOfRomanceShopPage:getAllPageCellNdoe( _CellStatus )
    local nodeList = {}
    for cellIndex=1,self.m_cellNum do
        local node = self:findChild("kuang" .. cellIndex)
        local child = node:getChildByName(self:getPageCellName(self.m_pageIndex,cellIndex ))
        table.insert(nodeList,child)
    end
    
    return nodeList
end

function WheelOfRomanceShopPage:updatePageCell(cellIndex)

    local needPoins = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getPageNeedPoints( self.m_pageIndex )
    local pageCellStatus = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getPageCellState(self.m_pageIndex, cellIndex)
    local CellDarkStaetes = globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA:getCellDarkStaetes(self.m_pageIndex )
    local node = self:findChild("kuang" .. cellIndex)
    local child = node:getChildByName(self:getPageCellName(self.m_pageIndex,cellIndex ))
    local view

    if pageCellStatus ==  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_LOCK then
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageItemLock", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    elseif pageCellStatus == globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_IDLE then
        if CellDarkStaetes then
            local states =  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_DARK
            view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageItemDark", self.m_pageIndex, cellIndex,states)
            view:updateUI()
        else
            
            view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageItemIdle", self.m_pageIndex, cellIndex,pageCellStatus)
            view:updateUI(needPoins)
        end
        
    elseif pageCellStatus ==  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_PORTRAIT_WHEEL then
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPagePortraitWheel", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    elseif pageCellStatus ==  globalData.slotRunData.WHEELOFROMANCE_SHOP_RESULT_DATA.ITEM_TYPE_CIRCULAR_WHEEL then
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageCircularWheel", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    else
        view = util_createView("CodeWheelOfRomanceSrc.ShopView.WheelOfRomanceShopPageCoin", self.m_pageIndex, cellIndex,pageCellStatus)
        view:updateUI()
    end

    view:setName(self:getPageCellName(self.m_pageIndex,cellIndex ))
    node:removeAllChildren()
    node:addChild(view)

    return view

end



return WheelOfRomanceShopPage
