-- 高倍场 小猫活动
local BaseActivityData = require("baseActivity.BaseActivityData")
local DeluxeClubCatActivityData = class("DeluxeClubCatActivityData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

local MAX_LEVEL = 3 -- 猫最大三级

function DeluxeClubCatActivityData:ctor()
    DeluxeClubCatActivityData.super.ctor(self)

    self.m_sourceCatInfoList = {}
    --[[
        catIdx: 此次喂猫 的 idx
        bUpgradeLevel: 此次喂猫 升级了
        bSpanLevel: 是否跨级 从 1级到3级
        sourceLevel: 源数据等级
        sourceTotalExp: 升级前的经验
        addExp: 此次喂猫增加的 经验
        rewardInfoList: 此次喂猫达到档位 可领取的奖励
    ]]
    self.m_feedCatGrowInfo = {}
end

function DeluxeClubCatActivityData:parseData(_data)
    _data = _data or {}
    BaseActivityData.parseData(self, _data)
    
    self.p_expire = _data.expire  -- 剩余秒数
    self.p_expireAt = _data.expireAt -- 过期时间
    self.p_activityId = _data.activityId -- 活动id
  
    -- 剩余的猫粮
    self.p_leftHighExpBag = _data.leftHighExpBag
    self.p_leftMiddleExpBag = _data.leftMiddleExpBag
    self.p_leftLowExpBag = _data.leftLowExpBag
    -- 猫粮经验
    self.p_unitHighExp = _data.unitHighExp or 0 -- 高级喵粮可以加的经验
    self.p_unitMiddleExp = _data.unitMiddleExp or 0  -- 中级喵粮可以加的经验
    self.p_unitLowExp = _data.unitLowExp or 0 -- 低级级喵粮可以加的经验

    local leftTime = _data.remaindSeconds or 0 --领取免费经验包剩余秒数
    local curTime = util_getCurrnetTime()
    self.p_freeFoodLeftTime = curTime + tonumber(leftTime)

    -- 猫咪信息
    self.p_catInfos = {}
    self.p_allCatMaxLvExp = true -- 所有的猫满级并且最大经验
    for k, serverInfo in ipairs(_data.cars or {}) do
        local catInfo = {}
        catInfo.catIdx = serverInfo.car  -- 猫的id
        catInfo.curLevel = serverInfo.level  -- 猫的等级
        catInfo.collectedNum = serverInfo.collectedNum  -- 已经领取的次数
        catInfo.curExp = serverInfo.exp  -- 猫的 当前经验

        catInfo.rewardInfoList, catInfo.totalExp = self:parseRewardInfo(serverInfo.poses) -- 所有的奖励, 猫的总经验
        catInfo.bMaxLvExp = catInfo.curLevel >= MAX_LEVEL and catInfo.curExp >= catInfo.totalExp -- 猫是否最大满级
        if not catInfo.bMaxLvExp then
            self.p_allCatMaxLvExp = false
        end

        -- 喂猫后 新数据刷新
        self:parseFeedCatGrowInfo(catInfo)
        self.p_catInfos[catInfo.catIdx] = catInfo
    end
    self.m_sourceCatInfoList = self.p_catInfos

    self.p_bGainFreeCatFood = _data.freeExpBag or false -- 是否每日免费领取
    self.p_fullLevelCoins = _data.fullLevelCoins or 0 -- 全部满级给的金币

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.DeluxeClubCatActivity}) --统一活动数据 更新就刷新UI(猫粮数量小红点)
end

-- 解析 所有奖励信息
function DeluxeClubCatActivityData:parseRewardInfo(_datas)
    local rewardInfoList = {}
    local totalExp = 0
    for k, serverRewardInfo in ipairs(_datas or {}) do
        local rewardInfo = {}
        rewardInfo.pos = serverRewardInfo.pos  -- 位置
        rewardInfo.needExp = serverRewardInfo.exp -- 需要的经验值
        rewardInfo.pre2NextGearNeedExp = serverRewardInfo.exp - totalExp -- 到下一档位奖励需要的经验值
        rewardInfo.coins = serverRewardInfo.coins  -- 奖励的金币
        rewardInfo.collected = serverRewardInfo.collected -- 是否领取
        rewardInfo.shopItemDataList = self:parseShopItemData(serverRewardInfo.items) -- 奖励的道具

        totalExp = rewardInfo.needExp
        rewardInfoList[serverRewardInfo.pos] = rewardInfo
    end

    return rewardInfoList, totalExp
