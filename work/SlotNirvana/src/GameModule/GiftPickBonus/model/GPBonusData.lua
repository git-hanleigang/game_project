--[[
    author:JohnnyFred
    time:2019-10-08 19:36:07
]]
local BaseGameModel = require("GameBase.BaseGameModel")

local PickGameData = import(".PickGameData")

local GPBonusData = class("GPBonusData", BaseGameModel)

function GPBonusData:ctor()
    GPBonusData.super.ctor(self)
    self.m_curIdx = nil
    self.pickBonus = {}

    self:setRefName(G_REF.GiftPickBonus)
end

function GPBonusData:parseData(data)
    self.pickBonus = {}

    if data and #data > 0 then
        for i = 1, #data do
            local pickBonus = PickGameData:create()
            pickBonus:parseData(data[i])
            -- if self.pickBonus.status == "PREPARE" or self.pickBonus.status == "PLAYING" then
            --     if self.redPointList.rewards == nil then
            --         self.redPointList.rewards = {}
            --     end
            --     self.redPointList.rewards[#self.redPointList.rewards + 1] = self.pickBonus
            -- end

            self.pickBonus[i] = pickBonus
        end
    end
end

function GPBonusData:onRegister()
    self:freshCurPickGameIdx()
end

function GPBonusData:getCurPickGameIdx()
    return self.m_curIdx or 0
end

-- 刷新当前小游戏索引
function GPBonusData:freshCurPickGameIdx()
    for i = 1, #self.pickBonus do
        local _pickBonus = self.pickBonus[i]
        if _pickBonus and _pickBonus:isPlaying() then
            self.m_curIdx = i
        end
    end
end

function GPBonusData:setCurPickGameIdx(nIndex)
    if not nIndex then
        return
    end

    if self.m_curIdx and self.m_curIdx ~= nIndex then
        -- 与当前相同
        return
    end

    local _bonus = self.pickBonus[nIndex]
    if not _bonus or _bonus:isFinished() then
        -- 小游戏不存在或已经结束
        return
    end
    self.m_curIdx = nIndex
end

function GPBonusData:isAllOpen()
    if self:isOpen() and self:isReachLevel() then
        return true
    end
    return false
end

function GPBonusData:isOpen()
    -- if not self.start or not self.expireAt then
    --     return false
    -- end
    -- local curTime = os.time()
    -- if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
    --     curTime = globalData.userRunData.p_serverTime / 1000
    -- end
    -- if tonumber(self.start) / 1000 <= curTime and tonumber(self.expireAt) / 1000 > curTime then
    --     return true
    -- end
    -- return false
    return #self.pickBonus > 0
end

function GPBonusData:isReachLevel()
    -- if globalData.userRunData.levelNum < globalData.constantData.CHALLENGE_OPEN_LEVEL then
    --     return false
    -- end
    return true
end

function GPBonusData:checkGuideIndexShow(guideIndex)
    -- return false
    if not self:isAllOpen() then
        return false
    end
    if guideIndex == 1 then
        local showTimes = gLobalDataManager:getNumberByField("SPGuide_0_ShowTimes", 0)
        local showParam = gLobalDataManager:getNumberByField("SPGuide_0" .. util_formatServerTime(), 0)
        if showParam == 0 and showTimes <= 3 then
            gLobalDataManager:setNumberByField("SPGuide_0" .. util_formatServerTime(), 1)
            showTimes = showTimes + 1
            gLobalDataManager:setNumberByField("SPGuide_0_ShowTimes", showTimes)
            if showTimes == 3 then
                self:saveLCGuideIndex(1)
            end
            return true
        else
            return false
        end
    elseif guideIndex == 2 then
        return true
    elseif guideIndex == 3 then
        return true
    elseif guideIndex == 4 then
        return true
    elseif guideIndex == 5 then
        return true
    elseif guideIndex == 6 then
        return true
    end
end

function GPBonusData:getLCGuideIndex()
    -- gLobalDataManager:setNumberByField("SPGuide"..globalData.userRunData.uid,5)
    local guideIndex = gLobalDataManager:getNumberByField("SPGuide" .. globalData.userRunData.uid, 0)
    return guideIndex
end

function GPBonusData:saveLCGuideIndex(guideIndex)
    --同步到服务器  防止卸载包导致数据丢失
    gLobalSendDataManager:getNetWorkFeature():sendActionChallengeGuide(guideIndex)
    -- local guideIndex = gLobalDataManager:getNumberByField("SPGuide"..globalData.userRunData.uid,0)
    gLobalDataManager:setNumberByField("SPGuide" .. globalData.userRunData.uid, guideIndex)
end

-- 获取红点信息
-- 0  all 1 task 2 reward
-- function GPBonusData:getRedPoint(indexType)
--     local redNum = 0
--     if self.redPointList then
--         if indexType == 0 then
--             if self.redPointList.tasks then
--                 redNum = redNum + #self.redPointList.tasks
--             end
--             if self.redPointList.rewards then
--                 redNum = redNum + #self.redPointList.rewards
--             end
--         elseif indexType == 1 then
--             if self.redPointList.tasks then
--                 redNum = redNum + #self.redPointList.tasks
--             end
--         elseif indexType == 2 then
--             if self.redPointList.rewards then
--                 redNum = redNum + #self.redPointList.rewards
--             end
--         end
--     end
--     return redNum
-- end

function GPBonusData:getSmallGame()
    return {}
end

function GPBonusData:getCurPickGameData()
    if not self.m_curIdx then
        return nil
    end

    return self.pickBonus[self.m_curIdx]
end

function GPBonusData:setCurPickGameId(_id)
    if self.pickBonus and #self.pickBonus >= 0 then
        for i = 1, #self.pickBonus do
            local pickGameData = self.pickBonus[i]
            if _id == pickGameData:getId() then
                self.m_curIdx = i
                return true
            end
        end
    end
    return false
end

function GPBonusData:getPickGameDataById(_id)
    if self.pickBonus and #self.pickBonus >= 0 then
        for i = 1, #self.pickBonus do
            local pickGameData = self.pickBonus[i]
            if _id == pickGameData:getId() then
                return pickGameData
            end
        end
    end
    return nil
end

function GPBonusData:getNewestPickGameData()
    if self.pickBonus and #self.pickBonus >= 0 then
        return self.pickBonus[#self.pickBonus]
    end
    return nil
end

function GPBonusData:getPickGameDatas()
    return self.pickBonus
end

function GPBonusData:checkOpenLevel()
    if not GPBonusData.super.checkOpenLevel(self) then
        return false
    end

    local curLevel = globalData.userRunData.levelNum
    if curLevel == nil then
        return false
    end

    local needLevel = globalData.constantData.CHALLENGE_OPEN_LEVEL
    if needLevel > curLevel then
        return false
    end

    return true
end

function GPBonusData:checkCanOpenSale()
    --引导期间不弹出促销
    local guideIndex = self:getLCGuideIndex()
    if guideIndex < 6 then
        return false
    end
    --有buff时不弹出促销
    local buffLeftTime = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_LUCKYCHALLENGE_FAST)
    if buffLeftTime > 0 then
        return false
    end
    -- 上次弹出和本次弹出间隔大于 服务站返回值弹出
    if self.m_preTime then
        local tempTime = util_getCurrnetTime()
        local spaceTime = tempTime - self.m_preTime
        if globalData.constantData.CHALLENGE_SALE_TIMES then
            if spaceTime > globalData.constantData.CHALLENGE_SALE_TIMES then
                self.m_preTime = tempTime
            else
                return false
            end
        else
            release_print("CHALLENGE_SALE_TIMES-----is nil")
            return false
        end
    else
        self.m_preTime = util_getCurrnetTime()
    end
    return true
end

return GPBonusData
