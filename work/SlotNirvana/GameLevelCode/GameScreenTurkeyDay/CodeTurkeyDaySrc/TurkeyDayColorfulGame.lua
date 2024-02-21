---
--xcyy
--2018年5月23日
--TurkeyDayColorfulGame.lua
--多福多彩
--[[
    使用方式
    需要在调用时构造参数,具体如下:
    local bonusData = {
        rewardList = selfData.cards,
        winJackpot = jackpotType
    }

    --在调用showView之前需重置界面显示
    local endFunc = function()
    
    end
    self.m_colorfulGameView:resetView(bonusData,endFunc)
    self.m_colorfulGameView:showView()
]]
local PublicConfig = require "TurkeyDayPublicConfig"
local BaseDialog = util_require("Levels.BaseDialog")
local TurkeyDayColorfulGame = class("TurkeyDayColorfulGame",util_require("Levels.BaseLevelDialog"))

TurkeyDayColorfulGame.m_bonusData = nil   --bonus数据
TurkeyDayColorfulGame.m_endFunc = nil     --结束回调
TurkeyDayColorfulGame.m_curClickIndex = 1 --当前点击的索引

local ITEM_MAX_COUNT = 18 -- 可点击道具数量（最大数量）
local ITEM_COUNT = 15 -- 至少有15个
local JACKPOT_TYPE = {"grand", "mega", "major", "minor", "mini"}

function TurkeyDayColorfulGame:initUI(params)
    self.m_machine = params.machine

    self:createCsbNode("TurkeyDay/GameScreenTurkeyDay_pick.csb")

    self:runCsbAction("idle", true)
    --jackpot
    self.m_jackpotBar = util_createView("CodeTurkeyDaySrc.TurkeyDayColofulJackPotBar",{machine = self.m_machine})
    self:findChild("pick_jackpot"):addChild(self.m_jackpotBar)

    self.m_sortNumTbl = {
        15, 10, 5,
        14, 9, 4, 18,
        13, 8, 3, 16,
        12, 7, 2, 17,
        11, 6, 1,
    }

    --定时节点
    self.m_scheduleNode = cc.Node:create()
    self:addChild(self.m_scheduleNode)

    self.m_itemNodePos = {{cc.p(-123, 225)}, {cc.p(-288, 225), cc.p(30, 225)}, {cc.p(-365, 225), cc.p(-123, 225), cc.p(119, 225)}}

    --所有道具数组
    self.m_items = {}
    self.m_parentItems = {}
    for index = 1,ITEM_MAX_COUNT do
        self.m_parentItems[index] = self:findChild("Node_item_"..index)
        local item = util_createView("CodeTurkeyDaySrc.TurkeyDayColorfulItem",{
            parentView = self,
            itemID = index
        })

        if self.m_parentItems[index] then
            self.m_parentItems[index]:addChild(item)
        else
            self:addChild(item)
        end
        self.m_items[index] = item
    end

    self.m_left_item_counts = {}

    -- 特效层
    self.m_topEffectNode = self:findChild("Node_topEffect")
    -- jackpot锁定层
    self.m_rightRunNode = self:findChild("Node_run")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function TurkeyDayColorfulGame:scaleMainLayer(_scale)
    self:findChild("root"):setScale(_scale)
    self.m_machineRootScale = _scale
end

