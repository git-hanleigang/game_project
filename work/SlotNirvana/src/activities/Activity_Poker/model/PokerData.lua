--[[
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local PokerChapterData = import(".PokerChapterData")
local PokerDetailData = import(".PokerDetailData")
local BaseActivityData = require "baseActivity.BaseActivityData"
local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local PokerData = class("PokerData", BaseActivityData)

function PokerData:parseData(_netData)
    PokerData.super.parseData(self, _netData)

    self.p_pokerItemCount = _netData.leftProps -- 凭证道具

    -- 轮次奖励金币
    self.p_roundCoins = tonumber(_netData.roundCoins)
    -- 轮次奖励道具
    self.p_roundItems = {}
    if _netData.roundReward and #_netData.roundReward > 0 then
        for i = 1, #_netData.roundReward do
            local sItem = ShopItem:create()
            sItem:parseData(_netData.roundReward[i])
            table.insert(self.p_roundItems, sItem)
        end
    end

    -- 当前章节index
    self.p_curChapterIndex = _netData.current

    -- 章节数据
    self.p_chapters = {}
    if _netData.chapters and #_netData.chapters > 0 then
        for i = 1, #_netData.chapters do
            local pChapterData = PokerChapterData:create()
            pChapterData:parseData(_netData.chapters[i])
            table.insert(self.p_chapters, pChapterData)
        end
    end

    -- 主界面中用的所有数据（包括小游戏数据）
    self.p_pokerDetail = nil
    if _netData.detail and _netData.detail.maxChips ~= nil then
        self.p_pokerDetail = PokerDetailData:create()
        self.p_pokerDetail:parseData(_netData.detail)
    end

    -- 关卡能量条
    self.p_collect = _netData.collect
    self.p_max = _netData.max

    -- double游戏进度
    self.p_curDouble = _netData.leftDoubles
    self.p_maxDouble = _netData.maxDoubles

    self.p_round = _netData.round

    self.p_spinPropLimit = _netData.spinPropLimit

    self.p_beHitDouble = _netData.beHitDouble -- 必中double or nothing 玩法 道具剩余
    self.p_fixWildItems = _netData.fixWildItems -- 固定2个wild 道具剩余

    self.p_leftTreasures = _netData.leftTreasures -- 累积充能次数
    self.p_maxTreasures = _netData.maxTreasures -- 最大充能次数
    self.p_doubleWinTimes = _netData.doubleWinItems -- 双倍筹码道具
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Poker})
end

function PokerData:getRoundCoins()
    return self.p_roundCoins
end

function PokerData:getRoundItems()
    return self.p_roundItems
end

function PokerData:getRound()
    return self.p_round
end

function PokerData:getCurChapterIndex()
    return self.p_curChapterIndex
end

function PokerData:getChapterData()
    return self.p_chapters
end

function PokerData:getPokerDetail()
    return self.p_pokerDetail
end

function PokerData:getCurDoubles()
    return self.p_curDouble
end

function PokerData:getMaxDoubles()
    return self.p_maxDouble
end

--打点用
function PokerData:getSequence()
    return self:getRound() or 0
end

function PokerData:getCurrent()
    return self:getCurChapterIndex()
end

--[[--
    扩展函数
]]
function PokerData:setLeftDoubles(_leftDouble)
    self.p_curDouble = _leftDouble
end

function PokerData:setPokerDetail(_detail)
    self.p_pokerDetail = _detail
end

function PokerData:getCurChapterData()
    return self:getChapterDataByIndex(self.p_curChapterIndex)
end

function PokerData:getChapterDataByIndex(_index)
    if self.p_chapters and #self.p_chapters >= _index then
        return self.p_chapters[_index]
    end
end

-- 登陆时是否触发新手引导
function PokerData:isLoginTriggerGuide()
    if self:getCurChapterIndex() == 1 and self:getRound() == 1 and self.p_pokerDetail:getChapterCurChips() == 0 then
        return true
    end
    return false
end

-- 断线重连和游戏中，触发double小游戏
function PokerData:isTriggerDoubleGame()
    if self.p_pokerDetail:isDoubleStatus() then
        return true
    end
    return false
end

---大厅小红点-------------------------------------
function PokerData:getLobbyRedNum()
    return self:getMaterialNum() or 0
end
------------------------------------------------
---关卡中用的数据 ---------------------------------
function PokerData:getMaterialNum()
    return self.p_pokerItemCount
end
function PokerData:getMaterialMax()
    return self.p_spinPropLimit
end
function PokerData:getCollectNum()
    return self.p_collect
end
function PokerData:getCollectMax()
    return self.p_max
end
function PokerData:setMaterialNum(_count)
    self.p_pokerItemCount = _count
end
function PokerData:setCollectNum(_num)
    if _num ~= nil then
        self.p_collect = _num
    end
end
function PokerData:setCollectMax(_max)
    self.p_max = _max
end
--获取入口位置 1：左边，0：右边
function PokerData:getPositionBar()
    return 1
end
-------------------------------------------------
---关卡弹框增加逻辑判断-----------------------------
function PokerData:isTicketEnough()
    if self.p_pokerItemCount > 0 then
        return true
    end
    return false
end
-------------------------------------------------
---促销用函数-------------------------------------
function PokerData:getDoubleHits()
    return self.p_beHitDouble or 0
end
function PokerData:getDoubleHitsMax()
    return 9999
end
function PokerData:getWildHits()
    return self.p_fixWildItems or 0
end
function PokerData:getWildHitsMax()
    return 9999
end
function PokerData:setDoubleHits(_doubleHits)
    self.p_beHitDouble = _doubleHits
end
function PokerData:setWildHits(_wildHits)
    self.p_fixWildItems = _wildHits
end
function PokerData:setDoubleWinTimes(_leftCount)
    self.p_doubleWinTimes = _leftCount
end
function PokerData:getDoubleWinTimes()
    return self.p_doubleWinTimes
end
function PokerData:getDoubleWinMax()
    return 9999
end
-------------------------------------------------
-- 优化新增：累计奖励进度----------------------------
function PokerData:getTreasureCurPro()
    return self.p_leftTreasures
end
function PokerData:setTreasureCurPro(_cur)
    self.p_leftTreasures = _cur
end
function PokerData:getTreasureMaxPro()
    return self.p_maxTreasures
end
function PokerData:setTreasureMaxPro(_max)
    self.p_maxTreasures = _max
end
------------------------------------------------
------------------------------------------------
--获取排行榜数据
function PokerData:parsePokerRankConfig(data)
    if data == nil then
        return
    end
    if not self.pokerRankConfig then
        self.pokerRankConfig = BaseActivityRankCfg:create()
    end
    self.pokerRankConfig:parseData(data)
    local myRankConfigInfo = self.pokerRankConfig:getMyRankConfig()
    if myRankConfigInfo ~= nil then
        self:setRank(myRankConfigInfo.p_rank)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.Poker})
end

function PokerData:getRankCfg()
    return self.pokerRankConfig
end

return PokerData
