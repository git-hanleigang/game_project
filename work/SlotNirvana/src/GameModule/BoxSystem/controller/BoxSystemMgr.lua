--[[
    神秘宝箱系统
]]
require("GameModule.BoxSystem.config.BoxSystemConfig")

local BoxSystemNet = require("GameModule.BoxSystem.net.BoxSystemNet")
local BoxSystemMgr = class("BoxSystemMgr", BaseGameControl)

function BoxSystemMgr:ctor()
    BoxSystemMgr.super.ctor(self)

    self:setRefName(G_REF.BoxSystem)
    self:setResInApp(true)
    self:setDataModule("GameModule.BoxSystem.model.BoxSystemData")

    self.m_net = BoxSystemNet:getInstance()
    self.m_triggerQueue = util_require("manager.TriggerFunctionQueue"):create()
end

-- 获得宝箱列表
function BoxSystemMgr:getBoxGroupList()
    local data = self:getData()
    if data then
        return data:getBoxGroupList()
    end
    return {}
end

-- 获得宝箱列表通过分组
function BoxSystemMgr:getBoxListByGroup(_group)
    if not _group then
        return nil
    end
    local data = self:getData()
    if data then
        return data:getBoxListByGroup(_group)
    end
    return nil
end

function BoxSystemMgr:checkTriggerList(_funcList, _overcall)
    self.m_triggerQueue:checkTriggerList(_funcList, _overcall)
end

--[[
    宝箱收集弹板队列
    _groupName：组名 服务器确定
    _overFunc:
    _boxNum：宝箱数量 本次获得的宝箱个数(不传走分组总数量，邮件用)
]]
function BoxSystemMgr:showBoxCollectLayer(_groupName, _overFunc, _boxNum)
    -- 查找商品信息
    local boxList = self:getBoxListByGroup(_groupName)
    if not boxList or boxList:getNum() <= 0 then
        return nil
    end

    local boxNum = _boxNum or boxList:getNum()
    if boxNum <= 0 then
        return nil
    end
    local funcList = {}
    for i = 1, boxNum, 1 do
        funcList[#funcList + 1] = {func = handler(self, self.showRewardLayer), params = _groupName}
    end
    self:checkTriggerList(funcList, _overFunc)
    return true
end

function BoxSystemMgr:showRewardLayer(_params, _overcall)
    self:requestCollectReward(
        _params,
        function(resData)
            local layer = util_createView("GameModule.BoxSystem.views.BoxSystemRewardLayer", _params, resData)
            self:showLayer(layer, ViewZorder.ZORDER_UI)
            layer:setOverFunc(
                function()
                    if _overcall then
                        _overcall()
                    end
                end
            )
        end,
        function()
            if _overcall then
                _overcall()
            end
        end
    )
end

-- 领取奖励
function BoxSystemMgr:requestCollectReward(_groupName, _succCallFunc, _failedCallFunc)
    local boxList = self:getBoxListByGroup(_groupName)
    if not boxList or boxList:getNum() <= 0 then
        return
    end

    local succCallFunc = function(resData)
        if _succCallFunc then
            _succCallFunc(resData)
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BOX_SYSTEM_COLLECTED, resData)
    end

    local failedCallFunc = function(errorCode, errorData)
        if _failedCallFunc then
            _failedCallFunc()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BOX_SYSTEM_COLLECTED, false)
    end

    self.m_net:requestCollectReward(_groupName, succCallFunc, failedCallFunc)
end

return BoxSystemMgr
