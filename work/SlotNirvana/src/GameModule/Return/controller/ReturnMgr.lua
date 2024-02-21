--[[

]]

require("GameModule.Return.config.ReturnConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")
local ReturnMgr = class("ReturnMgr", BaseGameControl)

function ReturnMgr:ctor()
    ReturnMgr.super.ctor(self)
    self:setRefName(G_REF.Return)
    self:setDataModule("GameModule.Return.model.ReturnData")

    self.m_isActiveSignPuchase = false


    --"Return"
    --"Return_Fourth"
    self.themeName = "Return"


    -- -- 任意一笔付费都会产生数据变化
    -- gLobalNoticManager:addObserver(self,
    --     function(target, params)
    --         if params and params.result then
    --             self:parsePurchaseData(params.result)
    --         end
    --     end,
    --     ViewEventType.NOTIFY_PURCHASE_SUCCESS
    -- )

    -- 付费跳过quest关卡，完成回归签到的quest任务
    gLobalNoticManager:addObserver(self,
        function(target, params)
            if params and params.result ~= nil and params.result ~= "" then
                local resultData = cjson.decode(params.result)
                if resultData.returnQuestTask and #resultData.returnQuestTask > 0 then
                    self:refreshQuestTaskData(resultData)
                end
            end
        end,
        ViewEventType.NOTIFY_QUEST_SKIP_BUY_SUC
    )    
end

-- 换皮时需主动更改这个名字，暂时无法通过配置来换皮
function ReturnMgr:getThemeName()
    --return "Return"
    return  self.themeName
end

-- function ReturnMgr:parsePurchaseData(_resultData)
--     local _resultData = util_cjsonDecode(_resultData)
--     if _resultData and _resultData.returnSignData ~= nil then
--         local returnNetData = _resultData.returnSignData
--         local data = G_GetMgr(G_REF.Return):getRunningData()
--         if data then
--             -- 激活了付费后双倍签到
--             if data:isActiveExtra() == false then
--                 data:setActiveExtra(true)
--                 data:refreshDaysData(returnNetData)
--                 self:setActiveSignPurchase(true)
--             end

--             -- 解锁了回归pass
--             if globalData.iapRunData.p_lastBuyType == BUY_TYPE.RETURN_PASS then
--                 if data:isPassUnlocked() == false then
--                     data:setPassUnlocked(true)
--                 end
--             end
--         end
--     end
-- end

-- -- 客户端记录等待表现逻辑
-- function ReturnMgr:setActiveSignPurchase()
--     self.m_isActiveSignPuchase = true
-- end
-- function ReturnMgr:isActiveSignPurchase()
--     return self.m_isActiveSignPuchase
-- end

function ReturnMgr:refreshTaskData(_taskData)
    if not _taskData then
        return
    end
    local data = self:getRunningData()
    if data then
        data:refreshTaskData(_taskData)
    end
end

function ReturnMgr:refreshQuestTaskData(_taskData)
    if not _taskData then
        return
    end
    local data = self:getRunningData()
    if data then
        data:refreshQuestTaskData(_taskData)
    end
end


function ReturnMgr:setExitGameCallFunc(_over)
    self.m_over = _over
end

function ReturnMgr:createEntryNode(_isLevelEntry)
    if not self:isCanShowLayer() then
        return nil
    end

    return util_createView(self.themeName .. "Code.EntryNode.ReturnEntryNode", _isLevelEntry)
end

