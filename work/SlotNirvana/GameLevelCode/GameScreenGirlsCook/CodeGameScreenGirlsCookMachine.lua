---
-- island li
-- 2019年1月26日
-- CodeGameScreenGirlsCookMachine.lua
-- 
-- 玩法：
-- 
local BaseSlotoManiaMachine = require "Levels.BaseSlotoManiaMachine"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local CodeGameScreenGirlsCookMachine = class("CodeGameScreenGirlsCookMachine", BaseNewReelMachine)

CodeGameScreenGirlsCookMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

-- CodeGameScreenGirlsCookMachine.SYMBOL_XXXXX_XXXX = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE  -- 自定义的小块类型
CodeGameScreenGirlsCookMachine.CUSTOMER_ENTER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 4 -- 顾客入场
CodeGameScreenGirlsCookMachine.FREESPIN_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 3 -- 收集食物
CodeGameScreenGirlsCookMachine.FOOD_COLLECT_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 -- 收集食物
CodeGameScreenGirlsCookMachine.FOOD_COLLECT_OVER_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 -- 收集完成

local FOOD_CSB      =       {
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_1] = "GirlsCook_food_1.csb",
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_2] = "GirlsCook_food_2.csb",
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_3] = "GirlsCook_food_3.csb",
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_4] = "GirlsCook_food_4.csb",
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_5] = "GirlsCook_food_5.csb",
}

local ORDER_ENTER   =   100

--配音文件配置
local ENTER_SOUND = {
    "GirlsCookSounds/music_GirlsCook_grandma_enter.mp3",
    "GirlsCookSounds/music_GirlsCook_man_enter.mp3",
    "GirlsCookSounds/music_GirlsCook_child_enter.mp3"
}
--焦急声音
local SAD_SOUND = {
    "GirlsCookSounds/music_GirlsCook_grandma_sad.mp3",
    "GirlsCookSounds/music_GirlsCook_man_sad.mp3",
    "GirlsCookSounds/music_GirlsCook_child_sad.mp3"
}

--吃到食物配音
local EAT_SOUND = {
    "GirlsCookSounds/music_GirlsCook_grandma_eat.mp3",
    "GirlsCookSounds/music_GirlsCook_man_eat.mp3",
    "GirlsCookSounds/music_GirlsCook_child_eat.mp3"
}
--free中奖音效
local FREE_HIT_SOUND = {
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_9] = "GirlsCookSounds/music_GirlsCook_women_hit.mp3",
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_8] = "GirlsCookSounds/music_GirlsCook_grandma_hit.mp3",
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_7] = "GirlsCookSounds/music_GirlsCook_man_hit.mp3",
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_6] = "GirlsCookSounds/music_GirlsCook_child_hit.mp3",
}

--顾客spine
local SPINE_CUSTOMER    =       {
    "Socre_GirlsCook_8_dajuese",
    "Socre_GirlsCook_7_dajuese",
    "Socre_GirlsCook_6_dajuese"
}

--情绪状态
local STATUS_EMOTION = {
    HAPPY = 1,
    NORMAL = 2,
    SAD = 3
}

--emoji表情
local STATUS_EMOJI = {
    HAPPY = 1,
    NORMAL = 2,
    SAD = 3,
    ANGRY = 4,
    FINISHED = 5
}

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

local MAX_HEIGHT = {
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_1] = 107,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_2] = 109,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_3] = 97,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_4] = 102,
    [TAG_SYMBOL_TYPE.SYMBOL_SCORE_5] = 87,
}

local SPECIAL_SYMBOL = {0,1,2,3}

local BASE_IDLE                      =           1001        --普通状态
local FREE_IDLE                      =           1002        --free状态
local BASE_TO_FREE                   =           1003        --普通转free
local FREE_TO_BASE                   =           1004        --free转普通

local STATUS_WITH_TIMER                 =       2001        --限时任务
local STATUS_WITH_SPINCOUNT_1           =       2002        --限次任务(在次数内)
local STATUS_WITH_SPINCOUNT_2           =       2003        --限次任务(超出次数)

-- 构造函数
function CodeGameScreenGirlsCookMachine:ctor()
    BaseNewReelMachine.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true
    self.m_isLongRun = false
    self.m_isAlreadyRefreshWinCoins = false
    self.m_collectWinCoins = 0
    self.m_refreshTime = 0
 
    --init
    self:initGame()
end

function CodeGameScreenGirlsCookMachine:initGame()

    --初始化基本数据
    self:initMachine(self.m_moduleName)

    self.m_configData = gLobalResManager:getCSVLevelConfigData("GirlsCookConfig.csv", "LevelGirlsCookConfig.lua")

end  

--[[
    初始轮盘
]]
function CodeGameScreenGirlsCookMachine:initRandomSlotNodes()
    
    if self.m_currentReelStripData == nil then
        if self.m_configData:isHaveInitReel() then
            self:initSlotNodes()
        else
            self:randomSlotNodes()
        end
        
    else
        self:randomSlotNodesByReel()
    end

end

--[[
    根据配置初始轮盘
]]
function CodeGameScreenGirlsCookMachine:initSlotNodes( )
    self.m_initGridNode = true
    for colIndex=1,self.m_iReelColumnNum do
        local columnData = self.m_reelColDatas[colIndex]
        local halfNodeH = columnData.p_showGridH * 0.5
        local rowCount = columnData.p_showGridCount
        -- local reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(colIndex)
        local initDatas = self.m_configData:getInitReelDatasByColumnIndex(colIndex)
        local parentData = self.m_slotParents[colIndex]
        local startIndex = 1
        for rowIndex=1,rowCount do
            local symbolType = initDatas[startIndex]
            startIndex = startIndex + 1
            if startIndex > #initDatas then
                startIndex = 1
            end

            local node = self:getSlotNodeWithPosAndType(symbolType,rowIndex,colIndex,false)
            node.p_slotNodeH = columnData.p_showGridH      
           
            node.p_symbolType = symbolType
            node.p_showOrder = self:getBounsScatterDataZorder(node.p_symbolType) - rowIndex
           

            if not node:getParent() then
                local slotParentBig = parentData.slotParentBig
                if slotParentBig and self.m_configData:checkSpecialSymbol(node.p_symbolType) then
                    slotParentBig:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                else
                    parentData.slotParent:addChild(node,
                    node.p_showOrder, colIndex * SYMBOL_NODE_TAG + rowIndex)
                end
            else
                node:setTag(colIndex * SYMBOL_NODE_TAG + rowIndex)
                node:setLocalZOrder(node.p_showOrder)
                node:setVisible(true)
            end
            
            node.p_reelDownRunAnima = parentData.reelDownAnima

            node.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
            node:setPositionX(parentData.startX + self.m_SlotNodeW * 0.5)
            node:setPositionY(  (rowIndex - 1) * columnData.p_showGridH + halfNodeH )
        end
    end
    self:initGridList()
end

---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenGirlsCookMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "GirlsCook"  
end

function CodeGameScreenGirlsCookMachine:initFreeSpinBar()
    self.m_baseFreeSpinBar = util_createView("CodeGirlsCookSrc.GirlsCookFreespinBarView")
    self:findChild("Node_free_cishu"):addChild(self.m_baseFreeSpinBar)
    util_setCsbVisible(self.m_baseFreeSpinBar, false)
end


