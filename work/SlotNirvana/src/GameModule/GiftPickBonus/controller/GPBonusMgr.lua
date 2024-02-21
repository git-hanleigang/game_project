--[[
  
    author:{author}
    time:2021-11-24 17:48:22
]]
local TEST_MODE = false -- 测试模式，使用本地数据

require("GameModule.GiftPickBonus.config.GPBonusCfg")
local GPBonusNet = require("GameModule.GiftPickBonus.net.GPBonusNet")
local GPBonusMgr = class("GPBonusMgr", BaseGameControl)

function GPBonusMgr:ctor()
    GPBonusMgr.super.ctor(self)

    self:setRefName(G_REF.GiftPickBonus)

    self.m_starPickNet = GPBonusNet:getInstance()

    if TEST_MODE == true then
        self:parseData(GPBonusCfg.TEST_DATA)
        self:getData():setCurPickGameIdx(1)
    end
end

function GPBonusMgr:parseData(data)
    if not data then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("GameModule.GiftPickBonus.model.GPBonusData"):create()
        _data:parseData(data)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
end

-- 掉落时二次确认面板
function GPBonusMgr:showConfirmLayer(_closeCall)
    if not self:isCanShowLayer() then
        return nil
    end

    if gLobalViewManager:getViewByName("GPBonusConfirmLayer") ~= nil then
        return nil
    end

    local view = util_createView("Activity.GiftPickBonus.GPBonusConfirmLayer", _closeCall)
    view:setName("GPBonusConfirmLayer")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function GPBonusMgr:showMainLayer(bonusId)
    if not self:isCanShowLayer() then
        return nil
    end

    self:setCurPickGameId(bonusId)

    local view = util_createView("Activity.GiftPickBonus.GPBonusMainLayer", bonusId)
    view:setName("GPBonusMainLayer")

    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return view
end

function GPBonusMgr:closeMainLayer()
    local _mainLayer = gLobalViewManager:getViewByName("GPBonusMainLayer")
    if _mainLayer then
        _mainLayer:closeUI()
    end
end

function GPBonusMgr:pickGameOver()
    self:closeMainLayer()
end

function GPBonusMgr:enterGame()
    if self:checkIsFirstShow() then
        -- 第一次打开时候展示start界面后面不再展示
        self:showStartUI()
    else
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GP_BONUS_START_UI_OVER)
    end
end

function GPBonusMgr:showStartUI()
    if not self:isCanShowLayer() then
        return nil
    end

    local view =
        util_createView(
        "Activity.GiftPickBonus.GPBonusStartLayer",
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GP_BONUS_START_UI_OVER)
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)
end

function GPBonusMgr:showOverUI()
    if not self:isCanShowLayer() then
        return nil
    end

    local view =
        util_createView(
        "Activity.GiftPickBonus.GPBonusOverLayer",
        self:getTotalwinCoins(),
        function()
            -- if not tolua.isnull(self) and self.closeUI then
            --     self:closeUI()
            -- end
        end
    )
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_POPUI)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
end

function GPBonusMgr:isHasPlaying()
    local _psData = self:getData()
    if _psData then
        local _curIdx = _psData:getCurPickGameIdx()
        return _curIdx > 0
    end
    return false
end

function GPBonusMgr:getCurPickGameData()
    local _psData = self:getData()
    if _psData then
        return _psData:getCurPickGameData()
    else
        return nil
    end
end

function GPBonusMgr:setCurPickGameId(bonusId)
    if not bonusId then
        return nil
    end

    local _psData = self:getData()
    if _psData then
        return _psData:setCurPickGameId(bonusId)
    else
        return nil
    end
end

-- function GPBonusMgr:checkStatus()
--     local _curData = self:getCurPickGameData()
--     if not _curData then
--         return false
--     end

--     return _curData:checkStatus()
-- end

function GPBonusMgr:getTotalwinCoins()
    local _curData = self:getCurPickGameData()
    if not _curData then
        return 0
    end

    return _curData:getTotalwinCoins()
