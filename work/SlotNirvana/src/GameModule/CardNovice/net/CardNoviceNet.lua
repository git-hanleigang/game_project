--[[
]]
local BaseNetModel = require("net.netModel.BaseNetModel")
local CardNoviceNet = class("CardNoviceNet", BaseNetModel)


-- -- 查询黑曜卡册（特殊卡册）某一个赛季卡册所有数据接口 --
-- function CardSysNetWork:sendObsidianCardsAlbumRequest(tExtraInfo, funS, funF)
--     if gLobalSendDataManager:isLogin() == false then
--         return
--     end

--     -- -- 添加消息等待面板 --
--     -- gLobalViewManager:addLoadingAnima(CardSysManager.m_isNetLoading)

--     local requestInfo = CardSysProto.CardNoviceAlbumResult()
--     requestInfo.udid = globalData.userRunData.userUdid
--     requestInfo.year = tExtraInfo.year
--     requestInfo.albumId = tExtraInfo.albumId

--     -- local bodyData = requestInfo:SerializeToString()
--     local sUrl = DATA_SEND_URL .. CardSysConfigs.Url.CardNoviceAlbumResult
--     local pbResponse = CardSysProto.CardNoviceAlbumResult()

--     local successCall = function(responseConfig)
--         -- -- 移除消息等待面板 --
--         -- gLobalViewManager:removeLoadingAnima()

--         -- local responseConfig = CardSysProto.ShortCardAlbumResult()
--         -- local responseStr = self:parseResponseData(responseTable)
--         -- responseConfig:ParseFromString(responseStr)
--         self:parseObsidianCardAlbumInfo(responseConfig)

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

return CardNoviceNet
