--[[
    新版商城下UI 按钮模块
]]
local ShopRapidLeftPositionBtnNode = require "GameModule.Shop2023.views.ShopRapidLeftPositionBtnNode"
local ShopRapidPositionBtnNode = class("ShopRapidPositionBtnNode", ShopRapidLeftPositionBtnNode)


function ShopRapidLeftPositionBtnNode:initUI(isPortrait,isLeft)
    self.m_isPortrait = isPortrait or false

    self:createCsbNode(self:getCsbName())

    if not isLeft and not isPortrait then
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
    self.m_sp_petLock = self:findChild("Sprite_2")

    self:addClick(self.m_btnHot)
    self:addClick(self.m_btnCoin)
    self:addClick(self.m_btnGem)
    self:addClick(self.m_btnPet)

    self:updateView()
end

function ShopRapidPositionBtnNode:getCsbName()
    if self.m_isPortrait then
        return SHOP_RES_PATH.RapidPositionBtn_Vertical
    else
        return SHOP_RES_PATH.RapidPositionBtn
    end
end

return ShopRapidPositionBtnNode