function CodeGameScreenGirlsCookMachine:initUI()

    self:initFreeSpinBar() -- FreeSpinbar
    --倒计时用节点
    self.m_countDownNode = cc.Node:create()
    self:addChild(self.m_countDownNode)

    --特效层
    self.m_effectNode = cc.Node:create()
    self:findChild("root"):addChild(self.m_effectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self:findChild("Node_collect"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 1000)

    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)

    --jackpot
    self.m_jackpotBar = util_createView("CodeGirlsCookSrc.GirlsCookJackPotBarView",{machine = self})
    self:findChild("jackpot"):addChild(self.m_jackpotBar)
    self.m_jackpotBar:setVisible(false)

    --freespin中奖框
    self.m_freeHitNode = util_createView("CodeGirlsCookSrc.GirlsCookFreeSpinHitNode",{machine = self})
    self:findChild("root"):addChild(self.m_freeHitNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 10)
    self.m_freeHitNode:setPosition(self:getNodePosByColAndRow(2,3,self:findChild("root")))

    --emoji收集框
    self.m_emoji_collect = util_createAnimation("GirlsCook_emoji_collect.csb")
    self:findChild("Node_emoji_collect"):addChild(self.m_emoji_collect)

   
    self.m_customers = {}
    self.m_customers_free = {}
    self.m_emojis = {}
    self.m_collectProcess = {}
    self.m_leftTimes = {}

    --收集菜单
    self.m_collectMenus = {}

    --金币特效
    self.m_coin_anis = {}

    for index = 1,3 do
        local countDownNode = self:findChild("daojishi_"..(index - 1).."_"..(index - 1))
        local menu = util_createView("CodeGirlsCookSrc.GirlsCookCollectMenu",{machine = self})
        countDownNode:addChild(menu)
        menu:setVisible(false)
        self.m_collectMenus[index] = menu

        self:findChild("Node_pos_"..(index - 1)):setLocalZOrder(ORDER_ENTER - index)

        local leftTimeItem = util_createView("CodeGirlsCookSrc.GirlsCookLeftTimes",{machine = self})
        self:findChild("Node_jindu_"..(index - 1)):addChild(leftTimeItem)
        leftTimeItem:setVisible(false)
        self.m_leftTimes[index] = leftTimeItem

        local coinAni = util_createAnimation("GirlsCook_juese_jinbi.csb")
        self:findChild("Node_jinbi_"..(index - 1)):addChild(coinAni)
        self:findChild("Node_jinbi_"..(index - 1)):setLocalZOrder(ORDER_ENTER + 10 + index)
        coinAni:setVisible(false)
        self.m_coin_anis[index] = coinAni

        -----------------------------------------------------------------------------------------

        --base下人物可以重复,free下人物不重复,所以要分开创建
        local spine = util_spineCreate(SPINE_CUSTOMER[index],true,true)
        self:findChild("Node_logo_"..(index - 1).."_"..(index - 1)):addChild(spine)
        self.m_customers[index] = spine
        spine.figure = index
        spine:setVisible(false)

        local spine_free = util_spineCreate(SPINE_CUSTOMER[index],true,true)
        self:findChild("Node_logo_free_"..(index - 1)):addChild(spine_free)
        self.m_customers_free[index] = spine_free
        spine_free:setVisible(false)

        --emoji表情
        local emoji = util_createAnimation("GirlsCook_emoji.csb")
        self:findChild("Node_emoji_"..(index - 1).."_"..(index - 1)):addChild(emoji)
        self.m_emojis[index] = emoji
        emoji:setVisible(false)
    end

    self.m_foodItems = {}
 
    self:showBaseUI()
    

end


function CodeGameScreenGirlsCookMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        self:playEnterGameSound( "GirlsCookSounds/sound_GirlsCook_enter_game.mp3" )
        
        self:delayCallBack(3,function()
            self:resetMusicBg()
            if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                self:reelsDownDelaySetMusicBGVolume( ) 
            end
        end)

    end,0.4,self:getModuleName())
end

function CodeGameScreenGirlsCookMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end

    self.m_countDownNode:onUpdate(function(dt)
        self.m_refreshTime = self.m_refreshTime + dt
        if self.m_refreshTime < 1 then
            return
        end

        self.m_refreshTime = 0
        --当前状态判断 滚轮转动时不刷新数据
        if self:getCurrSpinMode() == FREE_SPIN_MODE then
            return
        end
        --刷新数据
        for index = 1,3 do
            self.m_leftTimes[index]:countDown()
        end
    end)

    self:changeBgAni(BASE_IDLE)
    BaseNewReelMachine.onEnter(self)     -- 必须调用不予许删除

    
    --检测是否增加freespin次数
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        local newCount = self.m_runSpinResultData.p_freeSpinNewCount
        local leftCount = self.m_runSpinResultData.p_freeSpinsLeftCount

        self.m_baseFreeSpinBar:updateFreespinCount(leftCount - newCount)
    end

    self.m_freeHitNode:setVisible(self:getCurrSpinMode() == FREE_SPIN_MODE)

    self:addObservers()

    --刷新收集数据
    self:refreshDishCollectData(true)

    --初始化食物
    self:initFoodUI()
end

function CodeGameScreenGirlsCookMachine:initGameStatusData(gameData)
    BaseSlotoManiaMachine.initGameStatusData(self, gameData)
    self.m_dishCollect = gameData.gameConfig.extra.dishCollect
end

--[[
    修改背景
]]
function CodeGameScreenGirlsCookMachine:changeBgAni(bgType)
    if bgType == BASE_IDLE then --base状态
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"normal",true})
        self:runCsbAction("normal")
    elseif bgType == FREE_IDLE then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"freespin",true})
        self:runCsbAction("free")
    elseif bgType == BASE_TO_FREE then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"nor_free",false,function (  )
            self:changeBgAni(FREE_IDLE)
        end})
    elseif bgType == FREE_TO_BASE then
        gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,{"free_nor",false,function (  )
            self:changeBgAni(BASE_IDLE)
        end})
    end
end

--[[
    显示emoji表情
]]
function CodeGameScreenGirlsCookMachine:showEmoji(index,emotion)
    local emoji = self.m_emojis[index]
    emoji:setVisible(true)
    emoji:runCsbAction("actionframe",false,function()
        emoji:setVisible(false)
    end)

    emoji:findChild("GirlsCook_emoji_kaixin"):setVisible(emotion == STATUS_EMOJI.HAPPY)
    emoji:findChild("GirlsCook_emoji_pingchang"):setVisible(emotion == STATUS_EMOJI.NORMAL)
    emoji:findChild("GirlsCook_emoji_weiqu"):setVisible(emotion == STATUS_EMOJI.SAD)
    emoji:findChild("GirlsCook_emoji_angry"):setVisible(emotion == STATUS_EMOJI.ANGRY)
    emoji:findChild("GirlsCook_emoji_wancheng"):setVisible(emotion == STATUS_EMOJI.FINISHED)

    if emotion == STATUS_EMOJI.FINISHED then
        local tempSp = cc.Sprite:createWithSpriteFrameName("common/GirlsCook_emoji_wancheng.png")
        self.m_effectNode:addChild(tempSp)
        local startPos = util_convertToNodeSpace(emoji:findChild("GirlsCook_emoji_wancheng"),self.m_effectNode)
        local endPos = util_convertToNodeSpace(self.m_emoji_collect:findChild("GirlsCook_emoji_kaixin_3"),self.m_effectNode)

        tempSp:setPosition(startPos)

        tempSp:setScale(emoji:findChild("GirlsCook_emoji_wancheng"):getScale())

        local seq = cc.Sequence:create({
            cc.DelayTime:create(0.5),
            cc.EaseSineIn:create(cc.MoveTo:create(0.4,endPos)),
            cc.CallFunc:create(function()
                self.m_emoji_collect:runCsbAction("actionframe")
            end),
            cc.Hide:create(),
            cc.DelayTime:create(10 / 60),
            cc.CallFunc:create(function()
                self:refreshHappyEmojiCount()
            end),
            cc.RemoveSelf:create(true)
        })

        gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_emoji_collect.mp3")
        tempSp:runAction(seq)
    end
end

--[[
    初始化食物
]]
function CodeGameScreenGirlsCookMachine:initFoodUI()
    if not self.m_dishCollect then
        return
    end

    --刷新笑脸数量
    self:refreshHappyEmojiCount()


    local dishCollect = self.m_dishCollect

    self.m_foodItems = {}
    self.m_collectProcess = {}
    --设置食物
    for index = 1,3 do
        local dishData = dishCollect[index]
        if dishData then
            self:initFoodByPosition(dishData,index)
            --检测是否需要修改spine
            local spine = self.m_customers[index]
            if spine.figure ~= dishData.figure then
                self:changeCustomerSpine(dishData,index)
            end
        end
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    --第一次进关卡
    if not selfData then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self:custormsEnterAni(function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, true})
            self:refreshFoodPercent()
            
        end)
        
    else
        

        --更新顾客状态
        self:updateCustomsEmotion(true)

        self:refreshFoodPercent(true)
    end

    self:refreshCountDown()
end

--[[
    刷新笑脸数量
]]
function CodeGameScreenGirlsCookMachine:refreshHappyEmojiCount()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    local completeRewardCount = 0
    if selfData then
        completeRewardCount = selfData.completeRewardCount or 0
    end

    local lbl_count = self.m_emoji_collect:findChild("BitmapFontLabel_1")
    lbl_count:setString(completeRewardCount)
    self:updateLabelSize({label=lbl_count,sx=1,sy=1},116)
end

