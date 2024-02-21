--[[
    
    author:{author}
    time:2021-09-28 17:58:50
]]
local WordSaleMgr = class("WordSaleMgr", BaseActivityControl)

function WordSaleMgr:ctor()
    WordSaleMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.WordSale)
    self:addPreRef(ACTIVITY_REF.Word)
end

function WordSaleMgr:showMainLayer(entry_name)
    if not self:isCanShowLayer() then
        return nil
    end

    -- local wordData = G_GetActivityDataByRef(ACTIVITY_REF.Word)
    -- if wordData == nil then
    --     return nil
    -- end

    local extra_data = nil
    if entry_name == "word_play_btn" or entry_name == "autoPop" then
        extra_data = {
            inEntry = true,
            name = "Activity/Word/csd/Word_NoLetterLeft/Word_NoLetterLeft.csb",
            itemName = "Activity/Word/csd/Word_NoLetterLeft/Word_NoLetterLeft_Item.csb"
        }
    end

    local uiView = nil
    local showWordSale = function ()
        local uiView = self:createPopLayer(extra_data)
        if uiView then
            entry_name = entry_name or "Promotion_Word"
            if gLobalSendDataManager.getLogIap and gLobalSendDataManager:getLogIap().setEnterOpen then
                gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", entry_name)
            end

            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
        end
        return uiView
    end

    -- 无限促销
    local showInfiniteSale = function ()
        if extra_data then
            uiView = G_GetMgr(ACTIVITY_REF.FunctionSaleInfinite):checkShowMainLayer({showPromotion = true, closeFunc = showWordSale})
        else
            uiView = showWordSale()
        end
        return uiView
    end

    -- 大活动PASS
    local showPassSale = function ()
        if extra_data then
            uiView = G_GetMgr(ACTIVITY_REF.FunctionSalePass):checkShowMainLayer({showPromotion = true, closeFunc = showInfiniteSale})
        else
            uiView = showInfiniteSale()
        end
        return uiView
    end

    uiView = showPassSale()

    return uiView
end

return WordSaleMgr
