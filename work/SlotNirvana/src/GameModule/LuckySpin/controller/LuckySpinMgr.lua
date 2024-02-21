--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-05 11:58:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-05 12:09:32
FilePath: /SlotNirvana/src/GameModule/LuckySpin/controller/LuckySpinMgr.lua
Description: LuckySpin mgr
--]]
local LuckySpinMgr = class("LuckySpinMgr", BaseGameControl)

function LuckySpinMgr:ctor()
    LuckySpinMgr.super.ctor(self)
    
    self:setRefName(G_REF.LuckySpin)
end

function LuckySpinMgr:getData()
    return globalData.luckySpinData
end

-- 获取网络 obj
function LuckySpinMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local LuckySpinNet = util_require("GameModule.LuckySpin.net.LuckySpinNet")
    self.m_net = LuckySpinNet:getInstance()
    return self.m_net
end

-- 检查 关闭luckSpin是否触发先享后付弹板
function LuckySpinMgr:checkCanPopEnjoyTip()
    local data = self:getData()
    if not data then
        return false
    end
    return data.p_enjoyStatus
end

--[[
    显示LuckySpin界面
    _params = {
        closeCall: -- 关闭回调方法
        buyIndex: -- 商城档位那个idx
        itemIndex: -- 商城档位那个idx
        buyShopData: --商城档位数据
        reconnect: --断线重连标识
    }
]]
function LuckySpinMgr:showMainLayer(_params)
    if not _params or not _params.buyShopData then
        return
    end

    local view = util_createView("GameModule.LuckySpin.views.LuckySpinMainLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LuckySpinMgr:popSpinLayer(_params)
    if not _params or not _params.buyShopData then
        return
    end
    if (_params.type and _params.type == "HIGH") or self:getIsSuper(_params.buyShopData) then
        self:showMainV2(_params)
    else
        self:showMainLayer(_params)
    end
end

function LuckySpinMgr:getIsSuper(_data)
    local luckdata = globalData.luckySpinV2
    local isf = false
    if luckdata and #luckdata:getGearList() > 0 then
        for i,v in ipairs(luckdata:getGearList()) do
            if v.p_index == _data.p_id and v.p_type == "HIGH" then
                isf = true
                break
            end
        end
    end
    return isf
end

function LuckySpinMgr:showMainV2(_params)
    if not _params or not _params.buyShopData then
        return
    end

    local view = util_createView("GameModule.LuckySpin.views.luckyV2.LuckySpinMainV2", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LuckySpinMgr:showRewards(_params,_callback)
    local view = util_createView("GameModule.LuckySpin.views.luckyV2.LuckySpinRewardLayer", _params,_callback)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end


-- 弹出 先享后付费 提示弹板
function LuckySpinMgr:showEnjoyTipLayer(_mainView)
    if not _mainView then
        return
    end
    local view = util_createView("GameModule.LuckySpin.views.LuckySpinEnjoyTipLayer", _mainView)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function LuckySpinMgr:goPurchase(_type, _extraStr)
    self:getNetObj():goPurchase(_type, _extraStr)
end

function LuckySpinMgr:goPurchaseV2(_type, _extraStr)
    self:getNetObj():goPurchaseV2(_type, _extraStr)
end

return LuckySpinMgr