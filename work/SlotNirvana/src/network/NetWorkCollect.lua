
---
-- 处理 游戏内的spin 消息同步等， 处理
--

local NetWorkCollect = class("NetWorkCollect",require "network.NetWorkBase")

NetWorkCollect.startSpinTime = nil
NetWorkCollect.levelName = nil

function NetWorkCollect:ctor( )

end


---
-- 点击collect 请求collect_result 数据

function NetWorkCollect:sendActionData_Collect(messageData)
      if gLobalSendDataManager:isLogin() == false then
            return
      end

      local actType = nil

      self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()

      if messageData and type(messageData)=="table" then
            if messageData.msg == MessageDataType.MSG_MISSION_COMLETED then
                  actType=ActionType.MissionCollect
            end
      end

      local actionData = self:getSendActionData(actType)

      actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
      actionData.data.exp = globalData.userRunData.currLevelExper
      actionData.data.level = globalData.userRunData.levelNum
      actionData.data.vipLevel = globalData.userRunData.vipLevel
      actionData.data.vipPoint = globalData.userRunData.vipPoints
      actionData.data.version = self:getVersionNum()
      local extraData = {}
      extraData.missionType = messageData.taskType
      extraData.taskId = messageData.taskId
      actionData.data.extra = cjson.encode(extraData)

      if DEBUG >= 2 then
            printInfo("========   显示messageData的数据   ========")
            printInfo(actionData.action)
            printInfo(actionData.game)
            printInfo(actionData.platform)
            printInfo(actionData.data.balanceCoinsNew)
            printInfo(actionData.data.exp)
            printInfo(actionData.data.level)
            printInfo("----------"..actionData.data.version)
            printInfo("========   显示messageData的数据  END   ========")
      end

      self:sendMessageData(actionData,self.collectResultSuccessCallFun,self.collectResultFaildCallFun)
end

---
-- 点击collect 请求collect_result 数据

function NetWorkCollect:sendActionData_CollectNew(messageData)
      if gLobalSendDataManager:isLogin() == false then
            return
      end

      local actType = nil

      self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()

      if messageData and type(messageData)=="table" then
            if messageData.msg == MessageDataType.MSG_MISSION_COMLETED then
                  actType=ActionType.DailyTaskAwardCollect
            end
      end

      local actionData = self:getSendActionData(actType)

      actionData.data.balanceCoinsNew = get_integer_string(globalData.userRunData.coinNum)
      actionData.data.exp = globalData.userRunData.currLevelExper
      actionData.data.level = globalData.userRunData.levelNum
      actionData.data.vipLevel = globalData.userRunData.vipLevel
      actionData.data.vipPoint = globalData.userRunData.vipPoints
      actionData.data.version = self:getVersionNum()
      local extraData = {}
      extraData.missionType = messageData.taskType
      extraData.taskId = messageData.taskId
      actionData.data.extra = cjson.encode(extraData)

      if DEBUG >= 2 then
            printInfo("========   显示messageData的数据   ========")
            printInfo(actionData.action)
            printInfo(actionData.game)
            printInfo(actionData.platform)
            printInfo(actionData.data.balanceCoinsNew)
            printInfo(actionData.data.exp)
            printInfo(actionData.data.level)
            printInfo("----------"..actionData.data.version)
            printInfo("========   显示messageData的数据  END   ========")
      end

      self:sendMessageData(actionData,self.collectResultSuccessCallFun,self.collectResultFaildCallFun)
end


--- 成功回调
function NetWorkCollect:collectResultSuccessCallFun(resultData)
      gLobalViewManager:removeLoadingAnima()

      --dump(resultData,"spin回调的数据")
      local result = resultData.result
      if DEBUG == 2 then
            release_print(result)
            print(result)
      end

      if resultData:HasField("simpleUser") == true then
            globalData.syncSimpleUserInfo(resultData.simpleUser)
      end

      if resultData:HasField("activity") == true then
            globalData.syncActivityConfig(resultData.activity)
      end

      local collectData = util_cjsonDecode(result)
      if collectData then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GET_COLLECTRESULT,{true,collectData})
      end
end

--- 失败回调
function NetWorkCollect:collectResultFaildCallFun(errorCode)
      gLobalViewManager:removeLoadingAnima()
      gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GET_COLLECTRESULT,
            {false,errorCode})
end

return NetWorkCollect