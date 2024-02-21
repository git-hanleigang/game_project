--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-06 14:41:03
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-06 14:56:59
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/model/NewUserExpandData.lua
Description: 扩圈系统 数据
--]]
local BaseGameModel = require("GameBase.BaseGameModel")
local NewUserExpandData = class("NewUserExpandData", BaseGameModel)

function NewUserExpandData:ctor()
    NewUserExpandData.super.ctor(self)
    
    self:setRefName(G_REF.NewUserExpand)
end

function NewUserExpandData:parseData(_data)
    if not _data then
        return 
    end

    self.m_gameType = _data.gameType or ""
    if self.m_gameType ~= "" then
        G_GetMgr(G_REF.NewUserExpand):setUserExpandEnabled(self.m_gameType, false, true)
    end

    self.m_gameStatus = _data.status or 0 -- 0未初始化 1已知来源等待初始化 2已开启 3已关闭 4直接关闭
    if _data:HasField("pyi") then
        -- 跑马灯游戏
        self:parseMarqueeGameData(_data.pyi, "MiniGameMarqueeData")
    elseif _data:HasField("tq") then
        -- 弹球游戏
        self:parsePlinkoGameData(_data.tq, "")
    end

    self.m_expandType = _data.initType or 0 --激活标记 0未初始化 1登录时激活 2客户端激活
end

-- 跑马灯游戏
function NewUserExpandData:parseMarqueeGameData(_gameData)
    if self.m_gameData then
        self.m_gameData:parseData(_gameData)
        return
    end
    
    local Model = util_require("GameModule.NewUserExpand.model.marquee.MiniGameMarqueeData")
    self.m_gameData = Model:create()
    self.m_gameData:parseData(_gameData)
end

-- 弹球游戏
function NewUserExpandData:parsePlinkoGameData(_gameData)
    if self.m_gameData then
        self.m_gameData:parseData(_gameData)
        return
    end
    
    local Model = util_require("GameModule.NewUserExpand.model.plinko.MiniGamePlinkoData")
    self.m_gameData = Model:create()
    self.m_gameData:parseData(_gameData)
end

function NewUserExpandData:getGameData()
    return self.m_gameData
end

function NewUserExpandData:isRunning()
    return (self.m_gameStatus and self.m_gameData and self.m_expandType and self.m_gameStatus < 3 and self.m_gameData:checkGameEnabled() and self.m_expandType ~= 0)
end

--激活标记 0未初始化 1登录时激活 2客户端激活
function NewUserExpandData:getExpandType()
    return self.m_expandType or 0
end
function NewUserExpandData:checkIsClientActiveType()
    return self.m_expandType == 2
end
function NewUserExpandData:checkIsServerActiveType()
    return self.m_expandType == 1
end

function NewUserExpandData:getServerGameType()
    return self.m_gameType
end

return NewUserExpandData