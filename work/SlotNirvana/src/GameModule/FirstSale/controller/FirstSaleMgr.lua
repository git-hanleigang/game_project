--[[
    首充整理
]]

local Facade = require("GameMVC.core.Facade")
local FirstSaleNet = require("GameModule.FirstSale.net.FirstSaleNet")
local FirstSaleMgr = class("FirstSaleMgr", BaseGameControl)

function FirstSaleMgr:ctor()
    FirstSaleMgr.super.ctor(self)

    self.m_firstSaleNet = FirstSaleNet:getInstance()
    self:setRefName(G_REF.FirstCommonSale)
    self:setResInApp(true)
end

function FirstSaleMgr:parseData(data, _isNoCoins)
    if not data then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("GameModule.FirstSale.model.FirstSaleData"):create()
        _data:parseData(data, _isNoCoins)
        _data:setRefName(G_REF.FirstCommonSale)
        self:registerData(_data)
    else
        _data:parseData(data, _isNoCoins)
    end
end

-- 检查是不是 首冲礼包（第一次购买)
function FirstSaleMgr:checkIsFirstSaleType()
    local data = self:getData()
    if not data then
        return false
    end

    return data:checkIsFirstSaleType()
end

function FirstSaleMgr:showMainLayer(_params, data)
    if not self:isCanShowLayer() then
        return
    end

    local _data = data or self:getRunningData()
    if not _data then
        return
    end

    local view = nil
    if _data:getGroup() == 0 then 
        view = util_createView("views.sale.FirstSaleLayerA", _params, _data)
    elseif _data:getGroup() == 1 and _data:isOnSale() then
        view = util_createView("views.sale.FirstSaleLayerB", _params, _data)
    end

    if view then 
        view:setName("FirstSaleMainLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end

    return view
end

function FirstSaleMgr:deleteFirstSaleData()
    local _data = self:getData()
    if _data then 
        Facade:getInstance():removeModel(self:getRefName())
    end
end

function FirstSaleMgr:deleteNoCoinsSaleData()
    local _data = self:getData()
    if _data then 
        _data:setIsNoCoins(false)
    end
end

function FirstSaleMgr:getSaleOpenData(_onSale)
    local _data = self:getData()
    if not _data then
        return nil
    end

    if _onSale then 
        _data:setOnSale(_onSale)    
    end

    if _data:isCanShow() then 
        return _data
    end
end

function FirstSaleMgr:isNoCoins()
    local _data = self:getData()
    if _data then 
        return _data:isNoCoins()
    else
        return false
    end
end

function FirstSaleMgr:checkShowMianLayer(_params)
    local _data = self:getRunningData()

    if _data and _data:isCanShow() then 
        local view = self:showMainLayer(_params, _data)
    else
        if _params.callback then 
            _params.callback()
        end
    end
end

function FirstSaleMgr:requestFirstSale()
    local _data = self:getData()
    if _data then 
        local type = _data:getRequestFirstSaleTpye()
        if type ~= -1 then 
            local successFunc = function (_result)
                self:parseData(_result)
            end
            local failedFunc = function ()
                
            end
            self.m_firstSaleNet:requestFirstSale(type, successFunc, failedFunc)
        end
    end
end

function FirstSaleMgr:setIsFirst()
    self.m_isfirst = true
end

function FirstSaleMgr:getIsFirst()
    return self.m_isfirst or false
end

function FirstSaleMgr:isNewMan()
    local isman = false
    local createTime = globalData.userRunData.createTime or 0
    local serverTime = globalData.userRunData.p_serverTime or 86400
    local spanTime = serverTime - createTime
    if spanTime < (14 * 86400 * 1000) then
        isman = true
    end
    return isman
end

return FirstSaleMgr
