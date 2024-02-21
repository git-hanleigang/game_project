-- 处理数据和消息
local ScratchWinnerShopManager = class("ScratchWinnerShopManager")
local ScratchWinnerCardConfig = require "CodeScratchWinnerSrc.ScratchWinnerCardSrc.ScratchWinnerCardConfig"

ScratchWinnerShopManager._instance = nil
function ScratchWinnerShopManager:getInstance()
    if not self._instance then
		self._instance = ScratchWinnerShopManager.new()
	end
	return self._instance
end
function ScratchWinnerShopManager:removeInstance()
    ScratchWinnerShopManager._instance = nil
end

function ScratchWinnerShopManager:ctor()
    self:addObservers()
end

function ScratchWinnerShopManager:initMachine(_machine)
    self.m_machine = _machine
end

function ScratchWinnerShopManager:initData()
    self.m_shopData = {}
    --[[ --卡片在商店的数据
        m_shopData = {
            {
                --必有
                name           = "",    --卡片名称/类型
                jpIndex        = 0,     --奖池索引
                unlockBetLevel = 0,     --解锁档位

                --额外
                lineInfo       = {
                    {{赢钱线位置1, 赢钱线位置2, 赢钱线位置3,}, 赢钱倍数}
                },
            },
        }
    ]]

    self.m_bagData = {
        index = 0,
        list  = {}
    }
    --[[ --卡片在背包时的数据
        m_bagData = {
            index = 0,
            list  = {
                name       = "",
                lines      = {},
                reels      = {},
                bingoReels = {},
            }
        }
    ]]

    --请求状态
    self.m_isWaitData = false
    --激励视频结束回调
    self.m_adsVedioCallBack = nil
end
function ScratchWinnerShopManager:addObservers()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:scratchWinnerResultCallFun(params)
        end,
        ViewEventType.NOTIFY_GET_SPINRESULT
    )
    --激励视频
    gLobalNoticManager:addObserver(self,function(self, params)
        if nil ~= self.m_adsVedioCallBack then
            self.m_adsVedioCallBack()
            self.m_adsVedioCallBack = nil
        end
    end, "ads_vedio")
end

--[[
    商店列表相关
]]
function ScratchWinnerShopManager:upDataShopData(_shopData)
    self.m_shopData = {}

    for _cardName,_cardData in pairs(_shopData) do
        local data = {
            name           = _cardName,
            jpIndex        = _cardData.jpIndex,
            unlockBetLevel = _cardData.unlockBetLevel,
        }
        if _cardData.lineInfo then
            data.lineInfo = clone(_cardData.lineInfo)
        end
        if _cardData.signalMulti then
            data.signalMulti = {}
            for _sSymbolType,_iMulti in pairs(_cardData.signalMulti) do
                local iSymbolType = tonumber(_sSymbolType)
                data.signalMulti[iSymbolType] = _iMulti
            end
        end
        
        table.insert(self.m_shopData, data)
    end

    --排序
    table.sort(self.m_shopData, function(_cardA, _cardB)
        local configA = self:getCardConfig(_cardA.name)
        local configB = self:getCardConfig(_cardB.name)
        -- 按照 order 排列
        if configA.order ~= configB.order then
            return configA.order < configB.order
        end

        return false
    end)
end
function ScratchWinnerShopManager:getShopListData()
    local dataList = {}
    for i,v in ipairs(self.m_shopData) do
        table.insert(dataList, v)
    end
    --插入 commingSoon 
    local commingSoonData = {
        name = "commingSoon",
        jpIndex = 0,
        unlockBetLevel = 0,
    }
    table.insert(dataList, commingSoonData)

    return dataList
end
--[[
    背包相关
]]
function ScratchWinnerShopManager:upDataBagData(_selfData)
    local list  = {}
    if nil ~= _selfData.bagData then
        for i,v in ipairs(_selfData.bagData) do
            local data = {
                index      = i,
                name       = v.kind,
                lines      = clone(v.lines),
            }
            -- 全部转换为一维数组
            if nil ~= v.reels then
                if "table" == type(v.reels[1]) then
                    data.reels = {}
                    for i,v in ipairs(v.reels) do
                        for ii,vv in ipairs(v) do
                            table.insert(data.reels, vv)
                        end
                    end
                else
                    data.reels = clone(v.reels)
                end
            end
            if nil ~= v.bingoReels then
                if "table" == type(v.bingoReels[1]) then
                    data.bingoReels = {}
                    for i,v in ipairs(v.bingoReels) do
                        for ii,vv in ipairs(v) do
                            table.insert(data.bingoReels, vv)
                        end
                    end
                else
                    data.bingoReels = clone(v.bingoReels)
                end
            end
        
            list[i] = data
        end
    end
    self.m_bagData.index = _selfData.index or 0
    self.m_bagData.list  = list
end
function ScratchWinnerShopManager:getBagListData()
    local dataList = {}
    for i,v in ipairs(self.m_bagData.list) do
        table.insert(dataList, v)
    end

    return dataList
