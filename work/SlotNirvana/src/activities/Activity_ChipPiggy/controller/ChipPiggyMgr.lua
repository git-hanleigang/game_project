--[[
    集卡小猪
]]
local ChipPiggyNet = require("activities.Activity_ChipPiggy.net.ChipPiggyNet")
local ChipPiggyMgr = class("ChipPiggyMgr", BaseActivityControl)

function ChipPiggyMgr:ctor()
    ChipPiggyMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.ChipPiggy)

    self.m_net = ChipPiggyNet:getInstance()
end

function ChipPiggyMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function ChipPiggyMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function ChipPiggyMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

--[[--
    集卡掉落界面挂的集卡小猪节点
]]
function ChipPiggyMgr:createCollectChipPiggyNode()
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity_ChipPiggy.ChipPiggyCollectNode")
    return view
end

-- 三合一小猪主界面中的板子
function ChipPiggyMgr:createTrioPiggyBoardNode(_buyCall)
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity_ChipPiggy.ChipPiggyTrioBoardNode", _buyCall)
    return view
end

--[[--
    上UI挂的小猪控件节点
]]
function ChipPiggyMgr:createTopPigNode()
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity_ChipPiggy.PiggyNodeChip")
    return view
end

--[[--
    上UI弹出的小猪气泡
]]
function ChipPiggyMgr:createPiggyTip(_luaName, _luaPath, _ZOrder, _pos)
    if not self:isCanShowLayer() then
        return
    end
    if gLobalViewManager:getViewByName(_luaName) ~= nil then
        return
    end
    local view = util_createView(_luaPath)
    if view then
        view:setName(_luaName)
        gLobalViewManager:getViewLayer():addChild(view, _ZOrder)
        if _pos then
            view:setPosition(cc.p(_pos.x, _pos.y))
        end
    end
    return view
end

-- 请求购买集卡小猪
function ChipPiggyMgr:requestBuyChipPiggy()
    local successFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHIPPIGGY_BUY, {isSuc = true})
    end

    local failedCallFunc = function(_errorInfo)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHIPPIGGY_BUY, {errorInfo = _errorInfo})
    end
    self.m_net:requestBuyChipPiggy(successFunc, failedCallFunc)
end

return ChipPiggyMgr
