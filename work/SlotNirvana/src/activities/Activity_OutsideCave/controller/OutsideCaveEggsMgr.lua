-- 咋龙蛋 控制类
local OutsideCaveNet = require("activities.Activity_OutsideCave.net.OutsideCaveNet")
local OutsideCaveEggsMgr = class("OutsideCaveEggsMgr", BaseGameControl)
local ShopItem = require "data.baseDatas.ShopItem"

function OutsideCaveEggsMgr:ctor()
    OutsideCaveEggsMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.CaveEggs)
    self.m_Net = OutsideCaveNet:getInstance()
    self.m_isClick = true
end

function OutsideCaveEggsMgr:parseData(_netData)
    if not _netData then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("activities.Activity_OutsideCave.model.EggsData"):create()
        _data:parseData(_netData)
        self:registerData(_data)
    else
        _data:parseData(_netData)
    end
end

function OutsideCaveEggsMgr:setClick(_flag)
    self.m_isClick = _flag
end

function OutsideCaveEggsMgr:getClick()
    return self.m_isClick
end

function OutsideCaveEggsMgr:isDownloadRes(refName)
    return self:isDownloadTheme("Activity_OutsideCave")
end

function OutsideCaveEggsMgr:showMainLayer(params)
    if not self:isCanShowLayer() then
        return
    end
    local pipeMainUI = nil
    if gLobalViewManager:getViewByExtendData("EggsMainUI") == nil then
        pipeMainUI = util_createView("Activity_OutsideCave/Eggs/EggsMainUI", param)
        if pipeMainUI ~= nil then
            self:showLayer(pipeMainUI, ViewZorder.ZORDER_UI)
        end
    end
    return pipeMainUI
end

function OutsideCaveEggsMgr:showGameRewardLayer(_rewardInfo,_callback)
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity_OutsideCave.Eggs.EggsReward", _rewardInfo,_callback)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 点击蛋
function OutsideCaveEggsMgr:sendItemsRequest(_pos)
    local successFunc = function(_netData)
        if not self:getData() then
            return
        end
        self:setRewardId(_netData.order,_netData.over,_netData.reward)
        self.m_order.index = _pos + 1
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EGGS_CLICK,self.m_order)
    end
    local fileFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EGGS_CLICK)
    end
    self.m_Net:sendItemsRequest(_pos,successFunc,fileFunc)
end
--领取奖励
function OutsideCaveEggsMgr:sendRewardRequest(_callback)
    local successFunc = function(_netData)
        local data = self:getData()
        if not data then
            return
        end
        local pack = self:getPackages(_netData)
        self:showGameRewardLayer(pack,_callback)
    end
    local fileFunc = function()
        if _callback then
            _callback(false)
        end
    end
    self.m_Net:sendRewardRequest(successFunc,fileFunc)
end

function OutsideCaveEggsMgr:getPackages(_data)
    local list = {}
    if _data.coins and toLongNumber(_data.coins) > toLongNumber(0) then
        local item = {}
        item.p_type = "COIN"
        item.p_coins = toLongNumber(_data.coins)
        table.insert(list,item)
    end
    if _data.items and #_data.items > 0 then
        for i,v in ipairs(_data.items) do
            local item = {}
            item.p_type = "ITEM"
            local tempData = ShopItem:create()
            tempData:parseData(v)
            item.p_items = tempData
            table.insert(list,item)
        end
    end
    return list
end

function OutsideCaveEggsMgr:setRewardId(_id,_over,_reward)
    self.m_order = {}
    self.m_order.id = _id
    self.m_order.over = _over
    self.m_order.reward = self:getCurReward(_reward)
end

function OutsideCaveEggsMgr:getCurReward(_reward)
    local items = {}
    if _reward.coins and toLongNumber(_reward.coins) > toLongNumber(0) then
        items.m_type = "COIN"
    end
    items.m_coins = toLongNumber(_reward.coins)
    items.m_gems = _reward.gems
    local re = _reward.items
    local shopitem = {}
    if re and #re > 0 then
        for k=1,#re do
            local tempData = ShopItem:create()
            tempData:parseData(re[k])
            table.insert(shopitem,tempData)
        end
    end
    items.m_shopItem = shopitem
    return items
end

function OutsideCaveEggsMgr:getEggsReward()
    local data = self:getData()
    if not data then
        return
    end
    local rew = data:getPanlReward()
    local list = {}
    local grand = {}
    if #rew > 0 then
        for i,v in ipairs(rew) do
            if v.m_grand then
                grand = v
            else
                table.insert(list,v)
            end
        end
    end
    return list,grand
end

return OutsideCaveEggsMgr
