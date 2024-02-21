-- --
-- --大厅关卡循环显示与控制 万圣节主题
-- -- 添加前后景
-- --
-- local HolidayChallengeMapControl = class("HolidayChallengeMapControl")
-- HolidayChallengeMapControl.m_content = nil
-- HolidayChallengeMapControl.m_scroll = nil
-- HolidayChallengeMapControl.m_displayNodeList = nil
-- HolidayChallengeMapControl.m_removeLen = 350
-- HolidayChallengeMapControl.m_addLen = 450
-- HolidayChallengeMapControl.m_nodePool = nil

-- HolidayChallengeMapControl.m_roadWidth = 1661
-- HolidayChallengeMapControl.m_frontWidth= 1625

-- function HolidayChallengeMapControl:ctor()
--     self.m_nodeList = {}
--     self.m_displayNodeList = {}
--     self.m_nodePool = {}
-- end

-- --释放资源
-- function HolidayChallengeMapControl:purge()

-- end

-- function HolidayChallengeMapControl:initData_(node,nodeInfoList)
--     self.m_content = node
--     -- 初始化前后景 节点 --
--     self:initFarAndNearLayer()
--     -- 初始化远景显示 --
--     self.m_contentLen = 0
--     local count = #nodeInfoList
--     local mapCell = util_getRequireFile(QUEST_CODE_PATH.QuestMapCell)
--     for i=1,count do
--         local node = mapCell:create(nodeInfoList[i])
--         self.m_farBg:addChild(node)
--         node:setTag(i)
--         node:setPosition(self.m_contentLen,0)
--         self.m_contentLen = self.m_contentLen + nodeInfoList[i][2]
--         self.m_nodePool[i]=node
--     end

--     -- 当前路的长度 
--     self.m_contentLen = QUEST_RES_PATH.BG_ROAD_LEN

--     -- 初始化路面显示 --
--     self.m_InitRoad = false

--     -- 初始化前景显示 --
--     self.m_InitFront= false
-- end

-- -- 初始化地图远景/近景层 --
-- function HolidayChallengeMapControl:initFarAndNearLayer()
--     local pParent = self.m_content:getParent()
--     assert( pParent , "HolyShit , map controller root is nil" )

--     -- 远景跟节点 --
--     self.m_farBg = cc.Node:create()
--     pParent:addChild( self.m_farBg , 0 )

--     -- 近景根节点 --
--     self.m_nearBg= cc.Node:create()
--     pParent:addChild( self.m_nearBg , 2 )
-- end

-- -- 移动远景/近景图 --
-- function HolidayChallengeMapControl:moveFarAndNearLayer()
--     local vPos      = cc.p( self.m_content:getPosition() )

--     local farBgPos = vPos.x * QUEST_RES_PATH.BG_FAR_RATIO
--     if self.m_farBg then
--         self.m_farBg:setPosition( farBgPos , vPos.y )
--     end

--     local nearBgPos= vPos.x *  QUEST_RES_PATH.BG_NEAR_RATIO
--     if self.m_nearBg then
--         self.m_nearBg:setPosition( nearBgPos, vPos.y )
--     end
-- end

-- -- 初始化路面显示 --
-- function HolidayChallengeMapControl:roadRender()
--     if self.m_InitRoad == true then
--         return
--     end
--     local roadCount = math.ceil( self.m_contentLen / self.m_roadWidth ) 

--     local roadPos   = self.m_content:convertToNodeSpace(cc.p(0,0))
--     for i=1 , roadCount do
--         local roadTex =  util_createSprite( QUEST_RES_PATH.QuestMapRoadPath )
--         self.m_content:addChild( roadTex )
--         roadTex:setAnchorPoint(cc.p(0.0, 0.0))
--         roadTex:setPosition( cc.p( (i-1)*self.m_roadWidth , roadPos.y ) )
--     end
--     self.m_InitRoad = true
-- end
-- -- 初始化近景显示 --
-- function HolidayChallengeMapControl:frontRender()
--     if self.m_InitFront == true then
--         return
--     end

--     local frontWidth = self.m_contentLen *  GD.QUEST_RES_PATH.BG_NEAR_RATIO
--     local frontCount = math.ceil( frontWidth / self.m_frontWidth )