function ReturnMgr:showLetterLayer(_over) 
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("ReturnLetterLayer") ~= nil then
        return nil
    end
    local view = util_createView(self.themeName .. "Code.LetterUI.ReturnLetterLayer", _over)
    if not view then
        return nil
    end
    view:setName("ReturnLetterLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ReturnMgr:showMainLayer(_pageIndex, _taskPageIndex, _params, _over, _noOpenQuest)
    if not self:isCanShowLayer() then
        return nil
    end
    if gLobalViewManager:getViewByName("ReturnMainLayer") ~= nil then
        return nil
    end
    local view = util_createView(self.themeName .. "Code.MainUI.ReturnMainLayer", _pageIndex, _taskPageIndex, _params, _over, _noOpenQuest)
    if not view then
        return nil
    end
    view:setName("ReturnMainLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ReturnMgr:showPassBuyLayer()
    if gLobalViewManager:getViewByName("ReturnPassBuyLayer") ~= nil then
        return nil
    end
    local view = util_createView(self.themeName .. "Code.MainUI.ReturnPass.ReturnPassBuyLayer")
    if not view then
        return nil
    end
    view:setName("ReturnPassBuyLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ReturnMgr:showRuleLayer()
    if gLobalViewManager:getViewByName("ReturnRuleLayer") ~= nil then
        return nil
    end
    local view = util_createView(self.themeName .. "Code.RuleUI.ReturnRuleLayer")
    if not view then
        return nil
    end
    view:setName("ReturnRuleLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ReturnMgr:showSignRewardLayer(_over, _rewardCoins, _rewardGems, _rewardItems)
    if gLobalViewManager:getViewByName("ReturnRewardLayer") ~= nil then
        return nil
    end
    local view = util_createView(self.themeName .. "Code.RewardUI.ReturnRewardLayer", _over, _rewardCoins, _rewardGems, _rewardItems)
    if not view then
        return nil
    end
    view:setName("ReturnRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ReturnMgr:showPassRewardLayer(_over, _rewardCoins, _rewardItems) 
    if gLobalViewManager:getViewByName("ReturnPassRewardLayer") ~= nil then
        return nil
    end
    local view = util_createView(self.themeName .. "Code.RewardUI.ReturnPassRewardLayer", _over, _rewardCoins, _rewardItems)
    if not view then
        return nil
    end
    view:setName("ReturnPassRewardLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function ReturnMgr:showWheelLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView(self.themeName .. "Code.MainUI.ReturnWheel.ReturnWheelLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

function ReturnMgr:showWheelCollectLayer(_params)
    if not self:isCanShowLayer() then
        return nil
    end

    local view = util_createView(self.themeName .. "Code.MainUI.ReturnWheel.ReturnWheelCollectLayer", _params)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end
--[[---------------------------------------------------------------------
    接口
]]
function ReturnMgr:requestCollectSign(_dayIndex, _success, _fail)
    local successFunc = function(_result)
        -- 用户流失回归信息
        if _result.ChurnReturn ~= nil then
            local ChurnReturn = _result.ChurnReturn
            if ChurnReturn.returnVersion and ChurnReturn.returnVersion == "V2" then
                if ChurnReturn.signV2 ~= nil then
                    self:parseData(ChurnReturn.signV2)
                end
            end
        end
        if _success then
            _success()
        end
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    G_GetNetModel(NetType.Return):requestCollectSign(_dayIndex, successFunc, failFunc)
end

function ReturnMgr:requestCollectTask(_type, _taskId, _success, _fail)
    local successFunc = function(_result)
        -- 用户流失回归信息
        if _result.ChurnReturn ~= nil then
            local ChurnReturn = _result.ChurnReturn
            if ChurnReturn.returnVersion and ChurnReturn.returnVersion == "V2" then
                if ChurnReturn.signV2 ~= nil then
                    self:parseData(ChurnReturn.signV2)
                end
            end
        end
        -- 通知
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RETURN_TASK_COLLECT)
        if _success then
            _success()
        end
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    G_GetNetModel(NetType.Return):requestCollectTask(_type, _taskId, successFunc, failFunc)
end

function ReturnMgr:requestCollectPass(_level, _type, _success, _fail)
    local successFunc = function(_result)
        -- 用户流失回归信息
        if _result.ChurnReturn ~= nil then
            local ChurnReturn = _result.ChurnReturn
            if ChurnReturn.returnVersion and ChurnReturn.returnVersion == "V2" then
                if ChurnReturn.signV2 ~= nil then
                    self:parseData(ChurnReturn.signV2)
                end
            end
        end
        -- 记录pass的奖励
        self:recordPassReward(_result)
        -- 通知
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RETURN_PASS_COLLECT)
        if _success then
            _success()
        end
    end
    local failFunc = function()
        if _fail then
            _fail()
        end
    end
    local data = self:getRunningData()
    if not data then
        return
    end
    G_GetNetModel(NetType.Return):requestCollectPass(_level, _type, successFunc, failFunc)
end

function ReturnMgr:requestWheelSpin()
    local successFunc = function(_result)
        if _result and _result.churnReturn ~= nil then
            local churnReturn = _result.churnReturn
            if churnReturn.returnVersion and churnReturn.returnVersion == "V2" then
                if churnReturn.signV2 ~= nil then
                    self:parseData(churnReturn.signV2)
                end
            end
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RETURN_WHEEL_SPIN, {result = _result})
    end
    local failFunc = function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RETURN_WHEEL_SPIN)
    end

    G_GetNetModel(NetType.Return):requestWheelSpin(successFunc, failFunc)
end

-- 解锁pass
function ReturnMgr:buyPass(_key, _price, _success, _fail)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.RETURN_PASS,
        _key,
        _price,
        0,
        0,
        function(_result)
            -- -- 回调是下一帧调用的
            -- -- 解锁了回归pass
            -- local data = G_GetMgr(G_REF.Return):getRunningData()
            -- if data and data:isPassUnlocked() == false then
            --     data:setPassUnlocked(true)
            -- end
            -- 通知
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RETURN_PASS_UNLOCK)            
            if _success then
                _success()
            end
        end,
        function()
            if _fail then
                _fail()
            end
        end
    )
end

function ReturnMgr:recordPassReward(_result)
    self.m_passRewards = {}
    self.m_passRewards.coins = 0
    if _result.coins then
        self.m_passRewards.coins = tonumber(_result.coins)
    end
    self.m_passRewards.items = {}
    if _result.items and #_result.items > 0 then
        for i=1,#_result.items do
            local itemData = ShopItem:create()
            itemData:parseData(_result.items[i])
            table.insert(self.m_passRewards.items, itemData)
        end
    end
end

function ReturnMgr:getRecordPassReward()
    return self.m_passRewards
end

return ReturnMgr