end

-- 解析所有道具信息
function DeluxeClubCatActivityData:parseShopItemData(_items)
    local itemList = {}
    for _, data in ipairs(_items or {}) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)

        table.insert(itemList, shopItem)
    end

    return itemList
end

-- 喂猫后 新数据刷新
function DeluxeClubCatActivityData:parseFeedCatGrowInfo(_catInfo)
    if not self.m_sourceCatInfoList[_catInfo.catIdx] then
        return
    end
    local sourceCatInfo = self.m_sourceCatInfoList[_catInfo.catIdx]
    local sourceCurExp = sourceCatInfo.curExp
    local bLvUP = false
    if _catInfo.curLevel > sourceCatInfo.curLevel then
        bLvUP = true
        sourceCurExp = 0
        local upLv = _catInfo.curLevel - sourceCatInfo.curLevel
        self.m_feedCatGrowInfo.bSpanLevel = upLv > 1 -- 是否跨级
        self.m_feedCatGrowInfo.sourceLevel = sourceCatInfo.curLevel --跨级
        self.m_feedCatGrowInfo.bUpgradeLevel = true
        self.m_feedCatGrowInfo.sourceTotalExp = sourceCatInfo.totalExp
    end
    
    if _catInfo.curExp > sourceCurExp or bLvUP then
        -- 此次喂猫升级的经验
        self.m_feedCatGrowInfo.catIdx = _catInfo.catIdx
        self.m_feedCatGrowInfo.addExp = _catInfo.curExp - sourceCatInfo.curExp
        if bLvUP then
            self.m_feedCatGrowInfo.addExp = _catInfo.curExp + (sourceCatInfo.totalExp - sourceCatInfo.curExp)
        end
        -- 解析需要pop的奖励
        self.m_feedCatGrowInfo.rewardInfoList = self:getGainRewardInfo(sourceCatInfo.rewardInfoList, _catInfo.rewardInfoList, bLvUP)
    end
end

-- 本次喂猫 玩家需要弹板展示的奖励信息
function DeluxeClubCatActivityData:getGainRewardInfo(_sourceRewardList, _curRewardList, _bLvUP)
    local rewardInfoList = {}
    if _bLvUP then
        -- 升级后 档位信息就是新的等级的信息了，上一级的档位信息从source里取
        for _, rewardInfo in ipairs(_sourceRewardList) do
            local bCollected = rewardInfo.collected
            if not bCollected then
                rewardInfo["sourceType"] = "old"
                table.insert(rewardInfoList, rewardInfo)
            end
        end
        -- 升级后新数据的 
        for _, rewardInfo in ipairs(_curRewardList) do
            local bCollected = rewardInfo.collected
            if bCollected then
                rewardInfo["sourceType"] = "new"
                table.insert(rewardInfoList, rewardInfo)
            end
        end
        return rewardInfoList
    end

    -- 未升级就是 之前没领取现在领取了 的奖励
    local count = #_curRewardList
    for i = count, 1, -1 do
        local sourceInfo = _sourceRewardList[i]
        local curInfo = _curRewardList[i]
        if not sourceInfo.collected and curInfo.collected then
            curInfo["sourceType"] = "new"
            table.insert(rewardInfoList, curInfo)
        end

        if sourceInfo.collected then break end
    end
    
    return rewardInfoList
end
-- 本次喂猫增加更新的信息 - reset
function DeluxeClubCatActivityData:resetFeedCatGrowInfo(_rewarind)
    self.m_feedCatGrowInfo = {}
end
-- 本次喂猫增加更新的信息
function DeluxeClubCatActivityData:getFeedCatGrowInfo()
    return self.m_feedCatGrowInfo
end
-- 本次喂猫增加更新的信息 - delete 奖励信息（奖励是一个一个显示的）
function DeluxeClubCatActivityData:deleteFeedCatGrowRewardInfo(_rewardInfo)
    if not _rewardInfo or not next(_rewardInfo) then
        return
    end

    local rewardList = self.m_feedCatGrowInfo.rewardInfoList
    if not rewardList or not next(rewardList) then
        return
    end

    for i, info in ipairs(rewardList) do
        if _rewardInfo.pos == info.pos and
            _rewardInfo.sourceType == info.sourceType and 
            _rewardInfo.coins == info.coins then
            
            table.remove(rewardList, i)
            break
        end
    end

end