--[[
    开启定时idle
]]
function TurkeyDayColorfulGame:startIdleAni()
    local unClickdItems = self:getUnClickeItem()
    --每次随机控制3个摆动
    for index = 1,3 do
        if #unClickdItems > 0 then
            local randIndex = math.random(1,#unClickdItems)
            local item = unClickdItems[randIndex]
            if not tolua.isnull(item) then
                item:runShakeAni()
            end
            table.remove(unClickdItems,randIndex)
        end
    end
    performWithDelay(self.m_scheduleNode,function()
        self:startIdleAni()
    end,2.5)
end

--[[
    停止定时idle
]]
function TurkeyDayColorfulGame:stopIdleAni()
    self.m_scheduleNode:stopAllActions()
end

--[[
    获取还未点击位置
]]
function TurkeyDayColorfulGame:getUnClickeItem()
    local unClickdItems = {}
    for k,item in pairs(self.m_items) do
        if not item.m_isClicked then
            unClickdItems[#unClickdItems + 1] = item
        end
    end

    return unClickdItems
end

--[[
    设置bonus数据

    bonusData数据结构如下,需手动拼接数据结构
    {
        rewardList = selfData.cards,
        winJackpot = jackpotType
    }
]]
function TurkeyDayColorfulGame:setBonusData(bonusData,endFunc)
    self.m_bonusData = bonusData
    --兼容数据格式,可根据具体的数据调整
    self.m_rewardList = bonusData.jackpot.process
    self.m_removeRewardList = bonusData.jackpot.processpush
    local remainList = bonusData.jackpot.extraProcess
    local totalCount = #self.m_rewardList + #remainList
    -- remove个数
    self.m_addCount = totalCount - ITEM_COUNT
    self.m_endFunc = endFunc
    --当前点击的索引
    self.m_curClickIndex = 1
    -- --当前是否结束
    -- self.m_isEnd = false
    -- 当前点出remove是否可以点击
    self.m_isRemoveClick = false
    -- 当前点击的remove索引
    self.m_removeTypeIndex = 1
    self.m_topEffectNode:removeAllChildren()
    self.m_rightRunNode:removeAllChildren()
    --重置收集剩余数量
    for index,jackpotType in pairs(JACKPOT_TYPE) do
        self.m_left_item_counts[jackpotType] = 3
    end

    -- 判断数量；没有remove是15个；最多三个remove；根据数量判断位置
    for i=1, #self.m_items do
        self.m_items[i]:setVisible(totalCount>=i)
        if totalCount>=i then
            self.m_items[i]:setVisible(true)
        else
            self.m_items[i]:setVisible(false)
            self.m_items[i]:setClickedState(true)
        end
    end

    if self.m_addCount > 0 then
        local curPosTbl = self.m_itemNodePos[self.m_addCount]
        for i=16, totalCount do
            self.m_parentItems[i]:setPosition(curPosTbl[i-ITEM_COUNT])
        end
    end
end

--[[
    重置界面显示
]]
function TurkeyDayColorfulGame:resetView(bonusData,endFunc)
    self:setBonusData(bonusData,endFunc)
    self.m_jackpotBar:resetView()
    for index,item in ipairs(self.m_items) do
        item:resetStatus()
    end

    -- 设置层级
    for index, sortIndex in ipairs(self.m_sortNumTbl) do
        self.m_items[sortIndex]:setSortIndex(index)
    end
end

--[[
    显示界面(执行start时间线)
]]
function TurkeyDayColorfulGame:showView(func)
    self:setVisible(true)
    self:startIdleAni()
    -- 当前是否结束
    self.m_isEnd = true

    performWithDelay(self.m_scWaitNode, function()
        self:showPickStartDialog(function()
            self.m_isEnd = false
            if type(func) == "function" then
                func()
            end
        end)
    end, (105-78)/30)
end

-- 显示pick弹板
function TurkeyDayColorfulGame:showPickStartDialog(func)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    --特殊bonus
    local buffIcons = selfData.buffIcons[1]
    local buffCount = 0
    if buffIcons and next(buffIcons) then
        buffCount = buffIcons[2]
    end

    -- 将title1_idle（0,80）挂在TurkeyDay_pick_start.csd中wzsg的挂点上当auto播放到第35帧时开始播放，到200帧时结束播放
    -- 将idleframe挂在FreeSpinMore.csd中的zg的挂点上开始播放（持续播放）
    local freeStartSpine = util_spineCreate("TurkeyDay_tbsg",true,true)
    freeStartSpine:setVisible(false)

    local lightAni = util_createAnimation("TurkeyDay_tb_guang.csb")
    lightAni:runCsbAction("idleframe", true)
    
    performWithDelay(self.m_scWaitNode, function()
        freeStartSpine:setVisible(true)
        util_spinePlay(freeStartSpine, "title1_idle", false)
    end, 35/60)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Colorful_Auto)
    local view = self.m_machine:showDialog("TurkeyDay_pick_start", nil, func, BaseDialog.AUTO_TYPE_ONLY)
    view:findChild("root"):setScale(self.m_machineRootScale)
    
    view:findChild("wzsg"):addChild(freeStartSpine)
    view:findChild("zg"):addChild(lightAni)
    view:findChild("m_lb_num"):setString(buffCount)
    if buffCount == 0 then
        view:findChild("yichujiangli"):setVisible(false)
    end
    util_setCascadeOpacityEnabledRescursion(view, true)
end

--[[
    隐藏界面(执行over时间线)
]]
function TurkeyDayColorfulGame:hideView(func)
    self:setVisible(false)
end

--[[
    点击道具回调
]]
function TurkeyDayColorfulGame:clickItem(clickItem)
    if self.m_isEnd then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Pick_Click)
    --获取当前点击的的奖励
    local rewardType = self:getCurReward()

    if rewardType == "remove" then
        self.m_isRemoveClick = true
    else
        --收集到jackpot上
        local process = self.m_jackpotBar:getProcessByType(rewardType)
        local pointNode = self.m_jackpotBar:getFeedBackPoint(rewardType,process)
        self:flyParticleAni(clickItem,pointNode,function()
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_CollectJackpot_FeedBack)
            self.m_jackpotBar:collectFeedBackAni(rewardType,pointNode)
        end)

        --减少剩余奖励数量
        self.m_left_item_counts[rewardType] = self.m_left_item_counts[rewardType] - 1
        self.m_isRemoveClick = false
    end

    --累加点击索引
    self.m_curClickIndex  = self.m_curClickIndex + 1

    --游戏结束
    if self.m_curClickIndex > #self.m_rewardList then
        self.m_isEnd = true
        --停止idle定时器
        self:stopIdleAni()
    end

    --刷新点击位置的道具显示
    if not self.m_isEnd then
        clickItem:showRewardAni(rewardType)
    else
        --游戏结束
        clickItem:showRewardAni(rewardType,function()
            --显示其他未点击的位置的奖励
            self:showUnClickItemReward()
            --显示jackpot上的中奖光效(未中奖的压黑)
            self.m_jackpotBar:showHitLight(self.m_bonusData.winJackpot)

            --显示中奖动效
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Pick_RewardJackpot)
            self:showHitJackpotAni(rewardType,function()
                if type(self.m_endFunc) == "function" then
                    self.m_endFunc()
                end
            end)
        end)
    end
