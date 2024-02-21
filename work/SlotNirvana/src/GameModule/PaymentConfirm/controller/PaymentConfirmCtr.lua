--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-02-01 16:49:15
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-02-10 15:28:14
FilePath: /SlotNirvana/src/GameModule/PaymentConfirm/controller/PaymentConfirmCtr.lua
Description: 支付二次确认弹板 ctr
--]]
local PaymentConfirmCtr = class("PaymentConfirmCtr", BaseGameControl)

function PaymentConfirmCtr:ctor()
    PaymentConfirmCtr.super.ctor(self)

    self:setRefName(G_REF.PaymentConfirm)
end

--[[
@description: 显示支付 二次确认弹板
@_params: 支付显示信息
{
    coins: --金币
    price: --价格
    actRefName: --活动名(如果是活动，活动结束 需要关闭二次确认弹板 传)
    expireAt: -- 弹板过期时间(系统功能 或 活动类型 需要到期关闭 传)
}
@_confirmCB: 点击确认按钮回调 自己处理支付去
@_cancelCB:  点击关闭按钮回调
@return {*}
--]]
function PaymentConfirmCtr:showPayCfmLayer(_params, _confirmCB, _cancelCB)
    if not self:isDownloadRes() then
        return false
    end

    local layer = gLobalViewManager:getViewByExtendData("PaymentConfirmLayer")
    if layer then
        return
    end

    if not _params or not _params.coins or not _params.price then
        return
    end

    if _confirmCB then
        _params.confirmCB = _confirmCB
    end
    if _cancelCB then
        _params.cancelCB = _cancelCB
    end
    local layer = util_createView("GameModule.PaymentConfirm.views.PaymentConfirmLayer", _params)
    self:showLayer(layer, ViewZorder.ZORDER_POPUI)
    return layer 
end

-- 关闭 二次付费 确认弹板
function PaymentConfirmCtr:checkClosePayConfirmLayer()
    local layer = gLobalViewManager:getViewByExtendData("PaymentConfirmLayer")
    if not layer then
        return
    end

    layer:closeUI()
end

-- 移除 二次付费 确认弹板 所加的蒙版
function PaymentConfirmCtr:checkRemovePayConfirmLayerMask()
    local layer = gLobalViewManager:getViewByExtendData("PaymentConfirmLayer")
    if not layer then
        return
    end

    layer:removeMaskUI()
end

return PaymentConfirmCtr
