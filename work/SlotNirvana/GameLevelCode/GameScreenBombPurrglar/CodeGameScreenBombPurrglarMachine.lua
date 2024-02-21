---
-- island li
-- 2019年1月26日
-- CodeGameScreenBombPurrglarMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseMachine = require "Levels.BaseMachine"
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenBombPurrglarMachine = class("CodeGameScreenBombPurrglarMachine", BaseNewReelMachine)


CodeGameScreenBombPurrglarMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenBombPurrglarMachine.SYMBOL_10 = 9
-- 炸弹bonus
CodeGameScreenBombPurrglarMachine.SYMBOL_BONUS_1 = 95
CodeGameScreenBombPurrglarMachine.SYMBOL_BONUS_2 = 96
-- 社交玩法炸弹
CodeGameScreenBombPurrglarMachine.SYMBOL_BONUS_3 = 97
-- wild 炸弹将 普通信号 替换为 wild
-- CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_1 = TAG_SYMBOL_TYPE.SYMBOL_WILD
CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_2 = 93
CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_3 = 94
-- wild_scatter 炸弹将 scatter 替换为 wild
CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_SCATTER_1 = 102
CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_SCATTER_2 = 103
CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_SCATTER_3 = 104

CodeGameScreenBombPurrglarMachine.RespinPlayerItem = {}

-- 社交玩法信号
-- 金钥匙 乘倍(红，银) 空白 炸弹 
CodeGameScreenBombPurrglarMachine.SYMBOL_BONUSGAME_GOLDKEY = 120
CodeGameScreenBombPurrglarMachine.SYMBOL_BONUSGAME_MULTI_RED = 121  --服务器回传乘倍信号时 只回传(121) 具体使用那个背景颜色前端判断
CodeGameScreenBombPurrglarMachine.SYMBOL_BONUSGAME_MULTI_SILVER = 122
CodeGameScreenBombPurrglarMachine.SYMBOL_BONUSGAME_BLANK = 123

-- base炸弹玩法
CodeGameScreenBombPurrglarMachine.EFFECT_BASE_BONUS    = GameEffect.EFFECT_SELF_EFFECT - 10
-- base 收集scatter分数
CodeGameScreenBombPurrglarMachine.EFFECT_BASE_COLLECT_SCATTER = GameEffect.EFFECT_SELF_EFFECT - 20

-- 断线重连时展示玩法奖励界面
CodeGameScreenBombPurrglarMachine.EFFECT_RECONNECTION_REWARDVIEW = GameEffect.EFFECT_SELF_EFFECT - 30

-- 多人玩法事件
-- GameEffect.EFFECT_BONUS

CodeGameScreenBombPurrglarMachine.WildLevelData = {
    TAG_SYMBOL_TYPE.SYMBOL_WILD,
    CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_2,
    CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_3,
}
CodeGameScreenBombPurrglarMachine.ScatterWildLevelData = {
    CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_SCATTER_1,
    CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_SCATTER_2,
    CodeGameScreenBombPurrglarMachine.SYMBOL_WILD_SCATTER_3,
}

--bonus相关弹板的层级
CodeGameScreenBombPurrglarMachine.BONUSVIEW_ORDER = {
    -- 通用遮罩
    DARK = GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1,
    -- 过场
    GUOCHANG = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5,
    -- 下方玩家头像
    BOTTOMUSERITEM = GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 5,
}
-- 工程内调过的
CodeGameScreenBombPurrglarMachine.BonusBoxPos = cc.p(586, 238)


-- 构造函数
function CodeGameScreenBombPurrglarMachine:ctor()
    CodeGameScreenBombPurrglarMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.RespinPlayerItem = {}
    self.m_spinRestMusicBG = true
    self.m_isShowOutGame = false
    self.m_isShowSystemView = false

    -- baseBonus炸弹玩法的数据
    self.m_wildPosData = {}
    -- 升级的位置
    self.m_wildUpGradeData = {}

    -- base收集scatter的数据
    self.m_scatterPosData = {}
    -- 正在收集scatter数量
    self.m_scatterCollectNum = 0

    -- 断线重连时的玩家 乘倍和得分
    self.m_reconnectionBonusWinCoin = 0
    self.m_reconnectionBonusWinMultiple = 0

    -- 每次spin点击 stop按钮的次数
    self.m_quickStopNum = 0
    -- base炸弹玩法事件
    self.m_baseBonusEffect = nil
    -- 事件延时的节点，用来打断事件的延时触发
    self.m_baseBonusDelayNode = nil

    --添加头像缓存
    local cache = cc.SpriteFrameCache:getInstance()
    cache:addSpriteFrames("userinfo/ui_head/UserHeadPlist.plist")

    --init
    self:initGame()
end

function CodeGameScreenBombPurrglarMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("BombPurrglarConfig.csv", "LevelBombPurrglarConfig.lua")
    --初始化基本数据
    self:initMachine(self.m_moduleName)
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenBombPurrglarMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "BombPurrglar"  
end

--[[
    初始化房间列表
]]
function CodeGameScreenBombPurrglarMachine:initRoomList()
    --房间列表
    self.m_roomList = util_createView("CodeBombPurrglarSrc.BombPurrglarRoomListView", {machine = self})
    self:findChild("roomList"):addChild(self.m_roomList)
    self.m_roomData = self.m_roomList.m_roomData
end


function CodeGameScreenBombPurrglarMachine:initUI()
    -- local x = display.width / DESIGN_SIZE.width
    -- local y = display.height / DESIGN_SIZE.height
    -- local scale = x / y

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    --初始化房间列表
    self:initRoomList()

    --收集分数
    self.m_collectSorce = util_createAnimation("BombPurrglar_Credits.csb")
    self:findChild("Node_credit"):addChild(self.m_collectSorce)
    self.m_tip = util_createAnimation("BombPurrglar_Credits_Tip.csb")
    self.m_collectSorce:findChild("Node_Tip"):addChild(self.m_tip)
    self.m_tip:setVisible(false)
    self.m_tip.states = "idle"
    self:addClick(self.m_collectSorce:findChild("btn_Tip"))

    self.m_miniMachine = util_createView("CodeBombPurrglarSrc.BombPurrglarMini.BombPurrglarMiniMachine",{machine = self})
    self:addChild(self.m_miniMachine, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
    self.m_miniMachine:setPosition(display.width/2,display.height/2)
    self.m_miniMachine:setScale(self.m_machineRootScale)
    -- 不设置缩放的话，迷你轮盘一些计算坐标的地方会有微小的偏差
    self.m_miniMachine.m_machineRootScale = self.m_machineRootScale
    self.m_miniMachine:setVisible(false)

    self.m_bonusDark = util_createAnimation("BombPurrglar_Bonus_dark.csb")
    self:addChild(self.m_bonusDark, self.BONUSVIEW_ORDER.DARK)
    self.m_bonusDark:setPosition(display.width/2,display.height/2)
    self.m_bonusDark:setVisible(false)
    self.m_bonusDark:setScale(self.m_machineRootScale)


    self.m_bonusGuochang = util_spineCreate("BombPurrglar_guochang",true,true)
    self:addChild(self.m_bonusGuochang, self.BONUSVIEW_ORDER.GUOCHANG)
    self.m_bonusGuochang:setPosition(display.width/2,display.height/2)
    self.m_bonusGuochang:setVisible(false)
    self.m_bonusGuochang:setScale(self.m_machineRootScale)


    -- 弹板也要上移 换一个父节点吧
    local bonusBoxParent = self.m_miniMachine.m_bigReelClipNode
    self.m_bonusBox = util_createAnimation("BombPurrglar_Bonus_box.csb")
    -- 最高层级？？？
    local bonusBoxOrder = 0--9999
    bonusBoxParent:addChild(self.m_bonusBox, bonusBoxOrder)
    self.m_bonusBox:setPosition(self.BonusBoxPos)
    self.m_bonusBox:findChild("Sprite_redBg"):setVisible(true)
    self.m_bonusBox:setVisible(false)

    self.m_bonusJuese_dog = util_spineCreate("Socre_BombPurrglar_8",true,true)
    self.m_bonusBox:findChild("Node_box"):addChild(self.m_bonusJuese_dog)

    local godKeyOrder = 9999
    self.m_bonusKeys = {} 
    for iCol=1,8 do
        local key = util_createAnimation("BombPurrglar_key.csb")
        bonusBoxParent:addChild(key, godKeyOrder)
        -- self.m_bonusBox:findChild("Node_box"):addChild(key, 5)
        key:setVisible(false)
        table.insert(self.m_bonusKeys, key)
    end

    self.m_bonusKeyBao = util_createAnimation("BombPurrglar_key_bao.csb")
    self.m_bonusBox:findChild("Node_keyBao"):addChild(self.m_bonusKeyBao)
    self.m_bonusKeyBao:setVisible(false)


    -- respinover特效
    self.m_rsover_bonusBoom = util_createAnimation("BombPurrglar_Bonus_boom.csb")
    self.m_rsover_bonusBoom:setVisible(false)
    self:addChild(self.m_rsover_bonusBoom, self.BONUSVIEW_ORDER.DARK + 1)
    self.m_rsover_bonusBoom:setPosition(display.width/2,display.height/2)
    self.m_rsover_bonusBoom:setVisible(false)
    self.m_rsover_bonusBoom:setScale(self.m_machineRootScale)

    
    -- bonusBoxOver 界面放在裁切层内
    local bonusBoxOverClipNode = self.m_miniMachine:findChild("Panel_bonusBoxOver")
    local nodePos = util_convertToNodeSpace(bonusBoxOverClipNode, self)
    local clipData = {
        x= nodePos.x, 
        y= nodePos.y - display.height/2, 
        width = 0, 
        height = 0,
    }
    local bonusOverClip =  cc.ClippingRectangleNode:create(clipData)
    self:addChild(bonusOverClip, self.BONUSVIEW_ORDER.DARK + 5)
    
    self.m_rsover_bonusBox = util_createAnimation("BombPurrglar_Bonus_box.csb")
    self.m_rsover_bonusBox:setVisible(false)
    bonusOverClip:addChild(self.m_rsover_bonusBox)
    self:changeReSpinOverBonusBoxClipSize(false)

    nodePos = bonusOverClip:convertToNodeSpace(cc.p(display.width/2, display.height/2))
    self.m_rsover_bonusBox:setPosition(nodePos)
    self.m_rsover_bonusBox:setVisible(false)
    self.m_rsover_bonusBox:setScale(self.m_machineRootScale)

    self.m_rsover_bonusBox.m_redBox= util_spineCreate("Socre_BombPurrglar_8",true,true)
    self.m_rsover_bonusBox:findChild("Node_box"):addChild(self.m_rsover_bonusBox.m_redBox)


    self.m_baseBonusDelayNode = cc.Node:create()
    self:addChild(self.m_baseBonusDelayNode)  
end


-- 下方玩家头像
function CodeGameScreenBombPurrglarMachine:initRSPlayerItem(_parent)

    local parent = _parent
    local item_machine = util_createView("CodeBombPurrglarSrc.BombPurrglarMini.BombPurrglarMiniPlayerItem")
    self:addChild(item_machine, self.BONUSVIEW_ORDER.BOTTOMUSERITEM)
    item_machine:hideSomeUI( )
    item_machine:setVisible(false)
    item_machine:setScale(self.m_machineRootScale)
    table.insert(self.RespinPlayerItem , item_machine)

    performWithDelay(self,function(  )
        local worldPos = parent:getParent():convertToWorldSpace(cc.p(parent:getPosition()))
        local pos = self:convertToNodeSpace(worldPos)
        item_machine:setPosition(pos)
    end,0)

end

function CodeGameScreenBombPurrglarMachine:enterGamePlayMusic(  )
    self:playEnterGameSound(self.m_configData.Music_enterLevel)
end

function CodeGameScreenBombPurrglarMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBombPurrglarMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    --reSpin落地由 迷你轮盘监听就可以了
    gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_RESPIN_RUN_STOP)
    self.m_miniMachine:enterLevelMiniSelf()

    self:changeGameBgAction()
end

