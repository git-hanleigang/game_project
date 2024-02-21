--[[
    @desc: 新版商城 itemCell 上的icon图标
    author:csc
    time:2021-12-24
    --@_type: 类型
	--@_index: 下标
]]
local BaseView = util_require("base.BaseView")
local ShopItemIconNode = class("ShopItemIconNode", BaseView)

function ShopItemIconNode:initUI(_type,_index)

    local csbName = SHOP_RES_PATH.ItemIcon_Coin.._index..".csb"
    if _type == SHOP_VIEW_TYPE.GEMS then
        csbName = SHOP_RES_PATH.ItemIcon_Gems.._index..".csb"
    elseif _type == SHOP_VIEW_TYPE.HOT then
        csbName = SHOP_RES_PATH.ItemIcon_Hot.._index..".csb"
    elseif _type == SHOP_VIEW_TYPE.PET then
        csbName = SHOP_RES_PATH.ItemIcon_Pet.._index..".csb"
    end 
    self:createCsbNode(csbName)

    self:runCsbAction("idle",true,false,60)
    self.m_doAction = true
end

function ShopItemIconNode:stopAction()
    self.m_doAction = false
    self:stopAllActions()
end

function ShopItemIconNode:runAction()
    if self.m_doAction then
        return
    end
    self.m_doAction = true
    self:runCsbAction("idle",true,false,60)
end

return ShopItemIconNode