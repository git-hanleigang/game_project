--[[
    二选一翻倍游戏
]]
local PokerDoubleGameNet = require("activities.Activity_Poker.net.PokerDoubleGameNet")
local PokerDoubleGameMgr = class("PokerDoubleGameMgr", BaseSingleton)

function PokerDoubleGameMgr:ctor()
    PokerDoubleGameMgr.super.ctor(self)
    self.m_net = PokerDoubleGameNet:getInstance()
end

function PokerDoubleGameMgr:getNet()
    return self.m_net
end

function PokerDoubleGameMgr:getData()
    return G_GetMgr(ACTIVITY_REF.Poker):getData()
end

function PokerDoubleGameMgr:startDouble(_overcall)
    self.m_doubleOverCall = _overcall
    local pDetailData = G_GetMgr(ACTIVITY_REF.Poker):getPokerDetail()
    if pDetailData then
        local status = pDetailData:getPokerStatus()
        if status == "DOUBLE_FIRST" or status == "DOUBLE_SECOND" then
            self:showMainLayer()
        end
    end
end

function PokerDoubleGameMgr:overDouble()
    if self.m_doubleOverCall then
        self.m_doubleOverCall()
        self.m_doubleOverCall = nil
    end
end

function PokerDoubleGameMgr:showMainLayer()
    if gLobalViewManager:getViewByName("PDGMainUI") ~= nil then
        return
    end
    -- 过场特效
    local cfg = G_GetMgr(ACTIVITY_REF.Poker):getConfig()
    local cg = util_createView(cfg.luaPath .. "PokerDoubleGame.PDGCGUI")
    gLobalViewManager:showUI(cg, ViewZorder.ZORDER_UI + 1)
    cg:setName("PDGCGUI")
    -- double主界面
    local tempNode = cc.Node:create()
    gLobalViewManager:getViewLayer():addChild(tempNode)
    util_performWithDelay(
        tempNode,
        function()
            -- 界面
            local cfg = G_GetMgr(ACTIVITY_REF.Poker):getConfig()
            local ui = util_createView(cfg.luaPath .. "PokerDoubleGame.PDGMainUI")
            gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
            ui:setName("PDGMainUI")
            -- 移除
            util_nextFrameFunc(
                function()
                    tempNode:removeFromParent()
                    tempNode = nil
                end
            )
        end,
        40 / 60
    )
end

function PokerDoubleGameMgr:showRedeemPopLayer(_overCall)
    if gLobalViewManager:getViewByName("PDGRedeemUI") ~= nil then
        return
    end
    local cfg = G_GetMgr(ACTIVITY_REF.Poker):getConfig()
    local ui = util_createView(cfg.luaPath .. "PokerDoubleGame.PDGRedeemUI", _overCall)
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
    ui:setName("PDGRedeemUI")
end

function PokerDoubleGameMgr:showRoundLoadingLayer(_overCall)
    if gLobalViewManager:getViewByName("PDGRoundLoadingUI") ~= nil then
        return
    end
    local cfg = G_GetMgr(ACTIVITY_REF.Poker):getConfig()
    local ui = util_createView(cfg.luaPath .. "PokerDoubleGame.PDGRoundLoadingUI", _overCall)
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
    ui:setName("PDGRoundLoadingUI")
end

function PokerDoubleGameMgr:showGiveupPopLayer(_overCall)
    if gLobalViewManager:getViewByName("PDGGiveUpUI") ~= nil then
        return
    end
    local cfg = G_GetMgr(ACTIVITY_REF.Poker):getConfig()
    local ui = util_createView(cfg.luaPath .. "PokerDoubleGame.PDGGiveUpUI", _overCall)
    gLobalViewManager:showUI(ui, ViewZorder.ZORDER_UI)
    ui:setName("PDGGiveUpUI")
end

return PokerDoubleGameMgr