-- 获取猫的信息
function DeluxeClubCatActivityData:getCatInfos()
    return self.p_catInfos or {}
end
-- 获取某个猫的信息 ——idx
function DeluxeClubCatActivityData:getCatInfo(_idx)
    local infos = self:getCatInfos()
    
    return infos[_idx] or {}
end
-- 获取某个猫的经验进度
function DeluxeClubCatActivityData:getCatProg(_idx)
    local curCatInfo = self:getCatInfo(_idx)

    local curExp = curCatInfo.curExp or 0
    local totalExp = math.max(curCatInfo.totalExp or 1, 1)
    return math.min(curExp / totalExp, 1)
end

-- 获取猫的 高 猫粮
function DeluxeClubCatActivityData:getLeftHighExpBag()
    return self.p_leftHighExpBag or 0
end
-- 获取猫的 中 猫粮
function DeluxeClubCatActivityData:getLeftMiddleExpBag()
    return self.p_leftMiddleExpBag or 0
end
-- 获取猫的 低 猫粮
function DeluxeClubCatActivityData:getLeftLowExpBag()
    return self.p_leftLowExpBag or 0
end
function DeluxeClubCatActivityData:getFoodNum(_idx)
    if not _idx then return 0 end

    _idx = tonumber(_idx)
    if _idx == 1 then
        return self:getLeftLowExpBag()
    elseif _idx == 2 then
        return self:getLeftMiddleExpBag()
    elseif _idx == 3 then
        return self:getLeftHighExpBag()
    end

    return 0
end
function DeluxeClubCatActivityData:setFoodNum(_idx, _count)
    if not _idx then return 0 end
    _count = _count or 0

    _idx = tonumber(_idx)
    if _idx == 1 then
        self.p_leftLowExpBag = self.p_leftLowExpBag + _count
    elseif _idx == 2 then
        self.p_leftMiddleExpBag = self.p_leftMiddleExpBag + _count
    elseif _idx == 3 then
        self.p_leftHighExpBag = self.p_leftHighExpBag + _count
    end

    return 0
end
-- 获取单个喵粮的经验
function DeluxeClubCatActivityData:getFoodExp(_idx)
    if not _idx then return 0 end

    _idx = tonumber(_idx)
    if _idx == 1 then
        return self.p_unitLowExp
    elseif _idx == 2 then
        return self.p_unitMiddleExp
    elseif _idx == 3 then
        return self.p_unitHighExp
    end

    return 0
end

-- 获取距离领取免费猫粮的时间
function DeluxeClubCatActivityData:getLeftGainFreeFoodTime()
    if self.p_bGainFreeCatFood then
        return 0
    end
    
    local curTime = util_getCurrnetTime()
    local leftTime = self.p_freeFoodLeftTime - curTime
    return leftTime
end

-- 获取 全部满级给的金币
function DeluxeClubCatActivityData:getFullLVCoins()
    return self.p_fullLevelCoins or 0
end

-- 获取 所有 的猫粮数量
function DeluxeClubCatActivityData:getTotalFoodCount()
    local lowCount = self:getLeftLowExpBag()
    local middleCount = self:getLeftMiddleExpBag()
    local highCount = self:getLeftHighExpBag()

    local total = lowCount + middleCount + highCount
    return total
end

-- 检查所有的猫是否都最大 最满
function DeluxeClubCatActivityData:checkAllCatMaxLvExp()
    return self.p_allCatMaxLvExp
end

-- 检查猫是否都最大 最满
function DeluxeClubCatActivityData:checkCatMaxLvExp(_catIdx)
    local catInfo = self:getCatInfo(_catIdx)
    if not next(catInfo) then
        return false
    end

    return catInfo.bMaxLvExp
end

-- 检查 是否需要引导
function DeluxeClubCatActivityData:checkNeedGuide()
    local bNeedGuide = true
    local catInfos = self:getCatInfos()
    for i, info in ipairs(catInfos) do
        if info.curExp > 0 then
            bNeedGuide = false
            break
        end
    end

    return bNeedGuide
end

function DeluxeClubCatActivityData:getPopModule()
    --cxc 2021-07-08 17:01:17 活动配到1级，但是登录弹板 高倍场开启后再弹
    if globalData.userRunData.levelNum < globalData.constantData.CLUB_OPEN_LEVEL then
        return ""
    end
    return DeluxeClubCatActivityData.super.getPopModule(self)
end

return DeluxeClubCatActivityData