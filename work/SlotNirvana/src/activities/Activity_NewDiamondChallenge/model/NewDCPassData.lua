--钻石挑战奖励界面数据
local NewDCPassLevelData = require("activities.Activity_NewDiamondChallenge.model.NewDCPassLevelData")
local NewDCPassData = class("NewDCPassData")
local ShopItem = require "data.baseDatas.ShopItem"

--[[
    message LuckyChallengeV2Pass {
        optional int32 totalExp = 1;
        optional int32 curExp = 2;
        repeated LuckyChallengeV2PassLevel levelList = 3;
    }
]]
function NewDCPassData:parseData(data)
    self.p_totalExp = data.totalExp
    self.p_curExp = data.curExp
    self.p_levelList = self:parsePassLevelData(data.levelList)
end

--[[
    message LuckyChallengeV2PassLevel {
        optional int32 level = 1;
        optional int32 exp = 2;
        optional string rewardType = 3;//奖励类型
        optional string coins = 4;
        repeated ShopItem items = 5;
        optional int32 miniGameType = 6;//小游戏类
        optional bool collected = 7;//是否领取
        optional string boxType = 8;//宝箱类型 NORMAL\HIGH\AVATAR_FRAME
    }
]]
function NewDCPassData:parsePassLevelData(data)
    local list = {}
    if data then
        for i, v in ipairs(data) do
            local temp = {}
            temp.level = v.level
            temp.exp = v.exp
            temp.rewardType = v.rewardType
            temp.coins = v.coins
            temp.items = self:parseItems(v.items)
            temp.miniGameType = v.miniGameType
            temp.collected = v.collected
            temp.boxType = v.boxType
            table.insert(list, temp)
        end
    end
    return list
end

-- 解析道具
function NewDCPassData:parseItems(items)
    local list = {}
    if items then
        for i, v in ipairs(items) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v)
            table.insert(list, shopItem)
        end
    end
    return list
end

function NewDCPassData:getTotalExp()
    return self.p_totalExp or 0
end

function NewDCPassData:getCurExp()
    return self.p_curExp or 0
end

function NewDCPassData:getLevelList()
    return self.p_levelList or {}
end

function NewDCPassData:geDataByLevelId(levelId)
    for i = 1, #self.p_levelList do
        if self.p_levelList[i].level == tonumber(levelId) then
            return self.p_levelList[i]
        end
    end
    return nil
end

function NewDCPassData:getCurLevel()
    for i, v in ipairs(self.p_levelList) do
        -- 获取当前等级
        if self.p_curExp >= v.exp then
            self.curLevel = tonumber(v.level)
            return self.curLevel
        end
    end
    return 0
end

-- 获取第一个未解锁的 HIGH 类型的奖励
function NewDCPassData:getHighRewardFirst()
    for i, v in ipairs(self.p_levelList) do
        local exp = self.p_levelList[i].exp
        if self.p_curExp < exp then
            local boxType = self.p_levelList[i].boxType
            if boxType == "HIGH" then
                return self.p_levelList[i]
            end
        end
    end
    return nil
end

return NewDCPassData
