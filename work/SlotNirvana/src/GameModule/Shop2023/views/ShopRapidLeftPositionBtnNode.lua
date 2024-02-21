--[[
    新版商城下UI 按钮模块
]]
local  touch_nomal_pos_x = 73.33
local  touch_special_pos_x = 43.33

local ShopRapidLeftPositionBtnNode = class("ShopRapidLeftPositionBtnNode", util_require("base.BaseView"))
function ShopRapidLeftPositionBtnNode:initUI(isPortrait,isLeft)
    self.m_isPortrait = isPortrait 
    self.m_isLeft = isLeft 

    self:createCsbNode(self:getCsbName())

    if isLeft and isPortrait then
        return
    end

    -- 遮罩层
    self.m_panel = self:findChild("Panel_1")
    self.m_panel:setSwallowTouches(true)
    self:addClick(self.m_panel)

    -- 读取csb 节点
    self.m_nodePass = self:findChild("Node_titlePass")
    self.m_nodeNoPass = self:findChild("Node_titleNoPass")

    self.m_sprNormalHot = self:findChild("sp_offNormal")
    self.m_sprClickHot= self:findChild("sp_offerClick")

    self.m_nodeCoin = self:findChild("node_coin")
    self.m_sprNormalCoin = self:findChild("sp_coinNormal")
    self.m_sprClickCoin = self:findChild("sp_coinClick")

    self.m_sprNormalGem = self:findChild("sp_gemNormal")
    self.m_sprClickGem = self:findChild("sp_gemClick")

    self.m_sprNormalPet = self:findChild("sp_petNormal")
    self.m_sprClickPet = self:findChild("sp_petClick")

    self.m_nodePanel = self:findChild("panel_size")

    self.m_btnHot = self:findChild("btn_offer")
    self.m_btnCoin = self:findChild("btn_coin")
    self.m_btnGem = self:findChild("btn_gem")
    self.m_btnPet = self:findChild("btn_pet")
    self.m_sp_petLock = self:findChild("sp_pets1_lock")

    self:addClick(self.m_btnHot)
    self:addClick(self.m_btnCoin)
    self:addClick(self.m_btnGem)
    self:addClick(self.m_btnPet)
    self:runCsbAction("idle2",true)
    self:updateView()
end

function ShopRapidLeftPositionBtnNode:getUpCoinNode()
    return self.m_nodeCoin
end

function ShopRapidLeftPositionBtnNode:getCsbName()
    if self.m_isPortrait then
        return SHOP_RES_PATH.RapidLeftPositionBtn_Vertical
    else
        return SHOP_RES_PATH.RapidLeftPositionBtn
    end
end

function ShopRapidLeftPositionBtnNode:updateView()
    -- 初始化状态
    self:updateBtnStatus(SHOP_VIEW_TYPE.COIN)
    if self.m_sp_petLock then
        self.m_sp_petLock:setVisible(not G_GetMgr(G_REF.Sidekicks):isRunning())
    end
end

function ShopRapidLeftPositionBtnNode:updateBtnStatus(_type)
    if _type == self.m_type then
        return
    end
    if not self.m_isPortrait and not self.m_isLeft then
        return
    end
    self.m_type = _type

    self.m_sprClickCoin:setVisible( _type == SHOP_VIEW_TYPE.COIN)
    self.m_btnCoin:setVisible( not (_type == SHOP_VIEW_TYPE.COIN))
    self.m_btnCoin:setTouchEnabled( not (_type == SHOP_VIEW_TYPE.COIN))
    if not self.m_isPortrait then
        self.m_btnCoin:setPositionX( (_type == SHOP_VIEW_TYPE.COIN) and touch_nomal_pos_x or touch_special_pos_x)
    end

    self.m_sprClickGem:setVisible( _type == SHOP_VIEW_TYPE.GEMS)
    self.m_btnGem:setVisible(not (_type == SHOP_VIEW_TYPE.GEMS))
    self.m_btnGem:setTouchEnabled(not (_type == SHOP_VIEW_TYPE.GEMS))
    if not self.m_isPortrait then
        self.m_btnGem:setPositionX( (_type == SHOP_VIEW_TYPE.GEMS) and touch_nomal_pos_x or touch_special_pos_x)
    end
  
    
    self.m_sprClickHot:setVisible( _type == SHOP_VIEW_TYPE.HOT)
    self.m_btnHot:setVisible(not (_type == SHOP_VIEW_TYPE.HOT))
    self.m_btnHot:setTouchEnabled(not (_type == SHOP_VIEW_TYPE.HOT))
    if not self.m_isPortrait then
        self.m_btnHot:setPositionX( (_type == SHOP_VIEW_TYPE.HOT) and touch_nomal_pos_x or touch_special_pos_x)
    end

    self.m_sprClickPet:setVisible( _type == SHOP_VIEW_TYPE.PET)
    self.m_btnPet:setVisible(not (_type == SHOP_VIEW_TYPE.PET))
    self.m_btnPet:setTouchEnabled(not (_type == SHOP_VIEW_TYPE.PET))
    if not self.m_isPortrait then
        self.m_btnPet:setPositionX( (_type == SHOP_VIEW_TYPE.PET) and touch_nomal_pos_x or touch_special_pos_x)
    end

    self:runCsbAction("start",false)
end

function ShopRapidLeftPositionBtnNode:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_coin" then
        self:showLock()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWSHOP_JUMPTOVIEW, {type = SHOP_VIEW_TYPE.COIN, active = true})
        self:updateBtnStatus(SHOP_VIEW_TYPE.COIN)
    elseif name == "btn_gem" then
        self:showLock()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWSHOP_JUMPTOVIEW, {type = SHOP_VIEW_TYPE.GEMS, active = true})
        self:updateBtnStatus(SHOP_VIEW_TYPE.GEMS)
    elseif name == "btn_offer" then
        self:showLock()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWSHOP_JUMPTOVIEW, {type = SHOP_VIEW_TYPE.HOT, active = true})
        self:updateBtnStatus(SHOP_VIEW_TYPE.HOT)
    elseif name == "btn_pet" then
        if G_GetMgr(G_REF.Sidekicks):isRunning() then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWSHOP_JUMPTOVIEW, {type = SHOP_VIEW_TYPE.PET, active = true})
            self:updateBtnStatus(SHOP_VIEW_TYPE.PET)
        else
            if not self.m_petLock then
                self.m_petLock = util_createView(SHOP_CODE_PATH.ItemPetLockNode)
                self:findChild("node_pet"):addChild(self.m_petLock)
            end
            self.m_petLock:doShowOrHide()
        end
    end
end

function ShopRapidLeftPositionBtnNode:showLock()
    if self.m_petLock then
        self.m_petLock:getIsPet()
    end
end

function ShopRapidLeftPositionBtnNode:getPanelSize()
    if self.m_nodePanel then
        return self.m_nodePanel:getContentSize()
    end
    return {width = 0, height = 200}
end

return ShopRapidLeftPositionBtnNode