--[[
    按位置初始化食物
]]
function CodeGameScreenGirlsCookMachine:initFoodByPosition(dishData,index)
    if not dishData then
        return
    end

    self.m_foodItems[index] = nil
    self.m_collectProcess[index] = nil
    --设置食物
    local node_food = self:findChild("Node_food_"..(index - 1))
    node_food:removeAllChildren(true)
    node_food:setVisible(false)

    self.m_collectMenus[index]:initFood(dishData)
    self.m_leftTimes[index]:initFood(dishData)
    --获取信号值
    local signal = dishData.signal
    if FOOD_CSB[dishData.signal] then
        --创建食物
        local food = util_createAnimation(FOOD_CSB[dishData.signal])
        node_food:addChild(food)

        self.m_foodItems[index] = food
        food:setVisible(dishData.collectCount < dishData.targetCount)

        --收集进度
        local process = util_createAnimation("GirlsCook_menu_jindutiao.csb")
        food:findChild("Node_num"):removeAllChildren()
        food:findChild("Node_num"):addChild(process)
        self.m_collectProcess[index] = process
    end
end

--[[
    修改父节点
]]
function CodeGameScreenGirlsCookMachine:changeParent(node,newParent)
    local parent = node:getParent()
    if parent == newParent then
        return
    end

    util_changeNodeParent(newParent,node)
end

--[[
    顾客进场动画
]]
function CodeGameScreenGirlsCookMachine:custormsEnterAni(func)
    if not self.m_dishCollect then
        if type(func) == "function" then
            func()
        end
        return
    end
    local dishCollect = self.m_dishCollect

    --顾客进场动画
    for index = 1,3 do
        local dishData = dishCollect[index]
        if dishData then
            self:custormsEnterAniBySingle(dishData,index)
        end
    end

    self:delayCallBack(4,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    修改顾客spine
]]
function CodeGameScreenGirlsCookMachine:changeCustomerSpine(dishData,index)
    local spine = self.m_customers[index]
    if spine.figure ~= dishData.figure then
        spine:removeFromParent()

        spine = util_spineCreate(SPINE_CUSTOMER[dishData.figure],true,true)
        spine.figure = dishData.figure
        self:findChild("Node_logo_"..(index - 1).."_"..(spine.figure - 1)):addChild(spine)
        self.m_customers[index] = spine

        self:changeParent(self.m_collectMenus[index],self:findChild("daojishi_"..(index - 1).."_"..(spine.figure - 1)))
        self:changeParent(self.m_emojis[index],self:findChild("Node_emoji_"..(index - 1).."_"..(spine.figure - 1)))
        self.m_collectMenus[index]:setVisible(true)
    end
    return spine
end

--[[
    单个顾客进场动画
]]
function CodeGameScreenGirlsCookMachine:custormsEnterAniBySingle(dishData,index)
    if dishData and (not selfData or dishData.change) then
        local node_food = self:findChild("Node_food_"..(index - 1))

        self:findChild("Node_pos_"..(index - 1)):setLocalZOrder(ORDER_ENTER - 10 - index)
        
        local spine = self.m_customers[index]
        if spine.figure ~= dishData.figure then
            spine = self:changeCustomerSpine(dishData,index)
        end
        
        spine.isFinished = false
        spine.isIdled = false
        
        local delaytime = 0
        self:delayCallBack(delaytime,function()
            spine:setVisible(true)
            util_spinePlay(spine,"actionframe_jinchang",false)
            util_spineEndCallFunc(spine,"actionframe_jinchang",handler(nil,function(  )
                local selfData = self.m_runSpinResultData.p_selfMakeData
                if selfData then
                    gLobalSoundManager:playSound(ENTER_SOUND[dishData.figure])
                end
                
                self:findChild("Node_pos_"..(index - 1)):setLocalZOrder(ORDER_ENTER - index)
                self:delayCallBack(0.2 * (index - 1),function()
                    util_spinePlay(spine,"actionframe_sikao",false)
                    util_spineEndCallFunc(spine,"actionframe_sikao",handler(nil,function(  )

                        self:customerHappleIdleAni(spine)
                        
                        --设置等待状态
                        spine.emotion = STATUS_EMOTION.HAPPY
                        self:showEmoji(index,STATUS_EMOJI.HAPPY)
                        
                    end))
                end)
                
            end))
        end)
        self:delayCallBack(4,handler(nil,function()
            self.m_collectMenus[index]:startAni()
            self.m_leftTimes[index]:startAni()
        end) )
    end
end

--[[
    刷新食物收集进度
]]
function CodeGameScreenGirlsCookMachine:refreshFoodPercent(isNeedHide)
    if not self.m_dishCollect then
        return
    end

    
    local dishCollect = self.m_dishCollect
    for index = 1,3 do
        
        local dishData = dishCollect[index]
        if dishData then
            
            local node_food = self:findChild("Node_food_"..(index - 1))
            node_food:setVisible(self:getCurrSpinMode() ~= FREE_SPIN_MODE)

            
            if not self.m_collectMenus[index].m_isOver then
                self.m_collectMenus[index]:setVisible(self:getCurrSpinMode() ~= FREE_SPIN_MODE)
                self.m_collectMenus[index]:runCsbAction("idle")
            end

            if not self.m_leftTimes[index].m_isOver then
                self.m_leftTimes[index]:setVisible(self:getCurrSpinMode() ~= FREE_SPIN_MODE)
                self.m_leftTimes[index]:runCsbAction("idle")
            end
            
            --未收集完成才显示
            local percent = dishData.collectCount / dishData.targetCount
            if percent >= 1 then
                percent = 1
                
                --断线重连收集完成的隐藏人物
                if isNeedHide then
                    self.m_customers[index].isFinished = true
                    -- self.m_customers[index]:setVisible(self:getCurrSpinMode() ~= FREE_SPIN_MODE)
                end
            end

            local process = self.m_collectProcess[index]
            local leftCount = dishData.targetCount - dishData.collectCount
            if leftCount <= 0 then
                leftCount = 0
            end
            process:findChild("m_lb_num"):setString(leftCount)

            local foodItem = self.m_foodItems[index]
            local layout = foodItem:findChild("jindu")
            local size = layout:getContentSize()
            layout:setContentSize(CCSizeMake(size.width,self:getMaxHeight(dishData.signal) * percent))
        end
        
    end
end

--[[
    获取食物收集进度
]]
function CodeGameScreenGirlsCookMachine:getFoodPercent(foodIndex)
    if not self.m_dishCollect then
        return 0
    end

    
    local dishData = self.m_dishCollect[foodIndex]
    if dishData then
        local percent = dishData.collectCount / dishData.targetCount
        if percent >= 1 then
            percent = 1
        end
        return percent
    end

    return 0
end

--[[
    获取最大高度
]]
function CodeGameScreenGirlsCookMachine:getMaxHeight(symbolType)
    return MAX_HEIGHT[symbolType] or 0
end

