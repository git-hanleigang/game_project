--[[
    钻石小猪
]]
util_require("activities.Activity_GemPiggy.config.GemPiggyConfig")
local GemPiggyNet = require("activities.Activity_GemPiggy.net.GemPiggyNet")
local GemPiggyMgr = class("GemPiggyMgr", BaseActivityControl)

function GemPiggyMgr:ctor()
    GemPiggyMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.GemPiggy)

    self.m_net = GemPiggyNet:getInstance()
end

function GemPiggyMgr:getHallPath(hallName)
    return hallName .. "/" .. hallName .. "HallNode"
end

function GemPiggyMgr:getSlidePath(slideName)
    return slideName .. "/" .. slideName .. "SlideNode"
end

function GemPiggyMgr:getPopPath(popName)
    return popName .. "/" .. popName
end

-- function GemPiggyMgr:registerData()
--     GemPiggyMgr.super.registerData(self)
--     gLobalNoticManager:addObserver(self, function(target, params)
--         local rData = self:getRunningData()
--         if not rData then
--             return
--         end
--         local cacheGemNum = rData:getCurrentGemNum()
--         local curGemNum = globalData.userRunData.gemNum
--         if curGemNum > cacheGemNum then
--         end
--     end, ViewEventType.NOTIFY_TOP_UPDATE_GEM)
-- end

-- 在其他系统中消耗钻石时收集钻石小猪
function GemPiggyMgr:showGemPiggyCollectLayer(_over, _costGem, _pos)
    if not self:isCanShowLayer() then
        return
    end
    local view = util_createView("Activity_GemPiggy.GemPiggyCollectLayer", _over, _costGem, _pos)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_SPECIAL, false)
    end
    return view
end

-- 三合一小猪主界面中的板子
function GemPiggyMgr:createTrioPiggyBoardNode(_buyCall)
    if not self:isCanShowLayer() then
        return
    end    
    return util_createView("Activity_GemPiggy.GemPiggyTrioBoardNode", _buyCall)
end

--[[--
    上UI挂的小猪控件节点
]]
function GemPiggyMgr:createTopPigNode()
    if not self:isCanShowLayer() then
        return
    end    
    local view = util_createView("Activity_GemPiggy.PiggyNodeGem")
    return view
end

--[[--
    上UI弹出的小猪气泡
]]
function GemPiggyMgr:createPiggyTip(_luaName, _luaPath, _ZOrder, _pos)
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
function GemPiggyMgr:requestBuyGemPiggy()
    local successFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GEMPIGGY_BUY, {isSuc = true})
    end

    local failedCallFunc = function(_errorInfo)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GEMPIGGY_BUY, {errorInfo = _errorInfo})
    end
    self.m_net:requestBuyGemPiggy(successFunc, failedCallFunc)
end

return GemPiggyMgr
