--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-06-27 15:34:07
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-06-27 15:37:23
FilePath: /SlotNirvana/src/data/clanData/ClanRushTaskData.lua
Description: 公会rush任务数据
--]]
local ClanRushTaskData = class("ClanRushTaskData")
local ClanRushMemberData = util_require("data.clanData.ClanRushMemberData")
local ClanConfig = util_require("data.clanData.ClanConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ClanRushTaskData:ctor(_idx)
    self.m_idx = _idx or 0
    self.m_taskId = 0 --任务Id
    self.m_bFinish = false --奖励发放标记 0未发放 1已发放
    self.m_params = 0 --任务参数
    self.m_curCount = 0 --任务进度
    self.m_text = "" --任务描述
    self.m_actName = "" --关联活动
    self.m_coins = 0 --金币奖励
    self.m_rewardList = {} --物品奖励 (包含金币)
    self.m_membersList = {} --成员贡献
    self.m_limitCount = 0 --玩家贡献限制数量
    self.m_taskType = 0 -- 活动任务类型
end

function ClanRushTaskData:parseData(_data)
    if not _data then
        return
    end

    self.m_taskId = _data.taskId --任务Id (1001 大活动消耗道具， 1002 quest完成关卡， 1003 集卡收集赠送)
    self.m_bFinish = _data.reward --奖励发放标记
    self.m_params = tonumber(_data.params) or 0 --任务参数
    self.m_curCount = tonumber(_data.progress) or 0 --任务进度
    self.m_text = _data.text or "" --任务描述
    self.m_actName = _data.activityName or "" --关联活动
    self.m_coins = tonumber(_data.coins) or 0 --金币奖励
    self:parseItemList(_data.items or {}) --物品奖励
    self:parseMemberList(_data.members or {}) --成员贡献
    self.m_limitCount = tonumber(_data.limit) or self.m_params --玩家贡献限制数量
    self:parseTaskType()
end

function ClanRushTaskData:parseItemList(_list)
    self.m_rewardList = {}
    self.m_itemList = {}
    if self.m_coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_coins, 4))
        table.insert(self.m_rewardList, itemData)
    end
    for _, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self.m_rewardList, shopItem)
        table.insert(self.m_itemList, shopItem)
    end
end

function ClanRushTaskData:parseMemberList(_list)
    self.m_membersList = {}

    for _, data in ipairs(_list) do
        local memberData = ClanRushMemberData:create(self.m_coins, self.m_itemList)
        memberData:parseData(data)
        table.insert(self.m_membersList, memberData)
    end
end

function ClanRushTaskData:parseTaskType()
    self.m_taskType = 0 -- 活动任务类型
    local taskIdStr = tostring(self.m_taskId)
    if taskIdStr == "1001" and string.len(self.m_actName) > 0 then
        -- 1001 大活动消耗道具
        self.m_taskType = ClanConfig.RushTaskType.ACT
    elseif taskIdStr == "1002" then
        -- 1002 quest完成关卡
        self.m_taskType = ClanConfig.RushTaskType.QUEST
    elseif taskIdStr == "1003" then
        -- 1003 集卡收集赠送
        self.m_taskType = ClanConfig.RushTaskType.CHIP
    end
end
function ClanRushTaskData:getTaskType()
    return self.m_taskType
end

-- 获取任务 类型对应的图片
function ClanRushTaskData:getTaskIconPath()
    local taskIdStr = tostring(self.m_taskId)
    if self.m_taskType == ClanConfig.RushTaskType.ACT then
        -- 1001 大活动消耗道具  新手quest里也有相同显示大活动图片的功能用一个
        local iconStr = "icon_" .. (string.split(self.m_actName, "Activity_")[2] or "") .. ".png"
        local iconPath = "CommonTaskIcon/" .. iconStr
        return iconPath
    elseif self.m_taskType == ClanConfig.RushTaskType.QUEST then
        -- 1002 quest完成关卡
        local themeName = "Activity_Quest"
        local iconStr = ""
        local questNewData =  G_GetMgr(ACTIVITY_REF.QuestNew):getRunningData() -- 新版quest
        local questData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData() -- 正常quest
        if questNewData then
            themeName = questNewData:getThemeName()
            iconStr = "icon_QuestNew_" .. (string.split(themeName, "Activity_")[2] or "") .. ".png"
        elseif questData then
            themeName = questData:getThemeName()
            iconStr = "icon_" .. (string.split(themeName, "Activity_")[2] or "") .. ".png"
        end
        local iconPath = "CommonTaskIcon/" .. iconStr
        return iconPath
    elseif self.m_taskType == ClanConfig.RushTaskType.CHIP then
        -- 1003 集卡收集赠送
        return "CommonTaskIcon/icon_chip.png"
    end
end

-- 获取任务 任务idx
function ClanRushTaskData:getTaskIdx()
    return self.m_idx
end
-- 获取任务 任务id
function ClanRushTaskData:getTaskId()
    return tostring(self.m_taskId)
end
-- 获取任务 任务活动名
function ClanRushTaskData:getTaskActName()
    return self.m_actName
end

-- 获取任务 当前完成 数量
function ClanRushTaskData:getCurCount()
    return self.m_curCount
end

-- 获取任务 需要完成 数量
function ClanRushTaskData:getNeedCount()
    return self.m_params
end

-- 获取任务 奖励
function ClanRushTaskData:getRewardList()
    return self.m_rewardList
end

-- 获取任务 各成员贡献信息
function ClanRushTaskData:getMemberList()
    return self.m_membersList
end

-- 检查任务是否完成
function ClanRushTaskData:checkTaskFinish()
    return self.m_bFinish
end

-- 玩家贡献限制数量
function ClanRushTaskData:getLimitValue()
    return self.m_limitCount
end

-- 检查玩家自己有没有参与任务
function ClanRushTaskData:checkSelfIsJoinTask()
    for i, memberData in ipairs(self.m_membersList) do
        if memberData:checkIsBMe() and memberData:getProgress() > 0 then
            return true
        end
    end

    return false
end 

return ClanRushTaskData