--     local frontPos   = self.m_content:convertToNodeSpace(cc.p(0,0))
--     for i=1 , frontCount do
--         -- local frontTex = util_createSprite( QUEST_RES_PATH.QuestMapFrontPath )
--         -- self.m_nearBg:addChild( frontTex )
--         -- frontTex:setAnchorPoint(cc.p(0.0, 0.0))
--         -- frontTex:setPosition( cc.p( (i-1)*self.m_frontWidth , frontPos.y ) )

--         -- 这里是因为 特效直接在近景上做的，所以只需要直接添加特效csb 就可以了
--         local frontEff =  util_createAnimation(QUEST_RES_PATH.QuestMapFrontEff)
--         self.m_nearBg:addChild( frontEff )
--         frontEff:playAction("idle2",true)
--         frontEff:setPosition( cc.p( (i-1)*self.m_frontWidth , frontPos.y ) )
--     end
--     self.m_InitFront = true
-- end

-- -- 路面及近景显示
-- function HolidayChallengeMapControl:updateRoadAndFrontRender( x )

--     -- 路面计算 --
--     self:roadRender()
--     --
--     self:frontRender()

-- end


-- function HolidayChallengeMapControl:getContentLen()
--     return self.m_contentLen
-- end

-- --初始化节点信息
-- function HolidayChallengeMapControl:initDisplayNode(x)

--     -- 校正远景层位置 --
--     local farBgPos = x * GD.QUEST_RES_PATH.BG_FAR_RATIO

--     self.m_displayNodeList = {}
--     local count = #self.m_nodePool
--     for i=1,count do
--         local node = self.m_nodePool[i]
--         if node and node.isDisPlayContent then
--             if node:isDisPlayContent(farBgPos,self.m_addLen) then
--                 self.m_displayNodeList[#self.m_displayNodeList+1]=node
--                 node:showContent(false)
--             end
--         end
--     end
-- end

-- --刷新地图
-- function HolidayChallengeMapControl:updateMap(x)

--     self:moveFarAndNearLayer( x )
--     -- 路面及近景显示 --
--     self:updateRoadAndFrontRender( x )

--     local count = #self.m_displayNodeList
--     if count<=0 then
--         return
--     end
--     -- 校正远景层位置 --
--     local farBgPos = x * GD.QUEST_RES_PATH.BG_FAR_RATIO
--     --检测需要移除的元素
--     for i=count,1,-1 do
--         local node = self.m_displayNodeList[i]
--         if node and node.isDisPlayContent then
--             if not node:isDisPlayContent(farBgPos,self.m_removeLen) then
--                 table.remove( self.m_displayNodeList,i)
--                 node:hideContent()
--             end
--         end
--     end
--     self:checkAddDisplayNode(farBgPos)
-- end

-- --尝试显示可见区域内的贴图
-- function HolidayChallengeMapControl:checkAddDisplayNode(x)
--     self:checkAddLeftNode(x)
--     self:checkAddRightNode(x)
-- end

-- --向左检测加贴图
-- function HolidayChallengeMapControl:checkAddLeftNode(x)
--     local node = self.m_displayNodeList[1]
--     if not node then
--         return
--     end
--     local index = node:getTag()
--     if index <=1 then
--         return
--     end
--     index = index-1
--     local node = self.m_nodePool[index]
--     if node and node.isDisPlayContent then
--         if node:isDisPlayContent(x,self.m_addLen) then
--             table.insert(self.m_displayNodeList,1,node)
--             node:showContent(true)
--             self:checkAddLeftNode(x)
--         end
--     end
-- end

-- --向右检测加贴图
-- function HolidayChallengeMapControl:checkAddRightNode(x)
--     local count = #self.m_displayNodeList
--     if count<=0 then
--         return
--     end
--     local node = self.m_displayNodeList[count]
--     if not node then
--         return
--     end
--     local index = node:getTag()
--     if index <=1 then
--         return
--     end
--     index = index+1
--     local node = self.m_nodePool[index]
--     if node and node.isDisPlayContent then
--         if node:isDisPlayContent(x,self.m_addLen) then
--             self.m_displayNodeList[#self.m_displayNodeList+1]=node
--             node:showContent(true)
--             self:checkAddRightNode(x)
--         end
--     end
-- end

-- return HolidayChallengeMapControl