function CodeGameScreenBombPurrglarMachine:addObservers()
    CodeGameScreenBombPurrglarMachine.super.addObservers(self)

    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画

        if self:checkHasGameEffectType(GameEffect.EFFECT_EPICWIN) then
            self.m_roomList:showSelfBigWinAni("EPIC_WIN")
        elseif self:checkHasGameEffectType(GameEffect.EFFECT_MEGAWIN) then
            self.m_roomList:showSelfBigWinAni("MAGE_WIN")
        elseif self:checkHasGameEffectType(GameEffect.EFFECT_BIGWIN) then
            self.m_roomList:showSelfBigWinAni("BIG_WIN")
        end
        
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
        if winRate <= 1 then
            soundIndex = 1
        elseif winRate > 1 and winRate <= 3 then
            soundIndex = 2
        elseif winRate > 3 then
            soundIndex = 3
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = string.format(self.m_configData.Sound_WinCoin_Base, soundIndex)

        self.m_winSoundsId = gLobalSoundManager:playSound(soundName)  

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenBombPurrglarMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenBombPurrglarMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()

    --需手动调用房间列表的退出方法,否则未加载完成退出游戏不会主动调用
    self.m_roomList:onExit()

    scheduler.unschedulesByTargetName(self:getModuleName())
end

--[[
    退出到大厅
]]
function CodeGameScreenBombPurrglarMachine:showOutGame( )

    if self.m_isShowOutGame then
        return
    end
    self.m_isShowOutGame = true
    local view = util_createView("CodeBombPurrglarSrc.BombPurrglarGameOut")
    if globalData.slotRunData.machineData.p_portraitFlag then
        jackPotWinView.getRotateBackScaleFlag = function()
            return false
        end
    end
    gLobalViewManager:showUI(view)
end

--[[
    暂停轮盘
]]
function CodeGameScreenBombPurrglarMachine:pauseMachine()
    BaseMachine.pauseMachine(self)
    self.m_isShowSystemView = true
    --停止刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
end

--[[
    恢复轮盘
]]
function CodeGameScreenBombPurrglarMachine:resumeMachine()
    BaseMachine.resumeMachine(self)
    self.m_isShowSystemView = false
    if self.m_isTriggerBonus then
        return
    end
    --重新刷新房间消息
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
end

---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenBombPurrglarMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == self.SYMBOL_10 then
        return "Socre_BombPurrglar_10"

    elseif symbolType == self.SYMBOL_BONUS_1 then
        return "Socre_BombPurrglar_bonus_1"
    elseif symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_BombPurrglar_bonus_2"
    elseif symbolType == self.SYMBOL_BONUS_3 then
        return "Socre_BombPurrglar_bonus_3"
    
    elseif symbolType == self.SYMBOL_WILD_2 then
        return "Socre_BombPurrglar_Wild"
    elseif symbolType == self.SYMBOL_WILD_3 then
        return "Socre_BombPurrglar_Wild"

    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_BombPurrglar_Scatter_zi"
    elseif symbolType == self.SYMBOL_WILD_SCATTER_1 then
        return "Socre_BombPurrglar_Scatter_zi"
    elseif symbolType == self.SYMBOL_WILD_SCATTER_2 then
        return "Socre_BombPurrglar_Scatter_zi"
    elseif symbolType == self.SYMBOL_WILD_SCATTER_3 then
        return "Socre_BombPurrglar_Scatter_zi"

    elseif symbolType == self.SYMBOL_BONUSGAME_GOLDKEY then
        return "Socre_BombPurrglar_gold"
    elseif symbolType == self.SYMBOL_BONUSGAME_MULTI_RED then
        return "Socre_BombPurrglar_red"
    elseif symbolType == self.SYMBOL_BONUSGAME_MULTI_SILVER then
        return "Socre_BombPurrglar_silver"
    elseif symbolType == self.SYMBOL_BONUSGAME_BLANK then
        return "Socre_BombPurrglar_blue"

    
    end
    

    return nil
end

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenBombPurrglarMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenBombPurrglarMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end

--点击回调
function CodeGameScreenBombPurrglarMachine:clickFunc(sender)
    local name = sender:getName()

    if name == "btn_Tip" then
        self:changeShowTipStates()
    end
end

--[[
    界面组件接口
]]

-- GameBg
function CodeGameScreenBombPurrglarMachine:changeGameBgAction(_actionName, _loop, _fun)
    _actionName = _actionName or "base"
    if nil == _loop then
        _loop = true
    end

    if "base" ~= _actionName and "base_bonus" ~= _actionName then
        self.m_gameBg:findChild("base"):setVisible(false)
    else
        self.m_gameBg:findChild("base"):setVisible(true)
    end

    self.m_gameBg:runCsbAction(_actionName, _loop, function()
        if "base_bonus" == _actionName then
            self.m_gameBg:findChild("base"):setVisible(false)
        end
        
        if _fun then
            _fun()
        end
    end)
end

function CodeGameScreenBombPurrglarMachine:changeShowTipStates( )

    
    if self.m_tip.states == "idle" then
        if not self.m_tip:isVisible() then
            self:showTip()
        else
            self:hideTip()
        end    
    end

    
end
-- Tip
function CodeGameScreenBombPurrglarMachine:showTip()

    self.m_tip:stopAllActions()

    self.m_tip:setVisible(true)
    self.m_tip.states = "start"
    self.m_tip:runCsbAction("show", false, function()
        self.m_tip.states = "idle"
        performWithDelay(self.m_tip,function(  )
            self:hideTip( )
        end,2)
        
    end)

end

function CodeGameScreenBombPurrglarMachine:hideTip( )

    self.m_tip:stopAllActions()

    self.m_tip.states = "over"
    self.m_tip:runCsbAction("over", false, function()   
        self.m_tip.states = "idle"
        self.m_tip:setVisible(false)
    end)

end

function CodeGameScreenBombPurrglarMachine:quickhideTip( )
    self.m_tip:stopAllActions()
    self.m_tip.states = "idle"
    self.m_tip:setVisible(false)
end


----------------------------- 玩法处理 -----------------------------------
--[[
    base模式的炸弹玩法

    wildPos = {
        "0" = {         --爆炸点
            "0" = 92,   --变更位置 ： 变更生成的信号(最终结果)
            "1" = 92, 
            "6" = 92,
            "7" = 92,
        },
        "2" = {
            "2" = 92,  
            "3" = 92, 
            "8" = 92,
            "9" = 92,
        }
    }
]]
function CodeGameScreenBombPurrglarMachine:isTriggerBaseBonus()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}

    if selfData.wildPos and table_length(selfData.wildPos) >0 then
        return true
    end
    
    return false
end
function CodeGameScreenBombPurrglarMachine:initBaseBonusData()
    self.m_wildPosData = {}
    self.m_wildUpGradeData = {}

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local wildPos  = selfData.wildPos or {}
    -- 对服务器回传数据进行整理
    for _sBombPos,_changeData in pairs(wildPos) do 
        local iPos = tonumber(_sBombPos)
        local fixPos = self:getRowAndColByPos(iPos)
        local bombSymbol = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
        --bugly-没拿到回传炸弹位置的小块
        if not bombSymbol then
            local msg = string.format("[initBaseBonusData] iPos=(%d) iCol=(%d) iRow=(%d)", iPos, fixPos.iY, fixPos.iX)
            release_print(msg)
        end
        
        local posData = {
            bombPos = iPos,            --炸弹位置
            symbolType = bombSymbol.p_symbolType,     --炸弹信号
            changePos = {},                           --变更位置 : 变更结果 (只发最终结果，前端按照爆炸叠加的顺序对小块升级)
        }

        for _sChangePos,_iChangeType in pairs(_changeData) do
            posData.changePos[tonumber(_sChangePos)] = _iChangeType
        end

        table.insert(self.m_wildPosData,posData)
    end
    -- 排序
    table.sort(self.m_wildPosData, function(a, b)
        
        -- 信号类型排序
        if a.symbolType ~= b.symbolType then
            return a.symbolType < b.symbolType
        end

        -- 绝对位置排序
        if a.bombPos < b.bombPos then
            return true
        end
        return false
    end)
end

--[[
    收集scatter分数
]]
function CodeGameScreenBombPurrglarMachine:isTriggerBaseCollectScatter()
    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreData = selfData.positionScore or {}

    if table_length(scoreData) > 0 then
        return true
    end
    
    return false
end
function CodeGameScreenBombPurrglarMachine:initBaseCollectScatterData()
    self.m_scatterPosData = {}

    local selfData = self.m_runSpinResultData.p_selfMakeData or {}
    local scoreData  = selfData.positionScore or {}
    --整理成数组
    for _sPos,_iScore in pairs(scoreData) do
        table.insert(self.m_scatterPosData, {
            scatterPos = tonumber(_sPos),
            scatterScore = _iScore
        })
    end
    --排序
    table.sort(self.m_scatterPosData, function(a, b)
        if a.scatterPos < b.scatterPos then
            return true
        end
        return false
    end)
end

-- 断线重连 
function CodeGameScreenBombPurrglarMachine:MachineRule_initGame(  )
    local bool,coins,multiple = self:isTriggerReconnectionRewardView()
    if bool then
        -- 上次玩法的奖励
        self.m_reconnectionBonusWinCoin = coins
        self.m_reconnectionBonusWinMultiple = multiple

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_RECONNECTION_REWARDVIEW 
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_RECONNECTION_REWARDVIEW
    end
end

function CodeGameScreenBombPurrglarMachine:isTriggerReconnectionRewardView()
    local winSpots = self.m_roomData:getWinSpots()
    if winSpots and #winSpots > 0 then
        local coins = 0
        local multiple = winSpots[#winSpots].multiple or 0

        for key,winInfo in pairs(winSpots) do
            coins = coins + winInfo.coins
        end

        return coins > 0,coins,multiple
    end

    return false
end

--
--单列滚动停止回调
--
function CodeGameScreenBombPurrglarMachine:slotOneReelDown(reelCol)    
    CodeGameScreenBombPurrglarMachine.super.slotOneReelDown(self,reelCol) 
   
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenBombPurrglarMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenBombPurrglarMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------

---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenBombPurrglarMachine:MachineRule_SpinBtnCall()
    
    self:quickhideTip( )
    self:stopLinesWinSound()
    self:setMaxMusicBGVolume( )
    -- self.m_isTriggerBonus = false


    local bool = (true == self.m_isTriggerBonus) and true or false
    return bool -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenBombPurrglarMachine:addSelfEffect()

    if self:isTriggerBaseBonus() then
        self:initBaseBonusData()

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_BONUS 
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_BONUS
    end
        
    if self:isTriggerBaseCollectScatter() then
        self:initBaseCollectScatterData()

        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = self.EFFECT_BASE_COLLECT_SCATTER 
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.EFFECT_BASE_COLLECT_SCATTER
    end
    
    self:checkTriggerBonus()
end


---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenBombPurrglarMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.EFFECT_BASE_BONUS then
        self.m_baseBonusEffect = effectData
        self:playEffect_BaseBonus(1, function()
            if self.m_baseBonusEffect and not self.m_baseBonusEffect.p_isPlay then
                self.m_baseBonusEffect.p_isPlay = true
                self.m_baseBonusEffect = nil
                self:playGameEffect()
            end
        end)

    elseif effectData.p_selfEffectType == self.EFFECT_BASE_COLLECT_SCATTER then
        self:playEffect_BaseCollectScatter(1, function()
            
        end)
        effectData.p_isPlay = true
        self:playGameEffect()
    elseif effectData.p_selfEffectType == self.EFFECT_RECONNECTION_REWARDVIEW then
        self:playEffect_ReconnectionBonusWinCoin(function()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    end

    
    return true
end

--[[
    检测是否触发bonus
]]
function CodeGameScreenBombPurrglarMachine:checkTriggerBonus()

    --检测是否已经添加过bonus,防止刷新数据时导致二次添加
    for k,gameEffect in pairs(self.m_gameEffects) do
        if gameEffect and gameEffect.p_effectType == GameEffect.EFFECT_BONUS then
            return true
        end
    end
    
    --有玩家触发Bonus
    local result = self.m_roomData:getSpotResult()

    if result then
        --发送停止刷新房间消息
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_REFRESH_ROOM_DATA)
        self:addBonusEffect(result)
        return true
    end

    return false
end

--[[
    添加Bonus玩法
]]
function CodeGameScreenBombPurrglarMachine:addBonusEffect(result)
    self:setCurrSpinMode(SPECIAL_SPIN_MODE)
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER, true)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})

    local effect = GameEffectData.new()
    effect.p_effectType = GameEffect.EFFECT_BONUS
    effect.p_effectOrder = GameEffect.EFFECT_BONUS
    self.m_gameEffects[#self.m_gameEffects + 1] = effect
    effect.resultData = clone(result)

    self.m_isTriggerBonus = true
end

function CodeGameScreenBombPurrglarMachine:featureBonusEnd(_func, _effectData )
    

    self:showBonusEndGuoChang(function()
    
        --变更轮盘状态
        if globalData.slotRunData.m_isAutoSpinAction then
            self:setCurrSpinMode(AUTO_SPIN_MODE)
        else
            self:setCurrSpinMode(NORMAL_SPIN_MODE)
        end
    
        --打开排行界面
        local winnerList = _effectData.resultData.data.winnerChairId or {}
        local winnerChairId = winnerList[1] or 0
        local allPlayerData = _effectData.resultData.data.sets
        self:showBonusRankView(winnerChairId,allPlayerData, function()
            gLobalSoundManager:playSound(self.m_configData.Sound_BonusRank_over)

            if _func then
                _func()
            end
            
            self:reelsDownDelaySetMusicBGVolume()
            self:changeBaseReelVisible(true)
            self.m_miniMachine:setVisible(false)
            self:changeGameBgAction()
            -- 刷新基底
            self:setCollectScatterNum(false)
            -- 暂停背景音乐
            self:clearCurMusicBg()
            --打开自己结算界面
            local userData = self.m_roomList:getPlayerResultSetData(_effectData.resultData, nil, globalData.userRunData.userUdid)
            self:showBonusOver(userData.winCoins, userData.winMultiple, function()
            
                --领取奖励
                local winScore = 0
                local winSpots = self.m_roomData:getWinSpots()
                if winSpots and #winSpots > 0 then
                    local winInfo = winSpots[#winSpots]
                    winScore = winInfo.coins
                end
                -- self:checkFeatureOverTriggerBigWin(winScore, GameEffect.EFFECT_BONUS)
                local gameName = self:getNetWorkModuleName()
                --参数传-1位领取所有奖励,领取当前奖励传数组最后一位索引
                local index = #winSpots - 1
                gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
                    function()
                        globalData.slotRunData.lastWinCoin = 0
                        local params = {userData.winCoins, true, true}
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)
                    end,
                    function(errorCode, errorData)
                        
                    end
                )

                self:resetMusicBg()

                _effectData.p_isPlay = true
                self:playGameEffect()
                --重置bonus触发状态
                self.m_isTriggerBonus = false
    
                --重新刷新房间数据
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
            end)
        end)

    end, _effectData.resultData)

   

