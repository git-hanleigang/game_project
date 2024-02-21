--[[
    小猪送buff
]]
local PigSaleBoosterNet = require("activities.Activity_PigSaleBooster.net.PigSaleBoosterNet")
local PigSaleBoosterControl = class("PigSaleBoosterControl", BaseActivityControl)

function PigSaleBoosterControl:ctor()
    PigSaleBoosterControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PigBooster)

    self.m_net = PigSaleBoosterNet:getInstance()
end

-- 显示小猪银行 --
function PigSaleBoosterControl:showPiggyBank(_openPos)
    G_GetMgr(G_REF.PiggyBank):showMainLayer(nil, function(view)
        gLobalSendDataManager:getLogIap():setEnterOpen(nil, nil, _openPos)
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(view, "btn_go", DotUrlType.UrlName, false)
        end
    end)    
end

-- 进入大厅后 首先处理购买操作的遗留问题 然后再进行弹版等后续操作 --
function PigSaleBoosterControl:dealWithSaleProblemsFirst(callFun)
    -- 目前存留问题 1: 小猪booster后，未选择buff奖励就闪退或断网 --

    local pigBoost = self:getRunningData()

    -- 如果根本没有初始化boost字段 说明无此活动 --
    if not pigBoost or pigBoost:getBHasBuy() == nil or pigBoost:getSBuffID() == nil then
        callFun()
        return
    end

    -- 如果已经购买但是未选择buff --
    if pigBoost:getBHasBuy() == true then
        self:showPiggyBoosterChooseView(callFun)
    else
        if callFun ~= nil then
            callFun()
        end
    end
end

function PigSaleBoosterControl:getBoosterPath()
    local pigBoost = self:getRunningData()
    local themeName = pigBoost:getThemeName()
    if not themeName then
        return
    end
    local path
    if themeName == "Activity_PigSaleBooster" then
        return "Activity/Activity_PigSaleBoosterChooseNew"
    elseif themeName == "Activity_PigSaleBoosterPlus" then
        return "Activity/Activity_PigSaleBoosterPlusChoose"
    elseif themeName == "Activity_PigSaleBoosterLuxury" then
        return "Activity/Activity_PigSaleBoosterLuxuryChoose"
    elseif themeName == "Activity_PigSaleBooster_NoDiscount" then
        return "Activity/Activity_PigSaleBoosterNoDiscountChoose"
    else
        assert(false, "小猪送buff 未知的主题类型")
    end
end

-- 小猪银行 boost 购买成功操作 --
function PigSaleBoosterControl:showPiggyBoosterChooseView(callFun)
    if not self:isCanShowLayer() then
        return nil
    end

    local path = self:getBoosterPath()
    if not path then
        return
    end

    local view = util_createFindView(path)
    if view ~= nil then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        view:setOverFunc(callFun)
    end
    return view
end

-- 小猪银行 boost 选择buffer --
function PigSaleBoosterControl:doBoostChooseBuff(nBuffIndex)
    if nBuffIndex == nil or nBuffIndex < 0 or nBuffIndex > 3 then
        print("----------- >> SaleConfig:doBoostChooseBuff  nBuffIndex is " .. nBuffIndex)
        return
    end

    local chooseSuccessCall = function(responseData)
        print("----------- >> chooseSuccessCall  responseData is " .. tostring(responseData))
        --掉卡之前的提示
        gLobalViewManager:checkAfterBuyTipList(
            function()
                -- 有卡片掉落 --
                if CardSysManager:needDropCards("Purchase") == true then
                    CardSysManager:doDropCards("Purchase")
                end
            end
        )
    end

    -- 发送选择的buff消息至服务器 --
    local pigBoost = self:getRunningData()
    local buffID = pigBoost:getBuffByIndex(nBuffIndex)
    self.m_net:sendPiggyBankBoosterChooseBuff(buffID, chooseSuccessCall)
end

return PigSaleBoosterControl
