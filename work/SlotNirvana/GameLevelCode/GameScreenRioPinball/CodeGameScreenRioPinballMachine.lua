---
-- island li
-- 2019年1月26日
-- CodeGameScreenRioPinballMachine.lua
-- 
-- 玩法：
-- 
-- ！！！！！注意继承 有长条用 BaseNewReelMachine  无长条用 BaseNewReelMachine
-- local BaseNewReelMachine = require "Levels.BaseNewReelMachine" 
local BaseNewReelMachine = require "Levels.BaseNewReelMachine"
local GameEffectData = require "data.slotsdata.GameEffectData"
local BaseDialog = util_require("Levels.BaseDialog")
local CodeGameScreenRioPinballMachine = class("CodeGameScreenRioPinballMachine", BaseNewReelMachine)

CodeGameScreenRioPinballMachine.m_isMachineBGPlayLoop = false -- 是否循环播放主背景动画

CodeGameScreenRioPinballMachine.SYMBOL_BONUS_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  -- bonus用挡板1 /
CodeGameScreenRioPinballMachine.SYMBOL_BONUS_3 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 2  -- bonus用挡板2 \
CodeGameScreenRioPinballMachine.SYMBOL_BONUS_EMPTY = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 7  -- bonus分数
CodeGameScreenRioPinballMachine.SYMBOL_BONUS_4 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 8  -- bonus分数
CodeGameScreenRioPinballMachine.SYMBOL_BONUS_WILD_1 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 3  -- base用挡板1 /
CodeGameScreenRioPinballMachine.SYMBOL_BONUS_WILD_2 = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 4  -- base用挡板2 \
CodeGameScreenRioPinballMachine.SYMBOL_BONUS_WILD_1_2X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 5  -- base用挡板3 /
CodeGameScreenRioPinballMachine.SYMBOL_BONUS_WILD_2_2X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 6  -- base用挡板4 \
CodeGameScreenRioPinballMachine.SYMBOL_WILD_2X = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 9  -- wild2X

CodeGameScreenRioPinballMachine.HIT_BALL_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 1 --base下中弹珠玩法
CodeGameScreenRioPinballMachine.RESUME_MACHINE_EFFECT = GameEffect.EFFECT_SELF_EFFECT - 2 --base下中弹珠玩法

local BALL_MOVE_SPEED = 1040        --小球运动速度
local BG_MOVE_SPEED = 1040        --背景运动速度
local SYMBOL_WIDTH = 180
local SYMBOL_HEIGHT = 130

local ROAD_WIDTH    =       1215        --圆弧路径宽度
local ROAD_HEIGHT   =       962         --发射口到圆弧的高度


local ANGLE_START  =   52  --初始角度
local ANGLE_END    =   -55 --结束角度
local RADIUS        =   735 --旋转半径

local BALL_WIDTH    =   64  --小球宽度

--设置滚动状态
local runStatus = 
{
    DUANG = 1,
    NORUN = 2,
}

-- 构造函数
function CodeGameScreenRioPinballMachine:ctor()
    CodeGameScreenRioPinballMachine.super.ctor(self)

    self.m_isFeatureOverBigWinInFree = true
    self.m_spinRestMusicBG = true

    self.m_isTriggerHitBall = false
    self.m_isReelDown = false
 
    --init
    self:initGame()
end

function CodeGameScreenRioPinballMachine:initGame()

    self.m_configData = gLobalResManager:getCSVLevelConfigData("RioPinballConfig.csv", "LevelRioPinballConfig.lua")
    self.m_configData.m_machine = self

    --初始化基本数据
    self:initMachine(self.m_moduleName)
    --限定 scatter 出现的列
    -- self.m_ScatterShowCol = {2,3,4}
end  


---
-- 获取关卡名字
-- 这个字段和csv中的level_idx对应
function CodeGameScreenRioPinballMachine:getModuleName()
    --TODO 修改对应本关卡moduleName，必须实现
    return "RioPinball"  
end




function CodeGameScreenRioPinballMachine:initUI()

    util_csbScale(self.m_gameBg.m_csbNode, 1)
    
    self:initFreeSpinBar() -- FreeSpinbar

    self.m_rootNode = self:findChild("root")

    self.m_node_machine = self:findChild("node_machine")
    
    -- self.m_node_machine:setScale(0.4)
    -- self.m_node_machine:setPositionY(self.m_node_machine:getPositionY() - 800)

    --特效层
    self.m_effectNode = cc.Node:create()
    self.m_node_machine:addChild(self.m_effectNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + 100)

    self.m_effectNode2 = cc.Node:create()
    self:addChild(self.m_effectNode2, GAME_LAYER_ORDER.LAYER_ORDER_BOTTOM + 1)
    self.m_effectNode2:setScale(self.m_machineRootScale)
   
    --升轮遮黑
    self:findChild("sp_bamboo"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 1000)
    self:findChild("layer_black"):setLocalZOrder(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 1001)

    --压黑层
    self.m_layerColor = cc.LayerColor:create(cc.c4f(0,0,0,math.floor(255 * 0.7)))
    local reelSize = self.m_csbOwner["sp_reel_0"]:getContentSize()
    reelSize.height = reelSize.height + 5
    self.m_layerColor:setContentSize(CCSizeMake(reelSize.width * self.m_iReelColumnNum,reelSize.height))
    self.m_layerColor:setVisible(false)
    self.m_onceClipNode:addChild(self.m_layerColor,SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE + 1000000 - 1)
    local pos = util_convertToNodeSpace(self.m_csbOwner["sp_reel_0"],self.m_onceClipNode)
    pos.y = pos.y - 5
    self.m_layerColor:setPosition(pos)

    --弹簧
    self.m_Spring = util_createAnimation("RioPinball_penzui.csb")
    self:findChild("penzui"):addChild(self.m_Spring) 
    self.m_Spring:setVisible(false)

    --箭头
    local jiantou_1 = util_createAnimation("RioPinball_jiantou.csb")
    local jiantou_2 = util_createAnimation("RioPinball_jiantou.csb")
    
    self:findChild("jiantou1"):addChild(jiantou_1)
    self:findChild("jiantou1_0"):addChild(jiantou_2)

    jiantou_1:runCsbAction("idle",true)
    jiantou_2:runCsbAction("idle",true)

    self.m_jiantouAry = {
        jiantou_1,
        jiantou_2
    }

    --左右两侧挡板,前4个在左边,后4个在右边,顺序由上到下
    self.m_dangBanAry = {}
    for index = 1,8 do
        local item = util_createAnimation("RioPinball_dangban.csb")
        self:findChild("dangban"..(index - 1)):addChild(item)
        self.m_dangBanAry[index] = item
    end

    --过场动画
    self.m_changeSceneAni = util_createAnimation("RioPinball_guochang.csb")
    self.m_rootNode:addChild(self.m_changeSceneAni,100)

    --bonus背景
    self.m_bonusBg = util_spineCreate("RioPinball_Bonus_Bg",true,true)
    util_spinePlay(self.m_bonusBg,"idleframe",true)
    self.m_changeSceneAni:findChild("Bonus_bg"):addChild(self.m_bonusBg)

    --mini轮盘
    self.m_bonusView = util_createView("CodeRioPinballSrc.RioPinballBonusGame",{machine = self})
    self.m_changeSceneAni:findChild("Bonus"):addChild(self.m_bonusView)
    self.m_bonusView:setPosition(cc.p(-display.width / 2,-display.height / 2 + self.m_miniOffsetY))
    self.m_bonusView.m_miniMachine:findChild("Root"):setScale(self.m_miniScale)

    --顶部大鸟
    self.m_bird = util_spineCreate("Socre_RioPinball_idle",true,true)
    self:findChild("node_bird"):addChild(self.m_bird)
    util_spinePlay(self.m_bird,"idleframe",true)
    self.m_bird:setVisible(false)

    --拖尾
    local tail = cc.MotionStreak:create(0.3, 1, 80, cc.c3b(255, 255, 255), "RioPinball_qiutw.png")
    tail:setBlendFunc({ src = GL_ONE, dst = GL_ONE })
    self.m_effectNode:addChild(tail)
    -- tail:setRotation(180)
    self.m_tail = tail
    self.m_tail:setVisible(false)

    self.m_ball = self:createBall()
    self.m_effectNode:addChild(self.m_ball)
    self.m_ball:setVisible(false)

    --赢钱光效
    self.m_light_totalWin = util_createAnimation("RioPinball_totalwin.csb")
    self.m_bottomUI.coinWinNode:addChild(self.m_light_totalWin)
    self.m_light_totalWin:setVisible(false)
    self.m_light_totalWin:setPositionY(-10)

    
    --额外小球说明
    self.m_extraTip = util_createAnimation("RioPinball_Extra.csb")
    self:findChild("Extra"):addChild(self.m_extraTip)
    self.m_extraTip:setVisible(false)

    --base玩法tip
    self.m_baseTips = util_createAnimation("RioPinball_Tips.csb")
    self:findChild("Tips"):addChild(self.m_baseTips)
    self.m_baseTips:runCsbAction("auto",true)

    --base下玩法触发
    self.m_baseTriggerAni = util_createAnimation("RioPinball_Trigger.csb")
    self:findChild("Trigger"):addChild(self.m_baseTriggerAni)
    self.m_baseTriggerAni:setVisible(false)