end
--[[
    Bonus玩法
]]
function CodeGameScreenBombPurrglarMachine:showEffect_Bonus(effectData)
    if self.m_scatterCollectNum > 0 then
        self:levelPerformWithDelay(0.1, function()
            self:showEffect_Bonus(effectData)
        end)
        return true
    end
    
    -- 暂停背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    -- 取消掉赢钱线的显示 | 底栏
    self:clearWinLineEffect()
    self.m_bottomUI:resetWinLabel()
    self.m_bottomUI:checkClearWinLabel()

    -- 初始化一些数据 和 Ui展示
    self.m_miniMachine:initResultData(effectData.resultData)

    local playBonusStart = function()
        --2.打开 bonusStar 界面
        self:showBonusGameView(effectData.resultData, function()

            --3.播放开场动画
            self:playBonusStartAnim(effectData.resultData,function()

                --4.启动bonus轮盘
                self:levelPerformWithDelay(0.5, function()
                    self.m_miniMachine:startGame(function(_func )
                        self:featureBonusEnd(_func,effectData)
                    end)

                    self.m_roomData.m_teamData.room.result = nil
                end)
            
            end)

        end)

    end
    

    -- 1. 自己触发的话，播放scatter信号的动画
    local playerData = effectData.resultData.data.triggerPlayer
    local isMe = (globalData.userRunData.userUdid == playerData.udid)
    if isMe then
        local bHaveScatter = false
        local bPlaySymbolAnim = false
        local childs = self.m_clipParent:getChildren()
        for i,_slotNode in ipairs(childs) do
            local tag = _slotNode:getTag()
            if tag > SYMBOL_FIX_NODE_TAG and self:isBombPurrglarScatter(_slotNode.p_symbolType) then
                bHaveScatter = true
                -- scatter触发动画
                local SpineNode = _slotNode:getCcbProperty("SpineNode")
                local addSpineName = "scatterSpine"
                local addSpine = SpineNode:getChildByName(addSpineName)
                util_spinePlay(addSpine, "actionframe4", false)
                -- 在没回来时进行下一步 播放弹板
                self:levelPerformWithDelay(60/30, function()
                    if not bPlaySymbolAnim then
                        bPlaySymbolAnim = true
                        playBonusStart()
                    end
                end)
                
            end
        end
        
        gLobalSoundManager:playSound(self.m_configData.Sound_Scatter_trigger)
        if not bHaveScatter then
            playBonusStart()
        end
    else
        playBonusStart()
    end
    
    return true
end


function CodeGameScreenBombPurrglarMachine:showBonusGameView(_resultData, func)
    local playerData = _resultData.data.triggerPlayer
    local isMe = (globalData.userRunData.userUdid == playerData.udid)

    local nextFun = function()
        -- 三格动画
        gLobalSoundManager:playSound(self.m_configData.Sound_BonusGuochang_start)
        self.m_bonusGuochang:setVisible(true)
        util_spinePlay(self.m_bonusGuochang, "actionframe", false)
        util_spineEndCallFunc(self.m_bonusGuochang, "actionframe", function()
            self.m_bonusGuochang:setVisible(false)

            self.m_bonusBox:setVisible(true)
            local symbolTop = self.m_bonusBox:findChild("Node_symbolTop")
            local worldPos = symbolTop:getParent():convertToWorldSpace(cc.p(symbolTop:getPosition()))
            -- 滑块向下移动
            self:showBonusSlideMoveDown(
                function()    
                    -- 初始化一下滑动小块(上移)
                    self.m_bonusBox:setPosition(self.BonusBoxPos)
                    self.m_miniMachine:changeBonusBoxParentSize(true)
                    self.m_miniMachine:initSlideSymbol({
                        startPosY = worldPos.y,
                        startRow = self.m_miniMachine.m_multipleReelLength + 1,
                        rowDir = -1,
                    })
                    if func then
                        func()
                    end

                end,
                worldPos
            )
            self:setMaxMusicBGVolume()
            self:resetMusicBg(true, self.m_configData.Music_bonusGame)
        end)

        local winnerMultiple = _resultData.data.winnerMultiple or 0
        local boxLab = self.m_bonusBox:findChild("m_lb_coins")
        boxLab:setString(string.format("X%d", winnerMultiple))
        self:updateLabelSize({label = boxLab,sx = 0.9,sy = 0.9}, 261)
        self.m_bonusBox:runCsbAction("idleframe", true)
        util_spinePlay(self.m_bonusJuese_dog, "idle", true)
        
        -- 初始化一下滑动小块(下移)
        local symbolBottom = self.m_miniMachine.m_bigReelClipNode
        local worldPos = symbolBottom:getParent():convertToWorldSpace(cc.p(symbolBottom:getPosition()))
        self.m_miniMachine:initSlideSymbol({
            startPosY = worldPos.y,
            startRow = 1,
            rowDir = 1,
        })


        -- 通用遮罩
        self:showBonusDark()
        -- 第90帧，切换进入bonus玩法的展示
        self:levelPerformWithDelay(90/30, function()
            self:hideBonusDark()
            self:setCollectScatterNum(false)
            self:changeBaseReelVisible(false)

            self:changeGameBgAction("base_bonus", false, function()
                self:changeGameBgAction("bonus1")
            end)
            
            self.m_miniMachine:setVisible(true)
        end)
    end

    --
    local ownerlist = {}
    local showName = isMe and "YOU" or playerData.nickName
    ownerlist["lb_playerName"] = showName
    --刷新弹板头像背景
    local upDateBonusStartHead = function(_dialog)
        _dialog:findChild("BgPlayer_me"):setVisible(isMe)
        _dialog:findChild("headbox_me"):setVisible(isMe)
        _dialog:findChild("BgPlayer"):setVisible(not isMe)
        _dialog:findChild("headbox"):setVisible(not isMe)
        local head = _dialog:findChild("sp_head")
        head:removeAllChildren(true)

        local headRoot = _dialog:findChild("Node_head")
        -- headRoot:removeAllChildren(true)
        local fbid = playerData.facebookId
        local headName = playerData.head
        -- local frameId = isMe and globalData.userRunData.avatarFrameId or playerData.frame
        -- local headSize = cc.size(120, 120)
        -- local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, headSize)
        -- head:addChild(nodeAvatar)
        -- local headSize = head:getContentSize()
        -- nodeAvatar:setPosition( headSize.width * 0.5, headSize.height * 0.5 )

        -- local headFrameNode = headRoot:getChildByName("headFrameNode")
        -- if not headFrameNode then
        --     headFrameNode = cc.Node:create()
        --     headRoot:addChild(headFrameNode, 10)
        --     headFrameNode:setName("headFrameNode")
        --     headFrameNode:setPosition(head:getPosition())
        --     headFrameNode:setLocalZOrder(10)
        -- else
        --     headFrameNode:removeAllChildren(true)
        -- end
        -- util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)


        util_setHead(head, fbid, headName, nil, true)
    end
    
    
    -- 通用遮罩
    self:showBonusDark()
    gLobalSoundManager:playSound(self.m_configData.Sound_BonusStart)
    -- 自己触发,直接展示弹板
    if isMe then
        local view = self:showBonusStartView(ownerlist)
        upDateBonusStartHead(view)
        view:runCsbAction("auto", false, function()
            view:removeFromParent()
            nextFun()
        end)
        -- 250帧播放隐藏时间线
        self:levelPerformWithDelay(250/60, function()
            self:hideBonusDark()
        end)
    -- 别人触发， 头像发光 -> 飞过来
    else

        local item = self.m_roomList:getPlayerItem(playerData.udid)
        local playerInfo = item:getPlayerInfo()
        --
        local view = self:showBonusStartView(ownerlist)
        upDateBonusStartHead(view)
        view:setVisible(false)
        local moveItem = util_createView("CodeBombPurrglarSrc.BombPurrglarPlayerItem")
        self:addChild(moveItem, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +10)
        local startPos = util_convertToNodeSpace(item, self)
        local endPos = util_convertToNodeSpace(view:findChild("sp_head"), self)
        moveItem:setPosition(startPos)
        moveItem:refreshData(playerInfo)
        moveItem:refreshHead()

        -- 第15帧播放弹板auto,隐藏弹板头像
        self:levelPerformWithDelay(15/60, function()
            view:setVisible(true)
            view:runCsbAction("auto", false, function()
                view:removeFromParent()
                nextFun()
            end)
            -- 250帧播放隐藏时间线
            self:levelPerformWithDelay(250/60, function()
                self:hideBonusDark()
            end)
            -- 飞行过程先隐藏弹板部分节点
            local head = view:findChild("sp_head")
            head:setVisible(false)
            view:findChild("BgPlayer"):setVisible(false)
            view:findChild("headbox"):setVisible(false)
            
            -- 第20帧开始飞
            moveItem:runCsbAction("actionframe", false)
            self:levelPerformWithDelay(5/60, function()

                local actMove = cc.MoveTo:create(0.3, endPos)
                local actCallFun = cc.CallFunc:create(function()
                    head:setVisible(true)
                    view:findChild("BgPlayer"):setVisible(true)
                    view:findChild("headbox"):setVisible(true)
                    moveItem:removeFromParent()
                end)
                moveItem:runAction(cc.Sequence:create(actMove, actCallFun))

            end)
        end)
        
    end
    
    return view
end

