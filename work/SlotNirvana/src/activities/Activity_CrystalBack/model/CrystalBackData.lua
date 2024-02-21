--[[--
    宝石返还
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local CrystalBackData = class("CrystalBackData", BaseActivityData)

-- message MergeBack {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated MergeBackStage stage = 4;//累充阶段
--     optional string totalBackPercent = 5;//总返回比例
--     optional int32 rechargeAmount = 6;//累充金额
--     optional int64 useItemCount = 7; //使用合成道具数量
--     optional int64 backItemCount = 8; //返还合成道具数量
--   }
function CrystalBackData:parseData(_data)
    CrystalBackData.super.parseData(self, _data)

    self.p_totalBackPercent = _data.totalBackPercent
    self.p_rechargeAmount = _data.rechargeAmount
    self.p_useItemCount = tonumber(_data.useItemCount)
    self.p_backItemCount = tonumber(_data.backItemCount)
    self.p_stage = self:parseStage(_data.stage)
end

-- message MergeBackStage {
--     optional int32 stage = 1;//阶段
--     optional int32 amount = 2;//金额
--     optional String backPercent = 3;//返回比例
--   }
function CrystalBackData:parseStage(_data)
    local stageData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local tempData = {}
            tempData.p_stage = v.stage
            tempData.p_amount = v.amount
            tempData.p_backPercent = v.backPercent
            table.insert(stageData, tempData)
        end
    end
    return stageData
end

function CrystalBackData:getTotalPercent()
    return self.p_totalBackPercent
end

function CrystalBackData:getRechargeAmount()
    return self.p_rechargeAmount
end

function CrystalBackData:getUseItemCount()
    return self.p_useItemCount
end

function CrystalBackData:getBackItemCount()
    return self.p_backItemCount
end

function CrystalBackData:getStage()
    return self.p_stage
end

return CrystalBackData
