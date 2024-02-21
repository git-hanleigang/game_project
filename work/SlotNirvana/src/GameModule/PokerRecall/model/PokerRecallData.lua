--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2021-12-10 15:08:26
]]

local BaseGameModel = require("GameBase.BaseGameModel")
local PokerRecallData = class("PokerRecallData", BaseGameModel)
local PokerRecallGameData = util_require("GameModule.PokerRecall.model.PokerRecallGameData")

function PokerRecallData:ctor()
    PokerRecallData.super.ctor(self)
    self:setRefName(G_REF.PokerRecall)
    self.pokerGameList = {}
    -- self.m_curIdx = nil
end
--解析数据
function PokerRecallData:parseData(_data)
    -- if self.m_curIdx ~= nil then
    --     local GameId = self.pokerGameList[self.m_curIdx]:getGameId()
    -- end

    self.pokerGameList = {}
    if _data and #_data.pokerResult > 0 then
        --解析数据
        for i = 1, #_data.pokerResult do
            local gameData = PokerRecallGameData:create()
            gameData:parseData(_data.pokerResult[i])
            self.pokerGameList[i] = gameData
        end
    end

    self.m_pokerRecallStatus = _data.pokerRecallStatus

    -- if self.m_curIdx ~= nil then
    --     for i=1,#self.pokerGameList do
    --         if GameId == self.pokerGameList[i]:getGameId() then
    --             self.m_curIdx = i
    --         end
    --     end
    -- end

    -- if _data and #_data > 0 then
    --     self.pokerGameList = {}
    --     --解析数据
    --     for i = 1, #_data do
    --         local gameData = PokerRecallGameData:create()
    --         gameData:parseData(_data[i])
    --         self.pokerGameList[i] = gameData
    --     end
    --     release_print("--------开始解析miniGame中小游戏数据:1")
    -- elseif (_data and #_data <= 0) then
    --     release_print("--------开始解析miniGame中小游戏数据，此时没有数据")
    --     print("--------开始解析miniGame中小游戏数据，此时没有数据")
    --     self.m_curIdx = nil
    --     self.pokerGameList = {}
    -- end
end
function PokerRecallData:onRegister()
    self:freshCurPickGameIdx()
end

-- 刷新当前小游戏索引
function PokerRecallData:freshCurPickGameIdx()
    -- for i = 1, #self.pokerGameList do
    --     local pokerData = self.pokerGameList[i]
    --     if pokerData and pokerData:getIsPlaying() then
    --         self.m_curIdx = i
    --     end
    -- end
end

-- --TODO
-- function PokerRecallData:setCurPokerGameId(_id)
--     if self.pokerGameList and #self.pokerGameList > 0 then
--         for i = 1, #self.pokerGameList do
--             local gameData = self.pokerGameList[i]
--             if _id == gameData:getGameId() then
--                 self.m_curIdx = i
--                 return true
--             end
--         end
--     else
--         return false
--     end
-- end

function PokerRecallData:getCurPokerGameDataById(_id)
    if self.pokerGameList and #self.pokerGameList > 0 then
        for i = 1, #self.pokerGameList do
            local gameData = self.pokerGameList[i]
            if _id == gameData:getGameId() then
                return gameData
            end
        end
    end

    return nil
end

function PokerRecallData:getLastPokerGameData()
    if self.pokerGameList and #self.pokerGameList > 0 then
        return self.pokerGameList[#self.pokerGameList]
    end
    return nil
end

-- --获取玩家当前小游戏数据
-- function PokerRecallData:getCurPokerGameData()
--     if not self.m_curIdx then
--         if #self.pokerGameList > 0 then
--             self.m_curIdx = #self.pokerGameList
--         else
--             return nil
--         end
--     end
--     return self.pokerGameList[self.m_curIdx]
-- end

--获取所有数据
function PokerRecallData:getPokerRecallGameDatas()
    return self.pokerGameList
end

function PokerRecallData:getCurPokerRecallGameIdx()
    -- return self.m_curIdx or 0
    for i = 1, #self.pokerGameList do
        local pokerData = self.pokerGameList[i]
        if pokerData and pokerData:getIsPlaying() then
            return i
        end
    end
    return 0
end

-- function PokerRecallData:getGameId()
--     local curGameData = self:getCurPokerGameData()
--     if curGameData then
--         local gameId = curGameData:getGameId()
--         return gameId
--     end
--     return nil
-- end
-- --缓存一下当前游戏ID
-- function PokerRecallData:resetGameDataIndex()
--     if self.m_curIdx then
--         self.m_curIdx = nil
--     end
-- end

function PokerRecallData:getPokerRecallStatus()
    return self.m_pokerRecallStatus 
end

return PokerRecallData
