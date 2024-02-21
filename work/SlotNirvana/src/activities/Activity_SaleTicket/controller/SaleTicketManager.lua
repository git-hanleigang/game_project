local SaleTicketManager = class("SaleTicketManager", BaseActivityControl)

function SaleTicketManager:ctor()
    SaleTicketManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.SaleTicket)
end

-- function SaleTicketManager:getConfig()
--     local data = self:getRunningData()
--     if not data then
--         return
--     end
-- end

-- 显示弹板
function SaleTicketManager:showPopLayer(popUpInfo)
    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEXT_POP_VIEW)
    end

    return self:showMainLayer(callback)
end

-- 显示主界面
function SaleTicketManager:showMainLayer(callback, params)
    local callFunc = function()
        if callback then
            callback()
        end
    end
    local view = nil
    local saleTicketData = G_GetActivityDataByRef(ACTIVITY_REF.SaleTicket)
    if saleTicketData and saleTicketData.isRunning and saleTicketData:isRunning() then
        local refName = saleTicketData:getThemeName()
        view = util_createFindView("Activity/" .. refName, params)
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            -- csc 2021年04月03日11:55:47 修改代码 后续换皮需要用最新的 BaseLayer 写法
            if view.setCloseCallBack then
                view:setCloseCallBack(callFunc)
            else -- 兼容老换皮,后续如果都采取了 BaseLayer 写法，这里就可以去掉了
                view:setOverFunc(callFunc)
            end
        end
    end

    return view
end

-- 显示购买后弹板
function SaleTicketManager:showBuyPopLayer(callback)
    return self:showMainLayer(callback, {autoClose = true, noTouch = true})
end
return SaleTicketManager
