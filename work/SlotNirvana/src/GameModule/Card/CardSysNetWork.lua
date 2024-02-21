--[[
    集卡系统消息处理
--]]
local CardSysNetWork = class("CardSysNetWork", require "network.NetWorkBase")
local CardSysProto = require "protobuf.CardProto_pb"
if CardProto_pb ~= nil then
    CardSysProto = CardProto_pb
end

-- ctor
function CardSysNetWork:ctor()
    self:reset()
end

-- do something reset --
function CardSysNetWork:reset()
end

-- get Instance --
function CardSysNetWork:getInstance()
    if not self._instance then
        self._instance = CardSysNetWork.new()
    end
    return self._instance
end

-- do something init --
function CardSysNetWork:initBaseData()
    print("---------------->> CardSysNetWork:initBaseData ")
end

-- 通用发送接口 --
-- function CardSysNetWork:sendCardSysData(tBodyData, sUrl, callSuccess, callFaild)
--     local httpSender = xcyy.HttpSender:createSender()
--     local success_call_fun = function(responseTable)
--         if callSuccess then
--             callSuccess(responseTable)
--         end
--         httpSender:release()
--     end
--     local faild_call_fun = function(errorCode, errorData)
--         if callFaild then
--             callFaild(errorCode, errorData)
--         end
--         httpSender:release()
--     end
--     local offset = self:getOffsetValue()
--     local token = globalData.userRunData.loginUserData.token
--     local serverTime = globalData.userRunData.p_serverTime
--     httpSender:sendMessage(tBodyData, offset, token, sUrl, serverTime, success_call_fun, faild_call_fun)
-- end

--------------------------- 发送消息到服务器 start------------------------------------------

-- 登陆游戏，客户端请求集卡基础信息接口，服务器返回以年度为单位的卡册基础数据 --
function CardSysNetWork:sendCardsInfoRequest(funS, funF)
    release_print("CardSysNetWork:sendCardsInfoRequest")
    if gLobalSendDataManager:isLogin() == false then
        if funF then
            funF(1, "Has't login ")
        end
        return
    end

    local requestInfo = CardSysProto.CardsInfoRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardsInfoRequest
    local pbResponse = CardSysProto.CardsInfoResponse()

    local successCall = function(responseConfig, headers)
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)

        -- self:saveHeaderOffset(headers)

        self:parseSeasonBaseInfo(responseConfig)
        CardSysRuntimeMgr:setHasLoginCardSys(true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_LOBBY_CARD_INFO)
        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end

    local faildCall = function(errorCode, errorData)
        CardSysRuntimeMgr:setHasLoginCardSys(false)
        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- --保存headers信息
-- function CardSysNetWork:saveHeaderOffset(headers)
--     if headers then
--         local headersStr = headers
--         if headersStr then
--             local headersList = util_split(headersStr, "\n")
--             if headersList and #headersList > 0 then
--                 for i = 1, #headersList do
--                     local dataStr = headersList[i]
--                     if string.find(dataStr, "Offset") ~= nil then
--                         local offsets = util_split(dataStr, ":")
--                         local offset = tonumber(offsets[2] or 0) or 0
--                         CardSysManager:setResponseOffset(offsets)
--                     end
--                 end
--             end
--         end
--     end
-- end

