--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-27 15:41:41
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-27 16:49:32
FilePath: /SlotNirvana/src/GameModule/IcebreakerSale/controller/IcebreakerSaleCtrl.lua
Description: 新版 破冰促销 mgr
--]]
local IcebreakerSaleCtrl = class("IcebreakerSaleCtrl", BaseGameControl)
local IcebreakerSaleConfig = util_require("GameModule.IcebreakerSale.config.IcebreakerSaleConfig")
local IcebreakerSaleData = util_require("GameModule.IcebreakerSale.model.IcebreakerSaleData")
local IcebreakerSaleNet = util_require("GameModule.IcebreakerSale.net.IcebreakerSaleNet")

function IcebreakerSaleCtrl:ctor()
    IcebreakerSaleCtrl.super.ctor(self)

    self.m_data = IcebreakerSaleData:create()
    self.m_netObj = IcebreakerSaleNet:getInstance() 
    self:setRefName(G_REF.IcebreakerSale)
end

function IcebreakerSaleCtrl:parseData(_data) 
    self.m_data:parseData(_data)
end
function IcebreakerSaleCtrl:getData()
    return self.m_data
end

-- 显示 主界面
function IcebreakerSaleCtrl:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local layer = gLobalViewManager:getViewByName("IcebreakerSaleMainUI")
    if layer then
        return
    end

    local view = util_createView("GameModule.IcebreakerSale.views.IcebreakerSaleMainUI")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 创建 关卡左边条入口
function IcebreakerSaleCtrl:createMachineEntryView()
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("GameModule.IcebreakerSale.views.IcebreakerSaleEntryNode")
    return view
end

-- 支付
function IcebreakerSaleCtrl:goPurchase()
    local data = self:getData()
    self.m_netObj:goPurchase(data)
end

-- 请求领取 奖励
function IcebreakerSaleCtrl:sendCollectReq()
    local list = self.m_data:checkCanCollectList()
    if #list == 0 then
        return
    end

    local successCB = function(_result)
        if _result["close"] == 1 or _result["close"] == 2 then
            self.m_data:setSaleDataOver(true)
        end 
        self:checkPopRewardLayer(_result)
        gLobalNoticManager:postNotification(IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_COLLECT_SUCCESS)
    end
    local posList = {}
    for i=1, #list do
        table.insert(posList, list[i]:getPosition())
    end 
    self.m_netObj:sendCollectReq(posList, successCB)
end
function IcebreakerSaleCtrl:checkPopRewardLayer(_result)
    if not _result.coins and not _result.items then
    end

    local layer = gLobalViewManager:getViewByName("IcebreakerSaleRewardLayer")
    if layer then
        return
    end

    local view = util_createView("GameModule.IcebreakerSale.views.IcebreakerSaleRewardLayer", _result)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 检查弹出 弹板
-- ● 等级弹出：40级关闭升级领奖弹板后弹出
-- ● 返回大厅：未购买情况，加入返回大厅弹出队列，位置在队列最后，存在弹出cd，具体cd读取配置时间
-- ● 登录大厅：如果用户已购买且存在可领取奖励，在登录大厅队列中弹出，位置在队列最后
function IcebreakerSaleCtrl:checkPopMainUI(_popupType)
    if not _popupType or not self:isCanShowLayer() then
        return
    end

    if _popupType == "Game" then
        return self:showMainLayer()
    elseif _popupType == "Game_Lobby" then
        -- NOVICE_ICE_BROKEN_SALE_GTL_POP_CD
        local bPay = self.m_data:checkHadPay()
        if bPay then
            return
        end
        local lastPopTime = gLobalDataManager:getNumberByField("IceBrokenSaleGTLPopTime", 0)
        local curTime = util_getCurrnetTime()
        if lastPopTime + globalData.constantData.NOVICE_ICE_BROKEN_SALE_GTL_POP_CD < curTime then
            gLobalDataManager:setNumberByField("IceBrokenSaleGTLPopTime", curTime)
            return self:showMainLayer()
        end
    elseif _popupType == "Login_Lobby" then
        local list = self.m_data:checkCanCollectList()
        if #list == 0 then
            return
        end

        return self:showMainLayer()
    end
end

-- 检查是否可显示 轮播展示
function IcebreakerSaleCtrl:checkCanShowHallSlide()
    return self:isCanShowLayer()
end

-- 功能是否开启
function IcebreakerSaleCtrl:isCanShowLayer()
    local bCan = IcebreakerSaleCtrl.super.isCanShowLayer(self)
    if not bCan then
        return false
    end
    local bTimeOut = self:getData():checkTimeOut()
    if bTimeOut then
        self:getData():setSaleDataOver(true)
    end
    return not bTimeOut
end

-- 检查 功能结束
function IcebreakerSaleCtrl:checkTimeOut()
    local bCan = IcebreakerSaleCtrl.super.isCanShowLayer(self)
    if not bCan then
        return
    end

    local bTimeOut = self:getData():checkTimeOut()
    if bTimeOut then
        self:getData():setSaleDataOver(true)
        gLobalNoticManager:postNotification(IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_OVER)
    end
end

return IcebreakerSaleCtrl
