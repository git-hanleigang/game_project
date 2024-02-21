--[[
    新手期集卡
]]

require("GameModule.CardNovice.config.CardNoviceCfg")

local CardNoviceMgr = class("CardNoviceMgr", BaseGameControl)

function CardNoviceMgr:ctor()
    CardNoviceMgr.super.ctor(self)
    self:setRefName(G_REF.CardNovice)

    self.m_isHaveNoviceCardSys = false
end

-- 缓存在mgr，不放入data中，不受新手期结束的影响
function CardNoviceMgr:setNoviceCardSimpleInfo(_simpleInfo)
    if not _simpleInfo then
        return
    end

    -- 新手集卡当前赛季奖励金币
    if _simpleInfo:HasField("newUserCardAlbumCoins") then
        self:setNoviceAlbumCoins(_simpleInfo.newUserCardAlbumCoins)
    end
    -- 是否有新手集卡功能
    if _simpleInfo:HasField("newUserCardSystem") then
        self:setNoviceCardSys(_simpleInfo.newUserCardSystem)
    end
end

function CardNoviceMgr:setNoviceAlbumCoins(_albumCoins)
    self.m_noviceAlbumCoins = tonumber(_albumCoins)
end

function CardNoviceMgr:getNoviceAlbumCoins()
    return self.m_noviceAlbumCoins or 0
end

-- boolean
function CardNoviceMgr:setNoviceCardSys(_isHaveSys)
    self.m_isHaveNoviceCardSys = _isHaveSys
end

function CardNoviceMgr:isNoviceCardSys()
    return self.m_isHaveNoviceCardSys
end

function CardNoviceMgr:getUnlockLevel()
    return globalData.constantData.NEW_CARD_OPEN_LEVEL or 5
end

-- 解锁等级
function CardNoviceMgr:isUnlockLevel()
    local level = globalData.userRunData.levelNum
    if level and tonumber(level) >= tonumber(self:getUnlockLevel()) then
        return true
    end
    return false
end

-- 是否是新手期集卡赛季
function CardNoviceMgr:isCardNoviceOpening()
    if CardSysManager then
        return CardSysManager:isNovice()
    end
    if tonumber(globalData.cardAlbumId) == tonumber(CardNoviceCfg.ALBUMID) then
        return true
    end
    return false
end

return CardNoviceMgr