--[[
    检测收集完成,执行吃的动作
]]
function CodeGameScreenGirlsCookMachine:checkEatAction(func)
    if not self.m_dishCollect then
        if type(func) == "function" then
            func()
        end
        return
    end
    local oldCollect = self.m_runSpinResultData.p_selfMakeData.oldCollect
    local delayTime = 0
    local dishCollect = self.m_dishCollect
    if oldCollect then
        dishCollect = oldCollect
    end
    
    for index = 1,3 do
        local dishData = dishCollect[index]
        if dishData then
            local leftTime = dishData.surplusTime
            local spine = self.m_customers[index]

            

            local percent = dishData.collectCount / dishData.targetCount
            if percent >= 1 and not spine.isFinished and dishData.amount and dishData.amount > 0 then
                percent = 1
                
                delayTime = (45 + 60 + 60) / 30

                local foodItem = self.m_foodItems[index]
                
                spine.isFinished = true

                --规定时间内收集或在第一阶段次数内收集显示笑脸
                if dishData.collectType == "TIME" or (dishData.collectType == "COUNT" and dishData.spinCount <= dishData.firstCount) then
                    self:showEmoji(index,STATUS_EMOJI.FINISHED)
                end
                

                self:findChild("Node_pos_"..(index - 1)):setLocalZOrder(ORDER_ENTER - 10 - index)
                gLobalSoundManager:playSound(EAT_SOUND[dishData.figure])
                util_spinePlay(spine,"actionframe_chi_kaixin")
                util_spineEndCallFunc(spine,"actionframe_chi_kaixin",handler(nil,function(  )
                    util_spinePlay(spine,"actionframe_jiman",false)
                    
                    util_spineEndCallFunc(spine,"actionframe_jiman",handler(nil,function(  )
                        -- if dishData.figure ~= 3 then
                        --     gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_customer_leave.mp3")
                        -- end
                        
                        util_spinePlay(spine,"actionframe_chuchang")
                        util_spineEndCallFunc(spine,"actionframe_chuchang",handler(nil,function(  )
                            spine:setVisible(false)
                        end))

                        -- util_spinePlay(spine,"idleframe_freekaixin",true)
                    end))
                    self.m_coin_anis[index]:setVisible(true)
                    self.m_coin_anis[index]:runCsbAction("actionframe",false,function()
                        self.m_coin_anis[index]:setVisible(false)
                    end)
                    gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_fly_coin.mp3")
                    self:runFlyLineInFoodCollect(foodItem,self.m_bottomUI.coinWinNode,function()
                        local lightEffect = util_createAnimation("GirlsCook_jinbifankui.csb")
                        self.m_effectNode2:addChild(lightEffect)
                        lightEffect:setPosition(util_convertToNodeSpace(self.m_bottomUI.coinWinNode,self.m_effectNode2))
                        lightEffect:runCsbAction("actionframe",false,function()
                            lightEffect:removeFromParent()
                        end)
                        if not self.m_isRefreshCollectWinCoins then
                            
                            local params = {self.m_runSpinResultData.p_selfMakeData.dishAmount or 0,false}
                            params[self.m_stopUpdateCoinsSoundIndex] = true
                            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
                            self.m_isRefreshCollectWinCoins = true
                        end
                    end)
                    foodItem:runCsbAction("actionframe2")
                    
                    
                end))
                
                self.m_collectMenus[index]:overAni()
                self.m_leftTimes[index]:overAni()
                

                self.m_collectWinCoins = self.m_runSpinResultData.p_selfMakeData.dishAmount or 0

            elseif dishData.change then
                delayTime = (60 + 60) / 30
                self:findChild("Node_pos_"..(index - 1)):setLocalZOrder(ORDER_ENTER - 10 - index)
                util_spinePlay(spine,"idleframe_02pingchang")
                util_spineEndCallFunc(spine,"idleframe_02pingchang",handler(nil,function(  )
                    gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_customer_leave.mp3")
                    util_spinePlay(spine,"actionframe_chuchang")
                    util_spineEndCallFunc(spine,"actionframe_chuchang",handler(nil,function(  )
                        spine:setVisible(false)
                    end))
                    -- util_spinePlay(spine,"idleframe_02pingchang",true)
                end))

                self:showEmoji(index,STATUS_EMOJI.SAD)

                self.m_collectMenus[index]:overAni()
                self.m_leftTimes[index]:overAni()
            end
        end
        
    end

    local laseWinCoin = globalData.slotRunData.lastWinCoin
    globalData.slotRunData.lastWinCoin = 0
    self:delayCallBack(delayTime,function()
        globalData.slotRunData.lastWinCoin = laseWinCoin
        self.m_isRefreshCollectWinCoins = false
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    食物吃完收集金币
]]
function CodeGameScreenGirlsCookMachine:eatOverAndFlyCoin(foodItem)
    local tempNode = util_createAnimation(foodItem.m_baseFilePath)
    self.m_effectNode2:addChild(tempNode)
    tempNode:setPosition(util_convertToNodeSpace(foodItem,self.m_effectNode2))
    foodItem:setVisible(false)
    tempNode:runCsbAction("actionframe2",false,function()
        tempNode:runCsbAction("actionframe3")
    end)

    self.m_collectWinCoins = self.m_runSpinResultData.p_selfMakeData.dishAmount or 0

    local seq = cc.Sequence:create({
        cc.DelayTime:create(50 / 60),
        cc.EaseSineIn:create(cc.MoveTo:create(0.5,util_convertToNodeSpace(self.m_bottomUI.coinWinNode,self.m_effectNode2))),
        cc.CallFunc:create(function()
            local lightEffect = util_createAnimation("GirlsCook_jinbifankui.csb")
            self.m_effectNode2:addChild(lightEffect)
            lightEffect:setPosition(util_convertToNodeSpace(self.m_bottomUI.coinWinNode,self.m_effectNode2))
            lightEffect:runCsbAction("actionframe",false,function()
                lightEffect:removeFromParent()
            end)

            if not self.m_isAlreadyRefreshWinCoins then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_collectWinCoins,false})
                self.m_isAlreadyRefreshWinCoins = true
            end
            
        end),
        cc.RemoveSelf:create(true)
    })
    tempNode:runAction(seq)
end

--[[
    刷新收集数据
]]
function CodeGameScreenGirlsCookMachine:refreshDishCollectData(isInit)

    if isInit then
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end

    if not isInit and selfData.oldCollect then
        self.m_dishCollect = clone(selfData.oldCollect) 
    else
        self.m_dishCollect = clone(selfData.dishCollect) 
    end
    
end

--[[
    刷新倒计时
]]
function CodeGameScreenGirlsCookMachine:refreshCountDown()
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        return
    end
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not self.m_dishCollect then
        return
    end
    local dishCollect = self.m_dishCollect


    for index = 1,3 do
        local dishData = dishCollect[index]
        if dishData then
            self.m_leftTimes[index]:updataCountDownTimes(dishData)
        end
    end
end

--[[
    更新顾客心情
]]
function CodeGameScreenGirlsCookMachine:updateCustomsEmotion(isInit)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for index = 1,3 do
            local spine = self.m_customers_free[index]
            if not spine.isFreeIdle then
                spine.isFreeIdle = true
                spine:setVisible(true)
                util_spinePlay(spine,"idleframe_freekaixin",true)
            end

            self.m_customers[index]:setVisible(false)
        end
        return
    end

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not self.m_dishCollect then
        return
    end
    local dishCollect = self.m_dishCollect

    for index = 1,3 do
        local dishData = dishCollect[index]
        local spine = self.m_customers[index]
        spine.isFreeIdle = false
        if dishData and dishData.collectType == "COUNT" then
            

            local leftTime = dishData.firstCount - dishData.spinCount

            --计算当前剩余时间对应的顾客状态
            local status = STATUS_EMOTION.HAPPY
            if leftTime > 10 then  --开心
                status = STATUS_EMOTION.HAPPY
            else    --焦急
                status = STATUS_EMOTION.SAD
            end

            if leftTime == 10 then
                self:showEmoji(index,STATUS_EMOJI.NORMAL)
            elseif leftTime == 0 and (not dishData.amount or dishData.amount == 0) then
                self:showEmoji(index,STATUS_EMOJI.ANGRY)
            end
            
            if spine.emotion ~= status then
                spine.emotion = status

                if status == STATUS_EMOTION.HAPPY then
                    self:delayCallBack(0.2 * (index - 1),function()
                        self:customerHappleIdleAni(spine)
                    end)
                    
                elseif status == STATUS_EMOTION.SAD then
                    if not isInit then
                        gLobalSoundManager:playSound(SAD_SOUND[dishData.figure])
                    end
                    
                    util_spinePlay(spine,"idleframe_02pingchang_03jiaoji",false)
                    util_spineEndCallFunc(spine,"idleframe_02pingchang_03jiaoji",handler(nil,function(  )
                        util_spinePlay(spine,"idleframe_03jiaoji",true)
                    end))
                end
            end
        elseif dishData and dishData.collectType == "TIME" then
            if not spine.isIdled then
                self:delayCallBack(0.2 * (index - 1),function()
                    self:customerHappleIdleAni(spine)
                end)
                spine.isIdled = true
            end
            
        end
    end
end

--[[
    顾客次数充足时idle
]]
function CodeGameScreenGirlsCookMachine:customerHappleIdleAni(spine)
    util_spinePlay(spine,"idleframe",true)
end

function CodeGameScreenGirlsCookMachine:addObservers()
    BaseNewReelMachine.addObservers(self)

    --更改bet时触发
    gLobalNoticManager:addObserver(self,function(self, params)
        if self.m_dishCollect then
            for index = 1,3 do
                local dishData = self.m_dishCollect[index]
                if dishData then
                    self.m_collectMenus[index]:updateReward(dishData)
                end
            end
        end
        
    end,
    ViewEventType.NOTIFY_BET_CHANGE)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if params[self.m_stopUpdateCoinsSoundIndex] then
            -- 此时不应该播放赢钱音效
            return
        end
        
        if self.m_bIsBigWin then
            return
        end

        -- 赢钱音效添加 目前是写的根据获得钱数倍数分为四挡的格式--具体问策划
        local winCoin = params[1]
        
        local totalBet = globalData.slotRunData:getCurTotalBet()
        local winRate = winCoin / totalBet
        local soundIndex = 2
        if winRate > 0 then
            if winRate <= 1 then
                soundIndex = 1
            elseif winRate > 1 and winRate <= 3 then
                soundIndex = 2 
            elseif winRate > 3 then
                soundIndex = 3
            end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "GirlsCookSounds/music_GirlsCook_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,0.4,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenGirlsCookMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    BaseNewReelMachine.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    self.m_countDownNode:unscheduleUpdate()

    scheduler.unschedulesByTargetName(self:getModuleName())

