--[[
    author:{author}
    time:2019-04-18 21:53:40
]]
local BuffConfigData = class("BuffConfigData")

BuffConfigData.p_allBuffs = nil -- 所有 buff

function BuffConfigData:ctor()
end

function BuffConfigData:parseData(data)
    if self.p_allBuffs == nil then
        self.p_allBuffs = {}
    end
    for i = 1, #data, 1 do
        local buff = {}
        buff.buffID = data[i].id -- buff 唯一ID
        buff.buffType = data[i].type -- buff 类型
        buff.buffDescription = data[i].description -- buff 描述
        buff.buffDuration = data[i].duration -- buff 持续时间
        buff.buffExpire = data[i].expire -- buff 剩余时间
        buff.buffMultiple = data[i].multiple -- buff 加成
        buff.buffSysTime = util_getCurrnetTime()
        self.p_allBuffs[buff.buffType] = buff
        --临时代码检测赠送的buff是否到期
        if buff.buffID == 900102 then
            local curTime = util_getCurrnetTime()
            curTime = curTime + buff.buffExpire
            gLobalDataManager:setNumberByField("quest_temp_buff_end", curTime)
        end
    end
    print("...")
    util_nextFrameFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MULEXP_END)
        end
    )
end
--[[
      QuestXP:table: 0x0be86aa0
buffDescription:"QUESTbuff"
buffDuration:1440
buffExpire:8868
buffID:200002
buffMultiple:"1.5"
buffSysTime:1575552731
buffType:"QuestXP"
]]
function BuffConfigData:getBuffInfoByType(type)
    if self.p_allBuffs == nil then
        return nil
    end

    return self.p_allBuffs[type]
end
-- 清除buff数据 byType
function BuffConfigData:clearBuffInfoByType(type)
    if self.p_allBuffs == nil then
        return nil
    end

    self.p_allBuffs[type] = nil
end

function BuffConfigData:getBuffInfoById(buffId)
    if self.p_allBuffs == nil then
        return nil
    end
    for buffType, buffData in pairs(self.p_allBuffs) do
        if buffData.buffID == buffId then
            return buffData
        end
    end
end

--加层解析
function BuffConfigData:analysisMultiple(data, curLevel)
    if data == nil or data == "" then
        return 1
    end

    --0-30;1-2;2-2;3-2;4-2;5-2;6-2;7-2;8-2;9-2
    local list = util_split(data, ";")
    if list == nil then
        return 1
    end

    --只有一个值
    if #list == 1 then
        return tonumber(data)
    end

    local ret = {}
    for i = 1, #list do
        local strTemp = list[i]
        local listTemp = util_split(strTemp, "-")
        if listTemp ~= nil and #listTemp > 1 then
            local key = listTemp[1]
            local value = listTemp[2]
            ret[key] = value
        end
    end

    --获取当前等级
    if curLevel == nil then
        local levelNum = globalData.userRunData.levelNum or 1
        curLevel = levelNum + 1
    end
    curLevel = tostring(curLevel)

    local levelLen = #curLevel
    for k, v in pairs(ret) do
        local kLen = #k
        if levelLen >= kLen then
            local tempKey = string.sub(curLevel, -kLen, -1)
            if tempKey == k then
                return tonumber(v)
            end
        end
    end

    return 1
end

function BuffConfigData:getBuffMultipleByType(type, curLevel)
    if self.p_allBuffs == nil then
        return 1
    end
    local buff = self.p_allBuffs[type]
    local buffDeluxe = nil
    local buffQuest = nil
    if type == BUFFTYPY.BUFFTYPY_DOUBLE_EXP then
        buffDeluxe = self.p_allBuffs[BUFFTYPY.BUFFTYPE_DELUXE_EXP]
        buffQuest = self.p_allBuffs[BUFFTYPY.BUFFTYPE_MULTIPLE_EXP]
    end
    local multiple = 1
    local curTime = util_getCurrnetTime()
    if buff ~= nil then
        if (curTime - buff.buffSysTime) <= buff.buffExpire then
            multiple = self:analysisMultiple(buff.buffMultiple, curLevel)
        end
    end

    if buffDeluxe ~= nil then
        if (curTime - buffDeluxe.buffSysTime) <= buffDeluxe.buffExpire then
            multiple = multiple + (buffDeluxe.buffMultiple - 1)
        end
    end

    return multiple
end

