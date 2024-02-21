--[[--
    引导日志
    游戏中所有引导的日志添加
    注意：
      有可能存在引导嵌套问题，所以在处理记录的时候，以KEY为主
      非强制性引导，需要在拒绝引导的时候清除打点【理由：检测非强制性引导存在的必要性，如无必要可优化掉】
    外部：只需要传guideIndex和对应的属性
]]

-- 注意：数据的顺序和游戏逻辑无关
local LOG_GUIDE_TYPE = {
      [1] = {typeName = "FristEnterGame", step = 4},       -- 1.第一次进入关卡
      [2] = {typeName = "NewbieTask", },           -- 2.新手任务
      [3] = {typeName = "LevelUpGuide", step = 2},         -- 3.升级引导
      [4] = {typeName = "BetTips", step = 2},              -- 4.首次Bet提醒
      [5] = {typeName = "GameBackLobbyGuide", step = 2},   -- 5.返回游戏大厅提示
      [6] = {typeName = "MoreGameGuide", step = 2},        -- 6.MoreGame引导
      [7] = {typeName = "DailyMissionGuide", step = 3},    -- 7.每日任务提示
      [8] = {typeName = "CardGuide", step = 6},            -- 8.Card引导
      [9] = {typeName = "StoreGuide", step = 4},           -- 9.免费领取商店金币
      [10] = {typeName = "AdvertisementGuide", step = 2},  -- 10.广告引导
}
local NetworkLog = require "network.NetworkLog"
local LogGuide = class("LogGuide",NetworkLog)

function LogGuide:ctor()
      NetworkLog.ctor(self)
      self.m_curGuideList = {} -- 目前正在进行的引导
end

function LogGuide:sendLogMessage( ... )
      local args = {...}
      NetworkLog.sendLogData(self)
end

function LogGuide:isGuideBegan(guideIndex)
      local GuideConfig = LOG_GUIDE_TYPE[guideIndex]
      if self.m_curGuideList[GuideConfig.typeName] then
            return true
      end
      return false
end

function LogGuide:cleanParams(guideIndex)
      local GuideConfig = LOG_GUIDE_TYPE[guideIndex]
      if self.m_curGuideList[GuideConfig.typeName] then
            self.m_curGuideList[GuideConfig.typeName] = nil
      end
end

-- GuideData.isForce
-- GuideData.isRepeat
-- GuideData.guideId
-- GuideData.taskId
function LogGuide:setGuideParams(guideIndex, params)
      local GuideConfig = LOG_GUIDE_TYPE[guideIndex]
      if not self.m_curGuideList[GuideConfig.typeName] then
            self.m_curGuideList[GuideConfig.typeName] = {}
      end
      if params then
            for k,v in pairs(params) do                  
                  self.m_curGuideList[GuideConfig.typeName][tostring(k)] = v
            end
      end
end

function LogGuide:sendGuideLog(guideIndex, guideProgress)      
      local GuideConfig = LOG_GUIDE_TYPE[guideIndex]
      local GuideData = self.m_curGuideList[GuideConfig.typeName]
      if not GuideData then
            print("------------------------------ not GuideData --------------------- ", guideIndex, guideProgress)
            return
      end

      gL_logData:syncUserData()
      gL_logData:syncEventData("Guide")

      local isNewUser = globalNoviceGuideManager:isNoobUsera()

      local result = nil
      if GuideData.result ~= nil then
            result = GuideData.result
      end

      local messageData = {
            sid = globalData.userRunData.uid .. "_" .. GuideConfig.typeName .."_"..os.time(),
            guideType = GuideConfig.typeName,
            guideStatus = (GuideData.isForce==true) and "Compel" or "Free",
            guideTrigger = isNewUser and "NewUser" or "Action",
            guideId = GuideData.guideId,
            taskId = GuideData.taskId,
            guideName = guideProgress,
            status = GuideData.isRepeat and 1 or 0,
            result = result,
      }
      dump(messageData, "----------------- messageData ---------------- ")
      gL_logData.p_data = messageData
      self:sendLogData()
      -- TODO:MAQUN 放在这里是否合适？要不要放在数据发送成功里？
      if GuideConfig and GuideConfig.step == guideProgress then
            self:cleanParams(guideIndex)
      end
end

return  LogGuide