function CodeGameScreenBombPurrglarMachine:showBonusStartView(_ownerlist)
    local bonusStartView = util_createAnimation("BombPurrglar/BonusStart.csb")
    self:addChild(bonusStartView, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM +1)
    bonusStartView:setAnchorPoint(cc.p(0.5, 0.5))
    bonusStartView:setPosition(0,0)
    bonusStartView:setAutoScale(true)
    for _labName,_labStr in pairs(_ownerlist) do
        local labNode = bonusStartView:findChild(_labName)
        if labNode then
            -- 只有一个名称文本需要修改, 加一个滑动效果
            labNode:setString(_labStr)
            local nameClip = bonusStartView:findChild("Panel_nameClip") 
            local clipSize = nameClip:getContentSize()
            local labSize = labNode:getContentSize()

            if labSize.width > clipSize.width then
                util_wordSwing(labNode, 1, nameClip, 0, labSize.width/2, 0)
            end
            
        end
    end

    return bonusStartView
end
-- bonus滑块上移
function CodeGameScreenBombPurrglarMachine:showBonusSlideMoveDown(_fun, _endWorldPos)
    local moveData = {
        bonusBox = self.m_bonusBox,
        endWorldPos = _endWorldPos,
        
    }
    self.m_bonusBox:setPosition(self.BonusBoxPos)
    self.m_miniMachine:startSlideMoveDown(_fun, moveData)
end

function CodeGameScreenBombPurrglarMachine:playBonusStartAnim(_resultData, _fun)

    -- 展示宝箱的乘倍界面
    local playBonusBoxAnim = function()

       -- 狗左右张望
       util_spinePlay(self.m_bonusJuese_dog, "actionframe2", false)
       util_spineEndCallFunc(self.m_bonusJuese_dog, "actionframe2", function()
            --关门 和 角色一起播放
            gLobalSoundManager:playSound(self.m_configData.Sound_BonusDog_closeDoor)
            self.m_bonusBox:runCsbAction("actionframe", false)
            util_spinePlay(self.m_bonusJuese_dog, "actionframe3", false)
            util_spineEndCallFunc(self.m_bonusJuese_dog, "actionframe3", function()
                -- 没有闪烁的idle ， 迷你轮盘会在钥匙闪烁是调一下，宝箱的闪烁idle
                util_spinePlay(self.m_bonusJuese_dog, "idle3", true)

                local keyParent = self.m_bonusKeys[1]:getParent()
                local startPos = util_convertToNodeSpace(self.m_bonusBox:findChild("Node_keyPos_start"), keyParent)
                local lockPos  = util_convertToNodeSpace(self.m_bonusBox:findChild("Node_keyPos_lock"), keyParent)
                local boxPos   = util_convertToNodeSpace(self.m_bonusBox:findChild("Node_keyBao"), keyParent)
                local flyEndPos = self.m_miniMachine:getGoldKeyFlyEndPos()
                local bPlayActionEnd = false
                local bPlayBomb = false
                local bSoundFly2 = false

                gLobalSoundManager:playSound(self.m_configData.Sound_BonusKey_fly_1)
                for iCol,_key in ipairs(self.m_bonusKeys) do
                    _key:setPosition(startPos)
                    _key:setVisible(true)
                    
                    local keyParticle1 = _key:findChild("Particle_1")
                    local keyParticle2 = _key:findChild("Particle_2")
                    
                    keyParticle1:setDuration(-1)
                    keyParticle1:stopSystem()
                    keyParticle1:resetSystem()

                    keyParticle2:setDuration(-1)
                    keyParticle2:stopSystem()
                    keyParticle2:resetSystem()

                    _key:runCsbAction("actionframe", false, function()
                    end)
                    -- 30帧飞到锁孔 
                    
                    local actMoveLock = cc.MoveTo:create(30/60, lockPos)
                    local actDelayTime = cc.DelayTime:create(90/60)
                    -- 120-150帧飞行到宝箱中央 ,180 播放爆炸动效
                    local actCallFun_playFly2Sound = cc.CallFunc:create(function() 
                        if not bSoundFly2 then
                            bSoundFly2 = true
                            gLobalSoundManager:playSound(self.m_configData.Sound_BonusKey_fly_2)
                        end
                        
                    end)
                    local actMoveBox = cc.MoveTo:create(30/60, boxPos)
                    local actDelayTime2 = cc.DelayTime:create(30/60)
                    local actCallFun_playBomb = cc.CallFunc:create(function()
                        if not bPlayBomb then
                            bPlayBomb = true
                            self.m_bonusKeyBao:setVisible(true)
                            self.m_bonusKeyBao:runCsbAction("actionframe", false, function()
                                self.m_bonusKeyBao:setVisible(false)
                            end)
                        end
                    end)
                    local actDelayTime3 = cc.DelayTime:create(36/60)
                    
                    -- 215-245 飞行到轮盘首行
                    local reelPos = _key:getParent():convertToNodeSpace(flyEndPos[iCol])
                    local actMoveReel = cc.MoveTo:create(30/60, reelPos)
                    local actCallFun_actionEnd = cc.CallFunc:create(function()
                        _key:setVisible(false)
                        -- 钥匙移动全程结束，隐藏bonus弹板，mini轮盘滑动小块开始升行
                        if not bPlayActionEnd then
                            bPlayActionEnd = true

                            --3次闪光结束时弹板也要上移(开始设计时没有考虑弹板移动，加一个传入参数吧)
                            local oldPos = cc.p(self.m_bonusBox:getPosition())
                            local moveData = {
                                node = self.m_bonusBox,
                                fun = function()
                                    self.m_bonusBox:setVisible(false)
                                    self.m_bonusBox:setPosition(oldPos)
                                end
                            }
                            self.m_miniMachine:changeFirstLineSlideSymbol(_fun,moveData)
                        end
                    end)
                    

                    _key:runAction(cc.Sequence:create(
                        actMoveLock, 
                        actDelayTime, 
                        actCallFun_playFly2Sound,
                        actMoveBox, 
                        actDelayTime2,
                        actCallFun_playBomb,
                        actDelayTime3,
                        actMoveReel,
                        actCallFun_actionEnd
                    ))
                end
            end)
       end)

        --展示获胜奖励 刷新右侧宝箱倍数
        self.m_bonusBox:runCsbAction("idleframe", false, function()
    
        end)
    end

    playBonusBoxAnim()
end


function CodeGameScreenBombPurrglarMachine:showBonusRankView(_winnerChairId, _allPlayerData, _fun)

    local allPlayerData = clone(_allPlayerData)
    local dataList = self.m_miniMachine:getAllPlayerInfo()
    -- 重新组织一下数据包，将电脑用户的乘倍添加进去
    for iCol=1,8 do
        local hasData = false
        -- 有数据的话 不需要补充
        for _index,_playerData in ipairs(allPlayerData) do
            if iCol == _playerData.chairId + 1 then
                hasData = true
                break
            end
        end
        -- 补充一个不存在玩家座位的机器人数据
        if not hasData then
            local winMultiple = dataList[iCol] and dataList[iCol].curMulti or 0
            allPlayerData[iCol] = {
                chairId = iCol-1,
                winMultiple = winMultiple
            }
        end
    end
    table.sort(allPlayerData, function(a,b)
        --获胜玩家排在首位
        if _winnerChairId == a.chairId or _winnerChairId ==  b.chairId then
            return _winnerChairId == a.chairId
        end
        --其余玩家按赢钱多少排序
        if a.winMultiple and b.winMultiple then
            return a.winMultiple > b.winMultiple
        end

        return false
    end)

    gLobalSoundManager:playSound(self.m_configData.Sound_BonusRank_show)
    local view = self:showDialog("BonusRank", {}, _fun, BaseDialog.AUTO_TYPE_NOMAL)

    for index=1,8 do
        local data = allPlayerData[index]
        local isMe = (data and data.udid == globalData.userRunData.userUdid)

        local parent = view:findChild(string.format("player_%d", index))
        local playItem = nil
        if 1 == index then
            playItem = util_createAnimation("BombPurrglar_RankChampion.csb")
        else
            playItem = util_createAnimation("BombPurrglar_RankPlayer.csb")

            playItem:findChild("diban_me"):setVisible(isMe)
            playItem:findChild("diban"):setVisible(not isMe)
            playItem:findChild("kuang_me"):setVisible(isMe)
            playItem:findChild("kuang"):setVisible(not isMe)
        end
        parent:addChild(playItem)
        
        --刷新头像
        playItem:findChild("BgPlayer_me"):setVisible(isMe)
        playItem:findChild("headbox_me"):setVisible(isMe)
        playItem:findChild("BgPlayer"):setVisible(not isMe)
        playItem:findChild("headbox"):setVisible(not isMe)
        
        local head = playItem:findChild("sp_head")
        head:removeAllChildren(true)
        local facebookId = data and data.facebookId
        local headId = data and data.head

        local fbid = facebookId
        local headName = headId
        -- local frameId = isMe and globalData.userRunData.avatarFrameId or data.frame
        -- local headSizeLayout = head:getContentSize()
        -- local headSize = cc.size(headSizeLayout.height, headSizeLayout.height)
        -- local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbid, headName, frameId, nil, headSize)
        -- head:addChild(nodeAvatar)
        -- nodeAvatar:setPosition( headSizeLayout.width * 0.5, headSizeLayout.height * 0.5 )

        -- local headRoot = playItem:findChild("Node_head")
        -- local headFrameNode = headRoot:getChildByName("headFrameNode")
        -- if not headFrameNode then
        --     headFrameNode = cc.Node:create()
        --     headRoot:addChild(headFrameNode, 10)
        --     headFrameNode:setName("headFrameNode")
        --     headFrameNode:setPosition(head:getPosition())
        --     headFrameNode:setLocalZOrder(10)
        -- else
        --     headFrameNode:removeAllChildren(true)
        -- end
        -- util_changeNodeParent(headFrameNode, nodeAvatar.m_nodeFrame)

        util_setHead(head, fbid, headName, nil, true)
        -- 乘倍
        -- local coins = data and data.winCoins or 0
        -- local coinStr = util_formatCoins(coins, 3)
        local coins = data and data.winMultiple or 0
        local coinStr = string.format("X%d", coins)
        local labCoins = playItem:findChild("m_lb_coins")
        labCoins:setString(coinStr)
        if 1 == index then
            self:updateLabelSize({label = labCoins,sx = 0.39,sy = 0.39}, 307)
        else
            self:updateLabelSize({label = labCoins,sx = 0.19,sy = 0.19}, 378)
        end
        
        -- 播放当前玩家的动效 
        if isMe then
            playItem:findChild("Node_shine"):setVisible(true) 
            playItem:runCsbAction("idleframe", true)
        end

    end

    return view
end

function CodeGameScreenBombPurrglarMachine:showBonusOver(_coins, _multi, _fun)
    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(_coins, 50)
    ownerlist["m_lb_multi"] = string.format("X%d", _multi)

    gLobalSoundManager:playSound(self.m_configData.Sound_BonusOver_show)
    local view = self:showDialog("BonusOver", ownerlist, _fun)
    if _multi <= 0 then
        local labMultiDesc = view:findChild("ZeusVsHades_coinsin_1")
        local labMultiBg = view:findChild("BombPurrglar_overdi_1")
        local labMulti = view:findChild("m_lb_multi")

        labMultiDesc:setVisible(false)
        labMultiBg:setVisible(false)
        labMulti:setVisible(false)
    end

    local node=view:findChild("m_lb_coins")
    if node then
        view:updateLabelSize({label=node,sx=1,sy=1},692) 
    end
    

    local node=view:findChild("m_lb_multi")
    if node then
        view:updateLabelSize({label=node,sx=0.4,sy=0.4},307) 
    end

    return view
end
---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenBombPurrglarMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息

    --[[
        策划描述:
        一般情况下，接受结果过程进行非常快时间很短时，点击spin后，滚动一秒钟，
        前0.5秒用上次结果假滚，之后切换，根据下次的结果判断假滚0.5秒
        接受下次spin结果有延迟，如果大于0.5秒，则接受下次spin结果时间点为分界点，用下次结果判断假滚
    ]] 

    -- 数据返回后根据最终结果 修改假滚的效果
    local changeTime = 0.5
    for iCol = 1, self.m_iReelColumnNum do
        -- 假滚数据
        local parentData = self.m_slotParents[iCol]
        if parentData then
            -- 替换为配置假滚 或者 相同信号假滚
            local nowTime = xcyy.SlotsUtil:getMilliSeconds()
            --bugly self.m_startSpinTime 这个底层的数据可能是nil
            local startSpinTime = self.m_startSpinTime or 0
            local waitTime = (nowTime - startSpinTime) / 1000
            local delayTime = math.max(0, changeTime - waitTime) 
            self:levelPerformWithDelay(delayTime, function()
                --再走一遍 修改假滚
                self:checkUpdateReelDatas(parentData)

            end)
        end
    end
    