end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenGirlsCookMachine:MachineRule_GetSelfCCBName(symbolType)

    
    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenGirlsCookMachine:getPreLoadSlotNodes()
    local loadNode = BaseNewReelMachine.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenGirlsCookMachine:MachineRule_initGame(  )

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        self:showFreeSpinUI()
        self:changeBgAni(FREE_IDLE)
        self.m_baseFreeSpinBar:idleAni()
        util_setCsbVisible(self.m_baseFreeSpinBar, true)
        self.m_jackpotBar:refreshCoins(self.m_runSpinResultData.p_selfMakeData.rewards,true)
    else
        self:showBaseUI()
    end
end

--
--单列滚动停止回调
--
function CodeGameScreenGirlsCookMachine:slotOneReelDown(reelCol)    
    BaseNewReelMachine.slotOneReelDown(self,reelCol)

    local isScatterDown = false
    for iRow = 1,self.m_iReelRowNum do
        local symbol = self:getFixSymbol(reelCol,iRow)
        if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
            symbol:runAnim("buling")
            isScatterDown = true
        end
    end

    if isScatterDown then

        local soundPath = "GirlsCookSounds/sound_GirlsCook_scatter_down.mp3"
        if self.playBulingSymbolSounds then
            self:playBulingSymbolSounds( reelCol,soundPath )
        else
            gLobalSoundManager:playSound(soundPath)
        end

    end
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenGirlsCookMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenGirlsCookMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


----------- FreeSpin相关
-- FreeSpinstart
function CodeGameScreenGirlsCookMachine:showFreeSpinView(effectData)

    

    local showFSView = function ( ... )
        
        if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
            gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_fs_start.mp3")
            self:showFreeSpinMore(
                self.m_runSpinResultData.p_freeSpinNewCount,
                function()
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end,
                true
            )
        else

            local func = function()
                self:updateCustomsEmotion()
                self:showFreeSpinUI()
                
                self.m_jackpotBar:refreshCoins(self.m_runSpinResultData.p_selfMakeData.rewards,false)
                gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_fs_start.mp3")
                local view = self:showFreeSpinStart(self.m_iFreeSpinTimes,function()
                    
            
                    util_changeNodeParent(self:findChild("Node_free_cishu"),self.m_baseFreeSpinBar)
                    self.m_baseFreeSpinBar:setPosition(cc.p(0,0))
                    self:triggerFreeSpinCallFun()
                    effectData.p_isPlay = true
                    self:playGameEffect()       
                end)
                view:findChild("Node_Root"):setScale(self.m_machineRootScale)
                view:findChild("Node_Ani"):setScale(self.m_machineRootScale)

                self:delayCallBack(0.6,function()
                    --更换背景
                    self:changeBgAni(BASE_TO_FREE)
                end)

                --设置点击回调
                view:setBtnClickFunc(function()
                    self:flyFreeTimes(view,self.m_iFreeSpinTimes,false)
                end)

                -- view:setPosition(cc.p(display.width / 2,display.height / 2))
            end

            for iCol = 1,self.m_iReelColumnNum do
                for iRow = 1,self.m_iReelRowNum do
                    local symbol = self:getFixSymbol(iCol,iRow)
                    if symbol and symbol.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                        --修改触发动画层级
                        self:setSlotNodeEffectParent(symbol)
                        symbol:runAnim("actionframe",false,function()
                            symbol:runAnim("idle",true)
                            self:resetMaskLayerNodes()
                        end)
                    end
                end
            end
            gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_scatter_trigger.mp3")

            self:setCurrSpinMode(FREE_SPIN_MODE)
            self:delayCallBack(2,func)
        end
        
    end

    --  延迟0.5 不做特殊要求都这么延迟
    performWithDelay(self,function(  )
        
        showFSView()    
    end,0.5)
end

--[[
    freespin增加次数
]]
function CodeGameScreenGirlsCookMachine:flyFreeTimes(view,addTimes,isMore,func)
    local tempTimes = util_createAnimation("GirlsCook_free_cishu_fly.csb")
    tempTimes:findChild("m_lb_num"):setString(addTimes)
    local startNode = view:findChild("number")
    local endNode = self:findChild("Node_free_cishu")

    util_changeNodeParent(view:findChild("Node_Ani"),self.m_baseFreeSpinBar)
    
    
    

    local startPos = util_convertToNodeSpace(startNode,view:findChild("Node_Ani"))
    local endPos = util_convertToNodeSpace(endNode,view:findChild("Node_Ani"))

    self.m_baseFreeSpinBar:setPosition(endPos)

    view:findChild("Node_Ani"):addChild(tempTimes)
    tempTimes:setPosition(startPos)

    local seq = cc.Sequence:create({
        cc.EaseSineOut:create(cc.MoveTo:create(20 / 60,endPos)),
        cc.CallFunc:create(function()

        end)
    })

    tempTimes:runCsbAction("actionframe",false,function()
        if type(func) == "function" then
            func()
        end
    end)

    tempTimes:runAction(seq)
    gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_free_fly_add_times.mp3")
    

    if isMore then
        self.m_baseFreeSpinBar:addTimesAni()
    else
        self.m_baseFreeSpinBar:changeFreeSpinByCount()
        util_setCsbVisible(self.m_baseFreeSpinBar, true)
        self.m_baseFreeSpinBar:startAni()
    end
end

function CodeGameScreenGirlsCookMachine:showFreeSpinMore(num,func,isAuto)

    local freeSpinMoreView = util_createAnimation("GirlsCook/FreeSpinMore.csb")
    if globalData.slotRunData.machineData.p_portraitFlag then
        freeSpinMoreView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(freeSpinMoreView)

    -- freeSpinMoreView:setPosition(cc.p(display.width / 2,display.height / 2))

    local function newFunc()
        self:resetMusicBg(true)  
        gLobalNoticManager:postNotification(ViewEventType.SHOW_FREE_SPIN_NUM)

        util_changeNodeParent(self:findChild("Node_free_cishu"),self.m_baseFreeSpinBar)
        self.m_baseFreeSpinBar:setPosition(cc.p(0,0))
        freeSpinMoreView:removeFromParent()
        if func then
            func()
        end
    end

    freeSpinMoreView:findChild("m_lb_num"):setString(num)
    freeSpinMoreView:findChild("Node_Root"):setScale(self.m_machineRootScale)
    freeSpinMoreView:findChild("Node_Ani"):setScale(self.m_machineRootScale)

    freeSpinMoreView:runCsbAction("auto",false,newFunc)
    self:delayCallBack(124 / 60,function()
        self:flyFreeTimes(freeSpinMoreView,num,true)
    end)
end

--[[
    显示freespin相关UI
]]
function CodeGameScreenGirlsCookMachine:showFreeSpinUI()
    self.m_jackpotBar:setVisible(true)
    self:findChild("Node_food"):setVisible(false)
    self.m_emoji_collect:setVisible(false)
    for index = 1,3 do
        local node_food = self:findChild("Node_food_"..(index - 1))
        node_food:setVisible(false)

        self.m_collectMenus[index]:setVisible(false)

        self.m_customers_free[index]:setVisible(true)
        self.m_customers[index]:setVisible(false)
    end

    if self.m_freeHitNode then
        self.m_freeHitNode:setVisible(true)
    end
end

--[[
    显示base相关UI
]]
function CodeGameScreenGirlsCookMachine:showBaseUI()
    self.m_jackpotBar:setVisible(false)
    self.m_emoji_collect:setVisible(true)
    self:findChild("Node_food"):setVisible(true)

    for k,spine in pairs(self.m_customers) do
        spine:setVisible(false)
    end

    for index = 1,3 do
        
        
        local node_food = self:findChild("Node_food_"..(index - 1))
        node_food:setVisible(true)

        self.m_collectMenus[index]:setVisible(true)

        if self.m_dishCollect then
            local dishData = self.m_dishCollect[index]
            if dishData then
                local spine = self.m_customers[index]
                if not spine.isFinished then
                    spine:setVisible(true)
                end
            end
        end

        self.m_customers_free[index]:setVisible(false)
        
    end

    if self.m_freeHitNode then
        self.m_freeHitNode:setVisible(false)
    end
    
