--[[
    头像小游戏
]]

local AvatarGameNet = require("GameModule.AvatarGame.net.AvatarGameNet")
local AvatarGameManager = class("AvatarGameManager", BaseGameControl)

function AvatarGameManager:ctor()
    AvatarGameManager.super.ctor(self)
    self:setRefName(G_REF.AvatarGame)

    self.m_net = AvatarGameNet:getInstance()
end

function AvatarGameManager:isDownloadRes(_name)
    if not self:checkRes(_name) then
        return false
    end

    local isDownloaded = self:checkDownloaded(_name)
    if not isDownloaded then
        return false
    end

    return true
end

function AvatarGameManager:showMainLayer()
    -- 判断资源是否下载
    if not self:isDownloadRes(G_REF.AvatarFrame) then
        return nil
    end

    if not globalData.avatarFrameData:getMiniGameData() then 
        return nil
    end
    
    local gameView  = nil
    if gLobalViewManager:getViewByExtendData("AvatarGameMainLayer") == nil then
        gameView = util_createView("views.AvatarGame.AvatarGameMainLayer")
        gLobalViewManager:showUI(gameView, ViewZorder.ZORDER_UI)
    end

    return gameView
end

function AvatarGameManager:showInfoLayer()
    -- 判断资源是否下载
    if not self:isDownloadRes(G_REF.AvatarFrame) then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("AvatarGameInfoLayer") == nil then
        local gameView = util_createView("views.AvatarGame.AvatarGameInfoLayer")
        if gameView ~= nil then
            gLobalViewManager:showUI(gameView, ViewZorder.ZORDER_UI)
        end
    end
end

function AvatarGameManager:showCollectLayer(_params, _isAutoCollect)
    -- 判断资源是否下载
    if not self:isDownloadRes(G_REF.AvatarFrame) then
        return nil
    end

    if gLobalViewManager:getViewByExtendData("AvatarGameCollectLayer") == nil then
        local gameView = util_createView("views.AvatarGame.AvatarGameCollectLayer", _params, _isAutoCollect)
        if gameView ~= nil then
            gLobalViewManager:showUI(gameView, ViewZorder.ZORDER_UI)
        end
    end
end

function AvatarGameManager:sendPlay()
    self.m_net:sendPlay()
end

return AvatarGameManager