--[[
    关卡spin额外消耗的bet
]]
require("GameModule.BetExtraCosts.config.BetExtraCostsConfig")
local BetExtraCostsMgr = class("BetExtraCostsMgr", BaseGameControl)

function BetExtraCostsMgr:ctor()
    BetExtraCostsMgr.super.ctor(self)
    self:setRefName(G_REF.BetExtraCosts)  
end

function BetExtraCostsMgr:isExtraRef(_refName)
    if _refName and _refName ~= "" then
        local ExtraRefs = BetExtraCostsConfig.ExtraRefs
        for i=1,#ExtraRefs do
            if ExtraRefs[i] == _refName then
                return true
            end
        end
    end
    return false
end

function BetExtraCostsMgr:getInstance()
    BetExtraCostsMgr.super.getInstance(self)
end

--[[
    返回额外消耗的百分比，例如，0.2, 0.8
    必须实现： getBetExtraPercent 在活动的mgr中实现此方法
]]
function BetExtraCostsMgr:getExtraPercent()
    local percent = 0
    if BetExtraCostsConfig.isEffective == true then
        local ExtraRefs = BetExtraCostsConfig.ExtraRefs
        if ExtraRefs and #ExtraRefs > 0 then
            for i=1,#ExtraRefs do
                local refName = ExtraRefs[i]
                local mgr = G_GetMgr(refName)
                if mgr and mgr.getRunningData then
                    local runningData = mgr:getRunningData()
                    if runningData ~= nil and mgr.getBetExtraPercent then
                        percent = percent + (mgr:getBetExtraPercent() or 0)
                    end
                end
            end
        end
    end
    return percent
end

-- --[[--
--     额外消耗bet的活动气泡
--     必须实现： checkBetExtraBubble 在活动的mgr中实现此方法
-- ]]
-- function BetExtraCostsMgr:getEffectiveBetExtraRef()  
--     local effectiveRefs = {}
--     if BetExtraCostsConfig.isEffective == true then
--         local ExtraRefs = BetExtraCostsConfig.ExtraRefs
--         for i=1,#ExtraRefs do
--             local refName = ExtraRefs[i]
--             local mgr = G_GetMgr(refName)
--             if mgr and mgr.checkBetExtraBubble then
--                 if mgr:checkBetExtraBubble() then
--                     table.insert(effectiveRefs, refName)
--                 end
--             end
--         end
--     end
--     return effectiveRefs
-- end

return BetExtraCostsMgr