end

function CodeGameScreenBombPurrglarMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenBombPurrglarMachine.super.playEffectNotifyNextSpinCall( self )

    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenBombPurrglarMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

    --其他玩家大赢事件
    local eventData = self.m_roomData:getRoomEvent()
    self.m_roomList:showBigWinAni(eventData)

    CodeGameScreenBombPurrglarMachine.super.slotReelDown(self)
end



--[[
    执行事件 
]]
-- baseBonus炸弹玩法
-- 如果处于事件中，点击了stop按钮则可以直接切换到快停状态
function CodeGameScreenBombPurrglarMachine:playEffect_BaseBonus(_animIndex, _fun)
    -- 首次进入
    if 1==_animIndex then
        -- 打开stop按钮的点击状态 
        -- 修改的状态取自 SpinBtn:btnStopTouchEnd() 内判断的状态数据
        self.m_bottomUI.m_spinBtn.m_btnStopTouch = false
        globalData.slotRunData.gameSpinStage = GAME_MODE_ONE_RUN
        globalData.slotRunData.isClickQucikStop = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Stop, true}) 
    -- 后续触发了快停 直接跳出
    elseif self.m_quickStopNum > 1 then
        if self.m_baseBonusEffect and not self.m_baseBonusEffect.p_isPlay then
            self:playEffect_BaseBonus_QuickStop(function()
                self.m_baseBonusEffect.p_isPlay = true
                self.m_baseBonusEffect = nil
                self:playGameEffect()
            end)
        end
        return
    end


    local posData = self.m_wildPosData[_animIndex]
    -- 结束递归
    if not posData then
        self:playBombWildTipAnim(_fun)
        return
    end

    local fixPos = self:getRowAndColByPos(posData.bombPos)
    local bombSymbol = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    if bombSymbol then
        local isSmallBomb = bombSymbol.p_symbolType == self.SYMBOL_BONUS_1
        local switchWildFrame = isSmallBomb and 80 or 125

        -- 播放爆炸时 切换到裁剪区域，之后再放回来
        local oldParent = bombSymbol:getParent()
        local oldPos = cc.p(bombSymbol:getPosition())
        bombSymbol:runAnim("actionframe")

        local pos = util_getOneGameReelsTarSpPos(self,posData.bombPos)
        if bombSymbol.p_symbolType == self.SYMBOL_BONUS_1 then
            -- 小炸弹 110(60)
            self.m_boomAct:setPosition(pos.x + self.m_SlotNodeW/2,pos.y - self.m_SlotNodeH/2)
            self.m_boomAct:runCsbAction("actionframe",false,function(  )
                self.m_boomAct:setVisible(false)
            end)
            self.m_baseBombSoundId = gLobalSoundManager:playSound(self.m_configData.Sound_Bonus1_changeWild)
        elseif bombSymbol.p_symbolType == self.SYMBOL_BONUS_2 then
            -- 大炸弹 150(60)
            self.m_boomAct:setPosition(pos)
            self.m_boomAct:runCsbAction("actionframe2",false,function(  )
                self.m_boomAct:setVisible(false)
            end)
            self.m_baseBombSoundId = gLobalSoundManager:playSound(self.m_configData.Sound_Bonus2_changeWild)

            -- 延迟提层
            local clipParent = self.m_boomAct:getParent()
            local bombSymbolPos = util_convertToNodeSpace(bombSymbol, clipParent)
            performWithDelay(self.m_baseBonusDelayNode,function()
                util_changeNodeParent(clipParent, bombSymbol)
                bombSymbol:setPosition(bombSymbolPos)
            end, 48/30)
        end
        self.m_boomAct:setVisible(true)
        
        performWithDelay(self.m_baseBonusDelayNode,function()
            if not isSmallBomb then
                util_changeNodeParent(oldParent, bombSymbol)
                bombSymbol:setPosition(oldPos)
            end

            local bMultiWildSound = false
            for _iPos,_symbolType in pairs(posData.changePos) do

                fixPos = self:getRowAndColByPos(_iPos)
                local changeSymbol = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if changeSymbol then
                    -- 拿到当前位置信号的 等级 和 最终等级
                    local oldSymbolType = changeSymbol.p_symbolType
                    local wildLevel,levelData = self:getBombPurrglarWildLevelData(_symbolType)
                    local curLevel = self:getBombPurrglarWildLevelData(oldSymbolType)

                    -- 爆炸一次 升级一次 (重叠爆炸时爆炸前原位置就是wild的话, 升级要放在之后的爆炸动效)
                    local nextLevel = 1
                    if not self.m_wildUpGradeData[_iPos] then
                        self.m_wildUpGradeData[_iPos] = 1
                    else
                        nextLevel = self.m_wildUpGradeData[_iPos] + 1
                        self.m_wildUpGradeData[_iPos] = nextLevel
                    end
                    
                    --当前等级小于目标等级时 才需要切换
                    if curLevel < wildLevel then
                        --播放转换/升级动效
                        local changeSymbolType = levelData[nextLevel]

                        --1. scatter -> wild_scatter
                        if self:isBombPurrglarScatter(changeSymbolType) then

                            -- 一开始不是 wild_scatter , 直接切换到对应等级
                            if curLevel <= 0 then
                                self:changeBombPurrglarCCBByName(changeSymbol, changeSymbolType, true)
                            -- 播放 wild_scatter 的升级动画 
                            else
                                local animName = "change" 
                                if nextLevel > 1 then
                                    animName = string.format("change%d", nextLevel - 1)
                                end
                                self:changeBombPurrglarCCBByName(changeSymbol, changeSymbolType)
                                changeSymbol:runAnim(animName, false)
                            end

                        --2. 其他信号 -> wild
                        else
                            -- 炸弹修改自己的位置变为wild
                            local isBombSymbol = (oldSymbolType == self.SYMBOL_BONUS_1 or oldSymbolType == self.SYMBOL_BONUS_2)
                            local isSelf = _iPos == posData.bombPos

                            if isBombSymbol and not isSelf then

                            elseif isBombSymbol and isSelf then
                                self:changeBombPurrglarCCBByName(changeSymbol, changeSymbolType, true)
                            elseif nextLevel <= 1 then
                                self:changeBombPurrglarCCBByName(changeSymbol, changeSymbolType, true)
                            else
                                local animName = "change" 
                                if nextLevel > 2 then
                                    animName = string.format("change%d", nextLevel - 1)
                                end

                                self:changeBombPurrglarCCBByName(changeSymbol, changeSymbolType)
                                changeSymbol:runAnim(animName, false)
                                if not bMultiWildSound then
                                    bMultiWildSound = true
                                    self.m_baseChangeWildSoundId = gLobalSoundManager:playSound(self.m_configData.Sound_Multiwild_change)
                                end
                            end
                                              
                        end

                    end
                    
                end

            end

            -- wild升级动画最长 1s
            performWithDelay(self.m_baseBonusDelayNode,function()
                self:playEffect_BaseBonus(_animIndex+1, _fun)
            end, 30/30)
        end, switchWildFrame/60)

    --直接下一步
    else
        self:playEffect_BaseBonus(_animIndex+1, _fun)
    end
    
end

function CodeGameScreenBombPurrglarMachine:playEffect_BaseBonus_QuickStop(_fun)
    -- 停掉延时节点的动作
    self.m_baseBonusDelayNode:stopAllActions()
    -- 关闭掉爆炸动效的展示
    self.m_boomAct:setVisible(false)
    -- 关闭爆炸音效 和 乘倍音效
    if self.m_baseBombSoundId then
        gLobalSoundManager:stopAudio(self.m_baseBombSoundId)
        self.m_baseBombSoundId = nil
    end
    if self.m_baseChangeWildSoundId then
        gLobalSoundManager:stopAudio(self.m_baseChangeWildSoundId)
        self.m_baseChangeWildSoundId = nil
    end
    

    local wildPosList = {}
    for i,_posData in ipairs(self.m_wildPosData) do
        for _iPos,_symbolType in pairs(_posData.changePos) do
            if not wildPosList[_iPos] then
                wildPosList[_iPos] = true

                local fixPos = self:getRowAndColByPos(_iPos)
                local symbol = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
                if not symbol then
                    -- 拿不到的小块可能是被切换到裁切层内了
                    local clipParent = self.m_boomAct:getParent()
                    for ii,_child in ipairs(clipParent:getChildren()) do
                        if _child.p_cloumnIndex == fixPos.iY and _child.p_rowIndex == fixPos.iX then
                            symbol = _child
                            -- 拿回到卷轴内
                            local slotParent = self.m_slotParents[_child.p_cloumnIndex].slotParent
                            local pos = util_convertToNodeSpace(symbol, slotParent)
                            util_changeNodeParent(slotParent, symbol)
                            symbol:setPosition(pos)
                            break
                        end
                    end
                end

                if symbol then
                    self:changeBombPurrglarCCBByName(symbol, _symbolType, true)
                end
            end
        end
    end 

    if _fun then
        _fun()
    end
end

-- 播放所有爆炸生成的wild 2次提示动画
function CodeGameScreenBombPurrglarMachine:playBombWildTipAnim(_fun)
    -- 切换的wild没有参与连线的话不用播放 两次闪光
    local bWildLine = false
    local winLines = self.m_runSpinResultData.p_winLines or {}
    local iPosList = {}
    for i,_line in ipairs(winLines) do
        for ii,_iPosLine in ipairs(_line.p_iconPos) do
            if not iPosList[_iPosLine] then
                iPosList[_iPosLine] = true

                local tempPosList = {}
                for iii,_posData in ipairs(self.m_wildPosData) do
                    for _iPosWild,_symbolType in pairs(_posData.changePos) do

                        if not tempPosList[_iPosWild] then
                            tempPosList[_iPosWild] = true
                            -- 连线坐标 和 wild 坐标相等
                            if _iPosLine == _iPosWild then
                                bWildLine = true
                                break
                            end
                        end

                    end
                    if bWildLine then
                        break
                    end
                end
                if bWildLine then
                    break
                end

            end
        end
        if bWildLine then
            break
        end
    end

    if not bWildLine then
        if _fun then
            _fun()
        end

        return
    end

    local maxTipAnimTime = 30/30 * 2

    local wildPosList = {}
    for i,_posData in ipairs(self.m_wildPosData) do
        for _iPos,_symbolType in pairs(_posData.changePos) do
            if not wildPosList[_iPos] then
                wildPosList[_iPos] = true

                local fixPos = self:getRowAndColByPos(_iPos)
                local wildSymbol = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)
    
                if wildSymbol then
                    local curLevel = self:getBombPurrglarWildLevelData(wildSymbol.p_symbolType)
                    local animIndex = curLevel
                    -- local animName = self:isBombPurrglarScatter(wildSymbol.p_symbolType) and "start" or "show"
                    local animName = "show"
                    local tipAnim = animName
                    if animIndex > 1 then
                        tipAnim = string.format("%s%d", animName, animIndex)
                    end
                    
                    wildSymbol:runAnim(tipAnim, false, function()
                        wildSymbol:runAnim(tipAnim, false)
                    end)
                end
            end
        end
    end 

    self:levelPerformWithDelay(maxTipAnimTime,function()
        if _fun then
            _fun()
        end
    end)
end

function CodeGameScreenBombPurrglarMachine:changeBombPurrglarCCBByName(_slotsNode, _changeType, _runIdle)
    local ccbName = self:getSymbolCCBNameByType(self, _changeType)
    -- 期内有相同 ccbName 返回的判断
    _slotsNode:changeCCBByName(ccbName, _changeType)
    _slotsNode:changeSymbolImageByName(ccbName)
    _slotsNode.p_symbolType = _changeType

    self:addScatterSymbolSpine(_slotsNode)
    self:upDateScatterLineAnim(_slotsNode)
    self:upDateWildLineAnim(_slotsNode)

    if _runIdle then
        _slotsNode:runIdleAnim()
    end
