--[[
    弹珠
]]

local ZenPinball = class("ZenPinball" , util_require("base.BaseView") )
local Config     = require("CodeWallballSrc.ZenPinballConfig")

function ZenPinball:initUI( tData )

    self.m_machine = tData.machine
    --
    self:initBaseUI()
    --
    self:initBaseData()
    --
    self:initDingData()
    --
    self:initDingRender()
    -- 
    self:initSpecialRender( "BaseGame" )
end

-- 初始化基础数据 --
function ZenPinball:initBaseData(  )
    self.debugDraw      = Config.Debug
    self.lBallList      = {}
    self.nBallIndex     = 1
    self.nTopPosOff     = Config.TopPositionOffset                  -- 小球顶部掉落位置偏移量 --
    self.nBottomPos     = cc.p( self.bottomNode:getPosition() ).y - Config.BottomOffset   -- 当小球滚动出现意外 以这个数值来判断滚动完成 --
    self.lSpecialList   = {}  -- 用二维索引来存储特殊信号块 --

    self.nDingOrder     = Config.DingZOder
    self.nBallOrder     = Config.BallZOder
    self.nSymbolOrder   = Config.SymbolZOder

    self.m_vecCrashBalls = {}
    self.m_mutipleBalls = {}
end

function ZenPinball:onEnter()
    -- 开启定时器
    self:onUpdate( function(dt)
            self:tickZenPinBall(dt)
        end)
    

    if  self.debugDraw == true then
        performWithDelay(self,function(  )
            self:initDebugUI()
        end , 2 )
    end
    
end

function ZenPinball:onExit()
    -- 关闭定时器
    self:unscheduleUpdate()
end

-- 设置钉子数据列表 --
function ZenPinball:initDingData(  )
    -- 基本盘面位置数据  需要配置 --
    
    self.nBaseList  = Config.BaseList
    self.nMaxRow    = #self.nBaseList
    self.nMinCol    = Config.MinCol
    self.nMaxCol    = Config.MaxCol
    self.nInterval  = Config.Interval

    local baseNodePos   = cc.p( self.baseNode:getPosition()   )
    local bottomNodePos = cc.p( self.bottomNode:getPosition() )

    -- 特殊信号资源 --
    self.lSpecialRes        = Config.SpecialRes
    -- Base模式下特殊信号块位置索引 --
    self.lNormalSpecialList = Config.NormalSpecialList
    -- 特殊玩法模式下特殊信号块位置索引 --
    self.lFeatureSpecialList= Config.FeatureSpecialList
                    
    
    self.lDingList = {} 
    -- 先添加15行基础网格钉子 --
    for index , colNum in ipairs( self.nBaseList ) do
        self.lDingList[index] = {}
        local startPos  = cc.p(0,0)
        startPos.y      = baseNodePos.y + ( self.nMaxRow - index ) * self.nInterval / 2
        
        -- 针对不同列数 初始化不同的起始位置 --
        if colNum == self.nMinCol then
            startPos.x  = baseNodePos.x - ( ( colNum / 2 ) * self.nInterval - self.nInterval / 2 )
        elseif colNum == self.nMaxCol then
            startPos.x  = baseNodePos.x - ( ( colNum - 1 ) / 2 * self.nInterval  )
        end

        for i = 1 , colNum do
            local ding = {}
            -- 盘面上具体位置
            ding.pPos   = cc.p( startPos.x + (i -1 ) * self.nInterval ,  startPos.y )
            -- 行列的具体索引
            ding.pIndex = cc.p( index , i )
            -- 显示实体缩放值
            ding.nScale = Config.DingScale 
            -- 像素级物理半径
            ding.nRadius= Config.DingRadius
            -- 在盘面是否可用
            ding.customEnabled = true
            table.insert( self.lDingList[index], ding )
        end
    end

    -- 添加底线监测钉子 --
    local startPos  = cc.p(0,0)
    startPos.y      = bottomNodePos.y
    startPos.x      = bottomNodePos.x - ( ( self.nMaxCol - 1 ) / 2 * self.nInterval  )

    local xOffset   = { -10 , -15 , -15 , -25 , 0 , 25 , 15 , 15 ,10 }

    self.lDingList[self.nMaxRow+1] = {}
    for i = 1 , self.nMaxCol do
        local ding = {}
        -- 盘面上具体位置
        ding.pPos   = cc.p( startPos.x + (i -1 ) * self.nInterval + xOffset[i] ,  startPos.y )
        -- 行列的具体索引
        ding.pIndex = cc.p( index , i )
        -- 显示实体缩放值
        ding.nScale = 1 
        -- 像素级物理半径
        ding.nRadius= 8
        -- 在盘面是否可用
        ding.customEnabled = true

        -- 是否为最底部 --
        ding.bIsBottom  = true

        table.insert( self.lDingList[self.nMaxRow+1], ding )
    end
end

-- 设置钉子显示 --
function ZenPinball:initDingRender(  )
    
    self.dingOriPic         = Config.DingOriPic         -- 原始图片
    self.dingHighLihgtPic   = Config.DingHighLihgtPic   -- 高亮显示
    self.dingDisablePic     = Config.DingDisablePic     -- 禁用图片
    self.dingRouterPic      = Config.DingRouterPic      -- 必经图片
    self.dingFSOriPic       = Config.DingFreeSpinPic    -- FreeSpin下的钉子图标

    for i,dingList in ipairs(self.lDingList) do
        for j,ding in ipairs(dingList) do
            -- 添加显示属性 --
            ding.oriPic    = self.dingOriPic
            ding.renderObj = ccui.ImageView:create( ding.oriPic, 1) 
            ding.renderObj:setAnchorPoint( cc.p(0.5,0.5) )
            ding.renderObj:setPosition( ding.pPos )
            ding.renderObj:setScale( ding.nScale )
            ding.flash = function(  )
                    -- 切换闪烁图片 --
                    ding.renderObj:loadTexture( self.dingHighLihgtPic, 1 )
                    performWithDelay( ding.renderObj , function( )
                        -- 切回原图 --
                        ding.renderObj:loadTexture( ding.oriPic, 1 )
                    end,0.1)
                end
            ding.setCustomColor = function(  )
                -- 切换闪烁图片 --
                ding.renderObj:loadTexture( self.dingHighLihgtPic, 1 )
            end

            -- 如果是最底部的钉子 暂时先不绘制 --
            if ding.bIsBottom == true then
                ding.renderObj:setVisible( false )
            end
            self.baseHolder:addChild(ding.renderObj , self.nDingOrder )
            

            if self.debugDraw == true then
                -- 为调试添加触摸事件 --
                ding.renderObj:addTouchEventListener(function(sender, state)
                    -- Touch ended --
                    if state == 2 then
                            if ding.customEnabled == true then
                                ding.customEnabled = false
                                ding.renderObj:loadTexture( self.dingDisablePic, 1 )
                            else
                                ding.customEnabled = true
                                ding.renderObj:loadTexture( ding.oriPic, 1 )
                            end
                            print("HolyShit btn.. "..i.." "..j.." Enabled "..tostring(ding.customEnabled))
                            print("x.. "..ding.pPos.x.." y"..ding.pPos.y)
                        end
                end)
                ding.renderObj:setTouchEnabled(true)
            end
        end
    end
