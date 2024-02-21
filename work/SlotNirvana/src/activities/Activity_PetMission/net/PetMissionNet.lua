--[[
    -- 宠物7日任务
]]

local PetMissionConfig = require("activities.Activity_PetMission.config.PetMissionConfig")
local ActionNetModel = require("net.netModel.ActionNetModel")
local PetMissionNet = class("PetMissionNet", ActionNetModel)

-- 任务领奖
function PetMissionNet:sendMissionReward(_day, _id)
    local tbData = {
        data = {
            params = {
                day = _day,
                missionId = _id
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(PetMissionConfig.notify_mission_reward, {success = true, data = _result.result or {}})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(PetMissionConfig.notify_mission_reward)
    end

    self:sendActionMessage(ActionType.PetMissionMissionReward,tbData,successCallback,failedCallback)
end

-- Pass领奖
function PetMissionNet:sendPassReward(_idx)
    local tbData = {
        data = {
            params = {
                index = _idx
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(PetMissionConfig.notify_pass_reward, {success = true, data = _result.result or {}})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(PetMissionConfig.notify_pass_reward)
    end

    self:sendActionMessage(ActionType.PetMissionPointReward,tbData,successCallback,failedCallback)
end

-- 一键领奖
function PetMissionNet:sendAllReward()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    gLobalViewManager:addLoadingAnima(false, 1)

    local successCallback = function (_result)
        gLobalViewManager:removeLoadingAnima()        
        gLobalNoticManager:postNotification(PetMissionConfig.notify_all_reward, {success = true, data = _result.result or {}})
    end

    local failedCallback = function (errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        gLobalNoticManager:postNotification(PetMissionConfig.notify_all_reward)
    end

    self:sendActionMessage(ActionType.PetMissionAllReward,tbData,successCallback,failedCallback)
end

-- 宠物互动
function PetMissionNet:sendPetInteraction()
    local tbData = {
        data = {
            params = {
            }
        }
    }

    local successCallback = function (_result)

    end

    local failedCallback = function (errorCode, errorData)

    end

    self:sendActionMessage(ActionType.PetMissionPet,tbData,successCallback,failedCallback)
end

return PetMissionNet