end

function CodeGameScreenGirlsCookMachine:showFreeSpinOverView()

    -- gLobalSoundManager:playSound("GirlsCookSounds/music_GirlsCook_over_fs.mp3")
    if not self.m_isAlreadyRefreshWinCoins then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,false})
        self.m_isAlreadyRefreshWinCoins = true
    end
    self:refreshHappyEmojiCount()
    
    self.m_effectNode:removeAllChildren()
    self:delayCallBack(0.5,function()
        --更换背景
        self:changeBgAni(FREE_TO_BASE)
        self:showBaseUI()
    end)
    

    local strCoins=util_formatCoins(globalData.slotRunData.lastWinCoin,50)
    gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_freespin_over.mp3")
    local view = self:showFreeSpinOver( strCoins, 
        self.m_runSpinResultData.p_freeSpinsTotalCount,function()
        self:triggerFreeSpinOverCallFun()
        
    end)
    local node=view:findChild("BitmapFontLabel_2")
    node:setString(strCoins)
    view:updateLabelSize({label=node,sx=1,sy=1},623)
    -- view:setPosition(cc.p(display.width / 2,display.height / 2))
    

    self.m_jackpotBar:resetData()

    self.m_baseFreeSpinBar:overAni()

    if globalData.slotRunData.m_isAutoSpinAction then
        self:setCurrSpinMode(AUTO_SPIN_MODE)
    else
        self:setCurrSpinMode(NORMAL_SPIN_MODE)
    end
    self:updateCustomsEmotion()
    --刷新顾客
    self:refreshFoodPercent(true)
end

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenGirlsCookMachine:MachineRule_SpinBtnCall()
    
    -- self:setMaxMusicBGVolume( )

    if self.m_winSoundsId ~= nil then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
        self.m_winSoundsId = nil
    end
    self.m_isAlreadyRefreshWinCoins = false
    self.m_collectWinCoins = 0

    self.m_isLongRun = false
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenGirlsCookMachine:addSelfEffect()

    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end

    if selfData.rewards and #selfData.rewards ~= 0 then
        for key,reward in pairs(selfData.rewards) do
            if reward.hit then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.FREESPIN_COLLECT_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.FREESPIN_COLLECT_EFFECT -- 动画类型
                break
            end
        end
        
    end
    

    --判断是否需要收集
    local dishCollect = selfData.dishCollect
    if selfData.oldCollect then
        dishCollect = selfData.oldCollect
    end
    if dishCollect then

        if self:getCurrSpinMode() ~= FREE_SPIN_MODE then
            local selfEffect = GameEffectData.new()
            selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
            selfEffect.p_effectOrder = self.FOOD_COLLECT_EFFECT
            self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
            selfEffect.p_selfEffectType = self.FOOD_COLLECT_EFFECT -- 动画类型
        end

        for index = 1,3 do
            local dishData = dishCollect[index]
            if dishData and dishData.change and self:getCurrSpinMode() ~= FREE_SPIN_MODE then
                local selfEffect = GameEffectData.new()
                selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect.p_effectOrder = self.FOOD_COLLECT_OVER_EFFECT
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
                selfEffect.p_selfEffectType = self.FOOD_COLLECT_OVER_EFFECT -- 动画类型

                --顾客进场
                local selfEffect2 = GameEffectData.new()
                selfEffect2.p_effectType = GameEffect.EFFECT_SELF_EFFECT
                selfEffect2.p_effectOrder = GameEffect.EFFECT_EPICWIN + 1
                self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect2
                selfEffect2.p_selfEffectType = self.CUSTOMER_ENTER_EFFECT -- 动画类型


                if not self.m_runSpinResultData.p_winLines or (self.m_runSpinResultData.p_winLines and #self.m_runSpinResultData.p_winLines == 0) then
                    --检测大赢
                    self:checkFeatureOverTriggerBigWin(selfData.dishAmount,-1)
                end
                break
            end
        end
    end

end

--[[
    收集动画
]]
function CodeGameScreenGirlsCookMachine:collectAni(func)
    local isCollect = false
    --遍历所有信号小块
    for iCol=1,self.m_iReelColumnNum do
        for iRow=1,self.m_iReelRowNum do
            local symbol = self:getFixSymbol(iCol, iRow)
            if symbol then
                local symbolType = symbol.p_symbolType
                local isInCollectList,foodIndex = self:isInCollectList(symbolType)
                if isInCollectList then
                    isCollect = true
                    local flyNode = self:runFlyLineAni(symbol,self:findChild("Node_food_"..(foodIndex - 1)),function()
                        local foodItem = self.m_foodItems[foodIndex]
                        local percent = self:getFoodPercent(foodIndex)
                        if foodItem then
                            foodItem:runCsbAction("actionframe1",false,function()
                                --集满特效
                                if percent >= 1 then
                                    foodItem:runCsbAction("actionframe")
                                    self.m_collectProcess[foodIndex]:setVisible(false)
                                end
                            end)
                        end
                    end)

                    local ccbName = self:getSymbolCCBNameByType(self,symbolType)
                    local tempNode = util_createAnimation(ccbName..".csb")
                    tempNode:runCsbAction("actionframe1")
                    flyNode:addChild(tempNode)
                end
            end
        end
    end

    if isCollect then
        gLobalSoundManager:playSound("GirlsCookSounds/music_GirlsCook_food_collect.mp3")
        self:delayCallBack(15 / 60 + 0.5,function()
            --刷新收集进度
            self:refreshFoodPercent()
        end)
    end
    

    

    local delayTime = 0.5
    if self:isHaveCollectOver() then
        delayTime = 2
    end

    self:delayCallBack(delayTime,function()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    判断是否有收集满的
]]
function CodeGameScreenGirlsCookMachine:isHaveCollectOver()
    if not self.m_dishCollect then
        return false
    end

    --判断是否触发freespin
    local features = self.m_runSpinResultData.p_features
    for k,feature in pairs(features) do
        if feature == SLOTO_FEATURE.FEATURE_FREESPIN then
            return true
        end
    end

    
    local dishCollect = self.m_dishCollect
    for index = 1,3 do
        local dishData = dishCollect[index]
        if dishData then
            local percent = dishData.collectCount / dishData.targetCount
            if percent >= 1 and not self.m_customers[index].isFinished then
                return true
            end
        end
        
    end

    return false
end

--[[
    判断是否为所需收集品
]]
function CodeGameScreenGirlsCookMachine:isInCollectList(symbolType)
    if not self.m_dishCollect then
        return false,-1
    end
    local dishCollect = self.m_dishCollect
    for index = 1,3 do
        local dishData = dishCollect[index]
        
        if dishData then
            local signal = dishData.signal
            if signal == symbolType and not self.m_customers[index].isFinished then
                return true,index
            end
        end
        
    end
    return false,-1