end
--购买返回的打印列表
function ScratchWinnerShopManager:getBagExportList()
    local bagList = self:getBagListData()
    -- 反序
    table.sort(bagList, function(_cardA, _cardB)
        local configA = self:getCardConfig(_cardA.name)
        local configB = self:getCardConfig(_cardB.name)
        -- 按照 order 排列
        if configA.order ~= configB.order then
            return configA.order > configB.order
        end
        return false
    end)
    --分类
    local dataList = {}
    local cardName =""
    for i,_cardData in ipairs(bagList) do
       if cardName ~= _cardData.name then
            table.insert(dataList, {})
            cardName = _cardData.name
       end
       
       table.insert(dataList[#dataList], _cardData)
       
    end

    return dataList
end
--获取一种卡片在背包的数量
function ScratchWinnerShopManager:getCardCount(_name)
    local curIndex = self.m_bagData.index
    local count    = 0
    for _index,v in ipairs(self.m_bagData.list) do
        if curIndex <= _index and _name == v.name then
            count = count + 1
        end
    end
    return count
end
-- bonusGame的数据列表内jackpot没有增长量 赢钱应该以最新的数据包内为准
function ScratchWinnerShopManager:getCardWinCoinsByIndex(_cardIndex, _winType)
    local winCoins = 0
    local cardBagData = self:getOneCardBagData(_cardIndex)
    if not cardBagData then
        return winCoins
    end

    local lines = cardBagData.lines
    for i,v in ipairs(lines) do
        if not _winType or _winType == v.kind then
            winCoins = winCoins + v.amount
        end
    end

    return winCoins
end
--[[
    单张卡片的 商店数据 背包数据 配置
]]
function ScratchWinnerShopManager:getCardShopData(_cardName)
    for i,v in ipairs(self.m_shopData) do
        if _cardName == v.name then
            return v
        end
    end
end
function ScratchWinnerShopManager:getOneCardBagData(_cardIndex, _bMsg)
    for _index,v in ipairs(self.m_bagData.list) do
        if _index == _cardIndex then
            return v
        end
    end
    --bugly-日志-05.27
    if _bMsg then
        local sMsg = string.format("[ScratchWinnerShopManager:getOneCardBagData] index=(%d) max=(%d)",_cardIndex, #self.m_bagData.list)
        release_print(sMsg)
        release_print(debug.traceback())
    end
end
function ScratchWinnerShopManager:getCardConfig(_cardName)
    local config = nil
    for i,_cardConfig in ipairs(ScratchWinnerCardConfig.CardList) do
        if _cardName == _cardConfig.name then
            return _cardConfig
        end
    end

    return config
end

--[[
    所有和服务器交互的接口
    购买请求、刮卡请求、清空背包请求
]]
function ScratchWinnerShopManager:sendBuyData(_buyList)
    if not self:checkBuyState(_buyList, {}) then
        return
    end

    self.m_isWaitData = true

    -- gLobalNoticManager:postNotification("ScratchWinnerMachine_sendBuyData", {_buyList})
    local sMsg = "[ScratchWinnerShopManager:sendBuyData] 发送购买数据"
    print(sMsg)
    release_print(sMsg)

    local messageData = {
        msg  = MessageDataType.MSG_BONUS_SPECIAL,
        data = {
            betIndex = globalData.slotRunData:getCurBetIndex(),
            purchase = self:getSendBuyData(_buyList),
        }
    }
    self.m_machine:requestSpinResult(messageData)
end
function ScratchWinnerShopManager:sendReceiveRewardData()
    if self.m_isWaitData or #self.m_bagData.list < 1 or not self.m_bagData.list[self.m_bagData.index] then
        return
    end
    -- 金币不足
    if not self:checkRewardState() then
        self.m_adsVedioCallBack = function()
            -- 金币充足了
            if self:checkRewardState() then
                self:sendReceiveRewardData()
            -- 金币还是不充足
            else
                self:sendClearBagData()
            end
        end
        self.m_machine:operaUserOutCoins()
        local sMsg = "[ScratchWinnerShopManager:sendReceiveRewardData] 金币不足"
        print(sMsg)
        release_print(sMsg)
        return
    else
        self.m_adsVedioCallBack = nil
    end
    
    self.m_isWaitData = true

    local cardData = self.m_bagData.list[self.m_bagData.index]
    -- gLobalNoticManager:postNotification("ScratchWinnerMachine_sendReceiveReward", {cardData.name})
    local sMsg = "[ScratchWinnerShopManager:sendReceiveRewardData] 发送领取奖励"
    print(sMsg)
    release_print(sMsg)

    local messageData = {
        msg  = MessageDataType.MSG_SPIN_PROGRESS,
        data = {},
    }
    self.m_machine:requestSpinResult(messageData)
end
function ScratchWinnerShopManager:sendClearBagData()
    if self.m_isWaitData then
        return
    end
    if #self.m_bagData.list < 1 or not self.m_bagData.list[self.m_bagData.index] then
        return
    end

    self.m_isWaitData = true
    print("[ScratchWinnerShopManager:sendClearBagData] 发送清理背包")
    release_print("[ScratchWinnerShopManager:sendClearBagData] 发送清理背包")

    local messageData = {
        msg  = MessageDataType.MSG_BONUS_SPECIAL,
        data = {
            isClear = 1,
        },
    }
    self.m_machine:requestSpinResult(messageData)
end
function ScratchWinnerShopManager:scratchWinnerResultCallFun(_param)
    if  _param[1] ~= true then
        return
    end

    self.m_isWaitData = false

    local result   = _param[2].result
    local list  = result.selfData.bagData or {}
    -- 购买返回 
    local isBuy    = #list > 0 and 1 == result.selfData.index
    -- 刮卡返回
    local isReward = #list > 0 and result.selfData.index > 1
    -- 清理返回
    local isClear  = 0 == #list or 0 == result.selfData.index

    print("[ScratchWinnerShopManager:scratchWinnerResultCallFun] 消息返回 购买|领取|清理",isBuy, isReward, isClear)
    release_print("[ScratchWinnerShopManager:scratchWinnerResultCallFun] 消息返回 购买|领取|清理",isBuy, isReward, isClear)

    self:upDataBagData(result.selfData)
    -- 单张卡片的数据返回走关卡底层的监听了
    if not isReward then
        local params = {
            isBuy    = isBuy,
            isReward = isReward,
            isClear  = isClear,
        }
        gLobalNoticManager:postNotification("ScratchWinnerMachine_resultCallFun", params)
    end
    
end

-- 传入卡片数量获取发送的数据包
function ScratchWinnerShopManager:getSendBuyData(_buyList)
    print("[ScratchWinnerShopManager:getSendBuyData] 发送购买请求")
    release_print("[ScratchWinnerShopManager:getSendBuyData] 发送购买请求")
    
    local purchase = {}
    for _name,_count in pairs(_buyList) do
        print("[ScratchWinnerShopManager:getSendBuyData]",_name,_count)
        release_print("[ScratchWinnerShopManager:getSendBuyData]",_name,_count)
        table.insert(purchase, {_name, _count})
    end
    return purchase
end
--[[
    _params = {
        skipCheckCoins = false,    跳过检测金币
    }
]]
function ScratchWinnerShopManager:checkBuyState(_buyList, _params)
    -- 有卡片未刮
    if #self.m_bagData.list > 0 and nil ~= self.m_bagData.list[self.m_bagData.index] then
        return false
    end
    if self.m_isWaitData then
        return false
    end

    local currBetIndex = globalData.slotRunData:getCurBetIndex()
    local spend    = 0
    local allCount = 0
    for _name,_count in pairs(_buyList) do
        allCount = allCount + _count
        --检查商品
        local cardData = self:getCardShopData(_name)
        if not cardData then
            local sMsg = string.format("[ScratchWinnerShopManager:checkBuyState_coins] errorName=(%s)", _name)
            error(sMsg)
            return false
        end
        --检查档位
        local unLockBetIndex = cardData.unlockBetLevel
        if currBetIndex < unLockBetIndex then
            local sMsg = string.format("[ScratchWinnerShopManager:checkBuyState_coins] 档位不足 当前=(%d) 目标=(%d)",currBetIndex,  unLockBetIndex) 
            print(sMsg)
            release_print(sMsg)
            return false
        end
    end
    --检查金币
    if not _params.skipCheckCoins then
        local buyState = self:checkBuyState_coins(_buyList)
        if not buyState then
            return false
        end
    end
    
    --检查数量
    if allCount < 1 then
        return false
    end

    return true
end
function ScratchWinnerShopManager:checkBuyState_coins(_buyList)
    local spend = toLongNumber(self:getBuyListSpend(_buyList))
    local curCoins = globalData.userRunData.coinNum
    --检查金币
    if curCoins < spend then
        local sMsg = string.format("[ScratchWinnerShopManager:checkBuyState_coins] 金币不足 当前=(%s) 花费=(%s)", "" .. curCoins, "" .. spend)
        print(sMsg)
        release_print(sMsg)
        return false
    end

    return true
end
function ScratchWinnerShopManager:getBuyListSpend(_buyList)
    local spend  = 0
    local curBet = globalData.slotRunData:getCurTotalBet()
    for _name,_count in pairs(_buyList) do
        local price = curBet
        spend = spend + price * _count
    end

    return spend
end
-- 是否有金币执行领奖
function ScratchWinnerShopManager:checkRewardState()
    local curBet = globalData.slotRunData:getCurTotalBet()
    local curCoins = globalData.userRunData.coinNum
    return curCoins >= toLongNumber(curBet)
end

return ScratchWinnerShopManager