end

-- 随机翻出所有目前最低档的jackpot类型
function TurkeyDayColorfulGame:playTurnMinJackpot(_itemID)
    -- 当前remove的index
    local itemID = _itemID
    -- 当前需要掀开的个数
    local curRemoveCount = self.m_removeRewardList[self.m_removeTypeIndex]
    local needJumpBonusType = JACKPOT_TYPE[#JACKPOT_TYPE - self.m_removeTypeIndex + 1]

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_Pick_Jackpot_Sound)
    -- 需要掀开的jackpot类型
    local leftReward = {}
    local beginIndex = self.m_curClickIndex
    local endIndex = self.m_curClickIndex + curRemoveCount - 1
    for index = beginIndex, endIndex do
        leftReward[#leftReward + 1] = self.m_rewardList[index]
    end
    -- 获取未点击的蛋
    local unClickItems = self:getUnClickeItem()
    --打乱数组
    randomShuffle(unClickItems)
    for index = 1, #leftReward do
        self.m_curClickIndex  = self.m_curClickIndex + 1
        local rewardType = leftReward[index]
        local item = unClickItems[index]
        item:showRewardAni(rewardType)
        item:setClickedState(true)
        item:setJumpState(true)
        --减少剩余奖励数量
        self.m_left_item_counts[rewardType] = self.m_left_item_counts[rewardType] - 1
    end

    performWithDelay(self.m_scWaitNode, function()
        -- 翻出remove，小鸡跳走
        self:jumpBuffBonus(needJumpBonusType, itemID)
    end, 25/30)
end

-- 先飞buff
function TurkeyDayColorfulGame:jumpBuffBonus(_needJumpBonusType, _itemID)
    local needJumpBonusType = _needJumpBonusType
    local itemID = _itemID

    -- removeNode
    local item = self.m_items[itemID]

    local tblActionList = {}
    -- 上边新建的小鸡跳走
    local flyJackpotSpine = util_spineCreate("Socre_TurkeyDay_jackpot",true,true)
    flyJackpotSpine:setSkin("zi")
    local startPos = util_convertToNodeSpace(self.m_parentItems[itemID], self.m_topEffectNode)
    local endPosY = -250
    local endPosX = 245
    local endPos = cc.p(startPos.x, endPosY)
    -- 停止位置
    local endMovePos_1 = cc.p(endPosX, endPosY)
    -- 屏幕外位置
    local endMovePos_2 = cc.p(display.width/2 + 200, endPosY)
    flyJackpotSpine:setPosition(startPos)
    local zorder = item:getCurZorder()
    self.m_topEffectNode:addChild(flyJackpotSpine, zorder)

    local pickAni = util_createAnimation("TurkeyDay_pick_item.csb")
    util_spinePushBindNode(flyJackpotSpine, "jackpot_guadian1", pickAni)
    self:setJackpotTypeShow(pickAni, "remove")

    local offsetTime = (endPosX - startPos.x) / (display.width/2) * 200 / 320 * 0.5
    local delayTime_1 = (endPosX - startPos.x)/320*0.5 + offsetTime
    local delayTime_2 = (display.width/2 + 200 - endPosX)/320*0.5

    -- 终点的烟
    local bonusSpine = util_spineCreate("TurkeyDay_Bonus_js",true,true)
    bonusSpine:setPosition(endPos)
    self.m_topEffectNode:addChild(bonusSpine, zorder+10)
    bonusSpine:setVisible(false)

    -- 跑走的鸡
    local bonusRunSpine = util_spineCreate("TurkeyDay_Bonus_js",true,true)
    bonusRunSpine:setPosition(endPos)
    self.m_topEffectNode:addChild(bonusRunSpine)
    bonusRunSpine:setVisible(false)

    -- jackpot锁定板子
    local bonusRightSpine = util_spineCreate("TurkeyDay_Bonus_js",true,true)
    self.m_rightRunNode:addChild(bonusRightSpine)
    bonusRightSpine:setVisible(false)

    local rightSpineName = ""
    if self.m_removeTypeIndex == 1 then
        rightSpineName = "actionframe_yw3"
    elseif self.m_removeTypeIndex == 2 then
        rightSpineName = "actionframe_yw2"
    elseif self.m_removeTypeIndex == 3 then
        rightSpineName = "actionframe_yw"
    end

    -- jackpot_tiao_zi_ji（0，30）
    util_spinePlay(flyJackpotSpine,"jackpot_tiao_zi_ji", false)
    item:jumpJackpotToBottom()
    item:setClickedState(true)
    item:setJumpState(true)

    -- “第10--23帧”播位移
    tblActionList[#tblActionList+1] = cc.DelayTime:create(10/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_RemovePick_Jump)
        self:playMoveToAction(flyJackpotSpine,13/30,endPos)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(8/30)
    -- tblActionList[#tblActionList+1] = cc.EaseSineIn:create(cc.MoveTo:create(32/30, endPos))
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        bonusSpine:setVisible(true)
        util_spinePlay(bonusSpine,"buling", false)
        util_spineEndCallFunc(bonusSpine, "buling", function()
            bonusSpine:setVisible(false)
        end)
    end)
    -- 当TurkeyDay_Bonus_js buling（0,16）播放到第5针； 播actionframe_run（0,14）循环动画 程序控制位移；一个循环位移大概两个蛋的位置
    tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        flyJackpotSpine:setVisible(false)
        bonusRunSpine:setVisible(true)
        util_spinePlay(bonusRunSpine,"actionframe_run2", true)
    end)
    tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
    tblActionList[#tblActionList+1] = cc.EaseInOut:create(cc.MoveTo:create(delayTime_1, endMovePos_1), 1)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(bonusRunSpine,"actionframe", false)
    end)
    -- 当actionframe（0,18）播放到第18针时 播放actionframe_yw、2、3
    tblActionList[#tblActionList+1] = cc.DelayTime:create(18/30)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        bonusRightSpine:setVisible(true)
        util_spinePlay(bonusRightSpine,rightSpineName, false)
    end)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        util_spinePlay(bonusRunSpine,"actionframe_run3", true)
    end)
    tblActionList[#tblActionList+1] = cc.EaseInOut:create(cc.MoveTo:create(delayTime_2, endMovePos_2), 1)
    tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
        self:jumpJackpotBonus(needJumpBonusType)
    end)
    bonusRunSpine:runAction(cc.Sequence:create(tblActionList))
