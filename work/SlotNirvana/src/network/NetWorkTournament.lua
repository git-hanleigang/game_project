



---
-- 处理Tournament 相关消息
--

local NetWorkTournament = class("NetWorkTournament",require "network.NetWorkBase")


function NetWorkTournament:ctor( )
      
end


----------------------------------Tournament相关接口------------------------
---请求tournament数据

function NetWorkTournament:sendQueryTournament(tourName,successCallBack,failCallBack)
      local tourData = GameProto_pb.TournamentQueryRequest()
      tourData.tournamentName = tourName
      tourData.version = 2
      
      local bodyData = tourData:SerializeToString()
      local httpSender = xcyy.HttpSender:createSender()
  
      local url = DATA_SEND_URL .. RUI_INFO.TOURNAMENT_QUERY -- 拼接url 地址
  
      local success_call_fun = function(responseTable)
          local resData = GameProto_pb.Tournament()
          local responseStr = self:parseResponseData(responseTable)
          resData:ParseFromString(responseStr)
          if resData.status == 1 or resData.status == 2 then
              -- 锦标赛运行中
            --   printInfo("xcyy :Tournament查询成功 ")
              gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOURNAME_QUERY,
                  resData)
          else
              printInfo("xcyy :Tournament返回失败 failed")
  
          end
          httpSender:release()
      end
      local faild_call_fun = function(errorCode , errorData)
          -- 根据errorCode 做处理
          httpSender:release()
          printInfo("xcyy :Tournament返回失败 failed")
          -- 同步消息失败--
      end
  
      local offset = self:getOffsetValue()
      local token = globalData.userRunData.loginUserData.token
      local serverTime = globalData.userRunData.p_serverTime
  
      httpSender:sendMessage(bodyData,offset,token,url,serverTime,success_call_fun,faild_call_fun)
end
  --------------------------------------------------------------------------

return NetWorkTournament