end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenGirlsCookMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.FOOD_COLLECT_EFFECT then
        self:collectAni(function()
            self:checkEatAction(function()
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end)
        
        
    elseif effectData.p_selfEffectType == self.FOOD_COLLECT_OVER_EFFECT then
        local selfData = self.m_runSpinResultData.p_selfMakeData
        
        --收集完成
        self:showCollectOverView(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.CUSTOMER_ENTER_EFFECT then   --顾客进场
        local selfData = self.m_runSpinResultData.p_selfMakeData
        self.m_dishCollect = clone(selfData.dishCollect) 
        for index = 1,3 do
            local dishData = self.m_dishCollect[index]
            if dishData and dishData.change then
                self:initFoodByPosition(dishData,index)
                self:custormsEnterAniBySingle(dishData,index)
            end
        end
        
        local delayTime = 4

        self:delayCallBack(delayTime,function()
            self:refreshFoodPercent()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif effectData.p_selfEffectType == self.FREESPIN_COLLECT_EFFECT then
        self.m_freeHitNode:hitAni()
        local symbolNode = self:getFixSymbol(3,2)
        if symbolNode then
            symbolNode:runAnim("actionframe2")
            local lastAmounts = 0
            gLobalSoundManager:playSound(FREE_HIT_SOUND[symbolNode.p_symbolType])
            local tempNode = util_spineCreate(symbolNode.m_ccbName,true,true)
            self.m_effectNode:addChild(tempNode)
            tempNode:setPosition(util_convertToNodeSpace(symbolNode,self.m_effectNode))
            util_spinePlay(tempNode,"actionframe1",false)
            util_spineEndCallFunc(tempNode,"actionframe1",handler(nil,function(  )
                tempNode:setVisible(false)

                local selfData = self.m_runSpinResultData.p_selfMakeData
                
                for index = 1,3 do
                    local reward = selfData.rewards[index]
                    lastAmounts = lastAmounts + reward.lastAmount
                    if reward and reward.hit then
                        local spine = self.m_customers_free[index]
                        util_spinePlay(spine,"actionframe_shouji",false)
                        util_spineEndCallFunc(spine,"actionframe_shouji",handler(nil,function(  )
                            util_spinePlay(spine,"idleframe_freekaixin",true)
                        end))
                    end
                end

                self:refreshJackpot(function()
                    self.m_iOnceSpinLastWin = 0
                    effectData.p_isPlay = true
                    self:playGameEffect()
                end)
            end))
        else
            self:refreshJackpot(function()
                self.m_iOnceSpinLastWin = 0
                effectData.p_isPlay = true
                self:playGameEffect()
            end)
        end

        --没有连线
        if self.m_iOnceSpinLastWin == 0 then
            self.m_iOnceSpinLastWin = lastAmounts
        end
        self.m_isAlreadyRefreshWinCoins = true
        
        
        
    end

    return true
end

--[[
    刷新jackpot
]]
function CodeGameScreenGirlsCookMachine:refreshJackpot(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData
    self.m_jackpotBar:refreshCoins(selfData.rewards,false,function()
        gLobalSoundManager:playSound("GirlsCookSounds/sound_GirlsCook_fly_coin_free.mp3")
        for index = 1,3 do
            if selfData.rewards then
                local rewardData = selfData.rewards[index]
                if rewardData and rewardData.hit then
                    local startNode = self.m_jackpotBar:findChild("Node_"..index)
                    local endNode = self.m_bottomUI.coinWinNode
                    -- self:runFlyLineInHitFree(index,startNode,endNode)
                    self:runFlyLineInFoodCollect(startNode,endNode,function()
                        local params = {self.m_iOnceSpinLastWin,false}
                        params[self.m_stopUpdateCoinsSoundIndex] = true
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,params)
                    end)
                end
            end
        end

        -- self:delayCallBack(32 / 60,function()
        --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,false})
        -- end)
        
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    显示收集结果
]]
function CodeGameScreenGirlsCookMachine:showCollectOverView(func)
    local selfData = self.m_runSpinResultData.p_selfMakeData

    local endFunc = function(isNotFinish)

        local curTotalCoin = globalData.userRunData.coinNum
        globalData.coinsSoundType = 1
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN,curTotalCoin)

        if type(func) == "function" then
            func()
        end
    end

    if selfData.dishAmount and selfData.dishAmount > 0 then

        --需要显示的弹窗类型
        local viewTypes = {}
        for index = 1,3 do
            local dishData = self.m_dishCollect[index]
            if dishData and dishData.change and dishData.amount and dishData.amount > 0 then
                if not table.indexof(viewTypes,dishData.collectType) then
                    viewTypes[#viewTypes + 1] = dishData.collectType
                end
                
            end
        end

        self:setMinMusicBGVolume()
        if #viewTypes == 1 then
            local view = util_createView("CodeGirlsCookSrc.GirlsCookCollectOverView",{data = selfData,callBack = endFunc,viewType = viewTypes[1]})
            if globalData.slotRunData.machineData.p_portraitFlag then
                view.getRotateBackScaleFlag = function()
                    return false
                end
            end
            self:findChild("Node_collect"):addChild(view)
        else
            local view = util_createView("CodeGirlsCookSrc.GirlsCookCollectOverView",{data = selfData,callBack = function()
                local view1 = util_createView("CodeGirlsCookSrc.GirlsCookCollectOverView",{data = selfData,callBack = endFunc,viewType = viewTypes[2]})
                if globalData.slotRunData.machineData.p_portraitFlag then
                    view1.getRotateBackScaleFlag = function()
                        return false
                    end
                end
                self:findChild("Node_collect"):addChild(view1)
            end,viewType = viewTypes[1]})
            if globalData.slotRunData.machineData.p_portraitFlag then
                view.getRotateBackScaleFlag = function()
                    return false
                end
            end
            self:findChild("Node_collect"):addChild(view)
        end
    else
        endFunc(true)
    end
    
end


---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenGirlsCookMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenGirlsCookMachine:playEffectNotifyNextSpinCall( )

    BaseNewReelMachine.playEffectNotifyNextSpinCall( self )
    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenGirlsCookMachine:slotReelDown( )
    self:setMaxMusicBGVolume( )
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    --刷新收集数据
    -- self:refreshDishCollectData()

    --更新顾客状态
    self:updateCustomsEmotion()

    --刷新剩余次数
    if self.m_dishCollect then
        for index = 1,3 do
            local dishData = self.m_dishCollect[index]
            if dishData then
                if dishData.collectType == "COUNT" then
                    self.m_leftTimes[index]:updateLeftTimes(dishData)
                    self.m_collectMenus[index]:updateLeftTimes(dishData)
                end
            end
        end
    end
    

    BaseNewReelMachine.slotReelDown(self)
end

--[[
    延迟回调
]]
function CodeGameScreenGirlsCookMachine:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

--[[
    @desc: 获取滚动的 列表数据
    time:2020-07-21 18:30:10
    --@parentData:
    @return:
]]
function CodeGameScreenGirlsCookMachine:checkUpdateReelDatas(parentData )
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    parentData.reelDatas = reelDatas

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    parentData.lockSymbol = self:getColIsSameSymbol(parentData.cloumnIndex)

    return reelDatas

end

--[[
    判断该列整列信号是否相同
]]
function CodeGameScreenGirlsCookMachine:getColIsSameSymbol(iCol)
    local reelsData = self.m_runSpinResultData.p_reels
    local symbolType = -1
    if reelsData and next(reelsData) then
        for iRow = 1,self.m_iReelRowNum do
            if symbolType ~= -1 and symbolType ~= reelsData[iRow][iCol] then
                return -1
            end

            symbolType = reelsData[iRow][iCol]
        end
    end

    return symbolType
end

----
--- 处理spin 成功消息
--
function CodeGameScreenGirlsCookMachine:checkOperaSpinSuccess( param )
    local spinData = param[2]
    if spinData.action == "SPIN" then
        release_print("消息返回胡来了")
        print(cjson.encode(spinData)) 

        self:operaSpinResultData(param)
        
        self:operaUserInfoWithSpinResult(param )
        
        self:updateNetWorkData()
        gLobalNoticManager:postNotification("TopNode_updateRate")

        self:refreshDishCollectData()

        --刷新倒计时
        self:refreshCountDown()

        self:lockSymbol()
    end
end

--[[
    锁定滚动小块
]]
function CodeGameScreenGirlsCookMachine:lockSymbol()
    for k,parentData in pairs(self.m_slotParents) do
        parentData.lockSymbol = self:getColIsSameSymbol(parentData.cloumnIndex)
    end
end

--随机信号
function CodeGameScreenGirlsCookMachine:getReelSymbolType(parentData)
    if not parentData.reelDatas then
        return self:getRandomSymbolType()
    end
    local symbolType = parentData.reelDatas[parentData.beginReelIndex]
    parentData.beginReelIndex = parentData.beginReelIndex + 1
    if parentData.beginReelIndex > #parentData.reelDatas then
        parentData.beginReelIndex = 1
        symbolType = parentData.reelDatas[parentData.beginReelIndex]
    end

    --判断小块是否已被锁定
    if self:getCurrSpinMode() ~= FREE_SPIN_MODE and not self.m_isLongRun and parentData.lockSymbol and parentData.lockSymbol ~= -1 then
        symbolType = parentData.lockSymbol
    end
    return symbolType
end

--[[
    @desc: 获得轮盘的位置
]]
function CodeGameScreenGirlsCookMachine:getNodePosByColAndRow(row, col,targetNode)

    local pos = util_convertToNodeSpace(self:findChild("sp_reel_" .. (col - 1)),targetNode)

    pos.x = pos.x + self.m_SlotNodeW * 0.5
    pos.y = pos.y + (row - 0.5) * self.m_SlotNodeH
    return pos
end

--[[
    飞粒子动画
]]
function CodeGameScreenGirlsCookMachine:runFlyLineAni(startNode,endNode,func)
    local flyNode = cc.Node:create()--util_createAnimation("GirlsCook_shouji.csb")
    self.m_effectNode:addChild(flyNode)

    -- flyNode:findChild("Particle_1"):setPositionType(0)
    -- flyNode:findChild("Particle_1_0"):setPositionType(0)

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode)
    flyNode:setPosition(startPos)
    local seq = cc.Sequence:create({
        cc.DelayTime:create(0.1),
        cc.EaseSineIn:create(cc.MoveTo:create(0.4,endPos)),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end),
        cc.RemoveSelf:create(true)
    })
    flyNode:runAction(seq)
    return flyNode
