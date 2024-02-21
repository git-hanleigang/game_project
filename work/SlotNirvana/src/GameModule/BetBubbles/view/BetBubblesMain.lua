--[[
    加减bet时弹出的气泡
    
    根据现实的个数自动变化高度
    最多个数限制
    最高高度限制，如果超出，测试版报错提示
    排序规则（gamebet在最上方，其他的从下往上排序，优先级越高越靠近底部）
        gameBet--------A
        集卡-------------F
        公共jackpot------E
        彩虹-------------D
        1v1比赛----------C
        大赢宝箱---------B
]]

local LIMIT_H_MAX = 140 -- 有多个模块时，单个模块的最大高度
local LIMIT_H_MIN = 140 -- 只有一个模块时，单个模块的最小高度

local LineH = 5 -- 模块隔断线的高度

local Edage_Top = 20 -- 背景顶部的边厚度
local Edage_Bottom = 40 -- 背景底部的边厚度

local MOVETIME = 0.5 -- 移动时间

local showTime = 4

local UIStatus = {
    Up = "Up",
    Down = "Down",
    Change = "Change",
}

local BetBubblesMain = class("BetBubblesMain", BaseView)

function BetBubblesMain:initDatas()

    self.m_UIStatus = UIStatus.Down

    -- self:initModuleHeightList()

    self.m_isDeluxe = self:isDeluxe()

    self.m_moduleInfos = {}
    self.m_moduleViews = {}
    self.m_lines = {}
end

