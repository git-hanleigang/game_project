--[[
    特殊卡册 Quest入口
]]
local CardSpecialClanQuestEntry = class("CardSpecialClanQuestEntry", BaseView)

function CardSpecialClanQuestEntry:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicQuestEntry.csb"
end

function CardSpecialClanQuestEntry:initUI()
    CardSpecialClanQuestEntry.super.initUI(self)
    self:runCsbAction("idle", true)
end

function CardSpecialClanQuestEntry:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_entry" then
        local tExtraInfo = {
            ["year"] = CardSysRuntimeMgr:getCurrentYear(),
            ["albumId"] = CardSysRuntimeMgr:getCurAlbumID()
        }
        CardSysNetWorkMgr:sendCardsAlbumRequest(
            tExtraInfo,
            function()
                -- 移除消息等待面板 --
                gLobalViewManager:removeLoadingAnima()
                G_GetMgr(G_REF.CardSpecialClan):showMainLayer()
            end,
            function()
                -- 移除消息等待面板 --
                gLobalViewManager:removeLoadingAnima()
            end
        )
    end
end

return CardSpecialClanQuestEntry