end

--[[
    判断是否为特殊图标
]]
function CodeGameScreenGirlsCookMachine:isSpecialSymbol(symbolType)
    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        for k,v in pairs(SPECIAL_SYMBOL) do
            if v == symbolType then
                return true
            end
        end
    end

    return false
end

function CodeGameScreenGirlsCookMachine:setReelRunInfo()
    local iColumn = self.m_iReelColumnNum
    local bRunLong = false
    local scatterNum = 0
    local bonusNum = 0
    local longRunIndex = 0
    for col=1,iColumn do
        local reelRunData = self.m_reelRunInfo[col]
        local columnData = self.m_reelColDatas[col]
        local iRow = columnData.p_showGridCount
        if bRunLong == true then
            longRunIndex = longRunIndex + 1
            local runLen = self:getLongRunLen(col, longRunIndex)
            local preRunLen = reelRunData:getReelRunLen()
            local addRun = runLen - preRunLen
            reelRunData:setReelRunLen(runLen)
        end
        local runLen = reelRunData:getReelRunLen()
        --统计bonus scatter 信息
        scatterNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_SCATTER , col , scatterNum, bRunLong)
        bonusNum, bRunLong = self:setBonusScatterInfo(TAG_SYMBOL_TYPE.SYMBOL_BONUS, col , bonusNum, bRunLong)
    end --end  for col=1,iColumn do
end

--设置bonus scatter 信息
function CodeGameScreenGirlsCookMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
    local reelRunData = self.m_reelRunInfo[column]
    local runLen = reelRunData:getReelRunLen()
    local allSpecicalSymbolNum = specialSymbolNum
    local bRun, bPlayAni =  reelRunData:getSpeicalSybolRunInfo(symbolType)

    local soundType = runStatus.DUANG
    local nextReelLong = false

    local showCol = nil
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        showCol = self.m_ScatterShowCol
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS then 
        
    end
    
    soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

    local columnData = self.m_reelColDatas[column]
    local iRow = columnData.p_showGridCount

    local isScatterCol = true
    for row = 1, iRow do
        if self:getSymbolTypeForNetData(column,row,runLen) ~= symbolType then
            isScatterCol = false
            break
        end
    end

    if isScatterCol then
        local bPlaySymbolAnima = bPlayAni
        
        allSpecicalSymbolNum = allSpecicalSymbolNum + 1
        
        if bRun == true then
            
            soundType, nextReelLong = self:getRunStatus(column, allSpecicalSymbolNum, showCol)

            local soungName = nil
            if soundType == runStatus.DUANG then
                if allSpecicalSymbolNum == 1 then
                    soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_ONE_VOICE
                elseif allSpecicalSymbolNum == 2 then
                    soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_TWO_VOICE
                else
                    soungName = SOUND_ENUM.MUSIC_BONUS_SCATTER_THREE_VOICE
                end
            else
                --不应当播放动画 (么戏了)
                bPlaySymbolAnima = false
            end

            reelRunData:addPos(row, column, bPlaySymbolAnima, soungName)

        else
            -- bonus scatter不参与滚动设置
            local soundName = nil
            if bPlaySymbolAnima == true then
                --自定义音效
                
                reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
            else 
                reelRunData:addPos(row, column, bPlaySymbolAnima, soundName)
            end
        end
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
        self.m_isLongRun = true
    end
    return  allSpecicalSymbolNum, bRunLong
end

--返回本组下落音效和是否触发长滚效果
function CodeGameScreenGirlsCookMachine:getRunStatus(col, nodeNum, showCol)
    local showColTemp = {}
    if showCol ~= nil then 
        showColTemp = showCol
    else 
        for i=1,self.m_iReelColumnNum do
            showColTemp[#showColTemp + 1] = i
        end
    end
    
    if col == showColTemp[#showColTemp - 1] then
        if nodeNum <= 1 then
            return runStatus.NORUN, false
        elseif nodeNum == 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    elseif col == showColTemp[#showColTemp] then
        if nodeNum <= 2  then
            return runStatus.NORUN, false
        else
            return runStatus.DUANG, false
        end
    else
        if nodeNum == 2 then
            return runStatus.DUANG, true
        else
            return runStatus.DUANG, false
        end
    end
end

function CodeGameScreenGirlsCookMachine:checkNotifyUpdateWinCoin( )

    local winLines = self.m_reelResultLines

    if #winLines <= 0  then
        return
    end
    -- 如果freespin 未结束，不通知左上角玩家钱数量变化
    local isNotifyUpdateTop = true
    if self.m_bProduceSlots_InFreeSpin == true and self:getCurrSpinMode() == FREE_SPIN_MODE or globalData.slotRunData.freeSpinCount > 0 then
        isNotifyUpdateTop = false
    end

    if not self.m_isAlreadyRefreshWinCoins then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN,{self.m_iOnceSpinLastWin,isNotifyUpdateTop,true,self.m_collectWinCoins})
        self.m_isAlreadyRefreshWinCoins = true
    end
    
end

function CodeGameScreenGirlsCookMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2

    local winSize = display.size
    local mainScale = 1

    local hScale = mainHeight / self:getReelHeight()
    local wScale = winSize.width / self:getReelWidth()
    if hScale < wScale then
        mainScale = hScale
    else
        mainScale = wScale
        self.m_isPadScale = true
    end

    local radio = display.height / display.width
    if radio <= 1.5  then
        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale

        if radio < 1.5 then
            self.m_machineNode:setPositionY(mainPosY + 30)
        end
    end

end

function CodeGameScreenGirlsCookMachine:addLastWinSomeEffect() -- add big win or mega win
    BaseNewReelMachine.addLastWinSomeEffect(self)
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)
end

--[[
    飞粒子动画
]]
function CodeGameScreenGirlsCookMachine:runFlyLineInHitFree(index,startNode,endNode,keyFunc,endFunc)

    -- 创建粒子
    local flyNode =  util_createAnimation("GirlsCook_shuzituowei.csb")
    self.m_effectNode2:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1 )

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode2)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode2)
    
    flyNode:setPosition(startPos)

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)
    local aniName = "actionframe1"
    if index == 1 then
        aniName = "actionframe1"
    elseif index == 2 then
        aniName = "actionframe"
    else
        aniName = "actionframe2"
    end

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 570 )
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = flyNode,   --执行动画节点  必传参数
        actionName = aniName, --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        callBack = function(  ) --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end
            flyNode:stopAllActions()
            flyNode:removeFromParent()
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)

    return flyNode

end

--[[
    飞粒子动画
]]
function CodeGameScreenGirlsCookMachine:runFlyLineInFoodCollect(startNode,endNode,keyFunc,endFunc)

    -- 创建粒子
    local flyNode =  util_createAnimation("GirlsCook_food_collect.csb")
    self.m_effectNode2:addChild(flyNode,GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1 )

    local startPos = util_convertToNodeSpace(startNode,self.m_effectNode2)
    local endPos = util_convertToNodeSpace(endNode,self.m_effectNode2)
    
    flyNode:setPosition(startPos)

    local angle = util_getAngleByPos(startPos,endPos) 
    flyNode:setRotation( - angle)

    local scaleSize = math.sqrt( math.pow( startPos.x - endPos.x ,2) + math.pow( startPos.y - endPos.y,2 )) 
    flyNode:setScaleX(scaleSize / 850 )
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = flyNode,   --执行动画节点  必传参数
        actionName = "actionframe", --动作名称  动画必传参数,单延时动作可不传
        fps = 60,    --帧率  可选参数
        callBack = function(  ) --结束回调
            if type(endFunc) == "function" then
                endFunc()
            end
            flyNode:stopAllActions()
            flyNode:removeFromParent()
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)

    if type(keyFunc) == "function" then
        self:delayCallBack(29 / 60,keyFunc)
    end
    

    return flyNode
end

return CodeGameScreenGirlsCookMachine