function BetBubblesMain:getModuleShowTotalH()
    local height = 0
    -- 计算所有模块的总高度
    if self.m_moduleInfos and #self.m_moduleInfos > 0 then
        for i=1,#self.m_moduleInfos do
            height = height + self.m_moduleInfos[i].moduleShowH
        end
    end
    -- 分割线的高度
    local lineHeight = LineH * (#self.m_moduleInfos - 1)
    height = height + lineHeight
    return height
end

-- 获取展开后的move节点的位置
function BetBubblesMain:getMovePosY()
    local height = self:getModuleShowTotalH()
    local posY = height + Edage_Top
    return posY
end

-- 获取展开后的背景的高度
function BetBubblesMain:getBgHeight()
    local height = self:getModuleShowTotalH()
    height = height + Edage_Top + Edage_Bottom
    return height
end

function BetBubblesMain:getCsbName()
    return "BetBubbles/csd/BetBubblesMain.csb"
end

function BetBubblesMain:initCsbNodes()
    self.m_imageBg = self:findChild("Image_bg")
    self.m_imageBgH = self:findChild("Image_bg_H")

    local BgSize = self.m_imageBg:getContentSize()
    self.m_bgWidth = BgSize.width
    
    self.m_spArrowBg = self:findChild("sp_arrowBg")
    self.m_spArrowBgH = self:findChild("sp_arrowBg_H")

    self.m_spArrow = self:findChild("sp_arrow")
    self.m_spArrowH = self:findChild("sp_arrow_H")
    
    
    self.m_nodeBubbles = self:findChild("node_bubbles")

    self.m_nodeMove = self:findChild("node_move")
    
    -- 默认将节点置为0
    self.m_nodeMoveX = self.m_nodeMove:getPositionX()
end

function BetBubblesMain:initUI()
    BetBubblesMain.super.initUI(self)
    self:initView()
end

function BetBubblesMain:initView()
    self:initBgTexture()
    self:initBubbles()
    self:initBgHeight()
    self:updateArrowStatus()
    self:updateMoveNodePosY()
end

function BetBubblesMain:initBgHeight()
    local bgH = self:getBgHeight()
    self.m_imageBg:setContentSize(cc.size(self.m_bgWidth, bgH))    
    self.m_imageBgH:setContentSize(cc.size(self.m_bgWidth, bgH))    
end

function BetBubblesMain:initBgTexture()
    -- 箭头背景
    self.m_spArrowBg:setVisible(not self.m_isDeluxe)
    self.m_spArrowBgH:setVisible(self.m_isDeluxe)

    -- 箭头
    self.m_spArrow:setVisible(not self.m_isDeluxe)
    self.m_spArrowH:setVisible(self.m_isDeluxe)

    -- 方形背景
    self.m_imageBg:setVisible(not self.m_isDeluxe)
    self.m_imageBgH:setVisible(self.m_isDeluxe)
end

function BetBubblesMain:updateArrowStatus()
    if self.m_UIStatus == UIStatus.Up then
        self:setArrowDirection(false)
    elseif self.m_UIStatus == UIStatus.Down then
        self:setArrowDirection(true)
    end
end

function BetBubblesMain:setArrowDirection(_isUp)
    -- 朝上
    if _isUp then
        self.m_spArrow:setFlippedY(false)
        self.m_spArrowH:setFlippedY(false)
    else
        self.m_spArrow:setFlippedY(true)
        self.m_spArrowH:setFlippedY(true)
    end
end

function BetBubblesMain:updateMoveNodePosY()
    if self.m_UIStatus == UIStatus.Up then
        local posY = self:getMovePosY()
        self.m_nodeMove:setPositionY(posY)
    else
        self.m_nodeMove:setPositionY(0)
    end
end

-- 模块的所占空间高度
function BetBubblesMain:getModuleShowH(_isOnlyOne, _moduleH, _isLimitMax)
    local vHeight = _moduleH
    if _isOnlyOne then
        -- 高度不能低于最小值
        vHeight = math.max(vHeight, LIMIT_H_MIN)
    else
        -- 高度不能高于最大值
        if _isLimitMax then
            vHeight = math.min(vHeight, LIMIT_H_MAX)
        end
    end
    return vHeight
end

function BetBubblesMain:initBubbles()
    self.m_moduleInfos = {}

    local moduleDatas =  G_GetMgr(G_REF.BetBubbles):getShowModuleDatas()
    if moduleDatas and #moduleDatas > 0 then

        local isOnlyOne = #moduleDatas == 1
        local nowPosY = 0

        for i = 1, #moduleDatas do
            local mData = moduleDatas[i]

            -- 先创建view，再从view中获取高度

            -- -- 模块
            -- local mLayout = self:createModuleLayout()
            -- self.m_nodeBubbles:addChild(mLayout)

            -- 模块的真实高度
            local moduleMyH = 0            

            local refDatas = mData:getRefDatas()
            local moduleLua = mData:getModuleLua()
            local moduleName = mData:getModuleName()
            local isLimitMaxH = mData:isLimitMaxH()

            local viewNames = {}
            if moduleLua and moduleLua ~= "" then
                local viewInfo = self:getModuleViewByName(moduleName)
                if not (viewInfo and not tolua.isnull(viewInfo.node)) then
                    -- 自定义模块的UI类
                    local view = self:createModuleView(moduleLua, refDatas)
                    if view then
                        -- mLayout:addChild(view)
                        self.m_nodeBubbles:addChild(view)
                        local viewH = self:getViewH(view)
                        moduleMyH = viewH
                        table.insert(viewNames, moduleName)
                        table.insert(self.m_moduleViews, {name = moduleName, node = view, viewH = viewH})
                    end
                else
                    local view = viewInfo.node
                    view:setVisible(true)
                    local viewH = self:getViewH(view)
                    moduleMyH = viewH
                    table.insert(viewNames, moduleName)
                    viewInfo.viewH = viewH
                end
            else
                -- 气泡 垂直居中
                for j = 1, #refDatas do
                    local refData = refDatas[j]
                    local refName = refData:getRefName()
                    if refData:isSwitchOn() then
                        local viewInfo = self:getModuleViewByName(refName)
                        if not (viewInfo and not tolua.isnull(viewInfo.node)) then
                            local view = self:createBubble(refName)
                            if view then
                                -- mLayout:addChild(view)
                                self.m_nodeBubbles:addChild(view)
                                local viewH = self:getViewH(view)         
                                moduleMyH = moduleMyH + viewH
                                table.insert(viewNames, refName)
                                table.insert(self.m_moduleViews, {name = refName, node = view, viewH = viewH})
                            end
                        else
                            local view = viewInfo.node
                            view:setVisible(true)
                            local viewH = self:getViewH(view)
                            moduleMyH = viewH
                            table.insert(viewNames, refName)
                            viewInfo.viewH = viewH
                        end                        
                    end
                end
            end

            if #viewNames > 0 then
                -- 模块的所占空间高度
                local moduleShowH = self:getModuleShowH(isOnlyOne, moduleMyH, isLimitMaxH)
                table.insert(self.m_moduleInfos, {moduleName = moduleName, viewNames = viewNames, moduleMyH = moduleMyH, moduleShowH = moduleShowH})
                -- -- layout尺寸
                -- local mLayoutW = BetBubblesCfg.BG_W
                -- mLayout:setContentSize(cc.size(mLayoutW, moduleShowH))
                -- -- layout位置
                -- mLayout:setPosition(cc.p(0, nowPosY - moduleShowH/2))
                nowPosY = nowPosY - moduleShowH
                -- 重新排版模块内views
                local refPosY = nowPosY + (moduleShowH/2 + moduleMyH/2)
                for j=1,#viewNames do
                    local viewInfo = self:getModuleViewByName(viewNames[j])
                    if viewInfo and not tolua.isnull(viewInfo.node) then
                        local view = viewInfo.node
                        local viewH = viewInfo.viewH
                        view:setPosition(cc.p(0, refPosY - viewH/2))
                        refPosY = refPosY - viewH
                    end
                end
                -- 分割线
                if i+1 <= #moduleDatas then
                    local line = self:getLine()
                    line:setVisible(true)
                    line:setPosition(cc.p(0, nowPosY - LineH/2))
                    nowPosY = nowPosY - LineH
                end
            end
        end
    end
end

function BetBubblesMain:getModuleViewByName(_name)
    if self.m_moduleViews and #self.m_moduleViews > 0 then
        for i=1,#self.m_moduleViews do
            if self.m_moduleViews[i].name == _name then
                return self.m_moduleViews[i]
            end
        end
    end
    return
end

function BetBubblesMain:hideAllBubbles()
    if self.m_moduleViews and #self.m_moduleViews > 0 then
        for i=1,#self.m_moduleViews do
            self.m_moduleViews[i].node:setVisible(false)
        end
    end
end

function BetBubblesMain:getViewH(_view)
    local viewH = 0
    if not tolua.isnull(_view) and _view.getLabelSize then
        local vSize = _view:getLabelSize()
        viewH = vSize.height
    end
    return viewH
end

function BetBubblesMain:createModuleView(_filePath, _refDatas)
    if util_IsFileExist(_filePath .. ".lua") or util_IsFileExist(_filePath .. ".luac") then
        _filePath = string.gsub(_filePath, "/", ".")        
        return util_createView(_filePath, _refDatas)
    end
    return
end

function BetBubblesMain:createModuleLayout()
    local layout = ccui.Layout:create()
    layout:setTouchEnabled(false)
    layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
    layout:setBackGroundColor( cc.c4b(0, 0, 0 ) )
    layout:setBackGroundColorOpacity( 0 )
    layout:setAnchorPoint(cc.p(0.5, 0.5))
    return layout
end

function BetBubblesMain:createLine()
    local line = util_createAnimation("BetBubbles/csd/Bet_Line.csb")
    local spLine = line:findChild("sp_line")
    if spLine then
        spLine:setVisible(not self.m_isDeluxe)
    end
    local spLineH = line:findChild("sp_line_H")
    if spLineH then
        spLineH:setVisible(self.m_isDeluxe)
    end
    return line
end

function BetBubblesMain:getLine()
    local line = nil
    for i=1,#self.m_lines do
        if not self.m_lines[i]:isVisible() then
            line = self.m_lines[i]
            break
        end
    end
    if line == nil then
        line = self:createLine()
        self.m_nodeBubbles:addChild(line)
        table.insert(self.m_lines, line)
    end
    return line
end

function BetBubblesMain:hideAllLines()
    for i=1,#self.m_lines do
        self.m_lines[i]:setVisible(false)
    end    
end

function BetBubblesMain:createBubble(_refName)
    local view = nil
    local refMgr = G_GetMgr(_refName)
    if refMgr and refMgr.isCanShowBetBubble and refMgr:isCanShowBetBubble() then
        if refMgr.getBetBubbleLuaPath then
            local luaPath = refMgr:getBetBubbleLuaPath()
            if luaPath and luaPath ~= "" then
                view = util_createView(luaPath)
            end
        end
    end
    return view
end

function BetBubblesMain:checkVisible()
    local moduleDatas =  G_GetMgr(G_REF.BetBubbles):getShowModuleDatas()
    if moduleDatas and #moduleDatas > 0 then
        self.m_csbNode:setVisible(true)
    else
        self.m_csbNode:setVisible(false)
    end
end

function BetBubblesMain:refreshBubbles()
    if self.m_UIStatus == UIStatus.Change then
        return
    end
    -- self.m_nodeBubbles:removeAllChildren()
    self:hideAllLines()
    self:hideAllBubbles()
    self:initBubbles()

    self:initBgHeight()
    self:updateMoveNodePosY()    
end

-- 展开动作
function BetBubblesMain:playUp(_over)
    local moveDis = self:getMovePosY()
    -- 目标位置
    local targetPos = cc.p(self.m_nodeMoveX, moveDis)
    -- 动作序列    
    local actionList = {}
    actionList[#actionList+1] = cc.EaseQuarticActionIn:create(cc.MoveTo:create(MOVETIME, targetPos))
    actionList[#actionList+1] = cc.CallFunc:create(function()
        if not tolua.isnull(self) then
            if _over then
                _over()
            end
        end
    end)
    self.m_nodeMove:runAction(cc.Sequence:create(actionList))
end

-- 收起动作
function BetBubblesMain:playDown(_over)
    -- 目标位置
    local targetPos = cc.p(self.m_nodeMoveX, 0)
    -- 动作序列
    local actionList = {}
    actionList[#actionList+1] = cc.EaseQuarticActionOut:create(cc.MoveTo:create(MOVETIME, targetPos))
    actionList[#actionList+1] = cc.CallFunc:create(function()
        if not tolua.isnull(self) then
            if _over then
                _over()
            end
        end
    end)
    self.m_nodeMove:runAction(cc.Sequence:create(actionList))
end

function BetBubblesMain:showBet()
    self:stopAutoClose()
    self:initAutoClose()    
    self:__showBet()
end

function BetBubblesMain:__showBet()
    if self.m_UIStatus == UIStatus.Down then
        -- 状态
        self.m_UIStatus = UIStatus.Change

        self:playUp(function()
            self.m_UIStatus = UIStatus.Up
            -- self:initBgHeight()
            self:updateArrowStatus()
            self:updateMoveNodePosY()
        end)
    end
end

function BetBubblesMain:hideBet()
    if self.m_UIStatus == UIStatus.Up then
        self:stopAutoClose()
        -- 状态
        self.m_UIStatus = UIStatus.Change

        self:setArrowDirection(true)
        self:playDown(function()
            self.m_UIStatus = UIStatus.Down
            -- self:initBgHeight()
            self:updateArrowStatus()
            self:updateMoveNodePosY()
        end)
    end
end

-- 强制收起
function BetBubblesMain:forceHide()
    if self.m_UIStatus == UIStatus.Down then
        return
    end
    self.m_nodeMove:stopAllActions()
    -- 状态
    self.m_UIStatus = UIStatus.Change

    self:setArrowDirection(true)
    self:playDown(function()
        self.m_UIStatus = UIStatus.Down
        -- self:initBgHeight()
        self:updateArrowStatus()
        self:updateMoveNodePosY()
    end) 
end

function BetBubblesMain:initAutoClose()
    self.m_autoCloseTimer = util_performWithDelay(self, function()
        if not tolua.isnull(self) then
            self:hideBet()
        end
    end, showTime)
end

function BetBubblesMain:stopAutoClose()
    if self.m_autoCloseTimer then
        self:stopAction(self.m_autoCloseTimer)
        self.m_autoCloseTimer = nil
    end
end

function BetBubblesMain:onEnter()
    BetBubblesMain.super.onEnter(self)

    gLobalNoticManager:addObserver(self, 
        function(target, params)

            -- todomaqun
            -- 优化1：哪个模块变化了，移除再添加那个模块
            -- 优化2：当有多个模块同时变化时，这里维护一下变化列表

            self:checkVisible()
            self:refreshBubbles()
            self:stopAutoClose()
            self:initAutoClose()            
        end,
        ViewEventType.NOTIFY_BETBUBBLE_REFRESH
    )
    gLobalNoticManager:addObserver(self,
        function()
            self:forceHide()
        end,
        ViewEventType.STR_TOUCH_SPIN_BTN
    )    
end

function BetBubblesMain:onExit()
    BetBubblesMain.super.onExit(self)
    self:stopAutoClose()
end

function BetBubblesMain:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_click" then
        self:clickBtnBetBarFunc()
    end
end

function BetBubblesMain:clickBtnBetBarFunc()
    if self.m_UIStatus == UIStatus.Up then
        self:hideBet()
    elseif self.m_UIStatus == UIStatus.Down then
        self:refreshBubbles()
        self:stopAutoClose()
        self:initAutoClose()
        self:__showBet()
    end
end

function BetBubblesMain:isDeluxe()
    local bOpenDeluxe = globalData.slotRunData.isDeluexeClub
    if bOpenDeluxe then
        return true
    end
    return false
end


return BetBubblesMain