end

-- 最后飞翻出remove
function TurkeyDayColorfulGame:jumpJackpotBonus(_needJumpBonusType)
    local needJumpBonusType = _needJumpBonusType

    -- 获取当前类型小鸡的位置
    local needRemoveTbl = {}
    for k,item in pairs(self.m_items) do
        if item.m_curRewardType == needJumpBonusType then
            needRemoveTbl[#needRemoveTbl + 1] = item
        end
    end

    -- 排序
    table.sort(needRemoveTbl, function(a, b)
        return a.m_sortIndex < b.m_sortIndex
    end)

    local curCount = 0
    local delayTime = 0
    local isPlaySound = true
    -- 小鸡跳走动画，间隔0.25s
    for k,item in pairs(needRemoveTbl) do
        performWithDelay(self.m_scWaitNode, function()
            item:jumpJackpotToBottom(k==1)

            local tblActionList = {}
            -- 上边新建的小鸡跳走
            local flyJackpotSpine = util_spineCreate("Socre_TurkeyDay_jackpot",true,true)
            flyJackpotSpine:setSkin("huang")
            local startPos = util_convertToNodeSpace(self.m_parentItems[item.m_itemID], self.m_topEffectNode)
            local endPosY = -250
            local endPos = cc.p(startPos.x, endPosY)
            -- 屏幕外位置
            local endMovePos = cc.p(display.width/2 + 200, endPosY)
            local duration = (display.width/2 + 200 - startPos.x)/320*0.5
            delayTime = util_max(delayTime,duration)
            flyJackpotSpine:setPosition(startPos)
            local zorder = item:getCurZorder()
            self.m_topEffectNode:addChild(flyJackpotSpine, zorder)
            -- jackpot_tiao_huang_ji（0，70）
            util_spinePlay(flyJackpotSpine,"jackpot_tiao_huang_ji", false)

            local pickAni = util_createAnimation("TurkeyDay_pick_item.csb")
            util_spinePushBindNode(flyJackpotSpine, "jackpot_guadian1", pickAni)
            self:setJackpotTypeShow(pickAni, needJumpBonusType)

            -- 终点的烟
            local bonusSpine = util_spineCreate("TurkeyDay_Bonus_js",true,true)
            bonusSpine:setPosition(endPos)
            self.m_topEffectNode:addChild(bonusSpine, zorder+10)
            bonusSpine:setVisible(false)

            -- 跑走的鸡
            local bonusRunSpine = util_spineCreate("TurkeyDay_Bonus_js",true,true)
            bonusRunSpine:setPosition(endPos)
            self.m_topEffectNode:addChild(bonusRunSpine)
            bonusRunSpine:setVisible(false)

            -- 第50--62帧”播位移
            tblActionList[#tblActionList+1] = cc.DelayTime:create(50/30)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                self:playMoveToAction(flyJackpotSpine,12/30,endPos)
            end)
            tblActionList[#tblActionList+1] = cc.DelayTime:create(7/30)
            -- tblActionList[#tblActionList+1] = cc.EaseSineIn:create(cc.MoveTo:create(32/30, endPos))
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_RemovePick_JackpotJump)
                bonusSpine:setVisible(true)
                util_spinePlay(bonusSpine,"buling", false)
                util_spineEndCallFunc(bonusSpine, "buling", function()
                    bonusSpine:setVisible(false)
                end)
            end)
            -- 当TurkeyDay_Bonus_js buling（0,16）播放到第5针； 播actionframe_run（0,14）循环动画 程序控制位移；一个循环位移大概两个蛋的位置
            tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                flyJackpotSpine:setVisible(false)
                bonusRunSpine:setVisible(true)
                util_spinePlay(bonusRunSpine,"actionframe_run", true)
            end)
            tblActionList[#tblActionList+1] = cc.DelayTime:create(5/30)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                if isPlaySound then
                    isPlaySound = false
                    gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_RemovePick_JackpotDisappear)
                end
            end)
            tblActionList[#tblActionList+1] = cc.EaseInOut:create(cc.MoveTo:create(duration, endMovePos), 1)
            tblActionList[#tblActionList+1] = cc.CallFunc:create(function()
                bonusRunSpine:setVisible(false)
                curCount = curCount + 1
                if curCount >= 3 then
                    self.m_isRemoveClick = false
                    self.m_removeTypeIndex = self.m_removeTypeIndex + 1
                end
            end)
            bonusRunSpine:runAction(cc.Sequence:create(tblActionList))
        end, (k-1)*0.25)
    end
