local BrokenSaleCell = util_require("views.sale.BrokenSaleCell",true)
local BrokenSaleLayer = class("BrokenSaleLayer", BaseLayer)

function BrokenSaleLayer:initDatas()
    self._saleData = G_GetActivityDataByRef(ACTIVITY_REF.BrokenSale)


    self:setShownAsPortrait(globalData.slotRunData:isFramePortrait())

    self:setPortraitCsbName("BrokenSale/csd/BrokenSale_shu.csb")
    self:setLandscapeCsbName("BrokenSale/csd/BrokenSale.csb")

    self:setPauseSlotsEnabled(true)

    G_GetMgr(ACTIVITY_REF.BrokenSale):signOpenTime()
end

--刷新UI
function BrokenSaleLayer:refreshUI()
    for i,v in ipairs(self._views) do
        v:refreshUI(self._saleData:getSaleItemByIndex(i))
    end
end

function BrokenSaleLayer:initView()
    self._views = {}
    for i = 1 ,3 do
        local baseNode = self:findChild("node_coin"..i)
        local cellView = util_createView("views.sale.BrokenSaleCell",{
            index = i,
            delegate = self,
        })
        baseNode:addChild(cellView)

        self._views[i] = cellView

        local baseNodeMore = self:findChild("node_more"..i)
        local act
        local nodeMore, act = util_csbCreate("BrokenSale/csd/BrokenSale_more.csb")
        nodeMore:setName("node_more")
        baseNodeMore:addChild(nodeMore)
        util_csbPlayForKey(act, "idle", true, nil, 60)

        local discount = (self._saleData:getSaleItemByIndex(i):getDiscount().."%")
        nodeMore:getChildByName("ef_biaoqian"):getChildByName("lb_shuzi"):setString(discount)
    end

    self:refreshUI()

    self:createSpineLogo()

    util_csbPlayForKey(self.m_csbAct, "idle", true, nil, 60)
end

--创建小人spine
function BrokenSaleLayer:createSpineLogo()
    if not self:findChild("node_spine") then
        return
    end
    local spine = util_spineCreate("BrokenSale/spine/BrokenSale_npc",false,true,1)
    util_spinePlay(spine,"idle",true)
    spine:setPosition(cc.p(-10,-30))
    self:findChild("node_spine"):addChild(spine)
end

function BrokenSaleLayer:registerListener()
    BrokenSaleLayer.super.registerListener(self)

    -- gLobalNoticManager:addObserver(
    --     self,
    --     function()
    --         self:findChild("btn_buy"):setTouchEnabled(true)
    --     end,
    --     ViewEventType.NOTIFY_ACTIVITY_PURCHASING_CLOSE
    -- )
end

function BrokenSaleLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_buy" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        
        sender:setTouchEnabled(false)
        self:buySale()
    elseif name == "btn_close" then
        self:closeLayer()    
    end
end

function BrokenSaleLayer:closeLayer()
    G_DelActivityDataByRef(ACTIVITY_REF.BrokenSale)
    self:closeUI(function()
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
    end)
end

function BrokenSaleLayer:onKeyBack()
    self:closeLayer()
end

function BrokenSaleLayer:onEnter()
    BrokenSaleLayer.super.onEnter(self)
end

return BrokenSaleLayer