--[[
]]
util_require("GameModule.ShopBuck.config.ShopBuckConfig")

local ShopBuckGuideMgr = util_require("GameModule.ShopBuck.controller.ShopBuckGuideMgr")
local BaseGameControl = util_require("GameBase.BaseGameControl")
local ShopBuckMgr = class("ShopBuckMgr", BaseGameControl)

function ShopBuckMgr:ctor()
    ShopBuckMgr.super.ctor(self)
    self:setRefName(G_REF.ShopBuck)
    self:setResInApp(true)
    self:setDataModule("GameModule.ShopBuck.model.ShopBuckData")

    self.m_guideMgr = ShopBuckGuideMgr:getInstance()
end

function ShopBuckMgr:getBuckNum()
    local data = self:getRunningData()
    if data then
        local bucks = data:getBucks()
        return bucks
    end
    return 0
end

-- 是否能用代币购买
-- G_GetMgr(G_REF.ShopBuck):canBuyByBuck(_buyType, _buyPrice)
function ShopBuckMgr:canBuyByBuck(_buyType, _buyPrice)
    if ShopBuckConfig and ShopBuckConfig.SWITCH and ShopBuckConfig.BUCK_BUY_TYPE[_buyType] then
        local data = self:getRunningData()
        if data and data:isBuckEnough(_buyPrice) then
            return true
        end
    end
    return false
end

function ShopBuckMgr:isCommontBtnBuckVisible(_buyType)
    if ShopBuckConfig and ShopBuckConfig.SWITCH and ShopBuckConfig.BUCK_BUY_TYPE[_buyType] then
        return true
    end
    return false
end

function ShopBuckMgr:createBuckTopNode()
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("GameModule.ShopBuck.views.ShopBuckTopNode")
    return view
end

function ShopBuckMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("ShopBuckMainLayer") ~= nil then
        return
    end
    local view = util_createView("GameModule.ShopBuck.views.ShopBuckMainLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function ShopBuckMgr:showConfirmLayer(_price, _buck, _clickYes, _clickNo, _clickCancel)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("ShopBuckConfirmLayer") ~= nil then
        return
    end
    local view = util_createView("GameModule.ShopBuck.views.ShopBuckConfirmLayer", _price, _buck, _clickYes, _clickNo, _clickCancel)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function ShopBuckMgr:showInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("ShopBuckConfirmInfoLayer") ~= nil then
        return
    end
    local view = util_createView("GameModule.ShopBuck.views.ShopBuckConfirmInfoLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function ShopBuckMgr:showConfirmInfoLayer()
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("ShopBuckInfoLayer") ~= nil then
        return
    end
    local view = util_createView("GameModule.ShopBuck.views.ShopBuckInfoLayer")
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end




function ShopBuckMgr:showRewardLayer(_buck)
    if not self:isCanShowLayer() then
        return
    end
    if self:getLayerByName("ShopBuckRewardLayer") ~= nil then
        return
    end
    local view = util_createView("GameModule.ShopBuck.views.ShopBuckRewardLayer", _buck)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- -- 订单id todo
-- function ShopBuckMgr:createBuckOrderId()
--     local orderId = "BUCK:"
--     orderId = orderId .. tostring(globalData.userRunData.uid)
--     orderId = orderId .. tostring(os.time())
--     orderId = orderId .. tostring(math.random(100, 999))
--     return orderId
-- end

--创建本次购买唯一标识
function ShopBuckMgr:createBuckOrderId()
    local randomTag = xcyy.SlotsUtil:getMilliSeconds()
    local platform = device.platform
    local id = "BUCK"
    -- if platform == "ios" then
    --     id = id .. "_" .. globalPlatformManager:getIDFV() or "PlatfromID"
    -- else
    --     id = id .. "_" .. globalPlatformManager:getAndroidID() or "PlatfromID"
    -- end
    id = id .. "_" .. tostring(globalData.userRunData.uid)
    id = id .. "_" .. math.floor(randomTag/1000)
    id = id .. "_" .. tostring(math.random(100, 999))
    return id
end

function ShopBuckMgr:useBuckToBuy(_orderId, _buyType, _extra, _price, funS, funF)
    G_GetNetModel(NetType.ShopBuck):useBuckToBuy(_orderId, _buyType, _extra, _price, funS, funF)
end

--[[
    @desc: 引导
    author:{author}
    time:2023-12-13 10:38:05
    @return:
]]
function ShopBuckMgr:getGuideMgr()
    return self.m_guideMgr
end

function ShopBuckMgr:triggerGuide(view, name)
    if tolua.isnull(view) or not name then
        return false
    end
    return self.m_guideMgr:triggerGuide(view, name, G_REF.Shop)
end

return ShopBuckMgr