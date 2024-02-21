--[[--
    赛季和赛季之间的间歇期处理逻辑
    旧赛季结束的时候，赛季间歇期开始
    新赛季开启的时候，赛季间歇期结束
]]
local CardInterimManager = class("CardInterimManager")

function CardInterimManager:ctor()

    self.m_isInterimStart = nil
    self.m_isInterimOver = nil
end


function CardInterimManager:onUpdateTimer(delayTime)
    -- 旧赛季结束判断
    self:checkSeasonOverTimer(delayTime)

    -- 新赛季开启判断
    self:checkSeasonOpenTimer(delayTime)
end

-- 实时处理赛季结束逻辑
function CardInterimManager:checkSeasonOverTimer(delayTime)
    -- 逻辑只走一次
    if self.m_isInterimStart then
        return
    end

    local expireAt = CardSysManager:getSeasonExpireAt()
    if not expireAt then
        self.m_isInterimStart = true
        return
    end
    local leftTime = util_getLeftTime(expireAt * 1000)
    if leftTime > 3 * 60 * 60 then
        -- 3剩余3个小时才关闭就不管了
        self.m_isInterimStart = true
        return
    end

    -- cxc 赛季结束 清除buff
    if leftTime <= 0 then
        -- 新赛季 清除上个赛季的buff
        globalData.buffConfigData:clearPreCardSeasonBuff()
        self.m_isInterimStart = true
    end
end

-- 正在开着的赛季 实时结束逻辑
function CardInterimManager:doSeasonOverLogic()
    -- 处理一些功能
    -- 邮箱不能送卡
    -- 
end

-- 实时判断新赛季是否开启
function CardInterimManager:checkSeasonOpenTimer(delayTime)
    -- startAt
    -- 退出赛季界面
    -- 退出wild兑换界面，回收机乐透界面，nado机界面

    if self.m_isInterimOver == true then
        return
    end

    -- 当前没有开启的赛季
    if CardSysRuntimeMgr:hasSeasonOpening() then
        self.m_isInterimOver = true
    end

    if CardSysRuntimeMgr:hasLoginCardSys() then
        local nowTime = math.floor(globalData.userRunData.p_serverTime/1000) -- os.time()
        -- 获取当前赛季，如果没有开启的赛季那么当前赛季是旧赛季
        local yearsData = CardSysRuntimeMgr:getYearsData()
        for i=1,#yearsData do
            local yData = yearsData[i]
            if yData then
                local albumDatas = yData:getAlbumDatas()
                if albumDatas and #albumDatas > 0 then
                    for j=1,#albumDatas do
                        local albumData = albumDatas[j]
                        if albumData:getStatus() == CardSysConfigs.CardSeasonStatus.coming then
                            -- 一定只有一个即将开启的赛季
                            if nowTime >= math.floor(tonumber(albumData:getStartAt())/1000) then
                                self.m_isInterimOver = true
                                -- 处理新赛季开启了的事件
                                self:doSeasonOpenLogic()
                            end
                        end
                    end
                end
            end
        end
    end


end

-- 新赛季开启事件
function CardInterimManager:doSeasonOpenLogic()
    -- 直接退出集卡系统，并且不执行回调
    CardSysManager:exitCard(true)
    
    -- 请求集卡，刷新数据
    CardSysManager:requestCardCollectionSysInfo()

    -- 新赛季 清除上个赛季的buff
    globalData.buffConfigData:clearPreCardSeasonBuff()
    
    -- 发消息，关闭一些没有被关闭的界面
    gLobalNoticManager:postNotification(CardSysConfigs.ViewEventType.CARD_NEW_SEASON_OPEN)
end


return CardInterimManager