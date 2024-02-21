local SysRewardManager = class("SysRewardManager")
SysRewardManager.m_instance = nil

SysRewardManager.m_rewardTable = nil

function SysRewardManager:getInstance()
    if SysRewardManager.m_instance == nil then
        SysRewardManager.m_instance = SysRewardManager.new()
    end
    return SysRewardManager.m_instance
end

-- 构造函数
function SysRewardManager:ctor()
    self.m_rewardTable = {}
    local ok, reward =
        pcall(
        function()
            return require("manager.SysRewardConfig")
        end
    )
    if ok then
        self.m_rewardTable = reward
    else
        local table = gLobalResManager:parseCsvDataByName("Csv/Csv_systemReward.csv")
        for k, v in ipairs(table) do
            local rewardID = v[1]
            local rewardType = v[2]
            local rewardNum = v[3]
            local describetion = v[4]
            local rewardPath = v[5]
            self.m_rewardTable[rewardID] = {type = rewardType, num = rewardNum, describe = describetion, path = rewardPath}
        end
    end
end

function SysRewardManager:isOpenReward(rewardID)

    if globalData.signInfo == nil then
        globalData.signInfo={}
        --globalData.signInfo.appCode = util_convertAppCodeToNumber(xcyy.GameBridgeLua:getAppVersionCode()) --暂不开放
        --globalData.appCode = 1
        globalData.signInfo.fbReward = ""
    end
    if rewardID == "FBReward" then --facebook绑定奖励
        if globalData.userRunData.fbUdid ~= nil and globalData.userRunData.fbUdid ~= "" then
            --globalData.userRunData.fbUdid = "guhongshuai11"
            if globalData.signInfo.fbReward == nil then
                globalData.signInfo.fbReward = ""
            end
            if globalData.signInfo.fbReward ~= globalData.userRunData.fbUdid then
                gLobalSendDataManager:getLogFeature():sendFBCoins(globalData.userRunData.FB_LOGIN_FIRST_REWARD)
                return true
            end
        end
    elseif rewardID == "newVersion"  then
        if self.m_rewardTable[rewardID] == nil then
            return false
        end
        release_print("globalData.signInfo.appCode ---> " .. tostring(globalData.signInfo.appCode))
        local appCode = util_getAppVersionCode() or 0
        if globalData.signInfo.appCode == nil or globalData.signInfo.appCode == "" then
            globalData.signInfo.appCode = appCode
            gLobalSendDataManager:getNetWorkFeature():sendActionLoginReward(globalData.signInfo)
            return false
        end
        
        local clientV = string.gsub(tostring(appCode), "%.", "")
        local serverV = string.gsub(tostring(globalData.signInfo.appCode), "%.", "")
        if tonumber(clientV) > tonumber(serverV) then
            gLobalSendDataManager:getLogFeature():sendNewVersion(self.m_rewardTable[rewardID].num,globalData.signInfo.appCode)
            globalData.signInfo.appCode = appCode
            gLobalSendDataManager:getNetWorkFeature():sendActionLoginReward(globalData.signInfo)
            return true
        end
    elseif rewardID == "NewUserProtectReward" then
        -- 新用户金币不足奖励
        if self.m_rewardTable[rewardID] == nil then
            return false
        end

        local newUserReward = globalData.userRunData:getNewUserReward()
        return newUserReward > 0
    end

    return false
end

function SysRewardManager:showView(rewardID, param)
    return util_createView("views.sysReward.sysRewardView",self.m_rewardTable[rewardID],param,rewardID)
end

return SysRewardManager
