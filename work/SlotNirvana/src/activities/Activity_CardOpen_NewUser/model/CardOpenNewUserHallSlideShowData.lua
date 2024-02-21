--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-13 12:16:20
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-13 12:16:39
FilePath: /SlotNirvana/src/activities/Activity_CardOpen_NewUser/model/CardOpenNewUserHallSlideShowData.lua
Description: 集卡新手期 开启 活动 轮播展示 显示数据
--]]
local CardOpenNewUserHallSlideShowData = class("CardOpenNewUserHallSlideShowData")

function CardOpenNewUserHallSlideShowData:ctor()
    gLobalNoticManager:addObserver(self, "onTimeOutEvt", ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function CardOpenNewUserHallSlideShowData:parseNoviceCardSimpData(_data)
    self._cardAlbumCoins = tonumber(_data.newUserCardAlbumCoins) or 0 --新手集卡当前赛季奖励金币
    self._bNoviceCardSystem = _data.newUserCardSystem or false --是否有新手集卡功能
    self._cardAlbumUsd = tonumber(_data.newUserCardAlbumUsd) or 0 -- 赛季奖励美金
    self._cardClanTotal = _data.newUserCardClanTotal -- 卡组卡总数
    self._cardClanNum = _data.newUserCardClanNum -- 卡组卡数量
    self._cardClanCoins = tonumber(_data.newUserCardClanCoins) or 0 -- 卡组奖励金币
    self._cardClanId = _data.newUserCardClanId -- 卡组ID

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_CARD_OPEN_SHOW_DATA)
end

-- 收集所有卡册 获得的奖励 信息
function CardOpenNewUserHallSlideShowData:checkIsNoviceCardSys()
    return self._bNoviceCardSystem or false
end
function CardOpenNewUserHallSlideShowData:getNoviceAlbumCoins()
    return self._cardAlbumCoins or 0
end
function CardOpenNewUserHallSlideShowData:getCardAlbumUsd()
    return math.floor(tonumber(self._cardAlbumUsd) or 0)
end

function CardOpenNewUserHallSlideShowData:getMaxProgAlbumData()
    local _, _, normalClans = CardSysRuntimeMgr:getAlbumTalbeviewData()
    if not normalClans or #normalClans == 0 then
        return
    end

    local list = clone(normalClans)
    table.sort(list, function(a, b)
        local curA = CardSysRuntimeMgr:getClanCardTypeCount(a.cards)
        local curB = CardSysRuntimeMgr:getClanCardTypeCount(b.cards)
        if curA == curB then
            local aid = a and tonumber(a.clanId) or 0
            local bid = b and tonumber(b.clanId) or 0
            return aid > bid
        end
        return curA > curB
    end)

    local maxProgAlbumData = list[1]
    return maxProgAlbumData
end

-- 轮播显示 进度最高的卡册信息
function CardOpenNewUserHallSlideShowData:getSlideShowCardClanTotal()
    return self._cardClanTotal or 0
end
function CardOpenNewUserHallSlideShowData:getSlideShowCardClanNum()
    return self._cardClanNum or 0
end
function CardOpenNewUserHallSlideShowData:getSlideShowCardClanCoins()
    return self._cardClanCoins or 0
end
function CardOpenNewUserHallSlideShowData:getSlideShowCardClanLogo()
    if string.len(tostring(self._cardClanId)) ~= 8 then
        return
    end
    return CardResConfig.getCardClanIcon(self._cardClanId)
end

function CardOpenNewUserHallSlideShowData:onTimeOutEvt(params)
    if params.name == ACTIVITY_REF.CardOpenNewUser then
        -- 新手期集卡开启活动 到期移除轮播展示
        gLobalNoticManager:postNotification(ViewEventType.CLOSE_REMOVE_NEW_USER_CARD_OPEN_HALL_SLIDE)
    end
end

-- 服务器有给可显示的 卡册id
function CardOpenNewUserHallSlideShowData:checkEnabled()
    return string.len(tostring(self._cardClanId)) == 8
end

return CardOpenNewUserHallSlideShowData