--升级界面

local LevelUpNode = class("LevelUpNode", util_require("base.BaseView"))
function LevelUpNode:initUI()
    self:createCsbNode("LevelUp/LevelUp_new.csb")
    if globalData.slotRunData.isPortrait == true then
        self:setScale(0.7)
        self:setPosition(65, 45)
    else
        self:setPosition(0, 30)
    end

    -- titile
    -- local nodeTitle = self:findChild("node_title")
    -- if globalData.GameConfig:checkUseNewNoviceFeatures() and nodeTitle then
    --     nodeTitle:setPositionY(nodeTitle:getPositionY() + 25)
    -- end
end

function LevelUpNode:onEnter()
    local curLevel = globalData.userRunData.levelNum

    self:runCsbAction(
        "in",
        false,
        function()
            local endPos = globalData.flyCoinsEndPos
            local startPos = self:getCoinNodeWdPosition()
            local baseCoins = globalData.topUICoinCount
            gLobalViewManager:pubPlayFlyCoin(
                startPos,
                endPos,
                baseCoins,
                self:getLevelUpRewardCoins(),
                function()
                    if not tolua.isnull(self) then
                        self:runCsbAction(
                            "out",
                            false,
                            function()
                                --集卡预告和升级弹版错开目前写死在这里
                                --csc 2021年05月21日 去掉引导
                                if not globalData.GameConfig:checkUseNewNoviceFeatures() and (curLevel == 9 or curLevel == 14) then
                                    gLobalViewManager:showPreCard()
                                end
                                self:setVisible(false)
                            end
                        )
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPLEVEL_STATUS, {level = curLevel, levelUpData = self.levelUpData, type = 2})
                end,
                false,
                20,
                nil,
                nil,
                nil,
                true
            )
        end
    )
end

-- function LevelUpNode:onExit()
-- end

function LevelUpNode:getCoinNodeWdPosition()
    local spCoin = self:findChild("sp_icon1")
    local wdPos = spCoin:getParent():convertToWorldSpace(cc.p(spCoin:getPosition()))
    return wdPos
end

-- 商城buff倍数（升级buff）
function LevelUpNode:getShopBuffMultipe(levelNum)
    -- body

    local time = os.time()

    local gear = 1
    if globalData.shopRunData.shopLevelBurstEndTime > time or globalData.shopRunData.shopDoubleBurstEndTime > time then
        -- body
        local mod = math.fmod(levelNum, 5) -- 取余数
        if mod == 0 then
            gear = SHOP_BUFF_MULTIPE_LIST[2]
        else
            gear = SHOP_BUFF_MULTIPE_LIST[1]
        end
    end

    return gear
end

