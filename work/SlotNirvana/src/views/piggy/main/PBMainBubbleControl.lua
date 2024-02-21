--[[--
    小猪有气泡的相关活动
    送缺卡
    送buff、送buffplus
    送金卡
]]
local CFG_BUBBLES = {
    {ACTIVITY_REF.PigBooster, "checkPigBooster", "BoosterNode"},
    {ACTIVITY_REF.PigRandomCard, "checkPigRandomCard", "RandomCardNode"},
    {ACTIVITY_REF.PigGoldCard, "checkPigGoldenCard", "GoldenCardNode"}
}
local PBMainBubbleControl = class("PBMainBubbleControl", BaseSingleton)

function PBMainBubbleControl:getCfgs()
    return CFG_BUBBLES
end

function PBMainBubbleControl:getBubbleLuaPaths()
    local luaPaths = {}
    for i = 1, #CFG_BUBBLES do
        local cfg = CFG_BUBBLES[i]
        local funcName = cfg[2]
        local luaName = cfg[3]
        if self[funcName](self) then
            luaPaths[#luaPaths + 1] = "views.piggy.bubbles." .. luaName
        end
    end
    return luaPaths
end

function PBMainBubbleControl:checkPigBooster()
    if not gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.PigBooster) then
        return false
    end
    if not G_GetMgr(ACTIVITY_REF.PigBooster):isCanShowLayer() then
        return false
    end
    local pigBoost = G_GetMgr(ACTIVITY_REF.PigBooster):getRunningData()
    if pigBoost and pigBoost:isRunning() then
        if not pigBoost:beingOnPiggyBoostSale() then
            return false
        end
    end
    return true
end

function PBMainBubbleControl:checkPigRandomCard()
    if not gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.PigRandomCard) then
        return false
    end
    if not G_GetMgr(ACTIVITY_REF.PigRandomCard):isCanShowLayer() then
        return false
    end
    local data = G_GetMgr(ACTIVITY_REF.PigRandomCard):getRunningData()
    if not data then
        return false
    end    
    return true
end

function PBMainBubbleControl:checkPigGoldenCard()
    if not gLobalActivityManager:checktActivityOpen(ACTIVITY_REF.PigGoldCard) then
        return false
    end
    if not G_GetMgr(ACTIVITY_REF.PigGoldCard):isCanShowLayer() then
        return false
    end
    local pigGoldCardData = G_GetMgr(ACTIVITY_REF.PigGoldCard):getRunningData()
    if not pigGoldCardData then
        return false
    end
    local pigGoldOpen = pigGoldCardData:getPiggyGoldFlag()
    if not pigGoldOpen then
        return false
    end
    local statusList = pigGoldCardData:getStatus()
    if not (statusList and #statusList > 0) then
        return false
    end
    local collectedCount = 0
    for i = 1, #statusList do
        if statusList[i] == 1 then
            collectedCount = collectedCount + 1
        end
    end
    if collectedCount == #statusList then
        return false
    end
    return true
end

return PBMainBubbleControl