end

-- 根据游戏状态 切换钉子的显示 --
function ZenPinball:changeDingRender(  )

    self.changeIndex   = 1

    if self.changeHandler ~= nil then
        self.changeHandler:stop()
    end

    self.changeHandler = schedule( self , function (  )
        
        local dingList = self.lDingList[self.changeIndex]
        for i,ding in ipairs(dingList) do
        
            if self.curGameTpye == "BaseGame" then
                ding.oriPic    = self.dingOriPic
            elseif self.curGameTpye == "FeatureGame" then
                ding.oriPic    = self.dingFSOriPic[self.changeIndex]
            end
            ding.renderObj:loadTexture( ding.oriPic, 1 )
        end


        self.changeIndex = self.changeIndex + 1
        if self.changeIndex > #self.lDingList then
            self.changeIndex   = 1
            self.changeHandler:stop()
            self.changeHandler = nil
        end
    end , 0.02 )
end

-- 设置特殊信号块显示 --
function ZenPinball:initSpecialRender( sGameType )
    if self.curGameTpye == sGameType then
        return
    else
        -- step 1 :初始化特殊图标并设置状态 --
        for k,vList in pairs(self.lSpecialList) do
            for l,v in pairs(vList) do
                v:removeFromParent()
            end
        end

        self.lSpecialList = {}
        self.curGameTpye = sGameType 
        local specialList = nil
        if self.curGameTpye == "BaseGame" then
            specialList = self.lNormalSpecialList
        elseif self.curGameTpye == "FeatureGame" then
            specialList = self.lFeatureSpecialList 
        end

        for i,v in ipairs( specialList ) do
            for j,u in ipairs(v) do
                local pIndex = u.Index
                local ding   = self.lDingList[pIndex.x][pIndex.y]
                local pPos   = ding.pPos

                -- 创建特殊信号块csb --
                local specialBall = util_createView("CodeWallballSrc.WallballGridBall", self.lSpecialRes[i])
                self.baseHolder:addChild( specialBall , self.nSymbolOrder )
                specialBall:setPosition( pPos )
                --记录加倍小球
                if i == 3 then
                    specialBall.isMultis = true
                else
                    specialBall.isMultis = false
                end
                -- 存储到列表 --
                self.lSpecialList[pIndex.x] = self.lSpecialList[pIndex.x] or {}
                self.lSpecialList[pIndex.x][pIndex.y] = specialBall
            end
        end

        -- step 2 : 设置背景钉子状态 --
        self:changeDingRender()

    end
end

-- 初始化基础UI --
function ZenPinball:initBaseUI(  )

    
    self:createCsbNode( Config.BaseCsbRes )
    -- 接下来的所有节点都将加到parentNode上 --
    self.renderNode = self.m_csbNode
    -- 网格节点 之后所有附加节点都放到这上面 --
    self.baseHolder= self:findChild( "wallball_wg" )
    -- 基础节点 所有钉子的位置都以这个节点为基础 --
    self.baseNode   = self:findChild( "baseNode"    )
    -- 底部节点 小球运动底线 --
    self.bottomNode = self:findChild( "bottomNode"  )
end