-- @param preLevel int 之前的等级
-- @param curLevel int 升级后的等级
function LevelUpNode:initLevelUpData(data)
    -- gLobalSoundManager:playSound("Sounds/level_up.mp3")
    self.levelUpData = data
    local preLevel = data[1]
    local curLevel = globalData.userRunData.levelNum
    local m_lb_num = self:findChild("m_lb_num")
    local m_lb_level = self:findChild("m_lb_level")
    if m_lb_num and m_lb_level then
        m_lb_num:setString(curLevel .. "")
        util_alignCenter({{node = m_lb_level}, {node = m_lb_num, alignX = 10}})
    end

    local rewardList = {}
    rewardList[LEVEL_REWARD_ENMU.MAXBET] = 0 -- MAXBET
    rewardList[LEVEL_REWARD_ENMU.CASHMONEY] = 0 -- 银库奖励
    rewardList[LEVEL_REWARD_ENMU.CASHWHEEL] = 0 -- 转盘奖励
    rewardList[LEVEL_REWARD_ENMU.VIP] = 0 -- 升级奖励vip 点数
    rewardList[LEVEL_REWARD_ENMU.CLUB] = 0 -- 高倍场奖励
    local rewardCoins = 0
    local mulCoins = 0
    --从服务器获取升级通用奖励
    for i = preLevel, curLevel - 1 do
        local curData = globalData.userRunData:getLevelUpRewardInfo(i)
        if curData and curData.p_coins then
            rewardCoins = rewardCoins + curData.p_coins -- 升级到下一级奖励金币
            rewardList[LEVEL_REWARD_ENMU.CASHMONEY] = rewardList[LEVEL_REWARD_ENMU.CASHMONEY] + curData.p_treasury -- 银库奖励
            rewardList[LEVEL_REWARD_ENMU.CASHWHEEL] = rewardList[LEVEL_REWARD_ENMU.CASHWHEEL] + curData.p_wheel -- 转盘奖励
            rewardList[LEVEL_REWARD_ENMU.VIP] = rewardList[LEVEL_REWARD_ENMU.VIP] + curData.p_vipPoint -- 升级奖励vip 点数
            rewardList[LEVEL_REWARD_ENMU.CLUB] = rewardList[LEVEL_REWARD_ENMU.CLUB] + curData.p_clubPoint -- 高倍场奖励
        end
    end
    --maxBet
    local maxBetData = globalData.slotRunData:getMaxBetData()
    rewardList[LEVEL_REWARD_ENMU.MAXBET] = maxBetData.p_totalBetValue
    --cashmoney
    local cashMoneyData = G_GetMgr(G_REF.CashBonus):getCashMoneyData()
    if cashMoneyData and cashMoneyData.p_cashMultiply and cashMoneyData.p_vipMultiply then
        rewardList[LEVEL_REWARD_ENMU.CASHMONEY] = tonumber(cashMoneyData.p_cashMultiply) * tonumber(cashMoneyData.p_vipMultiply) * 4000
    end

    --活动标签
    local isHaveLevelBoom = false
    local multipleExp1 = globalData.buffConfigData:getBuffMultipleByType(BUFFTYPY.BUFFTYPY_LEVEL_BOOM)
    if multipleExp1 and multipleExp1 > 1 then
        isHaveLevelBoom = true
    end
    -- Buff倍数
    local multiple = globalData.buffConfigData:getAllCoinBuffMultiple(curLevel)
    if multiple <= 1 then
        self:findChild("m_sp_booster"):setVisible(false)
    else
        local nodeTitle = self:findChild("node_title")
        nodeTitle:setPositionX(nodeTitle:getPositionX() + 25)
        mulCoins = rewardCoins * (multiple - 1)
    end
    self.m_totalCoins = mulCoins + rewardCoins
    self:findChild("m_lb_booster"):setString("X" .. multiple)
    self.addRewardCoins = rewardCoins

    --先写死
    self:initCell(LEVEL_REWARD_ENMU.COINS, 1, self.m_totalCoins)
    self:initCell(LEVEL_REWARD_ENMU.VIP, 2, rewardList[LEVEL_REWARD_ENMU.VIP])
    self:initCell(LEVEL_REWARD_ENMU.MAXBET, 3, rewardList[LEVEL_REWARD_ENMU.MAXBET])
end

function LevelUpNode:initCell(name, index, value)
    local sp_icon = self:findChild("sp_icon" .. index)
    local m_sp_item = self:findChild("m_lb_item" .. index)
    local m_lb_item = self:findChild("m_lb_item" .. index .. "-SHUZI")
    if sp_icon then
        --图标
        if name == LEVEL_REWARD_ENMU.VIP then
            self:addVipIcon(sp_icon)
        end
    end
    if m_sp_item then
    --描述
    end
    if m_lb_item then
        --值
        m_lb_item:setString(util_formatCoins(value, 3))
    end
end

function LevelUpNode:getLevelUpRewardCoins()
    -- return self.addRewardCoins
    return self.m_totalCoins
end

--VIP单独处理
function LevelUpNode:addVipIcon(icon)
    local path = VipConfig.logo_shop .. globalData.userRunData.vipLevel .. ".png"
    local spVip = util_createSprite(path)
    if spVip then
        spVip:setScale(0.62)
        icon:addChild(spVip)
        local size = icon:getContentSize()
        spVip:setPosition(size.width * 0.5, size.height * 0.5 +1)
    end
end
return LevelUpNode