end
function CodeGameScreenBombPurrglarMachine:getBombPurrglarWildLevelData(_symbolType)
    local levelTab = CodeGameScreenBombPurrglarMachine.WildLevelData
    for _level,symbolType in ipairs(levelTab) do
        if symbolType == _symbolType then
            return _level,levelTab
        end
    end

    levelTab = CodeGameScreenBombPurrglarMachine.ScatterWildLevelData
    for _level,symbolType in ipairs(levelTab) do
        if symbolType == _symbolType then
            return _level,levelTab
        end
    end

    return 0,{}
end

function CodeGameScreenBombPurrglarMachine:playEffect_BaseCollectScatter(_animIndex, _fun)
    local scatterData = self.m_scatterPosData[_animIndex]
    local flyTime = 0.2 --(72 - 47)/60

    if 1 == _animIndex then
        gLobalSoundManager:playSound(self.m_configData.Sound_Collect_flyStart)
    end
    
    if not scatterData then
        self:levelPerformWithDelay(flyTime, function()
            gLobalSoundManager:playSound(self.m_configData.Sound_Collect_flyEnd)
            self:setCollectScatterNum(true)

            if _fun then
                _fun()
            end
        end)
        return
    end

    local fixPos = self:getRowAndColByPos(scatterData.scatterPos)
    local scatter = self:getFixSymbol(fixPos.iY , fixPos.iX , SYMBOL_NODE_TAG)


    --bugly-获取的小块拿不到scatter工程的文本节点添加一个判空
    if scatter and self:isBombPurrglarScatter(scatter.p_symbolType) then
        self.m_scatterCollectNum = self.m_scatterCollectNum + 1

        local scatterTuowei = util_createAnimation("BombPurrglar_Credits_trail.csb")
        self:addChild(scatterTuowei, GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1 )
        scatterTuowei:setScale(self.m_machineRootScale)
        -- 文字
        local scatterLab = scatter:getCcbProperty("m_lb_coins")
        --bugly-获取的小块拿不到scatter工程的文本节点添加一个打印
        if not scatterLab then
            local msg = string.format("[CodeGameScreenBombPurrglarMachine:playEffect_BaseCollectScatter] iCol=(%d) iRow=(%d)", fixPos.iY, fixPos.iX)
            release_print(msg)
        end
        scatterLab:setVisible(false)
        local scatterLab_text = scatterLab:getString()
        -- 工程做的有偏移，获取一下这个偏移
        local offsetY = -(scatter:getCcbProperty("money"):getPositionY())

        local flyLabel = util_createAnimation("Socre_BombPurrglar_Scatter_zi.csb")
        flyLabel:findChild("m_lb_coins"):setString(scatterLab_text)
        scatterTuowei:addChild(flyLabel)
        flyLabel:setScale(0.5)

        local startPos = util_convertToNodeSpace(scatter, self)

        scatterTuowei:setPosition(startPos)
        local particle_1 = scatterTuowei:findChild("Particle_1") 
        local particle_2 = scatterTuowei:findChild("Particle_2") 
        particle_1:setPositionType(0)
        particle_1:setDuration(-1)
        particle_1:stopSystem()
        particle_1:resetSystem()

        particle_2:setPositionType(0)
        particle_2:setDuration(-1)
        particle_2:stopSystem()
        particle_2:resetSystem()


        local labCoins = self.m_collectSorce:findChild("m_lb_coins")
        local endPos = util_convertToNodeSpace(labCoins, self)
        endPos = cc.p(endPos.x, endPos.y + offsetY)
        
        local actCallFunTuowei_1 = cc.CallFunc:create(function()
            particle_1:stopSystem()
            particle_2:stopSystem()
            flyLabel:setVisible(false)
        end) 
        local dalayTime = cc.DelayTime:create(1)
        local actCallFunTuowei = cc.CallFunc:create(function()
            self.m_scatterCollectNum = self.m_scatterCollectNum - 1

            scatterTuowei:removeFromParent()
        end)
        scatterTuowei:runAction(cc.Sequence:create(
            cc.MoveTo:create(flyTime, endPos), 
            actCallFunTuowei_1,
            dalayTime,
            actCallFunTuowei
        ))
    else
        --bugly-获取的小块拿不到scatter工程的文本节点添加一个打印 , 把这个错误信号的数据输出一下
        local p_symbolType    = scatter and scatter.p_symbolType or 999
        local p_cloumnIndex   = scatter and scatter.p_cloumnIndex or 99
        local p_rowIndex      = scatter and scatter.p_rowIndex or 99
        
        local sTitel = "[CodeGameScreenBombPurrglarMachine:playEffect_BaseCollectScatter] "
        local sUser = " error_userInfo_ udid=" .. (globalData.userRunData.userUdid or "isnil") .. " machineName="..(globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. " gameSeqID = " .. (globalData.seqId or "")
        local sServer = " sever传回的数据：  "..(globalData.slotRunData.severGameJsonData or "isnil")
        local curData = string.format("type=(%d) clo=(%d) row=(%d)", p_symbolType, p_cloumnIndex, p_rowIndex)
        local msg = sTitel .. sUser .. sServer .. curData
        
        if DEBUG == 2 then
            error(msg)
        else
            if util_sendToSplunkMsg then
                util_sendToSplunkMsg("BombPurrglar_1905_luaError",msg)
            end
        end
    end

    --直接下一步
    self:playEffect_BaseCollectScatter(_animIndex+1, _fun)
end

--[[
    设置收集的钱数
]] 
function CodeGameScreenBombPurrglarMachine:setCollectScatterNum(isPlayAni)
    local collectCoinNum = 1

    if isPlayAni == true then
         -- 刷新动效
         self.m_collectSorce:runCsbAction("actionframe", false, function()
            self.m_collectSorce:runCsbAction("idleframe", false)
        end)
    end

    local result = self.m_roomData:getSpotResult()
    local roomData = self.m_roomList:getRoomData()
    

    -- 本次收集触发了玩法
    if isPlayAni and result then
        local sets = result.data.sets or {}
        for iCol,_data in ipairs(sets) do
            if _data.udid == globalData.userRunData.userUdid then
                collectCoinNum = _data.coins
                break
            end
        end
    elseif roomData.extra.score then
        collectCoinNum = roomData.extra.score
    end

    collectCoinNum = math.max(1, collectCoinNum)

    local coinStr = util_formatCoins(collectCoinNum, 300)
    local labCoins = self.m_collectSorce:findChild("m_lb_coins")
    labCoins:setString(coinStr)
    self:updateLabelSize({label = labCoins,sx = 1,sy = 1}, 200)
end

function CodeGameScreenBombPurrglarMachine:enterLevelUpDateCollectNum()
    if not self.m_bEnterUpDateCollect then

        local roomData = self.m_roomList:getRoomData()
        if roomData.extra.score then
            self.m_bEnterUpDateCollect = true
            self:setCollectScatterNum(false)
        end
        
    end
end

-- 断线重连展示玩法赢钱
function CodeGameScreenBombPurrglarMachine:playEffect_ReconnectionBonusWinCoin(_fun)
    local winCoins = self.m_reconnectionBonusWinCoin
    local winMultiple = self.m_reconnectionBonusWinMultiple

    self:showBonusOver(winCoins, winMultiple, function()

        -- self:checkFeatureOverTriggerBigWin(winCoins, GameEffect.EFFECT_BONUS)
        local gameName = self:getNetWorkModuleName()
        --参数传-1位领取所有奖励,领取当前奖励传数组最后一位索引
        local index = - 1
        gLobalSendDataManager:getNetWorkFeature():sendTeamMissionReward(gameName,index,
            function()
                globalData.slotRunData.lastWinCoin = 0
                local params = {winCoins, true, true}
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_WINCOIN, params)

                --重新刷新房间消息
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_START_REFRESH_ROOM_DATA)
            end,
            function(errorCode, errorData)
                
            end
        )

        if _fun then
            _fun()
        end

        
    end)
end


--[[
    通用遮罩
]]
function CodeGameScreenBombPurrglarMachine:showBonusDark()
    self.m_bonusDark:setVisible(true)
    self.m_bonusDark:runCsbAction("dark", false, function()
        self.m_bonusDark:runCsbAction("dark_idle", true)
    end)
end
function CodeGameScreenBombPurrglarMachine:hideBonusDark()
    self.m_bonusDark:runCsbAction("dark_over", false, function()
        self.m_bonusDark:setVisible(false)
    end)
end

--[[
    reSpinOverBonusBox的裁剪区域 在播放动画时的各个阶段是会变的
]]

function CodeGameScreenBombPurrglarMachine:changeReSpinOverBonusBoxClipSize(_enlarge)
    
    local bonusBoxOverClipNode = self.m_miniMachine:findChild("Panel_bonusBoxOver")
    local bonusBoxOver_size = bonusBoxOverClipNode:getContentSize()
    local nodePos = util_convertToNodeSpace(bonusBoxOverClipNode, self)

    -- 加入裁切后，策划觉得不好看放弃纵向裁切 的下半部分
    local height = bonusBoxOver_size.height + display.height/2
    if _enlarge then
        height = height + 20
    end

    local clipData = {
        x= nodePos.x, 
        y= nodePos.y - display.height/2, 
        width = bonusBoxOver_size.width, 
        height = height,
    }

    local bonusOverClip = self.m_rsover_bonusBox:getParent()
    bonusOverClip:setClippingRegion(clipData)
end



--[[
    其他判断逻辑 和 工具接口
]]
function CodeGameScreenBombPurrglarMachine:levelPerformWithDelay(_time, _fun)
    if _time <= 0 then
        _fun()
        return
    end


    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(waitNode,function()

        _fun()

        waitNode:removeFromParent()
    end, _time)

    return waitNode
end

function CodeGameScreenBombPurrglarMachine:isBombPurrglarWild(_symbolType)
    if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or     -- 普通wild，对应乘倍wild
        _symbolType == self.SYMBOL_WILD_2 or 
        _symbolType == self.SYMBOL_WILD_3 or 

        _symbolType == self.SYMBOL_WILD_SCATTER_1 or     -- scatter变换的wild，对应乘倍wild
        _symbolType == self.SYMBOL_WILD_SCATTER_2 or 
        _symbolType == self.SYMBOL_WILD_SCATTER_3 then

        return true
    end

    return false
end

function CodeGameScreenBombPurrglarMachine:isBombPurrglarScatter(_symbolType)
    if _symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or     -- 普通scatter
        _symbolType == self.SYMBOL_WILD_SCATTER_1 or        -- 炸弹变换的scatter 和 对应的乘倍
        _symbolType == self.SYMBOL_WILD_SCATTER_2 or 
        _symbolType == self.SYMBOL_WILD_SCATTER_3 then

        return true
    end

    return false
end

 -- 根据行 列转化为位置(行数为从下往上数，位置是从左上开始数)
function CodeGameScreenBombPurrglarMachine:getPosByRowAndCol(row,col)
	local cols_nums = self.m_iReelColumnNum	-- 滚轴的数量(列数)
	local rows_nums = self.m_iReelRowNum    -- 行的数量
	local pos
	pos = (col - 1) + (rows_nums - row) * cols_nums
	return pos
end

function CodeGameScreenBombPurrglarMachine:changeBaseReelVisible( _visible )
    self:findChild("reel_kuang"):setVisible(_visible)
    self:findChild("reel_line"):setVisible(_visible)
    self:findChild("reel_base"):setVisible(_visible)
    self:findChild("sp_reel"):setVisible(_visible)
    self:findChild("roomList"):setVisible(_visible)
    self:findChild("Node_credit"):setVisible(_visible)
end

