local NotifyManager = class("NotifyManager")
NotifyManager._instance = nil
NotifyManager.m_notifyNode = nil
NotifyManager.m_selfInfo = nil

NotifyManager.m_nameList = nil
NotifyManager.m_levelList = nil
NotifyManager.m_interval = nil

--间隔时间
NotifyManager.m_timeInterval = nil
--时间权重
local TIME_WEIGHT = 8 --到达触发时间后0.08概率推送
--总权重
local MAX_WEIGHT = 1000


function NotifyManager:getInstance()
    if NotifyManager.m_instance == nil then
        NotifyManager.m_instance = NotifyManager.new()
    end
    return NotifyManager.m_instance
end

function NotifyManager:ctor()
    self.m_interval = 0
    self.m_timeInterval = math.random(50,70)
end

function NotifyManager:timeUpdate()
    self.m_interval = self.m_interval+1
    if self.m_interval >= self.m_timeInterval then
        self.m_interval = 0
        self.m_timeInterval = math.random(50,70)
        self:checkTimeNotify()
    end
end

function NotifyManager:checkTimeNotify()
    local weight = math.random(1,MAX_WEIGHT)
    if weight<TIME_WEIGHT then 
        globalData.jackpotRunData:notifyRandomJackpot()
    end
end

function NotifyManager:parseData(content) 
    self.m_nameList= content[1]
    self.m_levelList = {}
    
    local levels = globalData.slotRunData.p_machineDatas
    if not levels then
        return
    end
    for i=1,#levels do
        local levelData = levels[i]
        if levelData.p_showJackpot and levelData.p_showJackpot == 1 then
            self.m_levelList[levelData.p_id]=levelData.p_levelName
        end
    end
end

--获得jackpot需要的参数信息 头像路径 关卡图标路径 玩家名字 jackpot索引 金币数量
function NotifyManager:getInfo(headPath,levelPath,name,jackpotIndex,coins)
    local info = {}
    info.headPath=headPath
    info.levelPath =levelPath
    info.name=name
    info.jackpotText = jackpotIndex
    info.coins = util_formatCoins(coins,50)
    info.isJackpot = true
    return info
end

--兼容老版本
function NotifyManager:showSelfNotify(coins,jackpotIndex)
    -- globalData.jackpotRunData:notifySelfJackpot(coins,jackpotIndex)
end

--自己中了jackpot
function NotifyManager:showNewSelfNotify(coins,jackpotIndex)
    -- local levelPath ="Notify/Other/GameScreen"..globalData.slotRunData.gameModuleName..".png"
    -- self.m_selfInfo = self:getInfo("head/head_self.png",levelPath,"Me",jackpotIndex,coins)
    -- self:showNotify()
end

--其他人中了jackpot
function NotifyManager:showOtherNotify(gameID,jackpotID,jackpotPool)
    -- local levelName = self.m_levelList[gameID]
    -- if not levelName then
    --     return
    -- end
    -- local jackpotIndex = globalData.jackpotRunData:getJackpotIndex(gameID,jackpotID)
    -- local newLevelName = string.sub(levelName,11,-1)
    -- local headPath=self.m_headPaths[math.random(1,#self.m_headPaths)]
    -- local levelPath = "Notify/Other/GameScreen"..newLevelName..".png"
    -- local name =self.m_nameList[math.random(1,#self.m_nameList)]
    -- local info = self:getInfo(headPath,levelPath,name,jackpotIndex,jackpotPool)
    -- self:showNotify(info)
end
--显示jackpot 弹版
function NotifyManager:showNotify(info) 
    -- if not self.m_notifyNode then
    --     --自己中了jackpot优先级最高
    --     if self.m_selfInfo then
    --         self.m_notifyNode = util_createView("views.notify.NotifyNode",self.m_selfInfo)
    --         self.m_selfInfo= nil
    --     else
    --         self.m_notifyNode = util_createView("views.notify.NotifyNode",info)
    --     end
    --     gLobalViewManager:getViewLayer():addChild(self.m_notifyNode,ViewZorder.ZORDER_UI)
    --     local pos =gLobalViewManager:getViewLayer():convertToNodeSpace(cc.p(display.width-210,display.height-60))
    --     self.m_notifyNode:setPosition(pos)
    --     self.m_notifyNode:setOverFunc(function()
    --         self:overNotify()
    --     end)
    -- end
end

function NotifyManager:overNotify(info) 
    -- self.m_notifyNode = nil
    -- if self.m_selfInfo then
    --     self:showNotify()
    --     self.m_selfInfo= nil
    -- end
end

return NotifyManager
