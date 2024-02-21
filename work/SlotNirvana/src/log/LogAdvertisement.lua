--[[--
    广告弹出日志，
    action: Advertisement事件(区别于FreeCoins事件)
]]
local NetworkLog = require "network.NetworkLog"
local LogAdvertisement = class("LogAdvertisement",NetworkLog)

LogAdvertisement.m_type = nil
LogAdvertisement.m_adType = nil
LogAdvertisement.m_openSite = nil 
LogAdvertisement.m_openType = nil
LogAdvertisement.m_adStatus = nil 
LogAdvertisement.m_status = nil 
LogAdvertisement.m_rewardCoins = nil 
LogAdvertisement.m_dialyTimes = nil 

function LogAdvertisement:ctor()
      NetworkLog.ctor(self)
end

function LogAdvertisement:sendLogMessage( ... )
      local args = {...}
      NetworkLog.sendLogData(self)
end

-- 激励广告=Incentive
-- 插屏广告=Interstitial
function LogAdvertisement:setType(_type)
      self.m_type = _type
end

-- 1.界面弹出（含有视频按钮入口）=Push
-- 2.点击播放=Broadcast
-- 3.关闭广告=Close (sdk暂时没有暴露接口)
-- 4.奖励领取=Reward (服务器加)
function LogAdvertisement:setadType(adType)
    self.m_adType = adType
end

function LogAdvertisement:setOpenSite(site, noCleanParams)
      if not noCleanParams then
            self:cleanParams()
      end
      self.m_openSite = site
end

function LogAdvertisement:setOpenType(type)
      self.m_openType = type
end

function LogAdvertisement:setadStatus(status)
      self.m_adStatus = status
end

function LogAdvertisement:setStatus(status)
      self.m_status = status
end

function LogAdvertisement:setrewardCoins(coins)
      self.m_rewardCoins = coins
end

function LogAdvertisement:setdialyTimes(coins)
      self.m_dialyTimes = coins
end

function LogAdvertisement:cleanParams()
      self.m_type = nil
      self.m_adType = nil
      self.m_openSite = nil 
      self.m_openType = nil
      self.m_adStatus = nil 
      self.m_status = nil 
      self.m_rewardCoins = nil 
      self.m_dialyTimes = nil 
end

function LogAdvertisement:sendAdsLog()
      
      gL_logData:syncUserData()
      gL_logData:syncEventData("Advertisement")

      local adNum = 0
      if self.m_type == "Incentive" then
            adNum = globalData.adsRunData:getRewardVieoPlayTimes(self.m_openSite)
      elseif self.m_type == "Interstitial" then            
            adNum = -1
      end

      local messageData = {
            
            type = self.m_type,
            userType = globalData.adsRunData.p_userPurchaseType,
            adNum = adNum,
            adType = self.m_adType,

            openSite = self.m_openSite,
            openType = self.m_openType,
            adStatus = self.m_adStatus,
            status = self.m_status,
            rewardCoins = self.m_rewardCoins,
            dialyTimes = self.m_dialyTimes,
      }
      gL_logData.p_data = messageData
      self:sendLogData()
end

return  LogAdvertisement