-- 查询某一个赛季卡册所有数据接口 --
function CardSysNetWork:sendCardsAlbumRequest(tExtraInfo, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- -- 添加消息等待面板 --
    -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

    if not (tExtraInfo and tExtraInfo.year ~= nil and tExtraInfo.albumId ~= nil) then
        return
    end

    local requestInfo = CardSysProto.CardAlbumRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.year = tExtraInfo.year
    requestInfo.albumId = tExtraInfo.albumId

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardAlbumRequest
    local pbResponse = CardSysProto.CardAlbumResponse()

    local successCall = function(responseConfig)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        -- local responseConfig = CardSysProto.CardAlbumResponse()
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        self:parseCardAlbumInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end

        gLobalNoticManager:postNotification(ViewEventType.ONRECIEVE_CARDS_ALBUM_REQ_SUCCESS, responseConfig)
    end

    local faildCall = function(errorCode, errorData)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end


-- -- 查询 新手期集卡 卡册所有数据接口 --
-- function CardSysNetWork:sendCardNoviceAlbumRequest(tExtraInfo, funS, funF)
--     if gLobalSendDataManager:isLogin() == false then
--         return
--     end

--     -- -- 添加消息等待面板 --
--     -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

--     local requestInfo = CardSysProto.CardAlbumRequest()
--     requestInfo.udid = globalData.userRunData.userUdid
--     requestInfo.year = tExtraInfo.year
--     requestInfo.albumId = tExtraInfo.albumId

--     -- local bodyData = requestInfo:SerializeToString()
--     local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardNoviceAlbumRequest
--     local pbResponse = CardSysProto.CardAlbumResponse()

--     local successCall = function(responseConfig)
--         -- -- 移除消息等待面板 --
--         -- gLobalViewManager:removeLoadingAnima()

--         -- local responseConfig = CardSysProto.CardAlbumResponse()
--         -- local responseStr = self:parseResponseData(responseTable)
--         -- responseConfig:ParseFromString(responseStr)
--         G_GetMgr(G_REF.CardNovice):parseAlbumData(responseConfig)

--         -- do something yourself --
--         if funS then
--             funS(responseConfig)
--         end
--     end

--     local faildCall = function(errorCode, errorData)
--         -- -- 移除消息等待面板 --
--         -- gLobalViewManager:removeLoadingAnima()

--         if funF then
--             funF(errorCode, errorData)
--         end
--     end

--     self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
-- end

-- 查询黑曜卡册（特殊卡册）某一个赛季卡册所有数据接口 --
function CardSysNetWork:sendObsidianCardsAlbumRequest(tExtraInfo, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- -- 添加消息等待面板 --
    -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

    local requestInfo = CardSysProto.CardAlbumRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.year = tExtraInfo.year
    requestInfo.albumId = tExtraInfo.albumId

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.ShortCardAlbumResult
    local pbResponse = CardSysProto.ShortCardAlbumResult()

    local successCall = function(responseConfig)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        -- local responseConfig = CardSysProto.ShortCardAlbumResult()
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        self:parseObsidianCardAlbumInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end

    local faildCall = function(errorCode, errorData)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- 查询历史掉落数据接口 --
function CardSysNetWork:sendCardDropHistoryRequest(funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- -- 添加消息等待面板 --
    -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

    local requestInfo = CardSysProto.CardDropHistoryRequest()
    requestInfo.udid = globalData.userRunData.userUdid

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardDropHistoryRequest
    local pbResponse = CardSysProto.CardDropHistoryResponse()

    local successCall = function(responseConfig)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        -- local responseConfig = CardSysProto.CardDropHistoryResponse()
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        self:parseCardDropHistoryInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end

    local faildCall = function(errorCode, errorData)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- 查询回收机可回收年度的所有卡片数据接口 --
function CardSysNetWork:sendCardWheelAllCardsRequest(tExtraInfo, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- -- 添加消息等待面板 --
    -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

    local requestInfo = CardSysProto.CardWheelAllCardsRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.year = tExtraInfo.year

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardWheelAllCardsRequest
    local pbResponse = CardSysProto.CardWheelAllCardsResponse()

    local successCall = function(responseConfig)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        -- self:parseCardWheelAllCardsInfo( responseConfig )

        -- CardSysRuntimeMgr:setCardWheelSelYear( requestInfo.year )
        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end

    local faildCall = function(errorCode, errorData)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- 回收机回收卡片spin请求接口 --
function CardSysNetWork:sendCardWheelRequest(tExtraInfo, funS, funF, newUrl)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- 添加消息等待面板 --
    -- gLobalViewManager:addLoadingAnima()

    local requestInfo = CardSysProto.CardWheelRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.level = tExtraInfo.level
    requestInfo.type = tExtraInfo.type
    local cards = requestInfo.cards -- a CARDWHEELINFO table  --
    for i = 1, #tExtraInfo.cards do
        local card = CardSysProto.CardWheelInfo()
        card.cardId = tExtraInfo.cards[i][1]
        card.number = tExtraInfo.cards[i][2]
        table.insert(cards, card)
    end
    -- local bodyData = requestInfo:SerializeToString()

    local sUrl = nil
    if newUrl then
        --使用传入url
        sUrl = newUrl
    else
        --轮盘url
        sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardWheelRequest
    end
    local pbResponse = CardSysProto.CardWheelResponse()

    local successCall = function(responseTable)
        -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        self:parseCardWheelSpinInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end

    local faildCall = function(errorCode, errorData)
        -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- 回收机回收卡片spin请求接口 -- 乐透
function CardSysNetWork:sendCardLettoRequest(tExtraInfo, funS, funF)
    --乐透使用轮盘接口 url不同
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardLettoRequest
    self:sendCardWheelRequest(tExtraInfo, funS, funF, sUrl)
end

-- Link卡请求link游戏接口 --
function CardSysNetWork:sendCardLinkPlayRequest(tExtraInfo, funS, funF, updateAlbum)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local requestInfo = CardSysProto.CardNadoPlayRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.status = tExtraInfo.status
    requestInfo.times = tExtraInfo.times or 0

    local spinStatus = tExtraInfo.status
    local spinTimes = tExtraInfo.times

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardNadoPlayRequest -- CardLinkPlayRequest
    local pbResponse = CardSysProto.CardNadoGame()

    local successCall = function(responseConfig)
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)

        -- 处理客户端临时数据
        if spinStatus == 0 then
            -- spin一次
            local left = CardSysRuntimeMgr:getNadoGameLeftCount()
            if left and left > 0 then
                CardSysRuntimeMgr:setNadoGameLeftCount(left - 1)
            end
        elseif spinStatus == 1 then
            -- 领奖，不处理，因为掉落会处理
        elseif spinStatus == 2 then
            -- 一键spin，全部消耗
            CardSysRuntimeMgr:setNadoGameLeftCount(0)
        elseif spinStatus == 3 then
            -- 一键spin，指定次数
            local left = CardSysRuntimeMgr:getNadoGameLeftCount()
            if left and left > 0 and spinTimes > 0 and left >= spinTimes then
                CardSysRuntimeMgr:setNadoGameLeftCount(left - spinTimes)
            end
        end

        self:parseCardLinkPlayInfo(responseConfig)

        -- local responseStr     = self:parseResponseData(responseTable)
        -- self:parseCardLinkPlayInfo(responseStr)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end

        -- 同步下simperUser
        if responseConfig.simpleUser then
            globalData.syncSimpleUserInfo(responseConfig.simpleUser)
        end

        -- link 小游戏结束后，重新获取信息，用以刷新大厅集卡节点数据 --
        -- CardSysManager:requestCardCollectionSysInfo(updateAlbum)
        -- CardSysManager:requestCardAlbumData(nil, nil, updateAlbum)
        local yearID = CardSysRuntimeMgr:getCurrentYear()
        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        local tExtraInfo = {year = yearID, albumId = albumId}
        CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo, updateAlbum)
    end

    local faildCall = function(errorCode, errorData)
        -- 移除消息等待面板 --
        gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- wild卡可兑换的年度所有卡片数据接口 --
function CardSysNetWork:sendCardExchangeYearCardsRequest(tExtraInfo, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- -- 添加消息等待面板 --
    -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

    local requestInfo = CardSysProto.CardExchangeYearCardsRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.year = tExtraInfo.year
    requestInfo.type = tExtraInfo.type

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardExchangeYearCardsRequest
    local pbResponse = CardSysProto.CardExchangeYearCardsResponse()

    local successCall = function(responseConfig)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        -- self:parseCardExchangeYearCardsInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end

    local faildCall = function(errorCode, errorData)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- wild卡请求兑换接口 --
function CardSysNetWork:sendCardExchangeRequest(tExtraInfo, funS, funF, updateAlbum)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    -- -- 添加消息等待面板 --
    -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

    local requestInfo = CardSysProto.CardExchangeRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.newCardId = tExtraInfo.newCardId
    requestInfo.type = tExtraInfo.type

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardExchangeRequest
    local pbResponse = CardSysProto.CardExchangeResponse()

    local successCall = function(responseConfig)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        -- self:parseCardExchangeInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end

        -- wild卡兑换 结束后，重新获取信息，用以刷新大厅集卡节点数据 --
        CardSysManager:requestCardCollectionSysInfo()
        -- 请求章节数据，刷新章节选择界面 【201903赛季把章节选择界面作为了主界面，并且可以在集卡系统内部掉落卡牌】--
        -- CardSysManager:requestCardAlbumData(nil, nil, updateAlbum)
        local yearID = CardSysRuntimeMgr:getCurrentYear()
        local albumId = CardSysRuntimeMgr:getCurAlbumID()
        local tExtraInfo = {year = yearID, albumId = albumId}
        CardSysNetWorkMgr:sendCardsAlbumRequest(tExtraInfo, updateAlbum)
    end

    local faildCall = function(errorCode, errorData)
        -- -- 移除消息等待面板 --
        -- gLobalViewManager:removeLoadingAnima()

        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- 浏览卡片请求接口，重置卡片new状态 --
function CardSysNetWork:sendCardViewRequest(tExtraInfo, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local requestInfo = CardSysProto.CardViewRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.albumId = tExtraInfo.albumId
    requestInfo.clanId = tExtraInfo.clanId

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardViewRequest
    local pbResponse = CardSysProto.CardViewResponse()

    local successCall = function(responseConfig)
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        self:parseCardViewInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end

    local faildCall = function(errorCode, errorData)
        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end
-- ... ---

local StatuePickGameData = require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickGameData")
local StatuePickRewardData = require("GameModule.CardMiniGames.Statue.StatuePick.data.StatuePickRewardData")
-- 浏览卡片请求接口，重置卡片new状态 --
function CardSysNetWork:sendCardSpecialGameRequest(tExtraInfo, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local requestInfo = CardSysProto.CardSpecialGameRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    requestInfo.type = tExtraInfo.type
    -- 选中id
    requestInfo.id = tExtraInfo.id or 0

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardSpecialGameRequest
    local pbResponse = CardSysProto.CardSpecialGameResponse()

    local successCall = function(responseConfig)
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)

        -- TODO:MAQUN 小游戏数据解析方式
        if responseConfig:HasField("specialGame") then
            if StatuePickGameData then
                StatuePickGameData:getInstance():parseData(responseConfig.specialGame)
            end
        end

        if responseConfig:HasField("reward") then
            StatuePickRewardData:getInstance():parseData(responseConfig.reward)
        end

        -- cxc 更新活动数据（掉落高倍场小游戏活动数据）
        if responseConfig:HasField("activity") then
            globalData.syncActivityConfig(responseConfig.activity)
        end

        if responseConfig.buffs then
            local buffs = responseConfig.buffs
            globalData.syncBuffs(buffs)
        end

        if responseConfig.mission then
            local mission = responseConfig.mission
            globalData.syncMission(mission)
        end

        -- pass 任务刷新 csc 2021年06月28日16:44:43
        if responseConfig.passTask then
            local passTask = responseConfig.passTask
            G_GetMgr(ACTIVITY_REF.NewPass):refreshPassTaskData(passTask)
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CARD_SPECIALGAME_REQUEST_SUCC)

        -- do something yourself --
        if funS then
            funS(responseConfig.type)
        end
    end

    local faildCall = function(errorCode, errorData)
        if funF then
            funF(errorCode, errorData)
        end
    end

    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

-- tExtraInfo: {status = x}, x: 1 play, 2 collect, 3 purchase
function CardSysNetWork:sendPuzzleGameRequest(tExtraInfo, funS, funF)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local requestInfo = CardSysProto.CardVegasTornadoPlayRequest()
    requestInfo.udid = globalData.userRunData.userUdid
    for k, v in pairs(tExtraInfo) do
        requestInfo[k] = v
    end

    -- local bodyData = requestInfo:SerializeToString()
    local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardVegasTornadoPlayRequest
    local pbResponse = CardSysProto.CardVegasTornado()

    local successCall = function(responseConfig)
        -- local responseStr = self:parseResponseData(responseTable)
        -- responseConfig:ParseFromString(responseStr)
        self:parsePuzzleGameInfo(responseConfig)

        -- do something yourself --
        if funS then
            funS(responseConfig)
        end
    end
    local faildCall = function(errorCode, errorData)
        if funF then
            funF(errorCode, errorData)
        end
    end
    self:sendNetMsg(sUrl, requestInfo, pbResponse, successCall, faildCall)
end

--------------------------- 发送消息到服务器 end ------------------------------------------

--------------------------- 解析数据 start-----------------------------------------------
-- 解析赛季基本数据 --
function CardSysNetWork:parseSeasonBaseInfo(tData)
    CardSysRuntimeMgr:setCardSeasonsInfo(tData)

    --[[--
        此接口不等待返回数据后再处理逻辑
        所以，网络慢时，集卡内部功能比如集卡鲨鱼已经从第一关玩到了第3关，这时这个旧数据会脏集卡鲨鱼的数据
    --]]
    local data = G_GetMgr(G_REF.CardSeeker):getData()
    local isIn = G_GetMgr(G_REF.CardSeeker):isInView()
    if not (isIn and data and data:isPlaying()) then
        if tData:HasField("adventureGame") then
            release_print("CardSysNetWork:parseSeasonBaseInfo")
            G_GetMgr(G_REF.CardSeeker):parseData(tData.adventureGame)
        end
    end    

    -- 解析卡牌商店数据
    if tData:HasField("store") then
        G_GetMgr(G_REF.CardStore):parseData(tData.store)
    end

    -- 解析特殊卡册数据
    if tData:HasField("shortCurrentAlbumId") then
        G_GetMgr(G_REF.ObsidianCard):setCurAlbumID(tData.shortCurrentAlbumId)
    end
    if tData.shortCardYears ~= nil and #tData.shortCardYears > 0 then
        G_GetMgr(G_REF.ObsidianCard):parseShortCardYears(tData.shortCardYears)
    end
    if tData:HasField("shortCardAlbum") then
        G_GetMgr(G_REF.ObsidianCard):parseData(tData.shortCardAlbum)
    end
    -- 集卡排行榜
    if tData:HasField("cardRank") == true then
        G_GetMgr(G_REF.CardRank):parseData(tData.cardRank)
    end
    -- 新手集卡促销
    if tData:HasField("albumSale") then
        G_GetMgr(G_REF.CardNoviceSale):parseData(tData.albumSale)
    end
    
    -- 限时集卡多倍奖励
    if tData:HasField("albumMoreAward") == true then
        globalData.commonActivityData:parseNoCfgActivityData(tData.albumMoreAward, ACTIVITY_REF.AlbumMoreAward)
    end
end

-- 解析卡册基本数据 --
function CardSysNetWork:parseCardAlbumInfo(tData)
    CardSysRuntimeMgr:setCardAlbumInfo(tData)
end

-- 解析卡册基本数据 --
function CardSysNetWork:parseObsidianCardAlbumInfo(tData)
    G_GetMgr(G_REF.ObsidianCard):setCardAlbumInfo(tData, true)
end

-- 解析历史掉落数据 --
function CardSysNetWork:parseCardDropHistoryInfo(tData)
    CardSysRuntimeMgr:setCardDropHistoryInfo(tData)
end

-- -- 解析回收机可回收年度的所有卡片数据 --
-- function CardSysNetWork:parseCardWheelAllCardsInfo( tData )
--     CardSysRuntimeMgr:setCardWheelAllCardsInfo( tData )
-- end

-- 解析回收机回收卡片spin请求 --
function CardSysNetWork:parseCardWheelSpinInfo(tData)
    CardSysRuntimeMgr:setCardWheelSpinInfo(tData)
end

-- 解析Link卡请求link游戏数据 --
function CardSysNetWork:parseCardLinkPlayInfo(tData)
    CardSysRuntimeMgr:setCardLinkPlayInfo(tData)
end

-- -- 解析wild卡可兑换的年度所有卡片数据 --
-- function CardSysNetWork:parseCardExchangeYearCardsInfo( tData )
--     CardSysRuntimeMgr:setCardExchangeYearCardsInfo( tData )
-- end

-- -- 解析wild卡请求兑换数据 --
-- function CardSysNetWork:parseCardExchangeInfo( tData )
--     CardSysRuntimeMgr:setCardExchangeInfo( tData )
-- end

-- 解析浏览卡片请求数据 --
function CardSysNetWork:parseCardViewInfo(tData)
    CardSysRuntimeMgr:setCardViewInfo(tData)
end

-- 解析浏览卡片请求数据 --
function CardSysNetWork:parseCardSpecialGameInfo(tData)
    CardSysRuntimeMgr:setCardSpecialGameInfo(tData)
end

function CardSysNetWork:parsePuzzleGameInfo(tData)
    -- CardSysRuntimeMgr:parsePuzzleGameData(tData)
end

--------------------------- 解析数据 end  -----------------------------------------------

-- Global Var --
GD.CardSysNetWorkMgr = CardSysNetWork:getInstance()
