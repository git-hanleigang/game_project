--[[
    author:JohnnyFred
    time:2020-06-15 14:44:50
]]

local BaseNetModel = require("net.netModel.BaseNetModel")
local BingoNet = class("BingoNet", BaseNetModel)

function BingoNet:getInstance()
    if self.instance == nil then
        self.instance = BingoNet.new()
    end
    return self.instance
end

--普通Play
function BingoNet:sendBingoPlayBall()
    local guideData = G_GetMgr(ACTIVITY_REF.Bingo):getSaveData()
    local tbData = {
        data = {
            params = {
                saveData = guideData
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        if not resData or resData.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BALL_RESULT_FAILED)
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BALL_RESULT, resData)
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BINGO_BALL_RESULT_FAILED)
    end

    gLobalSendDataManager:getBingoActivity():updateLastBingoData()
    self:sendActionMessage(ActionType.BingoPlayV2, tbData, successCallFun, failedCallFun)
end

--Bingo活动，获取排行榜信息
function BingoNet:sendActionBingoRank()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    local function successCallFunc(resultData)
        if resultData ~= nil then
            local bingoData = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
            if bingoData then
                bingoData:parseRankData(resultData)
                
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.Bingo})
            end
        end
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:showReConnect()
    end

    self:sendActionMessage(ActionType.BingoRank, tbData, successCallFunc, failedCallFun)
end

function BingoNet:sendZeusPlay(_index)
    local guideData = G_GetMgr(ACTIVITY_REF.Bingo):getSaveData()

    local tbData = {
        data = {
            params = {
                clickPos = _index,
                saveData = guideData
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local function successCallFun(resData)
        gLobalViewManager:removeLoadingAnima()
        if resData and resData.error then 
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BINGO_ZEUS_BOX_OPEN)
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BINGO_ZEUS_BOX_OPEN, {index = _index, resData = resData})
    end

    local function failedCallFun(code, errorMsg)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_BINGO_ZEUS_BOX_OPEN)
    end

    self:sendActionMessage(ActionType.BingoPlayZeus, tbData, successCallFun, failedCallFun)
end

function BingoNet:getExtraDataKey()
    return "BingoExtra"
end

function BingoNet:getUserDefaultKey()
    return "BingoNet" .. globalData.userRunData.uid
end
return BingoNet