end

function GPBonusMgr:isFinished()
    -- if not G_GetActivityDataByRef(ACTIVITY_REF.LuckyChallenge) then
    --     return false
    -- end
    -- for i = 1, #self.m_localPickPos do
    --     if self.m_starData[i].type == GPBonusCfg.PICK_TYPE.GameOver then
    --         return true
    --     end
    -- end
    -- return false
    local _curData = self:getCurPickGameData()
    if not _curData then
        return false
    end

    return _curData:isFinished()
end

-- 节点是否被点击
function GPBonusMgr:isNodePicked(nodeIndex)
    -- for i = 1, #self.m_localPickPos do
    --     if tonumber(nodeIndex) == tonumber(self.m_localPickPos[i]) then
    --         return true, i
    --     end
    -- end
    -- return false
    local _curData = self:getCurPickGameData()
    if not _curData then
        return false
    end

    return _curData:isPicked(nodeIndex), nodeIndex
end

-- 获取节点的数据
function GPBonusMgr:getStarDataByIndex(nodeIndex, isAutoTurn)
    -- local index
    -- if isAutoTurn then
    --     local _, _index = self:isNodeUnPick(nodeIndex)
    --     _index = _index + #self.m_localPickPos
    --     index = _index
    -- else
    --     local _, _index = self:isNodePicked(nodeIndex)
    --     index = _index
    -- end
    -- return self.m_starData[index]
    local _curData = self:getCurPickGameData()
    if not _curData then
        return nil
    end

    return _curData:getBoxInfo(nodeIndex)
end

-- 获得节点位置显示的类型
function GPBonusMgr:getNodeInitShowType(nodeIndex)
    -- local isPicked, pickNum = self:isNodePicked(nodeIndex)
    -- local showType = nil
    -- if isPicked then
    --     local starData = self.m_starData[pickNum]
    --     showType = starData.type
    -- else
    --     if self:hasGameOver() then
    --         -- 显示结果
    --         -- showType = starData.type
    --         local _, count = self:isNodeUnPick(nodeIndex)
    --         count = count + #self.m_localPickPos
    --         local starData = self.m_starData[count]
    --         showType = starData.type
    --     else
    --         -- 显示星星
    --         showType = GPBonusCfg.PICK_TYPE.Star
    --     end
    -- end
    -- return showType
    local starInfo = self:getStarDataByIndex(nodeIndex)
    if starInfo then
        return starInfo:getType()
    else
        return nil
    end
end

-- 节点是否自动被翻开了
function GPBonusMgr:isNodeAutoPicked(nodeIndex)
    -- 游戏结束才有
    if self:isFinished() then
        -- 没有被手动点过的
        if not self:isNodePicked(nodeIndex) then
            return true
        end
    end
    return false
end

function GPBonusMgr:getJackpot()
    local _curData = self:getCurPickGameData()
    if not _curData then
        return 0
    end

    return _curData:getJackpot()
end

function GPBonusMgr:isJackpotLight(jackpotType)
    -- for i = 1, #self.m_localPickPos do
    --     if self.m_starData[i].type == jackpotType then
    --         return true
    --     end
    -- end
    -- return false
    local _curData = self:getCurPickGameData()
    if not _curData then
        return false
    end

    return _curData:isJackpotLight(jackpotType)
end

-- 进入小游戏时判断是不是第一次打开
function GPBonusMgr:checkIsFirstShow()
    local showParam = gLobalDataManager:getNumberByField("SP_PICKGAME_RULE", 0)
    if showParam == 0 then
        gLobalDataManager:setNumberByField("SP_PICKGAME_RULE", 1)
        return true
    end
    return false
end

function GPBonusMgr:getStarData()
    local _data = self:getData()
    if not _data then
        return nil
    else
        return _data:getBoxs()
    end
end