-- 初始化调试面板 --
function ZenPinball:initDebugUI(  )
    local pParent = ccui.Layout:create()
    pParent:setTouchEnabled(false)
    pParent:setSwallowTouches( false )
    pParent:setAnchorPoint(cc.p(0, 0))
    pParent:setContentSize(cc.size(display.width, display.height/4))
    pParent:setPosition(cc.p(0, 0))
    pParent:setClippingEnabled(false)
    pParent:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
    pParent:setBackGroundColor(cc.c4b(255, 255, 0 ));
    pParent:setBackGroundColorOpacity( 128 )

    display.getRunningScene():addChild(pParent)

    -- A button ，quit 3d scene --
    local resetBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    resetBtn:setTitleText("Ball")
    resetBtn:setPosition(  display.cx-200 ,  50 )

    resetBtn:addClickEventListener(function(sender)

        if self.curGameTpye == "BaseGame" then
            self:createBall( self.curGameTpye , 1 )
        elseif self.curGameTpye == "FeatureGame" then

            local ballList = {

                -- { sType = 4 , nReel = 2 },   -- 单球指定

                -- { sType = 1 , nReel = nil }  -- 单球不指定


                -- wildstack test --
                -- { sType = 4 , nReel = 2 },       -- 以下都是双球
                -- { sType = 4 , nReel = 4 }

                -- MultiplyWin
                -- { sType = 3 , nReel = nil },        -- MultiplyWin 都不指定也可以随机位置
                -- { sType = 3 , nReel = nil }

                -- 不同俩个球 --
                { sType = 4 , nReel = 2 },       --wildstack 指定
                { sType = 1 , nReel = nil },     --3🌟不指定
                

                -- 不同两个球
                -- { sType = 3 , nReel = 1 },       --MultiplyWin 指定
                -- { sType = 4 , nReel = 5 }        --wildstack   指定

                -- 不同两个球
                -- { sType = 1 , nReel = nil },        --3🌟不指定
                -- { sType = 2 , nReel = nil }         --2🌟不指定

            }

            self:createBalls( self.curGameTpye , ballList , nil , 1 )
        end
    end)
    pParent:addChild(resetBtn)

    -- A button ，quit 3d scene --
    resetBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    resetBtn:setTitleText("BaseGame")
    resetBtn:setPosition(  display.cx-100 ,  50 )
    resetBtn:addClickEventListener(function(sender)
        self:initSpecialRender( "BaseGame" )
    end)
    pParent:addChild(resetBtn)

    -- A button ，quit 3d scene --
    resetBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    resetBtn:setTitleText("FeatureGame")
    resetBtn:setPosition(  display.cx ,  50 )
    resetBtn:addClickEventListener(function(sender)
        self:initSpecialRender( "FeatureGame" )
    end)
    pParent:addChild(resetBtn)

    local lSpecialName = {"3Star","2Star","Multiwins","Wildstack","Grand","Minor","Major","2Spin"}
    for i=1,8 do
        local pBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
        pBtn:setTitleText( lSpecialName[i])
        pBtn:setPosition( (i-5)*100 + 50 + display.cx ,  10 )
        pBtn:addClickEventListener(function(sender)

            self:createBall( self.curGameTpye , i )
        end)
        pParent:addChild(pBtn)
    end

    -- 触发表现的概率 --
    local midLable = cc.Label:createWithSystemFont(""..Config.ExtraRouter.MidJump, "", 24)
    midLable:setAnchorPoint( cc.p(0.5,0.5) )
    midLable:setPosition( cc.p( 275+ display.cx , 50 ) )
    pParent:addChild( midLable )

    local leftLable = cc.Label:createWithSystemFont(""..Config.ExtraRouter.LeftUpJump, "", 24)
    leftLable:setAnchorPoint( cc.p(0.5,0.5) )
    leftLable:setPosition( cc.p( 275+ display.cx , 80 ) )
    pParent:addChild( leftLable )

    local rightLable = cc.Label:createWithSystemFont(""..Config.ExtraRouter.RightUpJump, "", 24)
    rightLable:setAnchorPoint( cc.p(0.5,0.5) )
    rightLable:setPosition( cc.p( 275+ display.cx , 110 ) )
    pParent:addChild( rightLable )


    local minSubBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    minSubBtn:setTitleText("MinSub")
    minSubBtn:setPosition(  200+ display.cx ,  50 )
    minSubBtn:addClickEventListener(function(sender)
        Config.ExtraRouter.MidJump = math.max( Config.ExtraRouter.MidJump - 1 , 1 )
        midLable:setString( ""..Config.ExtraRouter.MidJump )
    end)
    pParent:addChild(minSubBtn)

    local minAddBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    minAddBtn:setTitleText("MinAdd")
    minAddBtn:setPosition(  350+ display.cx ,  50 )
    minAddBtn:addClickEventListener(function(sender)
        Config.ExtraRouter.MidJump = math.min( Config.ExtraRouter.MidJump + 1 , 100 )
        midLable:setString( ""..Config.ExtraRouter.MidJump )
        -- check left num --
        if Config.ExtraRouter.MidJump > Config.ExtraRouter.LeftUpJump then
            Config.ExtraRouter.LeftUpJump = Config.ExtraRouter.MidJump
            leftLable:setString( ""..Config.ExtraRouter.LeftUpJump)
        end
        -- chedk right num --
        if Config.ExtraRouter.LeftUpJump > Config.ExtraRouter.RightUpJump then
            Config.ExtraRouter.RightUpJump = Config.ExtraRouter.LeftUpJump
            rightLable:setString(""..Config.ExtraRouter.RightUpJump)
        end 
    end)
    pParent:addChild(minAddBtn)

    local leftSubBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    leftSubBtn:setTitleText("LeftSub")
    leftSubBtn:setPosition(  200+ display.cx ,  80 )
    leftSubBtn:addClickEventListener(function(sender)
        Config.ExtraRouter.LeftUpJump = math.max( Config.ExtraRouter.LeftUpJump - 1, 1)
        leftLable:setString(""..Config.ExtraRouter.LeftUpJump )
        -- check mid num --
        if Config.ExtraRouter.LeftUpJump < Config.ExtraRouter.MidJump then
            Config.ExtraRouter.MidJump = Config.ExtraRouter.LeftUpJump
            midLable:setString(""..Config.ExtraRouter.MidJump)
        end
    end)
    pParent:addChild(leftSubBtn)

    local leftAddBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    leftAddBtn:setTitleText("LeftAdd")
    leftAddBtn:setPosition(  350+ display.cx ,  80 )
    leftAddBtn:addClickEventListener(function(sender)
        Config.ExtraRouter.LeftUpJump = math.min( Config.ExtraRouter.LeftUpJump + 1 , 100 )
        leftLable:setString( ""..Config.ExtraRouter.LeftUpJump )
        -- check right num --
        if Config.ExtraRouter.LeftUpJump > Config.ExtraRouter.RightUpJump then
            Config.ExtraRouter.RightUpJump = Config.ExtraRouter.LeftUpJump
            rightLable:setString( ""..Config.ExtraRouter.RightUpJump )
        end
    end)
    pParent:addChild(leftAddBtn)

    local rightSubBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    rightSubBtn:setTitleText("RightSub")
    rightSubBtn:setPosition(  200+ display.cx ,  110 )
    rightSubBtn:addClickEventListener(function(sender)
        Config.ExtraRouter.RightUpJump = math.max( Config.ExtraRouter.RightUpJump - 1 , 1 )
        rightLable:setString( ""..Config.ExtraRouter.RightUpJump )
        -- check left num --
        if Config.ExtraRouter.RightUpJump < Config.ExtraRouter.LeftUpJump then
            Config.ExtraRouter.LeftUpJump = Config.ExtraRouter.RightUpJump
            leftLable:setString(""..Config.ExtraRouter.LeftUpJump )
        end
        -- check min num --
        if Config.ExtraRouter.LeftUpJump < Config.ExtraRouter.MidJump then
            Config.ExtraRouter.MidJump = Config.ExtraRouter.LeftUpJump
            midLable:setString(""..Config.ExtraRouter.MidJump)
        end
    end)
    pParent:addChild(rightSubBtn)

    local rightAddBtn = ccui.Button:create("Default/btn.png", "Default/btn2.png")
    rightAddBtn:setTitleText("RightAdd")
    rightAddBtn:setPosition(  350+ display.cx ,  110 )
    rightAddBtn:addClickEventListener(function(sender)
        Config.ExtraRouter.RightUpJump = math.min( Config.ExtraRouter.RightUpJump + 1 , 100 )
        rightLable:setString(""..Config.ExtraRouter.RightUpJump)
    end)
    pParent:addChild(rightAddBtn)

end