end

function CodeGameScreenRioPinballMachine:baseTriggerAni(func)
    self.m_baseTriggerAni:setVisible(true)
    self.m_baseTriggerAni:findChild("Particle_1"):resetSystem()
    self.m_baseTriggerAni:runCsbAction("auto",false,function()
        if type(func) == "function" then
            func()
        end
    end)

    self:delayCallBack(65 / 60,function()
        self.m_baseTriggerAni:findChild("Particle_1"):stopSystem()
    end)
end

function CodeGameScreenRioPinballMachine:showColorLayer( )
    self.m_layerColor:setVisible(true)
    self.m_layerColor:setOpacity(0)
    
    self.m_layerColor:runAction(cc.FadeTo:create(0.1,math.floor(255 * 0.7)))
end

function CodeGameScreenRioPinballMachine:hideColorLayer( )
    self.m_layerColor:setVisible(true)
    self.m_layerColor:runAction(cc.FadeTo:create(0.1,0))
    self:delayCallBack(0.1,function()
        self.m_layerColor:setVisible(false)
    end)
end

function CodeGameScreenRioPinballMachine:updateNetWorkData()
    gLobalDebugReelTimeManager:recvStartTime()
    
    local isReSpin = self:updateNetWorkData_ReSpin()
    if isReSpin == true then
        return
    end

    
    local isWaitOpera = self:checkWaitOperaNetWorkData()
    if isWaitOpera == true then
        return
    end
    self.m_isWaitingNetworkData = false

    self:produceSlots()

    local function parseNetData()
        local selfData = self.m_runSpinResultData.p_selfMakeData

        if selfData and selfData.effectRoad then
            self.m_baseTips:setVisible(false)
            self:removeSoundHandler()
            
            --显示顶部大鸟
            self.m_bird:setVisible(true)
            self:showColorLayer()

            self.m_jiantouAry[1]:runCsbAction("actionframe",true)
            self.m_jiantouAry[2]:runCsbAction("actionframe",true)

            --升轮
            self:riseReel(true,function()
                self:dangbanAction(function()
                    
                    --背景聚焦
                    self:bgFocousBallAction(function()
                        self:springRiseAction()
                    end)
                    self:operaNetWorkData()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
                end)
            end)
            
            self:baseTriggerAni()
            
        else
            self.m_configData.p_specialSymbolList = {90,92,96,97,98,99,102}
            self:operaNetWorkData()
        end
    end

    
    if self.m_isReelDown then
        self.m_isReelDown = false
        self:delayCallBack(90 / 60,function()
            parseNetData()
        end)
    else
        parseNetData()
    end

    
    
    
    
end

--[[
    显示bonus轮子
]]
function CodeGameScreenRioPinballMachine:showBaseReel(isShow)
    self.m_node_machine:setVisible(isShow)
end

--[[
    升轮
]]
function CodeGameScreenRioPinballMachine:riseReel(isUp,func)
    
    if isUp then
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_reel_rise.mp3")
        self:runCsbAction("actionframe",false,func)
    else
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_reel_decline.mp3")
        self:runCsbAction("actionframe2",false,func)
    end
end

--[[
    背景移动到小球起始位置
]]
function CodeGameScreenRioPinballMachine:bgFocousBallAction(func)
    self:runCsbAction("jingtou1",false,func)
    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_jingtou1.mp3")

    self.m_node_machine.m_curPos = cc.p(-403,157)
end

--[[
    缩放背景动作
]]
function CodeGameScreenRioPinballMachine:scaleBgAction(func)
    local seq = cc.Sequence:create({
        cc.ScaleTo:create(0.5,0.6),
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end)
    })
    self.m_node_machine:runAction(seq)
end

--[[
    背景回归原点
]]
function CodeGameScreenRioPinballMachine:resumeBgPos(func)
    -- self:runCsbAction("actionframe3",false,func)
    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_jingtou_far.mp3")
    local spawn = cc.Spawn:create({
        cc.EaseSineInOut:create(cc.ScaleTo:create(45 / 60,0.56)),
        cc.EaseSineInOut:create(cc.MoveTo:create(45 / 60,cc.p(0,-121)))
    })

    local seq = cc.Sequence:create({
        spawn,
        cc.CallFunc:create(function()
            if type(func) == "function" then
                func()
            end
        end)
    })
    self.m_node_machine:runAction(seq)
end

--[[
    两侧挡板轮动
]]
function CodeGameScreenRioPinballMachine:dangbanAction(func)
    self:runCsbAction("idleframe4")

    local index = #self.m_dangBanAry
    local function runNext()
        local item = self.m_dangBanAry[index]
        if item then
            item:runCsbAction("actionframe2",false,function()

            end)
        else
            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_showLight.mp3")
            self:runCsbAction("actionframe5",false,function()
                if type(func) == "function" then
                    func() 
                end
            end)
            
            return
        end
        
        index = index - 1
        self:delayCallBack(5 / 60,function()
            runNext()
        end)
    end

    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_dangban_refresh.mp3")
    runNext()
end

--[[
    弹簧升起
]]
function CodeGameScreenRioPinballMachine:springRiseAction(func)
    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_penzui_rise.mp3")
    self.m_Spring:runCsbAction("start",false,func)
    self.m_Spring:setVisible(true)
end

--[[
    小球弹出动作
]]
function CodeGameScreenRioPinballMachine:ballEjectOut(ball,func)
    util_changeNodeParent(self.m_Spring:findChild("Node_qiu"),ball)
    ball:setPosition(cc.p(0,0))
    ball.m_isStopTail = false
    -- ball.m_tail:setVisible(false)
    ball:setRotation(0)
    
    ball:setVisible(true)
    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_show_ball.mp3")
    ball:runCsbAction("start",false,function()
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_penzui_energy_storage.mp3")
        self.m_Spring:runCsbAction("actionframe")
        self:runCsbAction("jingtou2")  
        self:delayCallBack(40 / 60,function()
            local randIndex = math.random(1,2)
            if randIndex == 1 then
                gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_shooting.mp3")
            else
                gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_Launch_a_pinball.mp3")
            end
            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_send_out.mp3")
            local pos = util_convertToNodeSpace(ball,self.m_effectNode)
            util_changeNodeParent(self.m_effectNode,ball)
            ball:setPosition(pos)
            if type(func) == "function" then
                func()
            end
        end) 
    end)
    
end