end

--[[
    设置具体的jackpot显示
]]
function TurkeyDayColorfulGame:setJackpotTypeShow(pickAni, rewardType)
    pickAni:findChild("mini"):setVisible(rewardType == "mini")
    pickAni:findChild("minor"):setVisible(rewardType == "minor")
    pickAni:findChild("major"):setVisible(rewardType == "major")
    pickAni:findChild("mega"):setVisible(rewardType == "mega")
    pickAni:findChild("grand"):setVisible(rewardType == "grand")
    pickAni:findChild("remove"):setVisible(rewardType == "remove")
end

--[[
    显示中奖动效
]]
function TurkeyDayColorfulGame:showHitJackpotAni(winType,func)
    for index = 1,#self.m_items do
        local item = self.m_items[index]
        --未中奖的压黑
        if not item:isSameType(winType) then
            item:runDarkAni()
        else
            item:getRewardAni()
        end
    end

    -- 除去触发；其余的reset
    self.m_jackpotBar:resetTriggerView(winType)
    --结果多展示一会(延迟为中奖时间时间线长度+0.5s)
    performWithDelay(self,function()
        if type(func) == "function" then
            func()
        end
    end,2.5)
end

--[[
    获取当前的奖励
]]
function TurkeyDayColorfulGame:getCurReward()
    local reward = self.m_rewardList[self.m_curClickIndex] or ""

    --防止服务器数据大小写不统一,一律转化为小写
    return string.lower(reward)
