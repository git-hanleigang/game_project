--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2020-06-19 17:57:43
]]
local GameCrazeData = class("GameCrazeData")

--映射
GD.CrazeType = {
    FIRST_MISSON = "GC11001",
}

GameCrazeData.m_ActivityDatas = nil
GameCrazeData.m_BuffDatas = nil

function GameCrazeData:ctor()
    self.m_ActivityDatas = {}
    self.m_BuffDatas = {}
 end

function GameCrazeData:parseData( data )       
    if data.activities ~= nil then
        self:reFreshActivityDatas( data.activities ) 
    end
    if data.buffs ~= nil then
        self:reFreshBuffDatas( data.buffs )
    end

    --刷新界面
    gLobalNoticManager:postNotification(ViewEventType.GAMECRAZE_REFRESH_BUFF)
end

function GameCrazeData:reFreshActivityDatas( activityData ) 
    local oldActId = {}
    for i=1,#self.m_ActivityDatas do
        local actDataId = self.m_ActivityDatas[i].p_activityName
        oldActId[tostring(actDataId)] = true
    end

    -- self.m_ActivityDatas = {}
    for i=1,#activityData do
        local data = activityData[i]
        local dataTmp = self:getActivityDataById(data.activityId ) 
        local localData = {}
        local newData = true
        if dataTmp then
            localData = dataTmp
            newData = false
        end

        localData.p_activityId    = data.activityId           --活动id
        localData.p_activityName    = data.activityName         --活动名称

        local ids = {}
        for j=1,#data.gameIds do                                    
            ids[#ids + 1]               = data.gameIds[j]           
        end

        localData.p_gameIds         = ids                                      --关卡ID
        localData.p_expireAt        = tonumber(data.expireAt )                 --截止时间
        localData.p_expire          = tonumber(data.expire )                   --剩余时间
        localData.p_completed       = data.completed                           --完成标识
        localData.p_reward          = data.reward                              --奖励发放标识
        localData.p_type            = data.type                                --任务类型0：只能完成一次，1：可完成多次
        localData.p_new             = false

        if not oldActId[tostring(localData.p_activityName)] or newData then
            localData.p_new         = true                                     --标记为新act
        end

        if newData then
            self.m_ActivityDatas[#self.m_ActivityDatas + 1] = localData
        end
    end 
end
 
function GameCrazeData:reFreshBuffDatas( buffData )

    local oldBuffIds = {}
    for i=1,#self.m_BuffDatas do
        local buffDataId = self.m_BuffDatas[i].p_gameIds
        oldBuffIds[tostring(buffDataId)] = true
    end

    self.m_BuffDatas = {}
    for i=1,#buffData do
        local data = buffData[i]
        local localBuffData = {}
        localBuffData.p_game              = data.game                   --关卡名称
        localBuffData.p_gameId            = data.gameId                 --关卡ID
        localBuffData.p_expireAt          = tonumber(data.expireAt)     --截止时间
        localBuffData.p_expire            = tonumber(data.expire)       --剩余时间
        if not oldBuffIds[tostring(localBuffData.p_gameId)] then
            localBuffData.p_new           = true                        --标记为新返回的Levelbuff
        end
        self.m_BuffDatas[#self.m_BuffDatas + 1] = localBuffData
    end      
end

function GameCrazeData:getActivityDatas() 
    return self.m_ActivityDatas
end

function GameCrazeData:getNewActivityDatas() 
    local data = nil
    for i=1,#self.m_ActivityDatas do
        local activityData = self.m_ActivityDatas[i]
        if activityData.p_new then
            if not data then
                data = {}
            end
            data[#data + 1] = activityData
        end
    end
    return data 
end

function GameCrazeData:getActivityDataById(activityId) 
    local data = nil
    for i=1,#self.m_ActivityDatas do
        local activityData = self.m_ActivityDatas[i]
        if activityData.p_activityId == activityId then
            data = activityData
            break
        end
    end
    return data 
end

function GameCrazeData:getActivityDataByName(activityName) 
    local data = nil
    for i=1,#self.m_ActivityDatas do
        local activityData = self.m_ActivityDatas[i]
        if activityData.p_activityName == activityName then
            data = activityData
            break
        end
    end
    return data 
end

function GameCrazeData:getNewBuffDatas() 
    local data = nil
    for i=1,#self.m_BuffDatas do
        local buffData = self.m_BuffDatas[i]
        if buffData.p_new then
            if not data then
                data = {}
            end
            data[#data + 1] = buffData
        end
    end
    return data 
end

function GameCrazeData:getBuffDataById(buffId) 
    local data = nil
    for i=1,#self.m_BuffDatas do
        local buffData = self.m_BuffDatas[i]
        if tonumber(buffData.p_gameId) == buffId then
            data = buffData
            break
        end
    end
    return data 
end

function GameCrazeData:getBuffDataByName(buffName) 
    local data = nil
    for i=1,#self.m_BuffDatas do
        local buffData = self.m_BuffDatas[i]
        if buffData.p_game == buffName then
            data = buffData
            break
        end
    end
    return data 
end

function GameCrazeData:getAllBuffDatas() 
   if self.m_BuffDatas and #self.m_BuffDatas > 0 then
       return self.m_BuffDatas 
   end 
   return nil
end
 
return GameCrazeData