--[[
    创建一个小球
]]
function CodeGameScreenRioPinballMachine:createBall()
    local ball = util_createAnimation("RioPinball_qiu.csb")
    ball:findChild("Particle_1"):setVisible(false)

    -- local tail = util_createAnimation("RioPinball_qiutw.csb")
    -- ball:addChild(tail)
    -- tail:runCsbAction("actionframe",true)

    -- ball.m_tail = tail
    -- tail:setVisible(false)

    util_schedule(self.m_tail,function()
        if ball and not ball.m_isStopTail then
            self.m_tail:setPosition(util_convertToNodeSpace(ball,self.m_effectNode))
        end
    end,0.001)

    
    return ball
end

--[[
    小球移动动作
]]
function CodeGameScreenRioPinballMachine:ballMoveAction(roadList,func)
    
    
    local ball = self.m_ball
    ball:setVisible(true)
    ball:runCsbAction("idle")
    self:ballEjectOut(ball,function()
        self.m_tail:setVisible(true)
        
        --小球动作
        self:runNextRoad(ball,roadList,1,function()
            
            if type(func) == "function" then
                func()
            end
        end)
    end)
end

--[[
    下一条路线
]]
function CodeGameScreenRioPinballMachine:runNextRoad(ball,roadList,index,func)
    --递归出口
    if index > #roadList then
        if type(func) == "function" then
            func()
        end
        
        return
    end

    -- ball.m_tail:setVisible(true)

    --路径信息
    local roadData = roadList[index].road
    local cornerList = roadList[index].corner
    local lastDirection = roadList[index].lastDirection

    local reels = self.m_runSpinResultData.p_reels

    -- local str_road = json.encode(roadData)
    -- local str_cornerList = json.encode(cornerList)
    -- local str_reels = json.encode(reels)

    -- print("road = "..str_road)
    -- print("corner = "..str_cornerList)
    -- print("reels = "..str_reels)

    --小球
    local startPos = cc.p(ball:getPosition())

    --过弯所需时间
    local timeInCircle = RADIUS * math.pi * 2 / 360 * (ANGLE_START - ANGLE_END) / BALL_MOVE_SPEED

    local routeList = {}

    local startSymbol = self:getFixSymbol(roadData[1][2] + 1,self.m_iReelRowNum - roadData[1][1],SYMBOL_NODE_TAG)
    local startSymbolPos = util_convertToNodeSpace(startSymbol,self.m_effectNode)

    --前一个点的位置
    local prePos = nil

    --从左侧进入
    if roadData[1][2] == 0 then
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_fly_to_bird.mp3")
        local panel_circle = self:findChild("panel_circle")
        panel_circle:setRotation(ANGLE_START)
        --获取圆弧轨道起始
        local circleStartPos = util_convertToNodeSpace(self:findChild("node_circle"),self.m_effectNode)
        ROAD_HEIGHT = circleStartPos.y - startPos.y
        local firstActTime = ROAD_HEIGHT / BALL_MOVE_SPEED
        local firstAct = cc.EaseOut:create(cc.MoveTo:create(firstActTime,cc.p(startPos.x,startPos.y + ROAD_HEIGHT)),1.1)
        routeList = { --路径列表
            {
                startPos = startPos,
                speed = BALL_MOVE_SPEED,
                endPos = cc.p(startPos.x,startPos.y + ROAD_HEIGHT),     --终点位置
                spcialAct = firstAct
            },
            {
                startFunc = function()
                    local panel_circle = self:findChild("panel_circle")
                    --将小球放在执行旋转动作的节点上
                    util_changeNodeParent(self:findChild("node_circle"),ball)
                    ball:setPosition(cc.p(0,0))
                    ball:setRotation(-(140 - ANGLE_START))
                    panel_circle:setRotation(ANGLE_START)
                    panel_circle:runAction(cc.Sequence:create({
                        cc.RotateTo:create(timeInCircle,ANGLE_END),
                        cc.CallFunc:create(function()
                            
                        end)
                    }))
                    util_changeNodeParent(self:findChild("node_tail"),self.m_tail)

                    util_spinePlay(self.m_bird,"actionframe",false)
                    util_spineEndCallFunc(self.m_bird,"actionframe",function (  )
                        util_spinePlay(self.m_bird,"idleframe",true)
                    end)

                end,
                startPos = cc.p(startPos.x,startPos.y + ROAD_HEIGHT),
                endPos = cc.p(startPos.x - ROAD_WIDTH,startPos.y + ROAD_HEIGHT),
                spcialAct = cc.DelayTime:create(timeInCircle),  --特殊动作
                
                endFunc = function()
                    --将小球放回原来节点
                    util_changeNodeParent(self.m_effectNode,self.m_tail)
                    util_changeNodeParent(self.m_effectNode,ball)
                    
                    ball:setPosition(cc.p(startPos.x - ROAD_WIDTH,startPos.y + ROAD_HEIGHT))
                    ball:setRotation(180)
                end
            },
            {

                startPos = cc.p(startPos.x - ROAD_WIDTH,startPos.y + ROAD_HEIGHT),
                speed = BALL_MOVE_SPEED,
                endPos = cc.p(startPos.x - ROAD_WIDTH,startSymbolPos.y),     --终点位置
                endFunc = function()
                    --确定当前挡板
                    local rowIndex = startSymbol.p_rowIndex
                    local item = self.m_dangBanAry[4 - (rowIndex - 1)]
                    item:runCsbAction("actionframe")
                    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_hit_board.mp3")

                    ball:setRotation(90)
                end
            }
        }

        prePos =  cc.p(startPos.x - ROAD_WIDTH,startSymbolPos.y)

    else --从右侧进入
        local firstActTime = (startSymbolPos.y - startPos.y) / BALL_MOVE_SPEED
        local firstAct = cc.EaseOut:create(cc.MoveTo:create(firstActTime,cc.p(startPos.x,startSymbolPos.y)),1.5)
        routeList = { --路径列表
            {
                startPos = startPos,
                speed = BALL_MOVE_SPEED,
                endPos = cc.p(startPos.x,startSymbolPos.y),     --终点位置
                spcialAct = firstAct,
                endFunc = function()
                    --确定当前挡板
                    local rowIndex = startSymbol.p_rowIndex
                    local item = self.m_dangBanAry[8 - (rowIndex - 1)]
                    item:runCsbAction("actionframe")
                    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_hit_board.mp3")
                    ball:setRotation(-90)
                end
            }
        }
        prePos = cc.p(startPos.x,startSymbolPos.y)
    end

    --碰到挡板慢放动作
    local isSlowly = false
    local curCorner = self.SYMBOL_BONUS_WILD_1
    --根据服务器数据插入路径
    for iRoad = 1,#roadData do
        local data = roadData[iRoad]
        local symbolNode = self:getFixSymbol(data[2] + 1,self.m_iReelRowNum - data[1], SYMBOL_NODE_TAG)
        if symbolNode then
            
            local symbolPos = util_convertToNodeSpace(symbolNode,self.m_effectNode)

            local distance = cc.pGetDistance(prePos, symbolPos)
            local delayFuncTime = distance / BALL_MOVE_SPEED
            if symbolNode.p_symbolType <= self.SYMBOL_BONUS_WILD_2_2X and symbolNode.p_symbolType >= self.SYMBOL_BONUS_WILD_1 then
                delayFuncTime = delayFuncTime - 0.06
            end
            
            routeList[#routeList + 1] = {
                startPos = prePos,
                speed = BALL_MOVE_SPEED,
                endPos = symbolPos,
                isSlowly = isSlowly,
                slowlyRate = 0.14,
                delayFuncTime = delayFuncTime,
                delayFunc = function()
                    --变更小球穿过的小块
                    if not (symbolNode.p_symbolType <= self.SYMBOL_BONUS_WILD_2_2X and symbolNode.p_symbolType >= self.SYMBOL_BONUS_WILD_1) then
                        if symbolNode.p_symbolType ~= self.SYMBOL_WILD_2X and (curCorner == self.SYMBOL_BONUS_WILD_1 or curCorner == self.SYMBOL_BONUS_WILD_2) then
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_show_wild.mp3")
                            symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,TAG_SYMBOL_TYPE.SYMBOL_WILD), TAG_SYMBOL_TYPE.SYMBOL_WILD)
                            symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(TAG_SYMBOL_TYPE.SYMBOL_WILD))
                            symbolNode.p_symbolType = TAG_SYMBOL_TYPE.SYMBOL_WILD
                        elseif curCorner == self.SYMBOL_BONUS_WILD_1_2X or curCorner == self.SYMBOL_BONUS_WILD_2_2X then
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_show_wild.mp3")
                            symbolNode:changeCCBByName(self:getSymbolCCBNameByType(self,self.SYMBOL_WILD_2X), self.SYMBOL_WILD_2X)
                            symbolNode:setLocalZOrder(self:getBounsScatterDataZorder(self.SYMBOL_WILD_2X))
                            symbolNode.p_symbolType = self.SYMBOL_WILD_2X
                        end

                        --将信号提升到大信号层
                        symbolNode:changeParentToTopNode(self:getBounsScatterDataZorder(symbolNode.p_symbolType) - symbolNode.p_rowIndex)
                        

                        if data[3] == "DOWN" then 
                            ball:setRotation(180)
                        elseif data[3] == "UP" then
                            ball:setRotation(0)
                        elseif data[3] == "RIGHT" then
                            ball:setRotation(90)
                        else
                            ball:setRotation(-90)
                        end
                        
                        -- 
                        symbolNode:runAnim("start")
                    else 
                        --记录当前拐角
                        curCorner = symbolNode.p_symbolType
                        if curCorner ==  self.SYMBOL_BONUS_WILD_1_2X or curCorner == self.SYMBOL_BONUS_WILD_2_2X  then
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_double.mp3")
                        else
                            -- gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_nice.mp3")
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_hit_board.mp3")
                        end
                        
                        if curCorner == self.SYMBOL_BONUS_WILD_1 or curCorner ==  self.SYMBOL_BONUS_WILD_1_2X then
                            --往右走的小球会转向上,向下走的小球会转向左
                            if data[3] == "DOWN" or data[3] == "RIGHT" then
                                symbolNode:runAnim("actionframe2")
                                if data[3] == "DOWN" then
                                    ball:setRotation(-90)
                                else
                                    ball:setRotation(0)
                                end
                            else
                                --向上走的小球会转向右侧,向左走的小球会转向下
                                if data[3] == "LEFT" then
                                    ball:setRotation(180)
                                else
                                    ball:setRotation(90)
                                end
                                symbolNode:runAnim("actionframe3")
                            end
                        elseif curCorner == self.SYMBOL_BONUS_WILD_2 or curCorner == self.SYMBOL_BONUS_WILD_2_2X then
                            if data[3] == "UP" or data[3] == "RIGHT" then
                                --往上走的小球会转向左,向右走的小球会转向下
                                if data[3] == "UP" then
                                    ball:setRotation(-90)
                                else
                                    ball:setRotation(180)
                                end
                                symbolNode:runAnim("actionframe2")
                            else
                                --往下走的小球会转向右,向左走的小球会转向上
                                if data[3] == "DOWN" then
                                    ball:setRotation(90)
                                else
                                    ball:setRotation(0)
                                end
                                symbolNode:runAnim("actionframe3")
                            end
                        end
                        
                    end
                end
            }

            if symbolNode.p_symbolType <= self.SYMBOL_BONUS_WILD_2_2X and symbolNode.p_symbolType >= self.SYMBOL_BONUS_WILD_1 then
                isSlowly = true
                
            else
                isSlowly = false
            end

            prePos = symbolPos
        end
    end

    local sidePos = cc.p(prePos.x,prePos.y)
    --小球移动到轮盘边缘
    if lastDirection == "LEFT" then
        sidePos.x = sidePos.x - SYMBOL_WIDTH * 0.5 + BALL_WIDTH * 0.5
    elseif lastDirection == "RIGHT" then
        sidePos.x = sidePos.x + SYMBOL_WIDTH * 0.5 - BALL_WIDTH * 0.5
    elseif lastDirection == "UP" then
        sidePos.y = sidePos.y + SYMBOL_HEIGHT * 0.5 - BALL_WIDTH * 0.5
    else
        sidePos.y = sidePos.y - SYMBOL_HEIGHT * 0.5 + BALL_WIDTH * 0.5
    end

    routeList[#routeList + 1] = {
        startPos = prePos,
        speed = BALL_MOVE_SPEED,
        endPos = sidePos,
        endFunc = function()
            ball.m_isStopTail = true
        end
    }

    local endPos = cc.p(sidePos.x,sidePos.y)
    --小球碎裂
    if lastDirection == "LEFT" then
        endPos.x = endPos.x  - BALL_WIDTH
    elseif lastDirection == "RIGHT" then
        endPos.x = endPos.x + BALL_WIDTH
    elseif lastDirection == "UP" then
        endPos.y = endPos.y + BALL_WIDTH
    else
        endPos.y = endPos.y - BALL_WIDTH
    end

    routeList[#routeList + 1] = {
        spcialAct = cc.Spawn:create({
            cc.MoveTo:create(50 / 60,endPos),
            cc.CallFunc:create(function()
                ball:findChild("Particle_1"):setVisible(true)
                ball:findChild("Particle_1"):resetSystem()
                gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_ball_over.mp3")
                ball:runCsbAction("over",false,function()
                    ball:setVisible(false)
    
                    self:delayCallBack(2,function()
                        self.m_tail:setVisible(false)
                        if index < #roadList then
                            self.m_extraTip:setVisible(true)
                            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_extra_ball.mp3")
                            self.m_extraTip:runCsbAction("auto",false,function()
                                self.m_extraTip:setVisible(false)
                            end)
                            self:resumeBgPos(function()
                                self:bgFocousBallAction(function()
                                    local ball = self.m_ball
                                    ball:setVisible(true)
                                    ball:runCsbAction("idle")
                                    self:ballEjectOut(ball,function()
                                        self.m_tail:setVisible(true)
                                        self:runNextRoad(ball,roadList,index + 1,func)
                                    end)
                                    
                                end)
                            end)
                            
                        end
                    end)
                    
                end)
            end)
        }),  --特殊动作
        endFunc = function()
            -- ball.m_tail:setVisible(false)
        end
    }

    util_moveByRouteList(ball,routeList)
    --背景跟随
    self:bgFollowAction(routeList,function() 
        self:resumeBgPos(function()
            if index >= #roadList then --最后一个小球收集完毕
                self:runNextRoad(nil,roadList,index + 1,func)
            end
        end)
        
    end)
