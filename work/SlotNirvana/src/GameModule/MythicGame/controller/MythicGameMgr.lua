--[[
    鲨鱼游戏道具化
]]

local MythicGameConfig = require("GameModule.MythicGame.config.MythicGameConfig")
local MythicGameNet = require("GameModule.MythicGame.net.MythicGameNet")
local MythicGameMgr = class("MythicGameMgr", BaseGameControl)

function MythicGameMgr:ctor()
    MythicGameMgr.super.ctor(self)

    self:setRefName(G_REF.MythicGame)
    self.m_net = MythicGameNet:getInstance()
end

function MythicGameMgr:parseData(data)
    if not data then
        return
    end
    local _data = self:getData()
    if not _data then
        _data = require("GameModule.MythicGame.model.MythicMiniGameData"):create()
        _data:parseData(data)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
end

function MythicGameMgr:getDataById(_gameId)
    local gameDatas = self:getData()
    if gameDatas then
        local data = gameDatas:getGameDataById(_gameId)
        return data
    end
end

function MythicGameMgr:setExitGameCallFunc(_over)
    self.m_over = _over
end

function MythicGameMgr:checkResAndData(_gameId)
    if not self:isDownloadRes() then
        return false
    end

    if not _gameId or _gameId <= 0 then
        return false
    end

    local data = self:getDataById(_gameId)
    if not data or data:isFinished() then
        return false
    end

    return true
end

function MythicGameMgr:enterGame(_gameId, _over)
    if not self:checkResAndData(_gameId) then
        return
    end
    
    self:setExitGameCallFunc(_over)

    self:showStartLayer(_gameId)
end

function MythicGameMgr:exitGame(_gameId)
    if self.m_over then
        self.m_over()
    end

    if not _gameId or _gameId <= 0 then
        return
    end

    -- self:clearData(_gameId)
end

function MythicGameMgr:showMainLayer(_gameId)
    if not self:checkResAndData(_gameId) then
        return
    end

    if gLobalViewManager:getViewByName("MythicGameCSMainLayer") ~= nil then
        return nil
    end

    local view = util_createView(MythicGameConfig.luaPath .. "mainUI.MythicGameCSMainLayer", _gameId)
    self:showLayer(view)
    return view
end

function MythicGameMgr:showRuleLayer()
    local view = util_createView(MythicGameConfig.luaPath .. "ruleUI.MythicGameCSInfoLayer")
    self:showLayer(view)

    return view
end

function MythicGameMgr:showStartLayer(_gameId)
    if not self:checkResAndData(_gameId) then
        return
    end

    if gLobalViewManager:getViewByName("MythicGameCSStartLayer") ~= nil then
        return nil
    end

    local view = util_createView(MythicGameConfig.luaPath .. "startUI.MythicGameCSStartLayer", _gameId)
    self:showLayer(view)

    return view
end

function MythicGameMgr:showRewardLayer(_isFinal, _gameId)
    if not self:checkResAndData(_gameId) then
        return
    end

    if gLobalViewManager:getViewByName("MythicGameCSRewardUI") ~= nil then
        return nil
    end

    local view = util_createView(MythicGameConfig.luaPath .. "rewardUI.MythicGameCSRewardUI", _isFinal, nil, _gameId)
    self:showLayer(view)

    return view
end

--[[---------------------------------------------------------------------
    接口
]]
function MythicGameMgr:requestOpenBox(_gameId, _pos)
    local data = self:getDataById(_gameId)
    if not data then
        return
    end
    local chapter = data:getCurLevelIndex()

    self.m_net:requestOpenBox(_gameId, chapter, _pos)
end

function MythicGameMgr:requestCollectReward(_gameId)
    local data = self:getDataById(_gameId)
    if not data then
        return
    end
    local chapter = data:getCurLevelIndex()

    self.m_net:requestCollectReward(_gameId, chapter)
end

function MythicGameMgr:clearData(_gameId)
    self.m_net:clearData(_gameId)
end

function MythicGameMgr:getNewGameDataId()
    local id = 0

    local gameDatas = self:getData()
    if gameDatas then
        id = gameDatas:getLastGameId()
    end

    return id
end

return MythicGameMgr
