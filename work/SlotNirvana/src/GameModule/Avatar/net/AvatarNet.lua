--[[
Author: cxc
Date: 2022-04-12 16:51:08
LastEditTime: 2022-04-12 16:51:09
LastEditors: cxc
Description: 头像信息 网络类
FilePath: /SlotNirvana/src/GameModule/Avatar/net/AvatarNet.lua
--]]
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")
local BaseNetModel = import("net.netModel.BaseNetModel")
local AvatarNet = class("AvatarNet", BaseNetModel)

function AvatarNet:sendHotPlayerReq(_levelName, _successFunc)
    if not _levelName then
        return
    end
    
    -- gLobalViewManager:addLoadingAnima(false, 1)
    local successFunc = function(protoResult)
        -- gLobalViewManager:removeLoadingAnima()

        if _successFunc and protoResult and protoResult.players then
            _successFunc(protoResult.game or _levelName, protoResult.players)
        end 
    end

    local faildFunc = function(_errorCode, errorMsg)
        -- gLobalViewManager:removeLoadingAnima()
    end

    local reqData = {
        data = {
            params = {
                game = _levelName
            }
        }
    }
    self:sendActionMessage(ActionType.AvatarFrameHotPlayer, reqData, successFunc, faildFunc)
end

return AvatarNet