end

--[[
    背景跟随小球动作
]]
function CodeGameScreenRioPinballMachine:bgFollowAction(routeList,func)
    local actionList = {}
    for index = 1,#routeList do
        local routeData = routeList[index]
        if routeData.startPos then
            local startPos = routeData.startPos
            local endPos = routeData.endPos
            local distance = cc.pGetDistance(startPos, endPos)

            local curPos = self.m_node_machine.m_curPos

            local targetPos = cc.p(curPos.x - (endPos.x - startPos.x),curPos.y - (endPos.y - startPos.y))
            
            --限定目标点区域范围
            targetPos = self:limitTargetPos(targetPos)
            

            actionList[#actionList + 1] = cc.MoveTo:create(distance / BG_MOVE_SPEED,targetPos)

            self.m_node_machine.m_curPos = targetPos
        end
        
        
    end

    actionList[#actionList + 1] = cc.DelayTime:create(1)
    -- actionList[#actionList + 1] = cc.MoveTo:create(1,cc.p(0,0))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if type(func) == "function" then
            func()
        end
    end)
    local seq = cc.Sequence:create(actionList)
    self.m_node_machine:runAction(seq)
end

--[[
    限制背景移动的范围
]]
function CodeGameScreenRioPinballMachine:limitTargetPos(pos)
    local targetPos = cc.p(pos.x,pos.y)
    --限定目标点区域范围
    if targetPos.x <= -display.width / 5 then
        targetPos.x = -display.width / 5
    elseif targetPos.x >= display.width / 5 then
        targetPos.x = display.width / 5
    end

    if targetPos.y <= -display.height then
        targetPos.y = -display.height
    elseif targetPos.y >= display.height / 2.5 then
        targetPos.y = display.height / 2.5
    end
    return targetPos
end


function CodeGameScreenRioPinballMachine:enterGamePlayMusic(  )
    scheduler.performWithDelayGlobal(function(  )
        
      self:playEnterGameSound( "RioPinballSounds/sound_RioPinball_enter_game.mp3" )

    end,0.4,self:getModuleName())
end

function CodeGameScreenRioPinballMachine:onEnter()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRioPinballMachine.super.onEnter(self)     -- 必须调用不予许删除
    self:addObservers()

    self.m_symbol_scatter = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,4 do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:changeParentToOtherNode(self.m_effectNode)
                self.m_symbol_scatter[#self.m_symbol_scatter + 1] = symbolNode
            end
        end
    end
end

function CodeGameScreenRioPinballMachine:addObservers()
    CodeGameScreenRioPinballMachine.super.addObservers(self)
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
        local winRatio = winCoin / totalBet
        local soundIndex = 1
        local soundTime = 2
        if winRatio > 0 then
            if winRatio <= 1 then
                soundIndex = 1
            elseif winRatio > 1 and winRatio <= 3 then
                soundIndex = 2
            else
                soundIndex = 3
            end

            -- if winRatio >= 2 then
            --     gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_nice_win.mp3")
            -- end
        end

        local soundTime = soundIndex
        if self.m_bottomUI  then
            soundTime = self.m_bottomUI:getCoinsShowTimes( winCoin )
        end

        local soundName = "RioPinballSounds/sound_RioPinball_last_win_".. soundIndex .. ".mp3"
        self.m_winSoundsId , self.m_delayHandleId = globalMachineController:playBgmAndResume(soundName,soundTime,1,1)

        

    end,ViewEventType.NOTIFY_UPDATE_WINCOIN)
end

function CodeGameScreenRioPinballMachine:onExit()
    if gLobalViewManager:isViewPause() then
        return
    end
    CodeGameScreenRioPinballMachine.super.onExit(self)      -- 必须调用不予许删除
    self:removeObservers()
    --恢复速率
    cc.Director:getInstance():getScheduler():setTimeScale(globalData.timeScale)
    scheduler.unschedulesByTargetName(self:getModuleName())
    util_resetChildReferenceCount(self.m_effectNode)
    util_resetChildReferenceCount(self.m_effectNode2)
end


---
-- 返回自定义信号类型对应ccbi，
-- @param symbolType int 信号类型
function CodeGameScreenRioPinballMachine:MachineRule_GetSelfCCBName(symbolType)
    if symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        return "Socre_RioPinball_Scatter"
    end

    if symbolType == self.SYMBOL_WILD_2X then
        return "Socre_RioPinball_Wild_2X"
    end

    if symbolType == self.SYMBOL_BONUS_2 then
        return "Socre_RioPinball_Bonus2"
    end

    if symbolType == self.SYMBOL_BONUS_3 then
        return "Socre_RioPinball_Bonus3"
    end

    if symbolType == self.SYMBOL_BONUS_4 or symbolType == self.SYMBOL_BONUS_EMPTY then
        return "Socre_RioPinball_Bonus4"
    end

    if symbolType == self.SYMBOL_BONUS_WILD_1 then 
        return "Socre_RioPinball_Wild_Gang_1"
    elseif symbolType == self.SYMBOL_BONUS_WILD_1_2X then
        return "Socre_RioPinball_Wild_2X_1"
    end

    if symbolType == self.SYMBOL_BONUS_WILD_2 then 
        return "Socre_RioPinball_Wild_Gang_2"
    elseif symbolType == self.SYMBOL_BONUS_WILD_2_2X then
        return "Socre_RioPinball_Wild_2X_2"
    end
    
    return nil
end

---
--设置bonus scatter 层级
function CodeGameScreenRioPinballMachine:getBounsScatterDataZorder(symbolType )
    -- 避免传递进来的是nil ，但是这种情况基本不会发生
    symbolType = symbolType or TAG_SYMBOL_TYPE.SYMBOL_SCORE_1
    
    local order = 0
    if symbolType ==  TAG_SYMBOL_TYPE.SYMBOL_WILD or symbolType == self.SYMBOL_WILD_2X or 
    symbolType == self.SYMBOL_BONUS_WILD_1 or symbolType == self.SYMBOL_BONUS_WILD_1_2X or 
    symbolType == self.SYMBOL_BONUS_WILD_2 or symbolType == self.SYMBOL_BONUS_WILD_2_2X or symbolType == self.SYMBOL_WILD_2X then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_1 + (self.SYMBOL_WILD_2X - symbolType)
    elseif symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
        order = REEL_SYMBOL_ORDER.REEL_ORDER_2_2 + 100
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

---
-- 预加载symbol资源，父类已经实现了基本Symbol_9 到Symbol_Bonus的创建，如果有特殊信号则自己添加
--
function CodeGameScreenRioPinballMachine:getPreLoadSlotNodes()
    local loadNode = CodeGameScreenRioPinballMachine.super.getPreLoadSlotNodes(self)
    --- loadNode插入需要预加载特殊信号CCB内容，降低运行时卡顿,

    -- loadNode[#loadNode + 1] = { symbolType = self.SYMBOL_SCORE_QUICKHIT,count =  2}


    return loadNode
end


----------------------------- 玩法处理 -----------------------------------

-- 断线重连 
function CodeGameScreenRioPinballMachine:MachineRule_initGame(  )

    
end

--
--单列滚动停止回调
--
function CodeGameScreenRioPinballMachine:slotOneReelDown(reelCol)    
    CodeGameScreenRioPinballMachine.super.slotOneReelDown(self,reelCol) 
end

---
-- 播放freespin轮盘背景动画触发
-- 改变背景动画等
function CodeGameScreenRioPinballMachine:levelFreeSpinEffectChange()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
end

---
--播放freespinover 轮盘背景动画触发
--改变背景动画等
function CodeGameScreenRioPinballMachine:levelFreeSpinOverChangeEffect()
    -- 自定义事件修改背景动画
    -- gLobalNoticManager:postNotification(ViewEventType.FREE_SPIN_CHANGE_MACHINE_BG,"时间线名称")
    
end
---------------------------------------------------------------------------


---------------- Spin逻辑开始时触发
-- 用于延时滚动轮盘等
function CodeGameScreenRioPinballMachine:MachineRule_SpinBtnCall()
    self.m_initFeatureData = nil
    self:setMaxMusicBGVolume( )

    if self.m_winSoundsId then
        gLobalSoundManager:stopAudio(self.m_winSoundsId)
    end

    self.m_configData.p_specialSymbolList = {92,96,97,98,99,102}

    for k,symbol in pairs(self.m_symbol_scatter) do
        symbol:putBackToPreParent()
    end

    if self.m_isTriggerHitBall then
        if self.m_soundHandlerId then
            self:reelsDownDelaySetMusicBGVolume()
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS, {SpinBtn_Type.BtnType_Spin, false})
        self.m_jiantouAry[1]:runCsbAction("idle",true)
        self.m_jiantouAry[2]:runCsbAction("idle",true)
        self.m_isReelDown = true
        --降轮
        self:riseReel(false,function()
            self.m_baseTips:setVisible(true)
            self.m_bird:setVisible(false)

            -- self:callSpinBtn()
        end)
        
        
        self.m_Spring:runCsbAction("over",false,function()
            self.m_Spring:setVisible(false)
        end)

        self.m_isTriggerHitBall = false

        return false
    end

    
    return false -- 用作延时点击spin调用
end


--------------------添加动画
---
-- 添加关卡中触发的玩法
--
function CodeGameScreenRioPinballMachine:addSelfEffect()
    local selfData = self.m_runSpinResultData.p_selfMakeData
    if not selfData then
        return
    end

    if selfData.effectRoad then
        -- 自定义动画创建方式
        local selfEffect = GameEffectData.new()
        selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        selfEffect.p_effectOrder = GameEffect.EFFECT_SELF_EFFECT
        self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        selfEffect.p_selfEffectType = self.HIT_BALL_EFFECT -- 动画类型
        selfEffect.roadList = selfData.effectRoad

        -- -- 自定义动画创建方式
        -- local selfEffect = GameEffectData.new()
        -- selfEffect.p_effectType = GameEffect.EFFECT_SELF_EFFECT
        -- selfEffect.p_effectOrder = GameEffect.EFFECT_EPICWIN + 1
        -- self.m_gameEffects[#self.m_gameEffects + 1] = selfEffect
        -- selfEffect.p_selfEffectType = self.RESUME_MACHINE_EFFECT -- 动画类型

        self.m_isTriggerHitBall = true
    end
        
        

end

---
-- 播放玩法动画
-- 实现自定义动画内容
function CodeGameScreenRioPinballMachine:MachineRule_playSelfEffect(effectData)

    if effectData.p_selfEffectType == self.HIT_BALL_EFFECT then
        self:removeSoundHandler()
        self:ballMoveAction(effectData.roadList,function()
            self:hideColorLayer()
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
    elseif self.RESUME_MACHINE_EFFECT then  -- 恢复背景位置
        --降轮
        self:riseReel(false,function()

            self.m_bird:setVisible(false)
            effectData.p_isPlay = true
            self:playGameEffect()
        end)
        
        self.m_Spring:runCsbAction("over",false,function()
            self.m_Spring:setVisible(false)
        end)
    end

    
    return true
end



---
-- 轮盘滚动数据生成之后
-- 改变滚动数据可以改变轮盘滚动效果 比如滚动长度, 是否触发长滚效果等
function CodeGameScreenRioPinballMachine:MachineRule_ResetReelRunData()
    --self.m_reelRunInfo 中存放轮盘滚动信息
 
end

function CodeGameScreenRioPinballMachine:playEffectNotifyNextSpinCall( )

    CodeGameScreenRioPinballMachine.super.playEffectNotifyNextSpinCall( self )

    self:setMaxMusicBGVolume()
    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)

end

function CodeGameScreenRioPinballMachine:slotReelDown( )



    self:checkTriggerOrInSpecialGame(function(  )
        self:reelsDownDelaySetMusicBGVolume( ) 
    end)


    CodeGameScreenRioPinballMachine.super.slotReelDown(self)
end

function CodeGameScreenRioPinballMachine:updateReelGridNode(node)
    
end

--[[
    延迟回调
]]
function CodeGameScreenRioPinballMachine:delayCallBack(time, func)
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

function CodeGameScreenRioPinballMachine:initFeatureInfo(spinData,featureData)

    if featureData.p_bonus and featureData.p_bonus.status == "OPEN" then
        self:addBonusEffect()
    end
end

function CodeGameScreenRioPinballMachine:addBonusEffect( )
    gLobalNoticManager:postNotification(ViewEventType.SHOW_TOUCH_LAYER,true)
    -- 添加bonus effect
    local bonusGameEffect = GameEffectData.new()
    bonusGameEffect.p_effectType = GameEffect.EFFECT_BONUS
    bonusGameEffect.p_effectOrder = GameEffect.EFFECT_QUEST_DONE + 1
    self.m_gameEffects[#self.m_gameEffects + 1] = bonusGameEffect
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SPIN_BTN_STATUS,{SpinBtn_Type.BtnType_Spin,false})

end

---
-- 显示bonus 触发的小游戏
function CodeGameScreenRioPinballMachine:showEffect_Bonus(effectData)
    self.m_beInSpecialGameTrigger = true

    local bsWinCoins = self.m_runSpinResultData.p_bonusWinCoins
    if self.m_initFeatureData then
        bsWinCoins = self.m_initFeatureData.p_bonus.bsWinCoins
    end
    if bsWinCoins and bsWinCoins > 0 then
        self.m_bottomUI:updateWinCount(util_getFromatMoneyStr(bsWinCoins))
    end

    

    if globalData.slotRunData.currLevelEnter == FROM_QUEST then
        self.m_questView:hideQuestView()
    end

    self:stopAllActionsByTag(self.ACTION_TAG_LINE_FRAME)
    self:clearFrames_Fun()

    -- 取消掉赢钱线的显示
    self:clearWinLineEffect()
    
    -- 停止播放背景音乐
    self:clearCurMusicBg()
    -- 播放震动
    if self.levelDeviceVibrate then
        self:levelDeviceVibrate(6, "bonus")
    end
    self:removeSoundHandler()
    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_journey_of_treasure.mp3")
    self:showScatterTriggerAni(function()
        --开始弹版
        local startView = self:showBonusStartView(function()
            -- 取消掉赢钱线的显示
            self:clearWinLineEffect()
            self:setMaxMusicBGVolume()
            self:resetMusicBg(true,"RioPinballSounds/music_RioPinball_bonus.mp3")
    
            --清空赢钱
            -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_STOP_WINCOIN)

            self:showBonusGameView(effectData)
            
        end)

        --切换场景
        self:changeScene("bonus",function()
            startView.m_allowClick = true
        end)
        self:delayCallBack(85 / 60,function()
            startView:findChild("Particle_1"):resetSystem()
            startView:findChild("Particle_2"):resetSystem()
            startView:showStart()
            
            startView.m_btnTouchSound = "RioPinballSounds/sound_RioPinball_click.mp3"
            gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_show_fs_start.mp3")
        end)
    end)
    

    gLobalSendDataManager:getLogSlots():sendPopupLog(LOG_ENUM_TYPE.Popup_Trigger_Bonus, self.m_iOnceSpinLastWin)

    return true
end

--[[
    scatter触发动画
]]
function CodeGameScreenRioPinballMachine:showScatterTriggerAni(func)
    self:clearCurMusicBg()

    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_Scatter_trigger.mp3")
    local nodes = {}
    local showScatterCol = {}
    for iCol = 1,self.m_iReelColumnNum do
        for iRow = 1,4 do
            local symbolNode = self:getFixSymbol(iCol, iRow, SYMBOL_NODE_TAG)
            if symbolNode and symbolNode.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                symbolNode:changeParentToOtherNode(self.m_effectNode)
                symbolNode:runAnim("actionframe")
                local index = self:getPosReelIdx(symbolNode.p_rowIndex, symbolNode.p_cloumnIndex)
                nodes[tostring(index)] = symbolNode

                showScatterCol[iCol] = true
            end
        end
    end

    for colIndex,v in pairs(showScatterCol) do
        local ani = util_createAnimation("RioPinball_Scatter_win.csb")
        self.m_effectNode:addChild(ani,1)
        ani:setPosition(util_convertToNodeSpace(self:findChild("sp_reel_"..(colIndex - 1)),self.m_effectNode))
        ani:runCsbAction("actionframe",false,function()
            ani:removeFromParent()
        end)
    end
    
    self:delayCallBack(70 / 30,function()
        local slotsParents = self.m_slotParents
        for key,symbol in pairs(nodes) do
            symbol:putBackToPreParent()
        end
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    过场动画
]]
function CodeGameScreenRioPinballMachine:changeScene(sceneType,func)
    if sceneType == "base" then
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_change_scent_fg_to_bg.mp3")
        self:showBaseReel(true)
        self.m_gameBg:setVisible(true)
        self.m_changeSceneAni:runCsbAction("bonus_base",false,function()
            util_changeNodeParent(self.m_rootNode,self.m_node_machine,50)
            self.m_node_machine:setPosition(cc.p(0,0))
            self.m_changeSceneAni:setVisible(false)
            if type(func) == "function" then
                func()
            end
        end)
    else
        gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_change_scent_bg_to_fg.mp3")
        util_changeNodeParent(self.m_changeSceneAni:findChild("Base"),self.m_node_machine)
        self.m_node_machine:setPosition(cc.p(0,0))
        self.m_changeSceneAni:setVisible(true)
        self.m_changeSceneAni:runCsbAction("base_bonus",false,function()
            self:showBaseReel(false)
            self.m_gameBg:setVisible(false)
            if type(func) == "function" then
                func()
            end
        end)

        self:delayCallBack(50 / 60,function()
            util_spinePlay(self.m_bonusBg,"guochang",false)
            util_spineEndCallFunc(self.m_bonusBg,"guochang",function (  )
                util_spinePlay(self.m_bonusBg,"idleframe",true)
            end)
        end)
    end
end

---
-- 根据Bonus Game 每关做的处理
--
function CodeGameScreenRioPinballMachine:showBonusGameView(effectData)
    local endFunc = function()
        effectData.p_isPlay = true
        self:playGameEffect() -- 播放下一轮
        self.m_runSpinResultData.p_features = {0}
        self:resetMusicBg()
        self:setMinMusicBGVolume()
    end
    
    local bonusExtraData = self.m_runSpinResultData.p_bonusExtra
    if self.m_initFeatureData then
        bonusExtraData = self.m_initFeatureData.p_bonus.extra
    end

    local bsWinCoins = self.m_runSpinResultData.p_bonusWinCoins
    if self.m_initFeatureData then
        bsWinCoins = self.m_initFeatureData.p_bonus.bsWinCoins
    end

    --设置数据
    self.m_bonusView:setBonusData(bonusExtraData)
    self.m_bonusView:uploadCoins(bsWinCoins)
    self.m_bonusView.m_miniMachine:resetView()
    
    self.m_bonusView:showView(endFunc)
end

function CodeGameScreenRioPinballMachine:showBonusStartView(func)
    local rootNode = self.m_bonusView.m_miniMachine:findChild("Root")
    local spine = util_spineCreate("Socre_RioPinball_tanban",true,true)
    local view = self:showDialog("BonusgameStart", nil, function()
        util_spineRemoveBindNode(spine,spine.m_label)
        if type(func) == "function" then
            func()
        end
    end,nil,nil,false,rootNode)
    view:stopAllActions()
    view:runCsbAction("idle2")
    view.m_allowClick = false
    view:setPosition(cc.p(-display.width / 2,-display.height / 2))

    
    view:findChild("Node_niao"):addChild(spine)
    util_spinePlay(spine,"idleframe",true)

    --将数字挂在spine上
    local node = view:findChild("RioPinball_zi1_7")
    node:removeFromParentAndCleanup(false)
    util_spinePushBindNode(spine,"SZ",node)
    spine.m_label = node
    node:setPosition(cc.p(0,0))

    return view

end

function CodeGameScreenRioPinballMachine:showBonusOverView(coins,func)
    --检测大赢
    self:checkFeatureOverTriggerBigWin(coins, GameEffect.EFFECT_BONUS)

    local spine = util_spineCreate("Socre_RioPinball_tanban",true,true)

    local ownerlist = {}
    ownerlist["m_lb_coins"] = util_formatCoins(coins, 30)
    local rootNode = self.m_bonusView.m_miniMachine:findChild("Root")
    local view = self:showDialog("BonusgameOver", ownerlist, function()
        util_spineRemoveBindNode(spine,spine.m_label)
        self.m_effectNode2:removeAllChildren()
        self:changeScene("base",function()
            self.m_bonusView.m_miniMachine:hideAllSymbol()
            self.m_bonusView.m_miniMachine:resetView()
            self.m_bottomUI:notifyTopWinCoin()
            if type(func) == "function" then
                func()
            end
        end)
    end,false,nil,false,rootNode)

    local node = view:findChild("m_lb_coins")
    view:updateLabelSize({label=node,sx=1,sy=1},400)

    view:setPosition(cc.p(-display.width / 2,-display.height / 2))

    
    view:findChild("Node_niao"):addChild(spine)
    util_spinePlay(spine,"idleframe",true)

    --将数字挂在spine上
    node:removeFromParentAndCleanup(false)
    util_spinePushBindNode(spine,"SZ",node)
    spine.m_label = node
    node:setPosition(cc.p(0,0))

    view.m_btnTouchSound = "RioPinballSounds/sound_RioPinball_click.mp3"

    return view
end

--ccbName ccbi名称 可用预定义好的\也可自定义,
--自定义规则 例如ccbName=FreeSpinOver, 关卡为Chinoiserie. 对应ccbi为Chinoiserie_FreeSpinOver.ccbi
--ownerlist 属性集合  func 回调  auto是否使用自动时间线
function CodeGameScreenRioPinballMachine:showDialog(ccbName,ownerlist,func,isAuto,index,isView,rootNode)
    local view=util_createView("Levels.BaseDialog")
    
    view:initViewData(self,ccbName,func,isAuto,index,self.m_baseDialogViewFps)
    view:updateOwnerVar(ownerlist)
    view.m_btnTouchSound = 'MagicianSounds/sound_Magician_btn_click.mp3'

    if globalData.slotRunData.machineData.p_portraitFlag then
        view.getRotateBackScaleFlag = function(  ) return false end
    end

    if isView then
        gLobalViewManager:showUI(view)
    else
        if rootNode then
            rootNode:addChild(view,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        else
            self.m_rootNode:addChild(view,SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER)
        end
    end
    

    return view
end



function CodeGameScreenRioPinballMachine:totalWinAnim()
    -- self.m_light_totalWin:setVisible(true)
    -- self.m_light_totalWin:runCsbAction("actionframe",false,function()
        
    -- end)
    -- self.m_light_totalWin:findChild("Particle_1"):resetSystem()
    self:playCoinWinEffectUI()
end

function CodeGameScreenRioPinballMachine:hideTotalWinLight()
    self.m_light_totalWin:setVisible(false)
end

--设置bonus scatter 信息
function CodeGameScreenRioPinballMachine:setBonusScatterInfo(symbolType, column , specialSymbolNum, bRunLong)
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
    local iRow = 4

    local selfData = self.m_runSpinResultData.p_selfMakeData

         
    for row = 1, iRow do
        --base下触发玩法时不触发快滚
        if selfData and selfData.effectRoad and self:getSymbolTypeForNetData(column,row,runLen) == symbolType then
        
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
        
    end

    if bRun == true and nextReelLong == true and bRunLong == false and self:checkIsInLongRun(column + 1, symbolType) == true then
        bRunLong = true
        --下列长滚
        reelRunData:setNextReelLongRun(true)
    end
    return  allSpecicalSymbolNum, bRunLong
end

function CodeGameScreenRioPinballMachine:scaleMainLayer()
    local uiW, uiH = self.m_topUI:getUISize()
    local uiBW, uiBH = self.m_bottomUI:getUISize()

    local mainHeight = display.height - uiH - uiBH
    local mainPosY = (uiBH - uiH - 30) / 2 + 13

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
    

    mainScale = (display.height - uiH - uiBH) / (DESIGN_SIZE.height - uiH - uiBH)
    self.m_miniScale = 1
    self.m_miniOffsetY = 0

    local ratio = display.height / display.width
    local winSize = cc.Director:getInstance():getWinSize()
    if ratio >= 768 / 1024 then
        mainScale = 0.7
        self.m_miniScale = 1.17
        mainPosY = mainPosY - 20
        self.m_miniOffsetY = 28
    elseif ratio < 768 / 1024 and ratio >= 640 / 960 then
        mainScale = 0.78
        self.m_miniScale = 1.21
        self.m_miniOffsetY = 10
    elseif ratio < 640 / 960 and ratio >= 768 / 1230 then
        mainScale = 0.83
        self.m_miniScale = 1.2
        mainPosY = mainPosY - 20
        self.m_miniOffsetY = 8
    elseif ratio < 768 / 1230 and ratio >= 768 / 1370 then
        mainScale = 0.93
        mainPosY = mainPosY - 15
        self.m_miniScale = 1.06
    else
        mainScale = 0.93
        mainPosY = mainPosY + 15
        self.m_miniScale = 1
    end
    util_csbScale(self.m_machineNode, mainScale)
    self.m_machineRootScale = mainScale
    self.m_machineNode:setPositionY(mainPosY)
end

--[[
    @desc: 初始化 触发scatter时 scatter落地buling音效
    time:2018-12-19 22:18:57
    --@jsonData:
    @return:
]]
function CodeGameScreenRioPinballMachine:setScatterDownScound()
    for i = 1, 5 do
        self.m_scatterBulingSoundArry[#self.m_scatterBulingSoundArry + 1] = "RioPinballSounds/sound_RioPinball_Scatter_down.mp3"
    end
end

---
-- 逐条线显示 线框和 Node 的actionframe
--
function CodeGameScreenRioPinballMachine:showLineFrameByIndex(winLines, frameIndex)
    local lineValue = winLines[frameIndex]
    if lineValue == nil then
        printInfo("xcyy : %s", "")
    end
    local frameNum = lineValue.iLineSymbolNum

    -- 根据frame 数量进行清理
    local inLineFrames = {}
    local checkIndex = 0
    while true do
        local preNode = nil
        checkIndex = checkIndex + 1

        if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
            preNode = self.m_slotFrameLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
        else
            preNode = self.m_slotEffectLayer:getChildByTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + checkIndex)
        end

        if preNode ~= nil then
            if checkIndex <= frameNum then
                inLineFrames[#inLineFrames + 1] = preNode
            else
                preNode:removeFromParent()
                self:pushFrameToPool(preNode)
            end
        else
            break
        end
    end

    local hasCount = #inLineFrames
    local runTimes = nil
    if hasCount >= 1 then
        runTimes = inLineFrames[1]:getCurAnimRunTimes()
    end

    for i = 1, frameNum do
        local symPosData = lineValue.vecValidMatrixSymPos[i]

        local columnData = self.m_reelColDatas[symPosData.iY]

        local posX = columnData.p_slotColumnPosX + self.m_SlotNodeW * 0.5
        local posY = columnData.p_showGridH * symPosData.iX - columnData.p_showGridH * 0.5 + columnData.p_slotColumnPosY
        -- local posY = columnData.p_showGridH / columnData.p_resultLen * symPosData.iX - columnData.p_showGridH / columnData.p_resultLen * 0.5 + columnData.p_slotColumnPosY

        local node = nil
        if i <= hasCount then
            node = inLineFrames[#inLineFrames]
            inLineFrames[#inLineFrames] = nil
        else
            node = self:getFrameWithPool(lineValue, symPosData)
        end
        node:setPosition(cc.p(posX, posY))

        if node:getParent() == nil then
            if self.m_LineEffectType == GameEffect.EFFECT_SHOW_FRAME then
                self.m_slotFrameLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME)
            else
                self.m_slotEffectLayer:addChild(node, 1, SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
            end

            -- if runTimes ~= nil then
            --     node:runDefaultFrameTime(runTimes)
            -- else
            --     node:runDefaultAnim()
            -- end
            node:runAnim("actionframe", true)
        else
            node:runAnim("actionframe", true)
            node:setTag(SLOT_LAYER_ZOEDER_FLAG.SLOT_EFFECT_LAYER + i)
        end
    end
    if self.m_eachLineSlotNode ~= nil then
        local vecSlotNodes = self.m_eachLineSlotNode[frameIndex]
        if vecSlotNodes ~= nil and #vecSlotNodes > 0 then
            for i = 1, #vecSlotNodes, 1 do
                local slotsNode = vecSlotNodes[i]
                if slotsNode ~= nil then
                    slotsNode:runLineAnim()
                    slotsNode:setLocalZOrder(slotsNode.p_showOrder + SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 100)
                end
            end
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenRioPinballMachine:playInLineNodesIdle()
    if self.m_lineSlotNodes == nil then
        return
    end

    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:runIdleAnim()
            slotsNode:setLocalZOrder(slotsNode.p_showOrder)
        end
    end
end

---
-- 播放在线上的SlotsNode 动画
--
function CodeGameScreenRioPinballMachine:playInLineNodes()
    if self.m_lineSlotNodes == nil then
        return
    end

    local animTime = 0
    for i = 1, #self.m_lineSlotNodes do
        local slotsNode = self.m_lineSlotNodes[i]
        if slotsNode ~= nil then
            slotsNode:setLocalZOrder(slotsNode.p_showOrder + SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 100)
            slotsNode:runLineAnim()
            if self.m_bGetSymbolTime == true then
                animTime = util_max(animTime, slotsNode:getAniamDurationByName(slotsNode:getLineAnimName()))
            end
        end
    end
    if self.m_bGetSymbolTime == true then
        self.m_changeLineFrameTime = animTime
    end
end

function CodeGameScreenRioPinballMachine:createReelEffect(col)
    local reelEffectNode, effectAct = util_csbCreate(self.m_reelEffectName .. ".csb")
    -- util_csbPlayForKey(effectAct,"run",true)

    reelEffectNode:retain()
    effectAct:retain()

    self.m_clipParent:addChild(reelEffectNode,SLOT_LAYER_ZOEDER_FLAG.SLOT_FRAME - 1002)
    self.m_reelRunAnima[col] = {reelEffectNode, effectAct}

    reelEffectNode:setVisible(false)

    return reelEffectNode, effectAct
end

---
--添加金边
function CodeGameScreenRioPinballMachine:creatReelRunAnimation(col)
    printInfo("xcyy : col %d", col)
    if self.m_reelRunAnima == nil then
        self.m_reelRunAnima = {}
    end

    local reelEffectNode = nil
    local reelAct = nil
    if self.m_reelRunAnima[col] == nil then
        reelEffectNode, reelAct = self:createReelEffect(col)
    else
        local reelObj = self.m_reelRunAnima[col]

        reelEffectNode = reelObj[1]
        reelAct = reelObj[2]
    end

    local reelNode = self:findChild("sp_reel_" .. (col - 1))
    reelEffectNode:setPosition(util_convertToNodeSpace(reelNode,self.m_clipParent))

    -- self:setLongAnimaInfo(reelEffectNode, col)

    --release_print("BaseMachine: creatReelRunAnimation reelEffectNode setVisible 2620")

    reelEffectNode:setVisible(true)
    util_csbPlayForKey(reelAct, "run", true)

    if self.m_reelBgEffectName ~= nil then -- 快滚背景特效
        local reelEffectNodeBG = nil
        local reelActBG = nil
        if self.m_reelRunAnimaBG == nil then
            self.m_reelRunAnimaBG = {}
        end
        if self.m_reelRunAnimaBG[col] == nil then
            reelEffectNodeBG, reelActBG = self:createReelEffectBG(col)
        else
            local reelBGObj = self.m_reelRunAnimaBG[col]

            reelEffectNodeBG = reelBGObj[1]
            reelActBG = reelBGObj[2]
        end

        reelEffectNodeBG:setScaleX(1)
        reelEffectNodeBG:setScaleY(1)

        -- if self.m_bProduceSlots_InFreeSpin == true then
        -- else
        -- end

        reelEffectNodeBG:setVisible(true)
        util_csbPlayForKey(reelActBG, "run", true)
    end

    gLobalSoundManager:stopAudio(self.m_reelRunSoundTag)
    self.m_reelRunSoundTag = gLobalSoundManager:playSound(self.m_reelRunSound)
end

--增加提示节点
function CodeGameScreenRioPinballMachine:addReelDownTipNode(nodes)
    local tipSlotNoes = {}
    for i = 1, #nodes do
        local slotNode = nodes[i]
        local columnData = self.m_reelColDatas[slotNode.p_cloumnIndex]

        if slotNode.m_isLastSymbol == true and slotNode.p_rowIndex <= columnData.p_showGridCount then

            --播放关卡中设置的小块效果
            self:playCustomSpecialSymbolDownAct(slotNode)
            
            if self:checkSymbolTypePlayTipAnima( slotNode.p_symbolType )then
                
                if slotNode.p_rowIndex <= 4 then
                    tipSlotNoes[#tipSlotNoes + 1] = slotNode
                end
            --                            break
            end
        --                        end
        end
    end -- end for i=1,#nodes
    return tipSlotNoes
end

return CodeGameScreenRioPinballMachine






