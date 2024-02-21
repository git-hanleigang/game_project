
-- 小猪送buff数据

local BaseActivityData = require "baseActivity.BaseActivityData"
local PiggyBoostSaleData = class("PiggyBoostSaleData", BaseActivityData) 

--message PigBoosterConfig {
--    optional int32 expire = 1;
--    optional int64 expireAt = 2;
--    optional string activityId = 3;
--    repeated string buffIds = 4;
--    optional bool buy = 5; //是否买过
--    optional string chooseId = 6; //选择的buffID
--    optional int32 discount = 7; // 折扣
--    repeated ShopItem items = 8; // 具体buff的信息
--    optional int32 oldDiscount = 9; // 旧折扣
--}
function PiggyBoostSaleData:parseData(data)
    PiggyBoostSaleData.super.parseData(self, data)
    self.p_expire       = tonumber(data.expire)
    self.p_expireAt     = tonumber(data.expireAt)
    self.p_activityId   = data.activityId
    self.p_discount     = data.discount
    self.p_discountPre  = data.oldDiscount
    

    self:setPiggyBoostSaleHasBuy(data.buy)
    self:setPiggyBoostChooseBuff(data.chooseId)

    self:setPiggyBoostSaleFlag(self.p_expire)

    -- 解析需要的buffID  类型为 string数组 --
    self.m_BuffList = {}
    if data.buffIds and #data.buffIds > 0 and data.items and #data.items > 0 then
        for i = 1, #data.buffIds do
            local dataTemp = {id = data.buffIds[i],info = data.items[i]}
            self.m_BuffList[i] = dataTemp
        end
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.PigBooster})
end

function PiggyBoostSaleData:setPiggyBoostSaleFlag(nOpenFlag)
    self.nFlag = nOpenFlag
end
function PiggyBoostSaleData:setPiggyBoostSaleHasBuy(bBuy)
    self.bHasBuy = bBuy
end
function PiggyBoostSaleData:setPiggyBoostChooseBuff(sBuffID)
    self.sBuffID = sBuffID
end

function PiggyBoostSaleData:beingOnPiggyBoostSale()
    return self.nFlag and self.nFlag > 0
end

function PiggyBoostSaleData:getBHasBuy()
    return self.bHasBuy
end

function PiggyBoostSaleData:getSBuffID()
    return self.sBuffID
end

function PiggyBoostSaleData:getBuffByIndex(nBuffIndex)
    return self.m_BuffList[nBuffIndex].id
end

-- 进入大厅后 首先处理购买操作的遗留问题 然后再进行弹版等后续操作 --
-- function PiggyBoostSaleData:dealWithSaleProblemsFirst(callFun)
--     -- 目前存留问题 1: 小猪booster后，未选择buff奖励就闪退或断网 --

--     -- 如果根本没有初始化boost字段 说明无此活动 --
--     if self.bHasBuy == nil or self.sBuffID == nil then
--         callFun()
--         return
--     end

--     -- 如果已经购买但是未选择buff --
--     if self.bHasBuy == true then
--         self:showPiggyBoosterChooseView(callFun)
--     else
--         if callFun ~= nil then
--             callFun()
--         end
--     end
-- end

function PiggyBoostSaleData:getBoosterPath() 
    local themeName = self:getThemeName()
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

-- -- 小猪银行 boost 购买成功操作 --
-- function PiggyBoostSaleData:showPiggyBoosterChooseView(callFun)
--     local path = self:getBoosterPath()
--     if not path then
--         return
--     end

--     local view = util_createFindView(path)
--     if view ~= nil then
--         gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
--         view:setOverFunc(callFun)
--     end
-- end

-- -- 小猪银行 boost 选择buffer --
-- function PiggyBoostSaleData:doBoostChooseBuff(nBuffIndex)
--     if nBuffIndex == nil or nBuffIndex < 0 or nBuffIndex > 3 then
--         print("----------- >> SaleConfig:doBoostChooseBuff  nBuffIndex is " .. nBuffIndex)
--         return
--     end

--     local chooseSuccessCall = function(responseData)
--         print("----------- >> chooseSuccessCall  responseData is " .. tostring(responseData))
--         --掉卡之前的提示
--         gLobalViewManager:checkAfterBuyTipList(function()
--             -- 有卡片掉落 --
--             if CardSysManager:needDropCards("Purchase") == true then
--                 CardSysManager:doDropCards("Purchase")
--             end
--         end)
--     end

--     -- 发送选择的buff消息至服务器 --
--     local buffID = self.m_BuffList[nBuffIndex].id
--     gLobalSendDataManager:getNetWorkFeature():sendPiggyBankBoosterChooseBuff(buffID, chooseSuccessCall)
-- end

return PiggyBoostSaleData
