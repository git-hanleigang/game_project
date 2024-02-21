-- message LuckyChallengeTask {
    -- optional int32 type = 1; //任务类型
    -- repeated int64 params = 2; //任务参数
    -- optional int32 points = 3; //完成任务奖励的积分
    -- optional int64 taskId = 4; //任务id
    -- optional string description = 5; //每日任务描述
    -- optional string status = 6; //状态：COLLECTED、COLLECT、PROGRESSING
    -- repeated int64 process = 7; //任务进度
    -- optional int32 difficulty = 8; //任务难度
    -- optional int32 gameId = 9; //任务关卡Id
    -- optional string game = 10; //关卡
--   }

local LuckyChallengeTask = class("LuckyChallengeTask")
local ShopItem = util_require("data.baseDatas.ShopItem")
function LuckyChallengeTask:ctor()

end

function LuckyChallengeTask:parseData(data,isJson)
    self.type = data.type -- 类型
    self.params = {}--任务参数
    for i=1,#data.params do
        self.params[i] = data.params[i]
    end
    self.points = data.points --完成任务奖励的积分
    self.taskId = tonumber(data.taskId)--任务id
    self.description = data.description --每日任务描述
    self.status = data.status --状态：COLLECTED、COLLECT、PROGRESSING

    self.process = {}--任务进度
    for i=1,#data.process do
        self.process[i] = data.process[i]
    end
    self.difficulty = data.difficulty --任务难度
    self.gameId = data.gameId--任务关卡Id
    self.highGameId = data.highGameId--任务关卡Id

    self.game = data.game --关卡
    self.jump = data.jump
    self.icon = data.icon
    if data.extra then
        self.extra = data.extra
    end

    self.rewards = {}
    if data.rewards then
        for k ,v in ipairs(data.rewards) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v)
            table.insert(self.rewards,shopItem)
        end
    end
    -- self.lead = data.lead --任务跳转

    self.gems = tonumber(data.gems) -- 跳过需要消耗的钻石数量
end

return  LuckyChallengeTask