end

--[[
    显示未点击位置的奖励
]]
function TurkeyDayColorfulGame:showUnClickItemReward()
    local leftReward = {}
    --计算还没有点出来的jackpot
    for rewardType,count in pairs(self.m_left_item_counts) do
        for iCount = 1,count do
            leftReward[#leftReward + 1] = rewardType
        end
    end

    -- 添加remove类型
    local needAddRemoveCount = self.m_addCount - (self.m_removeTypeIndex - 1)
    if needAddRemoveCount > 0 then
        for i=1, needAddRemoveCount do
            leftReward[#leftReward + 1] = "remove"
        end
    end

    --打乱数组
    randomShuffle(leftReward)

    local unClickItems = self:getUnClickeItem()
    for index = 1,#leftReward do
        local rewardType = leftReward[index]
        local item = unClickItems[index]
        -- item:showRewardAni(rewardType)
        item:setJackpotTypeShow(rewardType)
    end
end
--[[
    飞粒子动画
]]
function TurkeyDayColorfulGame:flyParticleAni(startNode,endNode,func)
    local flyNode = util_createAnimation("TurkeyDay_pick_tuoweilizi.csb")
    if flyNode:findChild("Particle_1") then --粒子必须判空,线上有获取不到的情况,原因不明
        flyNode:findChild("Particle_1"):setPositionType(0)
    end

    local startPos = util_convertToNodeSpace(startNode,self)
    local endPos = util_convertToNodeSpace(endNode,self)

    self:addChild(flyNode)
    flyNode:setPosition(startPos)

    local actionList = {
        cc.EaseIn:create(cc.MoveTo:create(0.5,endPos), 2),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
            if flyNode:findChild("Particle_1") then--粒子必须判空,线上有获取不到的情况,原因不明
                flyNode:findChild("Particle_1"):stopSystem()
            end
        end),
        cc.DelayTime:create(1),
        cc.RemoveSelf:create()
    }
    flyNode:runAction(cc.Sequence:create(actionList))
end

--[[
    获取剩余的奖励数量
]]
function TurkeyDayColorfulGame:getLeftRewrdCount(rewardType)
    return self.m_left_item_counts[rewardType] or 3
end

function TurkeyDayColorfulGame:playMoveToAction(node, time, pos, callback, type)
    local actionList = {}
    actionList[#actionList + 1] = cc.EaseIn:create(cc.MoveTo:create(time, pos), 2)

    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if callback then
                callback()
            end
        end
    )
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end

return TurkeyDayColorfulGame