-- 创建2个球 nGameType:Base or Feature   pBallAttList:中奖列表  func:落地回调  fInterval:掉落时间间隔
function ZenPinball:createBalls( nGameType , pBallList , func , fInterval )

    -- 要求1: 同类型的图标 不能落在同一个router 不能落在同一个最终轴(理论上会指定具体数值)--
    -- 要求2: 不同的图标 不能落在同一个最终轴

    -- step:1 是一个球还是两个球 --
    if table.nums(pBallList) == 1 then
        local tmpType = pBallList[1].sType
        local tmpReel = pBallList[1].nReel
        self:createBall( nGameType , tmpType , func , tmpReel )
        return
    end

    local specialList = nil
    if nGameType == "BaseGame" then
        specialList = self.lNormalSpecialList
    elseif nGameType == "FeatureGame" then
        specialList = self.lFeatureSpecialList
    end


    -- 最终球属性列表 --
    local ballAttList = {}

    -- step:2 指定两个相同type的球 必须指定两个不同的reel --
    if pBallList[1].sType == pBallList[2].sType then

        local tmpType   = pBallList[1].sType
        local tmpReel1  = pBallList[1].nReel
        local tmpReel2  = pBallList[2].nReel

        local specialNode = specialList[tmpType]
        if specialNode == nil then
            assert( false , "指定两个同样Type的球 但没有此模式的特殊信号块:"..tmpType )
            return
        end 

        local specialNum  = table.nums( specialNode )
        if specialNum ~= 2 then
            assert( false , "此信号块出现次数不为2 不符合现在需求: "..tmpType )
        end

        if tmpReel1 ~= nil then
            -- 完美状态 必须都指定 WildStack --
            local specialData1 = specialNode[1]
            local specialData2 = specialNode[2]
            if specialData1.Reel[tmpReel1] ~= nil and specialData2.Reel[tmpReel2] ~= nil then
                local pBall1Att = {sType = tmpType , pRouter = 1 , nReel = tmpReel1 , nIndex = 1 }
                table.insert( ballAttList, pBall1Att )
                local pBall2Att = {sType = tmpType , pRouter = 2 , nReel = tmpReel2 , nIndex = 2 }
                table.insert( ballAttList, pBall2Att )
            elseif specialData1.Reel[tmpReel2] ~= nil and specialData2.Reel[tmpReel1] ~= nil then
                local pBall1Att = {sType = tmpType , pRouter = 2 , nReel = tmpReel1 , nIndex = 1 }
                table.insert( ballAttList, pBall1Att )
                local pBall2Att = {sType = tmpType , pRouter = 1 , nReel = tmpReel2 , nIndex = 2 }
                table.insert( ballAttList, pBall2Att )
            else
                -- 其余状态都不满足需求 --
                assert( false , "两个同样状态的球 理应掉入两个指定的Reel 但不符合现在需求: " )
            end
        else
            -- 都不指定 MultiplyWin --
            -- 随机第一个球 --
            local nRandIndex    = math.random(1,2)
            local specialData   = specialNode[nRandIndex]
            local reelList      = specialData.Reel
            local pRouter1      = nRandIndex
            local startIndex    = 1
            for i = 1 , 5 do
                if reelList[i] ~= nil then
                    startIndex  = i
                    break 
                end
            end
            local nRandReel     = math.random( startIndex , startIndex + table.nums(reelList) - 1 )
            if reelList[nRandReel] ~= nil then
                tmpReel1 = nRandReel
            else
                assert(false , "没有在Reel表中随机到数据 "..nRandReel )
            end
            local pBall1Att = {sType = tmpType , pRouter = pRouter1 , nReel = tmpReel1 , nIndex = 1 }
            table.insert( ballAttList , pBall1Att )

            -- 随机第二个球 --
            if nRandIndex   == 1 then
                nRandIndex  = 2
            else
                nRandIndex  = 1
            end
            specialData     = specialNode[nRandIndex]
            reelList        = specialData.Reel
            local pRouter2  = nRandIndex
            startIndex      = 1
            for i = 1 , 5 do
                if reelList[i] ~= nil then
                    startIndex  = i
                    break
                end
            end
            while tmpReel2 == nil do
                local nRandReel = math.random( startIndex , startIndex + table.nums(reelList) - 1 )
                if reelList[nRandReel] ~= nil and nRandReel ~= tmpReel1 then
                    tmpReel2 = nRandReel
                end
            end
            local pBall2Att = {sType = tmpType , pRouter = pRouter2 , nReel = tmpReel2 , nIndex = 2 }
            table.insert( ballAttList , pBall2Att )
        end        
    else
        -- 指定两个不同Type的球 --
        local tmpType1  = pBallList[1].sType
        local tmpType2  = pBallList[2].sType
        local tmpReel1  = pBallList[1].nReel
        local tmpReel2  = pBallList[2].nReel

        --
        if tmpReel1 ~= nil and tmpReel2 ~= nil then

            if tmpReel1 == tmpReel2 then
                assert( false , "两个不同的球 但是指定了掉落同一个Reel 必然不允许")
            end

            -- 都被指定了reel  理论上就是各自处理各自的了 --
            local pBall1Att = {sType = tmpType1 , pRouter = nil , nReel = tmpReel1 , nIndex = 1 }
            table.insert( ballAttList , pBall1Att )
            local pBall2Att = {sType = tmpType2 , pRouter = nil , nReel = tmpReel2 , nIndex = 2 }
            table.insert( ballAttList , pBall2Att )
        
        elseif tmpReel1 ~= nil and tmpReel2 == nil then
            -- 只有第一个被指定reel --
            local pBall1Att = {sType = tmpType1 , pRouter = nil , nReel = tmpReel1 , nIndex = 1 }
            table.insert( ballAttList , pBall1Att )
            -- 第二个球不能随机到Reel1的轴 --
            local specialNode = specialList[tmpType2]
            if specialNode == nil then
                assert( false , "指定两个不同type的球 第二个球没有此Type:"..tmpType2 )
                return
            end 
            local specialNum  = table.nums( specialNode )
            local pRouter2    = nil
            while tmpReel2 == nil do
                local nRandIndex    = math.random( 1 , specialNum )
                local reelList      = specialNode[nRandIndex].Reel

                local startIndex    = 1
                for i = 1 , 5 do
                    if reelList[i] ~= nil then
                        startIndex = i
                        break
                    end
                end

                local nRandReel     = math.random( startIndex , startIndex + table.nums(reelList) - 1 )
                if  reelList[nRandReel] ~= nil and nRandReel ~= tmpReel1 then
                    tmpReel2 = nRandReel
                    pRouter2 = nRandIndex
                end
            end
            local pBall2Att = {sType = tmpType2 , pRouter = pRouter2 , nReel = tmpReel2 , nIndex = 2 }
            table.insert( ballAttList , pBall2Att)

        elseif tmpReel1 == nil and tmpReel2 ~= nil then
            -- 只有第二个被指定reel --
            local pBall2Att = {sType = tmpType2 , pRouter = nil , nReel = tmpReel2 , nIndex = 2 }
            table.insert( ballAttList , pBall2Att )
            -- 第一个球不能随机到Reel2的轴 --
            local specialNode = specialList[tmpType1]
            if specialNode == nil then
                assert( false , "指定两个不同type的球 第一个球没有此Type:"..tmpType1 )
                return
            end 
            local specialNum = table.nums( specialNode )
            local pRouter1   = nil
            while tmpReel1  == nil do
                local nRandIndex    = math.random(1 , specialNum )
                local reelList      = specialNode[nRandIndex].Reel

                local startIndex    = 1
                for i = 1 , 5 do
                    if reelList[i] ~= nil then
                        startIndex = i
                        break
                    end
                end

                local nRandReel     = math.random( startIndex ,startIndex + table.nums(reelList) - 1 )
                if reelList[nRandReel] ~= nil and nRandReel ~= tmpReel2 then
                    tmpReel1 = nRandReel
                    pRouter1 = nRandIndex
                end
            end
            local pBall1Att = {sType = tmpType1 , pRouter = pRouter1 , nReel = tmpReel1 , nIndex = 1 }
            table.insert( ballAttList , pBall1Att )

        elseif tmpReel1 == nil and tmpReel2 == nil then
            -- 都没有被指定reel --

            -- 随机第一个球的路点和Reel --
            local specialNode = specialList[tmpType1]
            local specialNum  = table.nums( specialNode )
            local pRouter1    = nil
            while tmpReel1 == nil do
                local nRandIndex    = math.random(1 , specialNum )
                local reelList      = specialNode[nRandIndex].Reel
                local startIndex    = 1
                for i = 1, 5 do
                    if reelList[i] ~= nil then
                        startIndex  = i
                        break
                    end
                end
                local nRandReel     = math.random( startIndex , startIndex + table.nums(reelList) - 1 )
                if reelList[nRandReel] ~= nil then
                    tmpReel1 = nRandReel
                    pRouter1 = nRandIndex
                end
            end
            local pBall1Att = {sType = tmpType1 , pRouter = pRouter1 , nReel = tmpReel1 , nIndex = 1 }
            table.insert( ballAttList , pBall1Att )

            -- 指定第二个球的路点和Reel --
            specialNode = specialList[tmpType2]
            specialNum  = table.nums( specialNode )
            local pRouter2 = nil
            while tmpReel2 == nil do
                local nRandIndex    = math.random(1 , specialNum )
                local reelList      = specialNode[nRandIndex].Reel
                local startIndex    = 1
                for i = 1 ,5 do
                    if reelList[i] ~= nil then
                        startIndex = i
                        break
                    end
                end
                local nRandReel     = math.random( startIndex , startIndex + table.nums(reelList) - 1 )
                if nRandReel ~= tmpReel1 and reelList[nRandReel] ~= nil then
                    tmpReel2 = nRandReel
                    pRouter2 = nRandIndex
                end
            end
            local pBall2Att = {sType = tmpType2 , pRouter = pRouter2 , nReel = tmpReel2 , nIndex = 2 }
            table.insert( ballAttList , pBall2Att )
        end

    end

    -- step 3:终于分析完了 开始创建小球 HolyShit --
    -- 先放第一个 --
    local ballAtt = ballAttList[1]
    self:createBall( nGameType , ballAtt.sType , func , ballAtt.nReel , ballAtt.pRouter ,ballAtt.nIndex )
    -- 在一定时间后释放第二个 --
    performWithDelay( self,function()
        local ballAtt = ballAttList[2]
        self:createBall( nGameType , ballAtt.sType , func , ballAtt.nReel , ballAtt.pRouter , ballAtt.nIndex )
    end , fInterval )