function BuffConfigData:getBuffLeftTimeByType(type)
    if self.p_allBuffs == nil then
        return 0
    end
    local buff = self.p_allBuffs[type]
    local buffDeluxe = nil
    local buffQuest = nil
    if type == BUFFTYPY.BUFFTYPY_DOUBLE_EXP then
        buffDeluxe = self.p_allBuffs[BUFFTYPY.BUFFTYPE_DELUXE_EXP]
        buffQuest = self.p_allBuffs[BUFFTYPY.BUFFTYPE_MULTIPLE_EXP]
    end
    local leftTime = 0
    local curTime = util_getCurrnetTime()
    if buff ~= nil then
        local times = curTime - buff.buffSysTime
        leftTime = buff.buffExpire - times
    end
    if buffDeluxe ~= nil then
        local times = curTime - buffDeluxe.buffSysTime
        leftTime = math.max(leftTime, buffDeluxe.buffExpire - times)
    end

    return leftTime
end

function BuffConfigData:getBuffDataByType(type)
    if self.p_allBuffs == nil then
        return nil
    end
    local leftTime = self:getBuffLeftTimeByType(type)
    if leftTime <= 0 then
        return nil
    end

    local buff = self.p_allBuffs[type]
    if buff ~= nil then
        return buff
    end

    return nil
end

--获取buff类型顺序
function BuffConfigData:getBuffTypeIndex()
    local buffs = {}
    buffs[#buffs + 1] = BUFFTYPY.BUFFTYPY_DOUBLE_EXP
    buffs[#buffs + 1] = BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN
    buffs[#buffs + 1] = BUFFTYPY.BUFFTYPY_LEVEL_BOOM
    buffs[#buffs + 1] = BUFFTYPY.BUFFTYPY_LEVEL_BURST
    -- buffs[#buffs+1] = BUFFTYPY.BUFFTYPE_DELUXE_EXP
    -- buffs[#buffs+1] = BUFFTYPY.BUFFTYPE_MULTIPLE_EXP
    return buffs
end

--检查是否有buff
function BuffConfigData:checkBuff()
    local buffs = self:getBuffTypeIndex()
    for i = 1, #buffs do
        local v = buffs[i]
        local multipleExp = self:getBuffMultipleByType(v)
        local exp_leftTime = self:getBuffLeftTimeByType(v)

        if multipleExp and multipleExp > 1 and exp_leftTime > 0 then
            return true
        end
    end

    return false
end

--获取buff叠加 金币加成的值
function BuffConfigData:getAllCoinBuffMultiple(curLevel, specialLevel)
    local nMultiple = 0

    --双倍经验
    local multipleExp = self:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_LEVEL_UP_DOUBLE_COIN, curLevel)
    if multipleExp and multipleExp > 1 then
        nMultiple = nMultiple + multipleExp
    end

    --levelBoom活动 buff加成
    local newLevel = specialLevel or curLevel
    local multipleExp1 = self:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_LEVEL_BOOM, newLevel)
    if multipleExp1 and multipleExp1 > 1 then
        nMultiple = nMultiple + multipleExp1
    end

    --商城中levelboom道具 buff加成
    local multipleExp2 = self:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_LEVEL_BURST, curLevel)
    if multipleExp2 and multipleExp2 > 1 then
        nMultiple = nMultiple + multipleExp2
    end
    --特殊处理如果没有倍数返回1倍 否则所有倍数相加 具体为什么问策划、、、
    if nMultiple == 0 then
        nMultiple = 1
    end
    return nMultiple
end

-- 清除上个赛季的集卡buff
function BuffConfigData:clearPreCardSeasonBuff()
    self:clearBuffInfoByType(BUFFTYPY.BUFFTYPE_CARD_LOTTO_COIN_BONUS) -- LOTTO结算时，金币加成
    self:clearBuffInfoByType(BUFFTYPY.BUFFTYPE_CARD_NADO_REWARD_BONUS) -- NADO机结算时，金币、高倍场点数、vip点数加成
    self:clearBuffInfoByType(BUFFTYPY.BUFFTYPE_CARD_COMPLETE_COIN_BONUS) -- 章节以及赛季集齐结算时，金币加成
    self:clearBuffInfoByType(BUFFTYPY.BUFFTYPE_GEMSHOP_GEM_BONUS) -- 钻石商城购买时，钻石加成
    self:clearBuffInfoByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_PACKAGE_BONUS) -- 金币商城购买时，卡包数量翻倍，
    self:clearBuffInfoByType(BUFFTYPY.BUFFTYPE_COINSHOP_CARD_STAR_BONUS) -- 金币商城购买时，卡包内卡牌的星级提升
end

return BuffConfigData
