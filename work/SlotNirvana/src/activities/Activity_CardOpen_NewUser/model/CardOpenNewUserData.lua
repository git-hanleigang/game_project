--[[--
    集卡新手期 开启
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local CardOpenNewUserData = class("CardOpenNewUserData", BaseActivityData)
function CardOpenNewUserData:ctor()
    CardOpenNewUserData.super.ctor(self)
    self.p_open = true
end

function CardOpenNewUserData:parseData(_netData)
    CardOpenNewUserData.super.parseData(self, _netData)
end

function CardOpenNewUserData:getOpenLevel()
    return globalData.constantData.NEW_CARD_OPEN_LEVEL or 5
end

function CardOpenNewUserData:isRunning()
    if not CardOpenNewUserData.super.isRunning(self) then
        return false
    end

    if self:isCompleted() then
        return false
    end
    return true
end

-- 检查完成条件
function CardOpenNewUserData:checkCompleteCondition()
    if CardSysManager then
        if not CardSysManager:isNovice() then
            return true
        end
    else
        if tonumber(globalData.cardAlbumId) ~= tonumber(CardNoviceCfg.ALBUMID) then
            return true
        end
    end
    return false
end

return CardOpenNewUserData