--[[
    获取一列信号是否相等，相等的话返回该信号，不相等 -1

    静止状态 : 获取轮盘信号

    滚动状态 : 获取server回传结果信号
]]
function CodeGameScreenBombPurrglarMachine:getReelColSameSymbol(_iCol)
    local sameSymbolType = -1

    local spinStage = self:getGameSpinStage()
    --拿轮盘数据
    if spinStage == WAITING_DATA then
        for iRow=1,self.m_iReelRowNum do
            local symbolNode = self:getFixSymbol(_iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode then
                if sameSymbolType < 0 then
                    sameSymbolType = symbolNode.p_symbolType
                elseif sameSymbolType ~= symbolNode.p_symbolType then
                    return -1
                end
            end
        end
    --拿回传数据
    else
        local reels = self.m_runSpinResultData.p_reels or {}

        for iLine,_lineData in ipairs(reels) do
            local symbolType = _lineData[_iCol]
            if symbolType then
                if sameSymbolType < 0 then
                    sameSymbolType = symbolType
                elseif sameSymbolType ~= symbolType then
                    return -1
                end
            end
        end
    end
    
    return sameSymbolType
end

--=================================================================一些需求重写父类接口

-- 使用服务器回传数据展示顶部补充小块
-- function CodeGameScreenBombPurrglarMachine:getNextReelSymbolType()
--     return self.m_runSpinResultData.p_prevReel
-- end

---
-- 点击快速停止reel
--
function CodeGameScreenBombPurrglarMachine:quicklyStopReel(colIndex)
    self.m_quickStopNum = self.m_quickStopNum + 1
    if self.m_baseBonusEffect and not self.m_baseBonusEffect.p_isPlay then
        self.m_quickStopNum = 2

        self:playEffect_BaseBonus_QuickStop(function()
            self.m_baseBonusEffect.p_isPlay = true
            self.m_baseBonusEffect = nil
            self:playGameEffect()
        end)
    end
    -- print("[CodeGameScreenBombPurrglarMachine:quicklyStopReel]", self.m_quickStopNum)
    CodeGameScreenBombPurrglarMachine.super.quicklyStopReel(self,colIndex)
end

function CodeGameScreenBombPurrglarMachine:beginReel()
    CodeGameScreenBombPurrglarMachine.super.beginReel(self)
    --
    self.m_quickStopNum = 0
    --重置自动退出时间间隔
    self.m_roomList:resetLogoutTime()
end

--[[
    @desc: 获取滚动的 列表数据， 
    假滚逻辑根据滚动
]]
function CodeGameScreenBombPurrglarMachine:checkUpdateReelDatas(parentData)
    local reelDatas = nil

    if self:getCurrSpinMode() == FREE_SPIN_MODE then
        reelDatas = self.m_configData:getFsReelDatasByColumnIndex(self.m_fsReelDataIndex, parentData.cloumnIndex)
    else
        reelDatas = self.m_configData:getNormalReelDatasByColumnIndex(parentData.cloumnIndex)
    end

    --!!! 如果一列信号全部相同，则假滚信号全部修改为该信号。
    local sameSymbolType = self:getReelColSameSymbol(parentData.cloumnIndex)
    if sameSymbolType >= 0 then
        local newReelDatas = {}
        for i,v in ipairs(reelDatas) do
            table.insert(newReelDatas, sameSymbolType)
        end
        parentData.reelDatas = newReelDatas
    else
        parentData.reelDatas = reelDatas
    end

    

    --首次点spin时 随机一个滚动循环数据的index 以后每轮在产生停止时上方假信号时生成
    if parentData.beginReelIndex == nil then
        parentData.beginReelIndex = util_random(1, #reelDatas)
    end

    return reelDatas
end
--[[
    设置bonus scatter 层级
    解决 新增 bonus1 bonus2 的层级
]]
function CodeGameScreenBombPurrglarMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_SCATTER or
        symbolType ==  self.SYMBOL_WILD_SCATTER_1 or
        symbolType ==  self.SYMBOL_WILD_SCATTER_2 or
        symbolType ==  self.SYMBOL_WILD_SCATTER_3 then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2
    --!!!
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_BONUS or 
        symbolType == self.SYMBOL_BONUS_1 or 
        symbolType == self.SYMBOL_BONUS_2 or
        symbolType == self.SYMBOL_BONUS_3 then

        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2
    else

        if symbolType < TAG_SYMBOL_TYPE.SYMBOL_SCATTER then -- 表明是普通信号
            -- 这样调整后 分支越高的信号层级越高
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1 + (TAG_SYMBOL_TYPE.SYMBOL_SCATTER - symbolType)
        else
            order = REEL_SYMBOL_ORDER.REEL_ORDER_1
        end
    end

    return order
end


--新滚动使用
function CodeGameScreenBombPurrglarMachine:updateReelGridNode(_symbolNode)
    CodeGameScreenBombPurrglarMachine.super.updateReelGridNode(self, _symbolNode)

    self:upDateBonus2Idle(_symbolNode)

    self:addScatterSymbolSpine(_symbolNode)
    self:setSpecialNodeScore(_symbolNode)

    self:upDateScatterLineAnim(_symbolNode)
    self:upDateWildLineAnim(_symbolNode)
end

function CodeGameScreenBombPurrglarMachine:upDateBonus2Idle(_symbolNode)
    if self.SYMBOL_BONUS_2 == _symbolNode.p_symbolType and _symbolNode.p_rowIndex == self.m_iReelRowNum+1 then
        _symbolNode.p_idleIsLoop = false
        _symbolNode:runIdleAnim()
    end
end

function CodeGameScreenBombPurrglarMachine:addScatterSymbolSpine(_symbolNode)
    if self:isBombPurrglarScatter(_symbolNode.p_symbolType) then
        -- 挂载一个spine
        local SpineNode = _symbolNode:getCcbProperty("SpineNode")
        local addSpineName = "scatterSpine"
        
        local addSpine = SpineNode:getChildByName(addSpineName)
        if not addSpine then
            addSpine = util_spineCreate("Socre_BombPurrglar_Scatter",true,true)
            SpineNode:addChild(addSpine)
            addSpine:setName(addSpineName)

            _symbolNode:registerAniamCallBackFun(function(_slotsNode)
                local spine = _slotsNode:getCcbProperty("scatterSpine")
                if spine then
                    util_spinePlay(spine, _slotsNode.m_currAnimName, _slotsNode.m_slotAnimaLoop)
                end
            end)
        elseif nil == _symbolNode.m_animaCallBackFun then
            _symbolNode:registerAniamCallBackFun(function(_slotsNode)
                local spine = _slotsNode:getCcbProperty("scatterSpine")
                if spine then
                    util_spinePlay(spine, _slotsNode.m_currAnimName, _slotsNode.m_slotAnimaLoop)
                end
            end)
        end
    end
end
-- 给一些信号块上的数字进行赋值
function CodeGameScreenBombPurrglarMachine:setSpecialNodeScore(symbolNode)
    local iCol = symbolNode.p_cloumnIndex
    local iRow = symbolNode.p_rowIndex

    -- Scatter
    if self:isBombPurrglarScatter(symbolNode.p_symbolType) then
        -- 重置 展示
        symbolNode:getCcbProperty("m_lb_coins"):setVisible(true)

        if iRow ~= nil and iRow <= self.m_iReelRowNum and iCol ~= nil and symbolNode.m_isLastSymbol == true then
            local pos = self:getPosByRowAndCol(iRow,iCol)
            local score = self:getReSpinSymbolScore(pos)
            local labCoins = symbolNode:getCcbProperty("m_lb_coins")
            labCoins:setString(util_formatCoins(score, 3))
            self:updateLabelSize({label = labCoins,sx = 0.5,sy = 0.5}, 390)
        else
            local score = self:randomDownRespinSymbolScore(symbolNode.p_symbolType)
            local labCoins = symbolNode:getCcbProperty("m_lb_coins")
            labCoins:setString(util_formatCoins(score, 3))
            self:updateLabelSize({label = labCoins,sx = 0.5,sy = 0.5}, 390)
        end

    end
    
end

function CodeGameScreenBombPurrglarMachine:upDateScatterLineAnim(_scatterNode)
    if self:isBombPurrglarScatter(_scatterNode.p_symbolType) then
        local name = {
            [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = "actionframe",
            [self.SYMBOL_WILD_SCATTER_1] = "actionframe",
            [self.SYMBOL_WILD_SCATTER_2] = "actionframe2",
            [self.SYMBOL_WILD_SCATTER_3] = "actionframe3",
        }

        local lineName = name[_scatterNode.p_symbolType] or name[TAG_SYMBOL_TYPE.SYMBOL_SCATTER]
        _scatterNode:setLineAnimName(lineName)

        local idleframe = {
            [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = "idleframe",
            [self.SYMBOL_WILD_SCATTER_1] = "idleframe2",
            [self.SYMBOL_WILD_SCATTER_2] = "idleframe3",
            [self.SYMBOL_WILD_SCATTER_3] = "idleframe4",
        }
        local idleName = idleframe[_scatterNode.p_symbolType] or idleframe[TAG_SYMBOL_TYPE.SYMBOL_SCATTER] 
        _scatterNode:setIdleAnimName(idleName)
    end
end

function CodeGameScreenBombPurrglarMachine:upDateWildLineAnim(_wildNode)
    if _wildNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD or
        _wildNode.p_symbolType == self.SYMBOL_WILD_2 or 
        _wildNode.p_symbolType == self.SYMBOL_WILD_3 then 

        local name = {
            [TAG_SYMBOL_TYPE.SYMBOL_WILD] = "actionframe",
            [self.SYMBOL_WILD_2] = "actionframe1",
            [self.SYMBOL_WILD_3] = "actionframe2",
        }            
        
        local lineName = name[_wildNode.p_symbolType] or name[TAG_SYMBOL_TYPE.SYMBOL_WILD]
        _wildNode:setLineAnimName(lineName)

        local idleframe = {
            [TAG_SYMBOL_TYPE.SYMBOL_WILD] = "idleframe",
            [self.SYMBOL_WILD_2] = "idleframe1",
            [self.SYMBOL_WILD_3] = "idleframe2",
        }
        local idleName = idleframe[_wildNode.p_symbolType] or idleframe[TAG_SYMBOL_TYPE.SYMBOL_WILD] 
        _wildNode:setIdleAnimName(idleName)
    end
end
-- 根据网络数据获得respinBonus小块的分数
function CodeGameScreenBombPurrglarMachine:getReSpinSymbolScore(id)
    local storedIcons = self.m_runSpinResultData.p_selfMakeData.positionScore or {}
    -- local storedIcons = self.m_runSpinResultData.p_storedIcons or {}
    local score = nil

    for _sPos,_iScore in pairs(storedIcons) do
        if tonumber(_sPos) == id then
            score = _iScore
            break
        end
    end

    if score == nil then
       return 0
    end

    return score
end

function CodeGameScreenBombPurrglarMachine:randomDownRespinSymbolScore(symbolType)
    local score = nil

    if TAG_SYMBOL_TYPE.SYMBOL_SCATTER == symbolType then
        -- 根据配置表来获取滚动时 respinBonus小块的分数
        -- 配置在 Cvs_cofing 里面
        score = globalData.slotRunData:getCurTotalBet() * 0.01 
    end

    return score
end

-- 解决落地动画
function CodeGameScreenBombPurrglarMachine:playCustomSpecialSymbolDownAct( slotNode )
    CodeGameScreenBombPurrglarMachine.super.playCustomSpecialSymbolDownAct(self, slotNode )
    -- 使用底层新加的 落地音效和动画配置,玩家热更底层代码后恢复正常，只动态下载代码不热更时会出现 没有提层效果和落地音效
    -- if slotNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or slotNode.p_symbolType == self.SYMBOL_BONUS_2 then
    --     local order = self:getBounsScatterDataZorder(slotNode.p_symbolType)
    --     slotNode = util_setSymbolToClipReel(self,slotNode.p_cloumnIndex, slotNode.p_rowIndex, slotNode.p_symbolType, order)
    --     local linePos = {}
    --     linePos[#linePos + 1] = {iX = slotNode.p_rowIndex, iY = slotNode.p_cloumnIndex}
    --     slotNode.m_bInLine = true
    --     slotNode:setLinePos(linePos)
    -- end

    local bulingSound = {
        [self.SYMBOL_BONUS_1] = self.m_configData.Sound_Bonus1_buling,
        [self.SYMBOL_BONUS_2] = self.m_configData.Sound_Bonus2_buling,
        -- [TAG_SYMBOL_TYPE.SYMBOL_SCATTER] = self.m_configData.Sound_Scatter_buling,
    }
    if nil ~= bulingSound[slotNode.p_symbolType] then
        slotNode:runAnim("buling",false)
        self:playBulingSymbolSounds( slotNode.p_cloumnIndex, bulingSound[slotNode.p_symbolType])
    end
end

function CodeGameScreenBombPurrglarMachine:checkSymbolTypePlayTipAnima(symbolType)
    return false
end
function CodeGameScreenBombPurrglarMachine:setScatterDownScound()

end

function CodeGameScreenBombPurrglarMachine:checkOnceClipNode()
 
    local iColNum = self.m_iReelColumnNum
    local reel = self:findChild("sp_reel_0")
    local startX = reel:getPositionX()
    local startY = reel:getPositionY()
    local reelEnd = self:findChild("sp_reel_" .. (iColNum - 1))
    local endX = reelEnd:getPositionX()
    local endY = reelEnd:getPositionY()
    local reelSize = reelEnd:getContentSize()
    local scaleX = reelEnd:getScaleX()
    local scaleY = reelEnd:getScaleY()
    reelSize.width = reelSize.width * scaleX
    reelSize.height = reelSize.height * scaleY
    endX = endX + reelSize.width - startX 
    endY = endY + reelSize.height - startY
    self.m_onceClipNodeEffect =
        cc.ClippingRectangleNode:create(
        {
            x = startX ,
            y = startY,
            width = endX,
            height = endY
        }
    )
    self.m_clipParent:addChild(self.m_onceClipNodeEffect, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_SPECIAL_NODE + 1)
    self.m_onceClipNodeEffect:setPosition(0, 0)


    self.m_boomAct = util_createAnimation("BombPurrglar_Wild_boom.csb")
    self.m_onceClipNodeEffect:addChild(self.m_boomAct)
    self.m_boomAct:setVisible(false)

    CodeGameScreenBombPurrglarMachine.super.checkOnceClipNode(self)
end

function CodeGameScreenBombPurrglarMachine:showBonusEndGuoChang(_func, _resultData)
    
    local keySymbol = nil
    for iCol=1,self.m_miniMachine.m_iReelColumnNum do
        local node = self.m_miniMachine.m_respinView:getBombPurrglarSymbolNode(1, iCol)
        if node.p_rowIndex == 1 and node.p_symbolType == self.SYMBOL_BONUSGAME_GOLDKEY then
            keySymbol = node
            break
        end
    end
    
    if keySymbol then

        local flayKey = util_createAnimation("Socre_BombPurrglar_gold.csb")
        self:addChild(flayKey,self.BONUSVIEW_ORDER.DARK + 6)
        flayKey:setPosition(util_getConvertNodePos(keySymbol,flayKey))
        flayKey:setScale(self.m_machineRootScale)
        keySymbol:setVisible(false)
        -- self.m_miniMachine:reSpinOverHideAllSymbol(function()
            
            self:showBonusDark()
            -- 隐藏金色光柱
            self.m_miniMachine:changeRunEffectVisible(false)
            self.m_miniMachine:changePlayerItemArrowVisible(false)
            local item = self.m_miniMachine.m_playerItems[keySymbol.p_cloumnIndex]
            local actitem = self.RespinPlayerItem[keySymbol.p_cloumnIndex]            
            actitem:setVisible(true)
            item:setVisible(false)
    
            -- 金钥匙飞行 宝箱右侧点位
            local endNode =  self.m_miniMachine:findChild("Node_flyKey") 
            local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPosition()))
            local endPos = self:convertToNodeSpace(cc.p(worldPos.x, worldPos.y))
            -- 金钥匙飞行 宝箱锁孔点位
            local endNode2 = self.m_rsover_bonusBox:findChild("Node_box")
            local endNode2Pos = cc.p(endNode2:getPosition())
            local worldPos2 = endNode2:getParent():convertToWorldSpace(cc.p(endNode2Pos.x + 10,endNode2Pos.y + 40))
            local endPos2 = self:convertToNodeSpace(cc.p(worldPos2.x, worldPos2.y))
            
            --获胜者的数据
            local winnerList = _resultData.data.winnerChairId or {}
            local winnerChairId = winnerList[1] or 0
            local winnerMultiple = _resultData.data.winnerMultiple or 0
    
    
            local actList = {}
            gLobalSoundManager:playSound(self.m_configData.Sound_BonusPlayerItem_light)
            actList[#actList+1] = cc.CallFunc:create(function(  )
                -- shouji(335-490帧) 
                flayKey:runCsbAction("shouji")
            end)
            -- 460_475帧时飞行时间
            actList[#actList+1] = cc.DelayTime:create(126/60)
            actList[#actList+1] = cc.MoveTo:create(15/60,endPos)
            actList[#actList+1] = cc.CallFunc:create(function(  )
    
                flayKey:runCsbAction("shouji_idle", true)

                actitem:playShineAnim()
            end)
            actList[#actList+1] = cc.DelayTime:create(20/60)
            -- 宝箱掉落下来
            local boxMoveTime = 0.5
            local boxResilienceTime = 0.1
            actList[#actList+1] = cc.CallFunc:create(function(  )

                --金色光效消失
                self.m_miniMachine:changeTopLightVisible(false)
                local boxParent = self.m_rsover_bonusBox:getParent()
                local boxSize = self.m_rsover_bonusBox:findChild("Sprite_bg"):getContentSize()
                local slotNodeH = self.m_miniMachine.m_reSpinNodeSize.height
                local symbolTopPosY = self.m_rsover_bonusBox:findChild("Node_symbolTop"):getPositionY()
                local boxEndPos = boxParent:convertToNodeSpace(cc.p(display.width/2, display.height/2))
                local boxStartPos = cc.p(boxEndPos.x, boxEndPos.y + self.m_machineRootScale*(slotNodeH * (self.m_miniMachine.m_iReelRowNum + 1) + symbolTopPosY - 20))
                local resilienceHeight = boxSize.height/16
                local pos1 = cc.p(boxEndPos.x, boxEndPos.y - resilienceHeight)

                self.m_rsover_bonusBox:setPosition(boxStartPos)

                self.m_miniMachine:reSpinOverHideAllSymbol({
                    moveTime = boxMoveTime,
                    distance = math.abs(boxStartPos.y - pos1.y),
                })
                -- 减小裁剪区域
                self:changeReSpinOverBonusBoxClipSize(false)
                -- 掉落
                local boxAct_move1 = cc.EaseSineIn:create(cc.MoveTo:create(boxMoveTime, pos1))
                -- 回弹
                local boxAct_move2 = cc.MoveTo:create(boxMoveTime, boxEndPos)
                -- 扩大裁剪区域
                local boxAct_fun = cc.CallFunc:create(function() 
                    self:changeReSpinOverBonusBoxClipSize(true)
                end)

                self.m_rsover_bonusBox:runCsbAction("show")
                util_spinePlay(self.m_rsover_bonusBox.m_redBox,"idleframe2")
                self.m_rsover_bonusBox:setVisible(true)
                self.m_rsover_bonusBox:runAction(cc.Sequence:create(
                    boxAct_move1,
                    boxAct_fun,
                    boxAct_move2
                ))

                --红色背景下落
                local redBg = self.m_rsover_bonusBox:findChild("Sprite_redBg") 
                local redBgStartPos = redBg:getParent():convertToWorldSpace(cc.p(redBg:getPosition()))
                self.m_miniMachine:playRedBgDownAnim({
                    moveTime = boxMoveTime,
                    resilienceTime = boxResilienceTime,
                    startPos = redBgStartPos,
                    resilienceHeight = resilienceHeight,
                })
            end)
            actList[#actList+1] = cc.DelayTime:create(boxMoveTime + boxResilienceTime)

            actList[#actList+1] = cc.CallFunc:create(function()
                self.m_rsover_bonusBoom:setVisible(true)
                
                gLobalSoundManager:playSound(self.m_configData.Sound_BonusBox_show)
                self.m_rsover_bonusBoom:runCsbAction("actionframe1",false,function(  )
                    self.m_rsover_bonusBoom:setVisible(false)
                end)
                
                self.m_miniMachine.m_respinView:setVisible(false)
            end)

            actList[#actList+1] = cc.DelayTime:create(90/60)
            
            actList[#actList+1] = cc.CallFunc:create(function()
                -- kaisuo(660-750帧)
                gLobalSoundManager:playSound(self.m_configData.Sound_BonusGoldKey_unlock)
                flayKey:runCsbAction("kaisuo", false, function()
                    flayKey:setVisible(false)
                end)
            end)
            -- 660-710帧是飞行时间
            actList[#actList+1] = cc.MoveTo:create(50/60,endPos2)
            actList[#actList+1] = cc.DelayTime:create(40/60)
            actList[#actList+1] = cc.CallFunc:create(function(  )
                -- "actionframe1" 240帧
                self.m_rsover_bonusBox:runCsbAction("actionframe1")
                util_spinePlay(self.m_rsover_bonusBox.m_redBox,"actionframe4")
    
                local lab = self.m_rsover_bonusBox:findChild("m_lb_coins") 
                if lab then
                    lab:setString("X"..winnerMultiple)
                    self:updateLabelSize({label = lab,sx = 0.9,sy = 0.9}, 261)
                end
    
            end)
            actList[#actList+1] = cc.DelayTime:create(240/60)
            actList[#actList+1] = cc.CallFunc:create(function(  )
                -- "shouji" 36帧  12～36帧飞行
                self.m_rsover_bonusBox:runCsbAction("shouji")
                local flayLab =  util_createAnimation("Socre_BombPurrglar_bonus_zi.csb")
                self:addChild(flayLab, self.BONUSVIEW_ORDER.BOTTOMUSERITEM + 1)
                local startNode =  self.m_rsover_bonusBox:findChild("m_lb_coins")
                local startPos = util_convertToNodeSpace(startNode, flayLab:getParent()) 
                flayLab:findChild("m_lb_coins"):setString(startNode:getString())
                flayLab:setPosition(startPos)
                gLobalSoundManager:playSound(self.m_configData.Sound_BonusBox_multiFly)
                flayLab:runCsbAction("shouji1")

                local endNode_flayLab = item:findChild("multi")
                local endPos_flayLab = util_convertToNodeSpace(endNode_flayLab, flayLab:getParent()) 
                local actList_flayLab = {} 
                actList_flayLab[#actList_flayLab + 1] = cc.DelayTime:create(12/60)
                actList_flayLab[#actList_flayLab + 1] = cc.MoveTo:create(24/60,endPos_flayLab)
                actList_flayLab[#actList_flayLab + 1] = cc.CallFunc:create(function()
                    gLobalSoundManager:playSound(self.m_configData.Sound_BonusBox_multiFly_end)
                    flayLab:removeFromParent()
                end)

                flayLab:runAction(cc.Sequence:create(actList_flayLab))
            end)
            actList[#actList+1] = cc.DelayTime:create(36/60)
            actList[#actList+1] = cc.CallFunc:create(function(  )
    
                local newMulti = item.m_playerInfo.curMulti + winnerMultiple
                item:upDateMultiLab(newMulti, "actionframe1")
                actitem:upDateMultiLab(newMulti, "actionframe1")
    
            end)
            actList[#actList+1] = cc.DelayTime:create(180/60)
            actList[#actList+1] = cc.CallFunc:create(function(  )
    
                self.m_rsover_bonusBoom:setVisible(false)
                self.m_rsover_bonusBox:setVisible(false)
                self.m_miniMachine:changeRedBgVisible(false)
                
                -- self.m_miniMachine.m_respinView:setVisible(true)
                if _func then
                    _func()
                end
                
                item:setVisible(true)
                actitem:setVisible(false)
                self:hideBonusDark()
                flayKey:removeFromParent()
            end)
            
            local sq = cc.Sequence:create(actList)
            flayKey:runAction(sq)

        -- end)
        

    else
        if _func then
            _func()
        end
    end
    


end

---
-- 增加赢钱后的 效果
function CodeGameScreenBombPurrglarMachine:addLastWinSomeEffect() -- add big win or mega win
    CodeGameScreenBombPurrglarMachine.super.addLastWinSomeEffect(self)
    self:removeEffectByType(GameEffect.EFFECT_FIVE_OF_KIND)

end

function CodeGameScreenBombPurrglarMachine:scaleMainLayer()
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
    if globalData.slotRunData.isPortrait == true then
        if display.height < DESIGN_SIZE.height then
            mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
            util_csbScale(self.m_machineNode, mainScale)
            self.m_machineRootScale = mainScale
        end
    else
        --!!!
        if display.width <= DESIGN_SIZE.width then
            mainScale = mainScale * 0.95
        end

        util_csbScale(self.m_machineNode, mainScale)
        self.m_machineRootScale = mainScale
        self.m_machineNode:setPositionY(mainPosY)
    end
end

return CodeGameScreenBombPurrglarMachine