-- 获取当前没有点击的位置
-- function GPBonusMgr:getUnPickPos()
--     local data = {}
--     for i = 1, 20 do
--         if not self:isNodePicked(i) then
--             data[#data + 1] = i
--         end
--     end
--     return data
-- end

-- function GPBonusMgr:isNodeUnPick(nodeIndex)
--     for i = 1, #self.m_unPickPos do
--         if nodeIndex == self.m_unPickPos[i] then
--             return true, i
--         end
--     end
--     return false
-- end

function GPBonusMgr:getPickCount()
    return self.m_pickCount
end

-- function GPBonusMgr:getLocalPickPos()
--     return self.m_localPickPos
-- end

----------------------------------- 本地缓存数据处理 >>> ------------------------------------------
function GPBonusMgr:table2String(data)
    local cacheStr = table.concat(data, "-")
    return cacheStr
end
function GPBonusMgr:string2Table(str)
    local data = {}
    if str ~= "" then
        data = string.split(str, "-")
    end
    return data
end

function GPBonusMgr:getLocalDataKey()
    return "StarPick_Pos" .. "-" .. tostring(self:getSeasonId()) .. "_" .. self.m_pickRewardId
end

-- 每次点击pick后都记录一次数据到缓存
-- 记录点击的位置
-- 记入缓存
-- function GPBonusMgr:writeLocalData(pickPos)
--     self.m_localPickPos[#self.m_localPickPos + 1] = pickPos
--     self.m_unPickPos = self:getUnPickPos()
--     -- pick次数计数
--     self.m_pickCount = #self.m_localPickPos
--     -- 记入缓存
--     local str = self:table2String(self.m_localPickPos)
--     gLobalDataManager:setStringByField(self:getLocalDataKey(), str)

-- end

-- 读取缓存
-- function GPBonusMgr:readLocalData()
--     local str = gLobalDataManager:getStringByField(self:getLocalDataKey(), "")
--     local data = self:string2Table(str)
--     self.m_localPickPos = {}
--     if #data > 0 then
--         for i = 1, #data do
--             self.m_localPickPos[#self.m_localPickPos + 1] = data[i]
--         end
--     end

--     self.m_unPickPos = self:getUnPickPos()
--     -- pick次数计数
--     self.m_pickCount = #self.m_localPickPos
-- end

-- 清除缓存数据
-- function GPBonusMgr:cleanLocalData()
--     gLobalDataManager:setStringByField(self:getLocalDataKey(), "")

-- end
----------------------------------- 本地缓存数据处理 <<< ------------------------------------------

-- 工具函数
function GPBonusMgr:getNFromM(sourceData, N)
    -- 从M个数中取出N个数
    -- local sourceData = {1,3,4,6,8,12,14}
    local resultData = {}

    local M = #sourceData
    -- local N = math.max(1, math.floor(M*0.3))

    if M == 0 then
        return resultData
    end

    local tempSource = {}
    for i = 1, M do
        tempSource[#tempSource + 1] = {sourceData[i], false}
    end

    local randomFunc = nil
    randomFunc = function()
        local rIndex = math.random(1, M)
        local rData = tempSource[rIndex]
        if rData and rData[2] == false then
            rData[2] = true
            resultData[#resultData + 1] = rData[1]
        else
            randomFunc()
        end
    end
    for i = 1, N do
        randomFunc()
    end

    return resultData
end

-- 点击星星
function GPBonusMgr:onPickStar(nPosIdx)
    local _data = self:getData()
    if not _data then
        return
    end

    local _gameData = _data:getCurPickGameData()
    local _gameId = _gameData:getId()
    if not _gameId then
        return
    end

    local successFunc = function(resultData)
        printInfo("==onPickStar==success==")
        -- 开箱子事件
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PICK_BONUS_INDEX, {posIdx = nPosIdx})
    end

    local failedFunc = function()
        printInfo("==onPickStar==failed==")
    end
    self.m_starPickNet:requestPickStar(_gameId, nPosIdx, successFunc, failedFunc)
end

return GPBonusMgr
