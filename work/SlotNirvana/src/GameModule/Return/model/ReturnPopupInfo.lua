--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2023-04-19 11:13:05
]]

local ReturnPopupInfo = class("ReturnPopupInfo")

-- message ReturnPopupInfo {
--     optional int32 goneDays = 1;// 消失了多少天
--     optional int32 gameId = 2;// 新关
--     optional int64 maxCoins = 3;//历史最大持金
--     optional int64 allSpinTimes = 4;
--     optional int64 maximumWinMultiple = 5;
--   }
function ReturnPopupInfo:parseData(_netData)
    self.p_goneDays = _netData.goneDays
    self.p_gameId = _netData.gameId
    self.p_maxCoins = tonumber(_netData.maxCoins)
    self.p_allSpinTimes = tonumber(_netData.allSpinTimes)
    self.p_maximumWinMultiple = tonumber(_netData.maximumWinMultiple)

    self:initGameName()
    self:initGameIconPath()
end

-- 关卡名字
function ReturnPopupInfo:initGameName()
    local name = ""
    local levelInfo = globalData.slotRunData:getLevelInfoById(self.p_gameId)
    if levelInfo then
        name = levelInfo:getServerShowName()
    end
    self.m_gameName = name
end

-- 关卡头像
function ReturnPopupInfo:initGameIconPath()
    local levelName = globalData.slotRunData:getLevelName(self.p_gameId)
    local path = globalData.GameConfig:getLevelIconPath(levelName, LEVEL_ICON_TYPE.SMALL)
    self.m_gameIconPath = path
end 

function ReturnPopupInfo:getGoneDays()
    return self.p_goneDays
end

function ReturnPopupInfo:getGameId()
    return self.p_gameId
end

function ReturnPopupInfo:getMaxCoins()
    return self.p_maxCoins
end

function ReturnPopupInfo:getAllSpinTimes()
    return self.p_allSpinTimes
end

function ReturnPopupInfo:getWinMultiple()
    return self.p_maximumWinMultiple
end


function ReturnPopupInfo:getGameName()
    return self.m_gameName
end

function ReturnPopupInfo:getGameIconPath()
    return self.m_gameIconPath
end

return ReturnPopupInfo