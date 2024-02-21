--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local MythicGameNet = class("MythicGameNet", BaseNetModel)

function MythicGameNet:requestOpenBox(_gameId, _chapter, _pos)
    local tbData = {
        data = {
            params = {
                index = _gameId,
                pos = _pos,
                chapter = _chapter
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.MYTHIC_GAME_REQUEST_OPENBOX, {isSuc = true})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.MYTHIC_GAME_REQUEST_OPENBOX, {isSuc = false})
    end

    self:sendActionMessage(ActionType.MythicGamePlay, tbData, successCallFun, failedCallFun)
end

function MythicGameNet:requestCollectReward(_gameId, _chapter, _success, _failed)
    local tbData = {
        data = {
            params = {
                index = _gameId,
                chapter = _chapter
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    -- 返回数据在minigame中解析
    local function successFunc(resData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.MYTHIC_GAME_REQUEST_COLLECT, {isSuc = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
        -- 重新拉取一下集卡最新数据
        local yearID = CardSysRuntimeMgr:getCurrentYear()
        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        local tExtraInfo = {year = yearID, albumId = albumId}
        CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo)
    end

    local function failedFunc(target, errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
        gLobalNoticManager:postNotification(ViewEventType.MYTHIC_GAME_REQUEST_COLLECT, {isSuc = false})
    end

    self:sendActionMessage(ActionType.MythicGameCollect, tbData, successFunc, failedFunc)
end

function MythicGameNet:clearData(_gameId)
    local tbData = {
        data = {
            params = {
                index = _gameId,
            }
        }
    }

    local function successCallFun(resData)
    end

    local function failedCallFun(code, errorMsg)
    end

    self:sendActionMessage(ActionType.MythicGameClear, tbData, successCallFun, failedCallFun)
end

return MythicGameNet