end

-- 创建一个球 nGameType:Base or Feature   nSpecialType:中奖类型  func:落地回调  nReel:指定落轴  pRouterIndex:指定类型索引 pRollIndex:原始数据第几个
function ZenPinball:createBall( nGameType , nSpecialType, func, nReel , pRouterIndex , nRollIndex )

    --!! 重要说明：此关卡玩法 有球出现的时候 必经过一个特殊图标 不会空跳 ！！--

    -- step 1 : 根据游戏类型设置特殊列表
    self:setSpecialDingList( nGameType , false )
    local specialList = nil
    if nGameType == "BaseGame" then
        specialList = self.lNormalSpecialList
    elseif nGameType == "FeatureGame" then
        specialList = self.lFeatureSpecialList
    end

    -- step 2 : 根据类型获取具体图标列表 并指定一个节点设置为路点
    local specialNode = specialList[nSpecialType]
    if specialNode == nil then
        self:setSpecialDingList( nGameType , true )
        assert( false , "xcyy----------------->此模式无:"..nSpecialType )
        return
    end

    local pRouter     = nil     -- 途径点 --
    local pStart      = nil     -- 起始点 --
    local pEnd        = nil     -- 终止点 --
    -- 如果指定了具体掉落哪个轴 --
    if nReel ~= nil then

        -- 如果指定了索引 --
        local nIndex  = pRouterIndex
        -- 否则 --
        if nIndex == nil then
            local nodeIndexList = {}
            for i,v in ipairs(specialNode) do
                if v.Reel[nReel] ~= nil then
                    table.insert( nodeIndexList,i )
                end
            end
            local nRandIndex = math.random(1,#nodeIndexList )
            nIndex  = nodeIndexList[nRandIndex]
        end

        local node          = specialNode[nIndex]
        pRouter             = node.Index
        local nStartIndex   = math.random(1,#node.Start)
        pStart              = node.Start[nStartIndex]
        local nEndIndex     = math.random(1,#(node.Reel[nReel]) )
        pEnd                = node.Reel[nReel][nEndIndex]
    
    else
        local node          = specialNode[math.random(1,#specialNode)]
        pRouter             = node.Index
        local nStartIndex   = math.random(1,#node.Start)
        pStart              = node.Start[nStartIndex]
        local nEndIndex     = math.random(1,#node.End)
        pEnd                = node.End[nEndIndex]
    end

    -- step 3 : 寻路起点-路点
    local ding = self.lDingList[pRouter.x][pRouter.y]
    -- 设置router及关联钉子可用 --
    self:setDingRefAtt( pRouter , true )
    -- ding.customEnabled = true
    local path = {}
    local tmpPath = self:genSearchPath( pStart , pRouter )
    if tmpPath == nil then
        assert( false , "xcyy---------------> 中间路点寻路失败 Start: "..pStart.x.." "..pStart.y.." Router: "..pRouter.x.." "..pRouter.y )
    end
    for i,v in ipairs(tmpPath) do
        table.insert( path , v )
    end

    -- 注：此处pRouter 会在寻路列表中添加2次，可以去重下 --
    table.remove( path, table.nums(path) )

    -- step 4 : 寻路路点-终点
    tmpPath = self:genSearchPath( pRouter , pEnd )
    if tmpPath == nil then
        assert( false , "xcyy---------------> 路点-终点寻路失败 Router: "..pRouter.x.." "..pRouter.y.." End: "..pEnd.x.." "..pEnd.y )
    end
    for i,v in ipairs(tmpPath) do
        table.insert( path , v )
    end

    -- 随机插入一些点 --
    path = self:insertExtraRouter( path , pRouter )


    -- step 5: 终于获取路径 可以创建小球开始运动了 HolyShit
    local ball = ccui.ImageView:create( Config.BallRes, 1)
    ball:setAnchorPoint( cc.p(0.5,0.5) )
    ball:setScale( Config.BallScale )
    ball.accY       = Config.AccGravity     --简单模拟重力加速度
    ball.moving     = true
    ball.radius     = Config.BallRadius * Config.BallScale
    self.baseHolder:addChild( ball , self.nBallOrder )
    
    local startIndex   = path[1]
    local startDing    = self.lDingList[startIndex.x][startIndex.y]
    local startPos     = startDing.pPos
    ball:setPosition( cc.p( startPos.x , startPos.y + self.nTopPosOff ) )
    ball.speed      = self:getJumpSpeed(0)
    ball.oriDest    = startIndex
    ball.destList   = path
    ball.destReel   = Config.Reel[pEnd.y]
    ball.rollIndex  = nRollIndex
    ball.router     = pRouter
    ball.targetID   = self.nBallIndex
    ball.endFunc    = func

    -- 为小球添加拖尾粒子 --
    local pParticle = cc.ParticleSystemQuad:create( Config.BallParticle )
    pParticle:setPosition( cc.p( ball.radius ,ball.radius ) )
    ball:addChild( pParticle )

    -- 添加到列表 --
    self.lBallList[self.nBallIndex] = ball
    self.nBallIndex= self.nBallIndex + 1

    -- step 6 : 清理寻路缓存 --
    self:setSpecialDingList( nGameType , true )

    -- 返回Ball targetID，便于外部逻辑
    return ball.targetID
end


-- 指定钉子属性 并指定周边相关钉子属性 --
function ZenPinball:setDingRefAtt( pIndex, bBlock )
    
    local ding   = self.lDingList[pIndex.x][pIndex.y]
    ding.customEnabled = bBlock 

    -- 新加障碍路点 左下右下两点都为不可寻址点 --
    --     B
    --    / \
    --   Bl  Br

    local rowNum    = table.nums( Config.BaseList )
    local colNum    = Config.BaseList[pIndex.x]

    -- 左下角的钉子 --
    local pLeftBm   = cc.p( pIndex.x + 1 , 0 )
    if colNum == Config.MinCol then     -- 8 --
        pLeftBm.y   = pIndex.y
    elseif colNum   == Config.MaxCol then -- 9 --
        pLeftBm.y   = pIndex.y - 1
    end
    if pLeftBm.x < rowNum and pLeftBm.y > 0  then
        local tmpDing = self.lDingList[pLeftBm.x][pLeftBm.y]
        if tmpDing then
            tmpDing.customEnabled = bBlock
        end
    end
    -- 右下角的钉子 --
    local pRightBm  = cc.p( pIndex.x + 1 , 0 )
    if colNum == Config.MinCol then     -- 8 --
        pRightBm.y   = pIndex.y + 1
    elseif colNum   == Config.MaxCol then -- 9 --
        pRightBm.y   = pIndex.y
    end
    local tmpColNum  = Config.BaseList[pRightBm.x]
    if pRightBm.x < rowNum and pRightBm.y <= tmpColNum   then
        local tmpDing = self.lDingList[pRightBm.x][pRightBm.y]
        if tmpDing then
            tmpDing.customEnabled = bBlock
        end
end
end

-- 设置特殊位置钉子属性 --
function ZenPinball:setSpecialDingList( nGameType ,bBlock )
    local specialList = nil
    if nGameType == "BaseGame" then
        specialList = self.lNormalSpecialList
    elseif nGameType == "FeatureGame" then
        specialList = self.lFeatureSpecialList
    end
    for i,v in ipairs( specialList ) do
        for j,u in ipairs(v) do
            self:setDingRefAtt( u.Index , bBlock )
        end
    end
end

-- 生成寻路路点 pStart:起点  pEnd:终点 
function ZenPinball:genSearchPath( pStart , pEnd )

    local startNode = {}
    startNode.iX = pStart.x
    startNode.iY = pStart.y
    startNode.enabled = true
    startNode.preNode = nil

    local endNode = {}
    endNode.iX = pEnd.x
    endNode.iY = pEnd.y
    endNode.enabled = true
    endNode.preNode = nil

    -- 寻路时随机先左还是先右 --
    local bSearchOrder = "LtoR"
    if math.random(1,100) > 50 then
        bSearchOrder = "RtoL"
    end

    --
    local bReached    = false
    -- 记录寻路过程中被访问过的路点
    local lSearchNodes= {}
    -- 寻路函数 --
    local searchPath  = nil
    searchPath = function( pNode )

        if bReached == true then
            return
        end
        
        lSearchNodes[pNode.iX] = lSearchNodes[pNode.iX] or {}
        -- 查找下一行
        local nNextRow = pNode.iX + 1
        if nNextRow > (self.nMaxRow + 1) then
            -- 查到底层了 不必再继续 --
            -- print( "查到底层了 不必再继续 "..pNode.iX.." "..pNode.iY )
            return
        end

        lSearchNodes[nNextRow] = lSearchNodes[nNextRow] or {}

        -- 获取下一行钉子列表 --
        local dingList = self.lDingList[nNextRow]
        local leftIndex = 0
        local rightIndex= 0
        local nIndex    = pNode.iY
        if #dingList == self.nMinCol then
            leftIndex = nIndex - 1
            rightIndex= nIndex
        else
            leftIndex = nIndex
            rightIndex= nIndex + 1
        end

        -- 检测左节点 --
        local leftNode = nil
        if leftIndex >= 1 then
            -- 检测是否到达目的地  行列匹配 --
            if nNextRow == endNode.iX and leftIndex == endNode.iY then
                bReached = true
                endNode.preNode = pNode
                return
            end
            -- 如果此节点已经被检索过 则不做操作 --
            leftNode = lSearchNodes[nNextRow][leftIndex]
            if leftNode == nil then
                -- 1 说明此节点之前没有被检索到 --
                -- 2 即使没有被检索过 也要判断此钉子是否被标记为不可用 --
                local dingNode = dingList[leftIndex]
                if dingNode.customEnabled == true then
                    -- 此钉子可以触碰 --
                    leftNode        = {}
                    leftNode.iX     = nNextRow
                    leftNode.iY     = leftIndex
                    leftNode.preNode= pNode
                    lSearchNodes[nNextRow][leftIndex] = leftNode
                end
            else
                -- 被检索过 就不要处理了 --
                leftNode = nil
            end
        end

        -- 检测右节点 --
        local rightNode = nil
        if rightIndex <= #dingList then
            -- 检测是否到达目的地  行列匹配 --
            if nNextRow == endNode.iX and rightIndex == endNode.iY then
                bReached = true
                endNode.preNode = pNode
                return
            end
            -- 如果此节点已经被检索过 则不做操作 --
            rightNode = lSearchNodes[nNextRow][rightIndex]
            if rightNode == nil then
                -- 1 说明此节点之前没有被检索到 --
                -- 2 即使没有被检索过 也要判断此钉子是否被标记为不可用 --
                local dingNode = dingList[rightIndex]
                if dingNode.customEnabled == true then
                    -- 此钉子可以触碰 --
                    rightNode        = {}
                    rightNode.iX     = nNextRow
                    rightNode.iY     = rightIndex
                    rightNode.preNode= pNode
                    lSearchNodes[nNextRow][rightIndex] = rightNode
                end
            else
                -- 被检索过 就不要处理了 --
                rightNode = nil
            end
        end

        -- 递归递归递归递归递归递归递归 HolyShit --
        if bSearchOrder == "LtoR" then
            if leftNode  ~= nil then
                searchPath( leftNode )
            end
            if rightNode ~= nil then
                searchPath( rightNode)
            end
        else
            if rightNode ~= nil then
                searchPath( rightNode)
            end
            if leftNode  ~= nil then
                searchPath( leftNode )
            end
        end
    end

    -- 执行寻路 --
    searchPath( startNode )

    -- 查找到了路径 --
    if bReached == true then
        local finalPath = {}
        table.insert( finalPath , 1 , cc.p( endNode.iX , endNode.iY ) )
        local ding    = self.lDingList[endNode.iX][endNode.iY]
        ding:setCustomColor( )

        -- 反向查找列表 --
        local tmpNode   = endNode.preNode
        while  tmpNode ~= nil do
            -- if self.debugDraw == true then
            --     local ding    = self.lDingList[tmpNode.iX][tmpNode.iY]
            --     ding:setCustomColor( )
            -- end
            -- 向最终列表中添加数据 --
            table.insert( finalPath , 1 , cc.p( tmpNode.iX , tmpNode.iY ) )
            tmpNode = tmpNode.preNode
        end
        return finalPath
    else
        print( "最终没有找到" )
        return nil 
    end
end

-- 随机插入纯表现路点 --
function ZenPinball:insertExtraRouter( lPath , pRouter )
    if not lPath or  #lPath == 0 then
        assert( false ,"xcyy---------------> 路径本身就有问题 不能插入随机表现" )
        return nil
    end

    -- 根据概率 向已经成功的路径中加入 直跳 左上 右上跳 纯为了表现 --
    local tmpPath = {}
    for i,v in ipairs( lPath ) do
        
        table.insert( tmpPath, v )

        -- 最后一行就不添加了 --
        if i == #lPath  then
            break
        end

        -- 随机数值 触发额外表现 --
        local nRandNum = math.random(0,100)

        -- 如果是路点 也不添加额外的表现 --
        if v.x == pRouter.x and v.y == pRouter.y then
            nRandNum = 1000
        end
        
        if nRandNum < Config.ExtraRouter.MidJump then
            --  添加一个直跳的表现 --
            table.insert( tmpPath , v )
        elseif nRandNum < Config.ExtraRouter.LeftUpJump then
            --  添加一个左上跳的表现 情况是有点复杂 HolyShit --
            local pLeftUp   = cc.p( 0,0)
            pLeftUp.x = v.x - 1
            if pLeftUp.x > 0 then
                local colNum = Config.BaseList[pLeftUp.x]
                
                if colNum == Config.MinCol then     -- 8 --
                    pLeftUp.y = v.y - 1
                elseif colNum == Config.MaxCol then -- 9 --
                    pLeftUp.y = v.y
                end
                if pLeftUp.y > 0 then
                    local ding = self.lDingList[pLeftUp.x][pLeftUp.y]
                    -- 这个钉子存在 并且是可触碰的 --
                    if ding and ding.customEnabled == true then
                        table.insert( tmpPath , pLeftUp )
                        table.insert( tmpPath , v )
                    end
                end
            end
        elseif nRandNum < Config.ExtraRouter.RightUpJump then
            -- 添加一个右上跳的表现 情况也稍有点复杂 HolyShit --
            local pRightUp = cc.p( v.x - 1 , 0 )
            if pRightUp.x > 0 then
                local colNum = Config.BaseList[pRightUp.x]

                if colNum == Config.MinCol then     -- 8 --
                    pRightUp.y = v.y
                elseif colNum == Config.MaxCol then -- 9 --
                    pRightUp.y = v.y + 1
                end

                if pRightUp.y <= colNum then
                    local ding = self.lDingList[pRightUp.x][pRightUp.y]
                    -- 这个钉子存在 并且是可触碰的 --
                    if ding and ding.customEnabled == true then
                        table.insert( tmpPath , pRightUp )
                        table.insert( tmpPath , v )
                    end
                end
            end
        else
            -- do nothing --
        end
    end

    return tmpPath
end

-- 重置小球动画

function ZenPinball:resetBallAnim()
    for i = #self.m_vecCrashBalls, 1, -1 do
        local ball = self.m_vecCrashBalls[i]
        if ball.showIdle then
            ball:showIdle()

            if ball.isMultis then
                self.m_mutipleBalls[#self.m_mutipleBalls + 1] = ball
            end
        end
        table.remove(self.m_vecCrashBalls, i)
    end
end

-- 到达目标  具体的哪个球(pBall)碰到的哪个钉子(pDing)
function ZenPinball:reachTarget( pDing , pBall )

    if pDing.bIsBottom == true then
        -- 抛出触底事件 --
        if pBall.endFunc ~= nil then
            local reelID    = pBall.destReel
            local rollIndex = pBall.rollIndex
            if rollIndex == nil then
                rollIndex = 1
            end
            pBall.endFunc(reelID , rollIndex )
        end
        return
    end


    -- 钉子可以做个闪烁动画 --
    pDing:flash()

    -- 抛出触碰事件 例如此处有挂在特殊图标 可能会有特殊动画等 --
    local pIndex    = pDing.pIndex
    if pBall.router.x == pIndex.x and pBall.router.y == pIndex.y then
        local pSymbol   = self.lSpecialList[pIndex.x][pIndex.y]
        if pSymbol then
            gLobalSoundManager:playSound("WallballSounds/sound_Wallball_crash_big_ball.mp3")
            
            local rollIndex = pBall.rollIndex
            if rollIndex == nil then
                rollIndex = 1
            end
            local ballInfo = self.m_machine.m_runSpinResultData.p_selfMakeData.balls[rollIndex] 
            local mutiples = 4
            if ballInfo then
                mutiples = ballInfo.winMultiple
            end

            pSymbol:crashAnim(mutiples)

            self.m_vecCrashBalls[#self.m_vecCrashBalls + 1] = pSymbol 
        end
    else
        gLobalSoundManager:playSound("WallballSounds/sound_Wallball_crash_small_ball.mp3")
    end
    
end

-- 到达终点  pBall:具体是哪个球到达地点
function ZenPinball:reachTheEnd( pBall )
    -- 移除小球 --
    local tagId = pBall.targetID
    pBall:removeFromParent()
    self.lBallList[tagId] = nil
end


-- Balls tick --
function ZenPinball:tickZenPinBall( dt )
    
    for k,v in pairs(self.lBallList) do
        repeat
            local ball = v
            if ball.moving == false then
                break
            end
        
            local pSpeed = ball.speed
            pSpeed.y =  pSpeed.y + ball.accY * dt
        
            -- 计算下一帧位置 --
            local pPos = cc.p ( ball:getPosition() ) 
            pPos.x = pPos.x + pSpeed.x * dt
            pPos.y = pPos.y + pSpeed.y
        
            -- 判断小球是否触底 --
            if ball.oriDest == nil then
                if pPos.y < self.nBottomPos then
                    -- 理论上应该向外抛事件 告诉球  已到位 --
                    self:reachTheEnd( ball )
                    break
                end
                ball:setPosition( pPos )
                break
            end


            local destIndex = ball.oriDest
            local dest      = self.lDingList[destIndex.x][destIndex.y]
            -- 还是纠正下X方向位置吧 --
            if pSpeed.x > 0 then
                if pPos.x > dest.pPos.x then
                    pPos.x = dest.pPos.x
                end
            elseif pSpeed.x < 0 then
                if pPos.x < dest.pPos.x then
                    pPos.x = dest.pPos.x
                end
            end

            -- 计算与目标距离 --
            local distance  = cc.pGetDistance( pPos , dest.pPos )
            local radiusAdd = ball.radius + dest.nRadius

            -- 如果到达条件  与目标距离小于自身半径+目标半径
            if distance <= radiusAdd then 
        
                -- 碰撞了钉子 --
                self:reachTarget( dest , ball )
                --step 1 移除列表第一个位置 --
                table.remove( ball.destList, 1 )
                --step 2 获取列表第一个索引 --
                local nextIndex = ball.destList[1]
                --step 3 计算接下来的跳跃类型 --
                if nextIndex == nil then
                    -- 如果已经空表了 临时采取上一个位置 --
                    ball.speed      = cc.p( 0 , ball.speed.y )
                    ball.oriDest    = nil
                    ball.needReverse= nil 
                else
                    -- 此情况就复杂了 HolyShit --
                    local curPos  = dest.pPos
                    local nextPos = self.lDingList[nextIndex.x][nextIndex.y].pPos
                    --[[ 此位置对应ball即将的去向  与RollingBall:getJumpSpeed关联
                    2   1   4
                        \  |  /
                        \ | /
                        cur
                        /   \
                        /     \
                    5.6      3.7
                    ]]
                    local speedType = 0
        
                    if nextIndex.x == ball.oriDest.x and nextIndex.y == ball.oriDest.y then
                        -- 目标点没有变化 --
                        speedType = 1
                    else
                        if  nextPos.x < curPos.x and nextPos.y > curPos.y     then
                            -- 上图中 type 2 
                            speedType = 2
                            ball.needReverse = true
                        elseif  nextPos.x > curPos.x and nextPos.y > curPos.y then
                            -- 上图中 type 4
                            speedType = 4
                            ball.needReverse = true
                        elseif  nextPos.x < curPos.x and nextPos.y < curPos.y then
                            if not ball.needReverse then
                                -- 上图中 type 6
                                speedType = 6
                            else
                                -- 上图中 type 5
                                speedType = 5
                            end
                            ball.needReverse = nil
                        elseif  nextPos.x > curPos.x and nextPos.y < curPos.y then
                            if not ball.needReverse then
                                -- 上图中 type 7
                                speedType = 7
                            else
                                -- 上图中 type 3
                                speedType = 3
                            end
                            ball.needReverse = nil
                        end
                    end
        
                    --指定接下来的速度模式 --
                    ball.speed  = self:getJumpSpeed(speedType)
                    ball.oriDest= nextIndex
                end
            else
                ball:setPosition( pPos )
            end
            break
        until true
    end
end

-- 定义各个运动的速度 --
function ZenPinball:getJumpSpeed( nType )
    local jumpSpeed  = Config.JumpSpeed[nType]
    return cc.p(jumpSpeed.x , jumpSpeed.y )
end

--[[
    获取加倍小球
]]
function ZenPinball:getMultisBalls()
    local temp = {}
    if self.m_vecCrashBalls and #self.m_vecCrashBalls then
        for key,ball in pairs(self.m_vecCrashBalls) do
            if ball.isMultis then
                temp[#temp + 1] = ball
            end
        end
    end

    return temp
end

--[[
    清空存储的加倍小球
]]
function ZenPinball:clearMutiBalls()
    self.m_mutipleBalls = {}
end

return ZenPinball