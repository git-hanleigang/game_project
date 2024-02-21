--[[
    模块引导
    author:{author}
    time:2022-06-18 17:55:24
]]
local GuideMgr = import(".GuideMgr")
local GuideRecordMgr = import(".GuideRecordMgr")

local GameGuideCtrl = class("GameGuideCtrl", BaseSingleton)

function GameGuideCtrl:ctor()
    GameGuideCtrl.super.ctor(self)
    -- 引导管理模块
    self.m_guideMgr = GuideMgr:getInstance()
    -- 引导记录管理模块
    self.m_recordMgr = GuideRecordMgr:getInstance()
    -- 引导遮罩
    self.m_maskLua = "GameModule.Guide.GameGuideMaskLayer"

    self.m_curStep = ""
    self.m_refName = ""
    -- 引导的功能主题
    self.m_guideTheme = ""
    -- self.m_guideData = nil

    self.m_signNodeInfos = {}
    self.m_tipNodeInfos = {}

    -- 裁切模版元素列表
    -- self.m_clipElems = {}
    -- 穿透Rect列表
    self.m_thoughRects = {}
end

function GameGuideCtrl:onRegist()
    -- self:initGuideDatas()
    self:reloadGuideRecords()
    self:initGuideRecords()
end

function GameGuideCtrl:initGuideDatas(guideData)
    local _theme = self:getGuideTheme()

    if not guideData then
        printError("%s guide data is nil!!!", _theme)
        return
    end

    self.m_guideMgr:parseGuideCfgs(guideData.stepCfg or {}, _theme)
    self.m_guideMgr:parseGuideStepInfos(guideData.stepInfos or {}, _theme)
    self.m_guideMgr:parseGuideSignInfos(guideData.signInfos or {}, _theme)
    self.m_guideMgr:parseGuideTipInfos(guideData.tipInfos or {}, _theme)
end

function GameGuideCtrl:setGuideTheme(theme)
    self.m_guideTheme = theme
end

function GameGuideCtrl:getGuideTheme()
    return self.m_guideTheme
end

function GameGuideCtrl:setRefName(refName)
    self.m_refName = refName
end

function GameGuideCtrl:getRefName()
    return self.m_refName
end

-- 引导数据
-- function GameGuideCtrl:setGuideData(data)
--     self.m_guideData = data
-- end

-- function GameGuideCtrl:getGuideData()
--     return self.m_guideData
-- end

-- 获得引导入口配置数据
function GameGuideCtrl:getGuideCfgInfo(guideName, theme)
    return self.m_guideMgr:getGuideCfgInfo(guideName, theme or self:getGuideTheme())
end

-- 获得引导步骤数据
function GameGuideCtrl:getGuideStepInfo(stepId, theme)
    return self.m_guideMgr:getGuideStepInfo(stepId, theme or self:getGuideTheme())
end

-- 获得引导信号数据
function GameGuideCtrl:getGuideSignInfo(signId, theme)
    return self.m_guideMgr:getGuideSignInfo(signId, theme or self:getGuideTheme())
end

-- 获得引导提示数据
function GameGuideCtrl:getGuideTipInfo(tipId, theme)
    return self.m_guideMgr:getGuideTipInfo(tipId, theme or self:getGuideTheme())
end

-- 获得引导记录步骤ID
function GameGuideCtrl:getGuideRecordStepId(guideName, theme)
    return self.m_recordMgr:getGuideRecordStepId(guideName, theme or self:getGuideTheme())
end

-- 引导是否执行中
function GameGuideCtrl:isGuideGoing(guideName, theme)
    local isOver, stepId = self:getGuideRecordStepId(guideName, theme)
    if not isOver and stepId then
        return true
    else
        return false
    end
end

-- 引导是否结束
function GameGuideCtrl:isGuideOver(guideName, theme)
    local isOver, stepId = self:getGuideRecordStepId(guideName, theme)
    if isOver then
        return true
    else
        return false
    end
end

-- ==============引导记录=======================================
-- 引导记录数据转字符串
function GameGuideCtrl:getGuideRecord2Str(theme)
    return self.m_recordMgr:getGuideRecord2Str(theme or self:getGuideTheme())
end

-- 更新引导记录数据
function GameGuideCtrl:updateGuideRecord(curStepInfo, guideName, theme)
    self.m_recordMgr:updateGuideRecord(curStepInfo, guideName, theme or self:getGuideTheme())
end

-- 引导结束
function GameGuideCtrl:setGuideStepOver(guideName, theme,curStepLua)
    -- 发送下一步引导事件
    util_nextFrameFunc(
        function()
            gLobalNoticManager:postNotification(
                "notify_GuideName_Over",
                {
                    guideName = guideName,
                    luaName = curStepLua
                }
            )
        end
    )
    self.m_recordMgr:setGuideStepOver(guideName, theme or self:getGuideTheme())
end

-- 保存引导记录数据
function GameGuideCtrl:saveGuideRecord(curStepInfo, guideName)
    -- 存服务器消息
    -- 保存方式上层重写
end

-- 加载引导记录数据
function GameGuideCtrl:reloadGuideRecords(recData)
    -- 数据存本地或服务器，由上层决定读取数据方式
    if not recData or #recData <= 0 then
        return
    end

    self.m_recordMgr:parseRecordData(recData, self:getGuideTheme())
end

-- 初始化引导记录
function GameGuideCtrl:initGuideRecords()
    local theme = self:getGuideTheme()
    local cfgInfos = self.m_guideMgr:getGuideCfgInfos(theme)
    if not cfgInfos then
        return
    end

    for key, cfgInfo in pairs(cfgInfos) do
        local guideName = cfgInfo:getGuideName()
        -- 判断是否有记录
        local recordInfo = self.m_recordMgr:getGuideRecordInfo(guideName, theme)
        if not recordInfo then
            -- 添加引导第一步
            local _curStep = cfgInfo:getStartStep()
            self.m_recordMgr:setGuideRecordInfo(_curStep, guideName, theme)
        else
            -- 判断引导是否结束
            local _stepId = recordInfo:getStepId()
            local guideInfo = self:getGuideStepInfo(_stepId)
            if guideInfo then
                local isEnd = guideInfo:isFinalStep()
                -- if not isEnd then
                --     local _nextStep = guideInfo:getNextStep()
                --     self:setCurStep(_nextStep, guideName)
                -- end
                recordInfo:setStepOver(isEnd)
            else
                recordInfo:setStepOver(true)
            end
        end
    end
end

-- ================================================================
-- 获得当前执行中的引导步骤信息
function GameGuideCtrl:getCurGuideStepInfo(guideName)
    local isOver, curStepId = self:getGuideRecordStepId(guideName)
    if isOver or (not curStepId) then
        -- 引导记录不存在或已经结束
        return nil
    end

    -- 显示引导
    local curStepInfo = self:getGuideStepInfo(curStepId)
    if not curStepInfo then
        return nil
    end

    return curStepInfo
end

-- 判断引导是否可触发
function GameGuideCtrl:isCanTriggerGuide(guideName, themeName)
    local cfgInfo = self:getGuideCfgInfo(guideName, themeName)
    if not cfgInfo then
        return false
    end

    local preGuides = cfgInfo:getPreGuides()
    for i = 1, #preGuides do
        if not self:isGuideOver(preGuides[i], themeName) then
            -- 存在未完成的前置引导点位
            return false
        end
    end

    -- 判断当前引导点位是否完成
    if self:isGuideOver(guideName, themeName) then
        return false
    end

    return true
end

-- 触发引导
function GameGuideCtrl:triggerGuide(view, guideName, themeName)
    if tolua.isnull(view) then
        return false
    end

    -- 获得引导入口信息
    -- 判断引导入口是否可执行
    if not self:isCanTriggerGuide(guideName, themeName) then
        return false
    end

    -- 获得当前步骤
    local curStepInfo = self:getCurGuideStepInfo(guideName, themeName)
    if not curStepInfo then
        return false
    end

    if view.__cname ~= curStepInfo:getLuaName() then
        -- 当前步骤和界面对不上
        self:stopGuide()
        return false
    end

    local callFunc = function()
        -- 触发过程执行结束回调
        self:triggerGuideShown(view, curStepInfo, guideName)
    end
    local guideLayer = self:showMaskLayer()
    if guideLayer then
        guideLayer:_addBlockMask()
    end

    self:hideAllTipView()
    -- 触发过程
    self:triggerGuideAction(callFunc, view, curStepInfo, guideName)

    return true
end

-- 执行触发过程
function GameGuideCtrl:triggerGuideAction(callFunc, view, curStepInfo, guideName)
    if callFunc then
        callFunc()
    end
end

-- 触发引导已显示完成
function GameGuideCtrl:triggerGuideShown(view, curStepInfo, guideName)
    if tolua.isnull(view) then
        self:stopGuide()
        return
    end

    -- 显示引导信号
    local signIds = curStepInfo:getSignIds()
    for i = 1, #signIds do
        self:showSignView(signIds[i], view, guideName)
    end

    -- 显示引导Tip
    local tipIds = curStepInfo:getTipIds()
    for j = 1, #tipIds do
        self:showTipView(tipIds[j], view, guideName)
    end
    -- 整理Tip
    self:tidyTips()

    local maskLayer = self:getGuideMaskLayer()
    if maskLayer then
        maskLayer:_removeBlockMask()
        -- 更新遮罩视图
        maskLayer:updateStepView(curStepInfo)
    end
end

--[[
    @desc: 获得引导节点
    @parent: layer节点
	@nodeName: 工程节点名
	@key: sign或tip的id
    @return:
]]
function GameGuideCtrl:getGuideNode(parent, nodeName, key)
    if not parent then
        return
    end

    -- local _temp = parent
    -- local _childNode = nil
    -- for i = 1, #nodeName do
    --     _childNode = _temp:findChild(nodeName[i])
    --     if not _childNode then
    --         break
    --     end
    -- end
    local _childNode = parent:findChild(nodeName)
    if not _childNode then
        -- 自定义节点
        _childNode = self:getUDefGuideNode(parent, key)
    end

    return _childNode
end

-- 自定义获得节点的方法
function GameGuideCtrl:getUDefGuideNode(layer, key)
    return nil
end

-- 显示标记信号
function GameGuideCtrl:showSignView(signId, view, guideName)
    if not view then
        return
    end

    local signInfo = self:getGuideSignInfo(signId)
    if not signInfo then
        return nil
    end

    if view.__cname ~= signInfo:getLuaName() then
        return
    end

    local _node = self:getGuideNode(view, signInfo:getNodeName(), signId)
    if not _node then
        -- 找不到节点
        return
    end

    -- 显示引导
    local maskLayer = self:showMaskLayer()

    if signInfo:isType(GuideSignType.Up) then
        -- 抬升显示节点
        local nodeInfo = self:showUpliftNode(maskLayer, _node, view:getScale())
        if nodeInfo then
            -- 保存节点初始位置信息
            table.insert(self.m_signNodeInfos, nodeInfo)
        end
        -- 添加触摸穿透区域
        self:addThoughRect(_node, guideName, signInfo)
    elseif signInfo:isType(GuideSignType.Clip) then
        local clipElem = self:showClipNode(maskLayer, _node, signInfo)
        if clipElem and (not signInfo:isBlock()) then
            local rect = clipElem:getBoundingBox()
            rect = {x = rect.x, y = rect.y, height = rect.height, width = rect.width}
            table.insert(self.m_thoughRects, rect)
        end
    end
    -- 添加引导触摸
    -- self:addGuideTouchLayout(_node, guideName, signInfo)
end

-- 显示提示气泡(指针)
function GameGuideCtrl:showTipView(tipId, view, guideName)
    if not view then
        return
    end

    local tipInfo = self:getGuideTipInfo(tipId)
    if not tipInfo then
        return
    end

    if view.__cname ~= tipInfo:getLuaName() then
        return
    end

    local _zOrder = math.max(tipInfo:getZOrder())

    -- 查找已存在的tip
    local _tipNode, idx = self:getExistTipNode(tipInfo:getPath())
    if not _tipNode then
        -- 创建Tip
        if tipInfo:isCsb() then
            _tipNode, _ = util_csbCreate(tipInfo:getPath())
        elseif tipInfo:isLua() then
            _tipNode = util_createView(tipInfo:getPath(), tipId)
        end
    end

    if tolua.isnull(_tipNode) then
        return
    end

    local tipNodeInfo = nil
    -- 显示引导
    local maskLayer = self:showMaskLayer()
    if not _tipNode:getParent() then
        maskLayer:addRootChild(_tipNode, 20)
        tipNodeInfo = {
            node = _tipNode,
            tipInfo = tipInfo,
            trigger = true
        }
        -- 保存节点初始位置信息
        table.insert(self.m_tipNodeInfos, tipNodeInfo)
    else
        if idx then
            -- 存在需要保留的tip，状态设置为新触发
            self.m_tipNodeInfos[idx].trigger = true
            _tipNode:setVisible(true)
        end
    end

    local _node = self:getGuideNode(view, tipInfo:getNodeName(), tipId)
    if _node then
        -- 工程有节点
        -- _node:addChild(_tipNode)
        -- 抬升显示节点
        -- tipNodeInfo = self:showUpliftNode(maskLayer, _node, view:getScale())
        -- if tipNodeInfo then
        --     tipNodeInfo.node:setZOrder(_zOrder)
        -- end
        local worldPos = _node:getParent():convertToWorldSpace(cc.p(_node:getPosition()))
        local nodeRoot = maskLayer:getRootNode()
        if nodeRoot then
            local _pos = nodeRoot:convertToNodeSpace(worldPos)
            -- maskLayer:addRootChild(_tipNode, 20)
            _tipNode:setPosition(_pos)
        end
    else
        -- 没有节点，添加到遮罩
        -- maskLayer:addRootChild(_tipNode, 20)
        _tipNode:setPosition(tipInfo:getPos())
    end

    -- 更新tip节点
    self:updateTipView(_tipNode, tipInfo)
end

-- 获得已存在的tip
function GameGuideCtrl:getExistTipNode(path)
    for k, v in ipairs(self.m_tipNodeInfos) do
        if v.tipInfo:getPath() == path then
            return v.node, k
        end
    end

    return nil, nil
end

-- 整理Tip
function GameGuideCtrl:tidyTips()
    for i = #self.m_tipNodeInfos, 1, -1 do
        local info = self.m_tipNodeInfos[i]
        if info.trigger then
            -- 是否刚触发的
            info.trigger = false
        else
            if not tolua.isnull(info.node) then
                info.node:removeFromParent()
            end
            table.remove(self.m_tipNodeInfos, i)
        end
    end
end

-- 更新Tip显示
function GameGuideCtrl:updateTipView(tipNode, tipInfo)
end

-- 隐藏tip
function GameGuideCtrl:hideAllTipView()
    local tbNodeInfos = self.m_tipNodeInfos
    for i = #tbNodeInfos, 1, -1 do
        local _info = tbNodeInfos[i]
        local _node = _info.node
        if _node then
            _node:setVisible(false)
        end
    end
end

-- 移除tip
function GameGuideCtrl:removeAllTipView()
    local tbNodeInfos = self.m_tipNodeInfos
    for i = #tbNodeInfos, 1, -1 do
        local _info = tbNodeInfos[i]
        local _node = _info.node
        if _node then
            _node:removeAllChildren()
        end
    end
end

function GameGuideCtrl:getGuideMaskLayer()
    return gLobalViewManager:getViewByName("GameGuideMaskLayer")
end

-- 显示引导遮罩
function GameGuideCtrl:showMaskLayer()
    local maskLayer = self:getGuideMaskLayer()
    if not maskLayer then
        maskLayer = util_createView(self:getMaskLua(), self)
        maskLayer:setName("GameGuideMaskLayer")
        gLobalViewManager:showUI(maskLayer, ViewZorder.ZORDER_GUIDE, false)
    end
    return maskLayer
end

-- 获得引导遮罩模块
function GameGuideCtrl:getMaskLua()
    return self.m_maskLua
end

-- 设置引导遮罩模块路径
function GameGuideCtrl:setMaskLua(luaPath)
    if not luaPath or luaPath == "" then
        return
    end
    self.m_maskLua = luaPath
end

function GameGuideCtrl:removeMaskLayer()
    local _layer = self:getGuideMaskLayer()
    if _layer then
        _layer:closeUI()
    end
end

function GameGuideCtrl:clearMaskChild()
    local _layer = self:getGuideMaskLayer()
    if _layer then
        _layer:removeUpliftChild()
        _layer:removeStencilChild()
        -- self.m_clipElems = {}
        self.m_thoughRects = {}
    end
end

-- 提高node的层级
function GameGuideCtrl:showUpliftNode(_maskLayer, _node, _scale)
    _scale = _scale or 1
    if not _node or not _maskLayer then
        return nil
    end
    local rootNode = _maskLayer:findChild("root")
    if not rootNode then
        return nil
    end

    local _zOrder = _node:getZOrder()
    local _parent = _node:getParent()
    local _pos = cc.p(_node:getPosition())
    local worldPos = _node:getParent():convertToWorldSpace(_pos)
    local localPos = rootNode:convertToNodeSpace(worldPos)
    util_changeNodeParent(rootNode, _node)
    _node:setPosition(localPos)
    _node:setScale(_scale)

    -- 保存节点信息
    local _info = {
        node = _node,
        isUp = true,
        parent = _parent,
        scale = _scale,
        pos = _pos,
        zOrder = _zOrder
    }
    return _info
end

-- 还原高亮节点
function GameGuideCtrl:resetHighLightNode(tbNodeInfos)
    tbNodeInfos = tbNodeInfos or {}
    for i = #tbNodeInfos, 1, -1 do
        local _info = tbNodeInfos[i]
        local _node = _info.node
        if _info.isUp then
            -- 抬升的节点
            local _parent = _info.parent
            if (not tolua.isnull(_node)) and (not tolua.isnull(_parent)) then
                local _pos = _info.pos
                local _zOrder = _info.zOrder
                local _scale = _info.scale

                util_changeNodeParent(_parent, _node, _zOrder)
                _node:setPosition(_pos)
                _node:setScale(_scale or 1)
            end
        else
            -- 直接添加的tip
            if (not tolua.isnull(_node)) then
                _node:removeFromParent()
            end
        end

        table.remove(tbNodeInfos, i)
    end
end

function GameGuideCtrl:onClickMask(pos)
end

function GameGuideCtrl:onTouchMaskBegan(pos)
end

-- 检测点击到可穿透的 RECT
function GameGuideCtrl:checkTouchThroughRect(pos)
    -- local _maskLayer = self:getGuideMaskLayer()
    -- if not _maskLayer then
    --     return false
    -- end
    -- local _nodeStencil = _maskLayer:getClipStencilNode()
    -- if _nodeStencil then
    --     local posnodef = cc.p(_nodeStencil:getPosition())

    --     local enableSwTc = false
    --     for i = 1, #(self.m_clipElems or {}) do
    --         local rect = self.m_clipElems[i]:getBoundingBox()
    --         rect = {y = rect.y + posnodef.y, x = rect.x + posnodef.x, height = rect.height, width = rect.width}
    --         if cc.rectContainsPoint(rect, pos) then
    --             enableSwTc = true
    --             return true
    --         end
    --     end
    -- end
    for i = 1, #(self.m_thoughRects or {}) do
        local rect = self.m_thoughRects[i]
        if cc.rectContainsPoint(rect, pos) then
            return true
        end
    end
    return false
end

-- 裁切引导节点
function GameGuideCtrl:showClipNode(maskLayer, node, signInfo)
    -- 裁切节点
    local _nodeClip = maskLayer:getClipNode()
    local clipElem = self:createClipElem(node, signInfo)
    if clipElem then
        -- 计算坐标
        local _nodePos = cc.p(node:getPosition())
        local _offset = signInfo:getOffsetPos()
        _nodePos = cc.pAdd(_nodePos, _offset)
        -- 引导节点转世界坐标
        local worldPos = node:getParent():convertToWorldSpace(_nodePos)
        -- 世界坐标转裁切节点坐标
        local signPos = _nodeClip:convertToNodeSpace(worldPos)
        clipElem:setScale(signInfo:getScale())
        clipElem:setPosition(signPos)
        -- 添加到裁切模板节点
        maskLayer:addToStencil(clipElem, signInfo:getZOrder())
    end
    return clipElem
end

-- 创建裁切元素
function GameGuideCtrl:createClipElem(node, signInfo)
    if not node or not signInfo then
        -- 找不到节点
        return
    end

    -- 裁切元素资源
    local elemRes = signInfo:getResPath()
    local spSize = signInfo:getSize()
    local spElem = nil
    if spSize.width < 0.1 or spSize.height < 0.1 then
        -- 没有大小
        spElem = util_createSprite(elemRes)
    else
        -- 有大小，使用九宫格
        local params = {
            scale9 = true,
            size = spSize,
            rect = {0, 0, spSize.width, spSize.height}
        }
        spElem = display.newSprite(elemRes, params)
    end

    return spElem
end

-- 重置引导步骤效果
function GameGuideCtrl:resetStepView()
    -- 还原高亮节点
    self:removeAllTipView()
    self:resetHighLightNode(self.m_tipNodeInfos)
    self:resetHighLightNode(self.m_signNodeInfos)

    self:clearMaskChild()
end

-- 停止引导
function GameGuideCtrl:stopGuide()
    self:resetStepView()

    self:removeMaskLayer()
end

-- 执行下一步引导
function GameGuideCtrl:doNextGuideStep(guideName)
    -- self:resetStepView()

    local curStepInfo = self:getCurGuideStepInfo(guideName)
    if not curStepInfo then
        return
    end

    -- 处理当前引导步骤是否存盘
    self:updateGuideRecord(curStepInfo, guideName)
    self:saveGuideRecord(curStepInfo, guideName)

    local curStepLua = curStepInfo:getLuaName()
    -- 查找下一步引导步骤
    local nextStep = curStepInfo:getNextStep()
    local nextStepInfo = self:getGuideStepInfo(nextStep)

    if nextStepInfo then
        local nextStepLua = nextStepInfo:getLuaName()
        if nextStepInfo:isFinalStep() then --curStepLua ~= nextStepLua or
            -- 下一步不在同一界面或引导结束
            self:setGuideStepOver(guideName,nil,curStepLua)
            self:stopGuide()
        else
            self:resetHighLightNode(self.m_signNodeInfos)
            self:clearMaskChild()

            -- 发送下一步引导事件
            util_nextFrameFunc(
                function()
                    gLobalNoticManager:postNotification(
                        "notify_doGuideStep",
                        {
                            stepId = nextStep,
                            guideName = guideName,
                            luaName = nextStepLua
                        }
                    )
                end
            )
        end
    else
        self:setGuideStepOver(guideName,nil,curStepLua)
        self:stopGuide()
    end
end

-- 添加可穿透矩形
function GameGuideCtrl:addThoughRect(guideNode, guideName, signInfo)
    if not guideNode or not signInfo then
        return
    end

    -- 是否阻断触摸
    local isBlock = signInfo:isBlock()
    if isBlock then
        return
    end

    local _size = signInfo:getSize()
    local contentSize = (_size or guideNode:getContentSize())
    local _anchorPos = signInfo:getAnchorPos()

    -- sign左下坐标
    local _x = 0 - _size.width * _anchorPos.x
    local _y = 0 - _size.height * _anchorPos.y
    local _pos1 = cc.pAdd(signInfo:getOffsetPos(), cc.p(_x, _y))
    local _pos = cc.pAdd(cc.p(guideNode:getPosition()), _pos1)

    -- 触摸穿透矩形
    local _rect = cc.rect(_pos.x, _pos.y, contentSize.width, contentSize.height)
    table.insert(self.m_thoughRects, _rect)
    -- self.m_thoughRects[guideName] = _rect

    if device.platform == "mac" then
        local touchLayout = ccui.Layout:create()
        touchLayout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid)
        touchLayout:setColor(cc.c3b(100, 100, 100))
        touchLayout:setBackGroundColorOpacity(100)

        touchLayout:setName("guide_touch_layout")
        -- touchLayout:setTouchEnabled(true)
        -- touchLayout:setSwallowTouches(isBlock)
        -- touchLayout:setAnchorPoint(_anchorPos or cc.p(0.5, 0.5))
        touchLayout:setAnchorPoint(cc.p(0, 0))
        touchLayout:setContentSize(contentSize)

        touchLayout:setPosition(_pos)

        local _maskLayer = self:getGuideMaskLayer()
        if _maskLayer then
            local _zOrder = math.max(signInfo:getZOrder(), guideNode:getZOrder())
            _maskLayer:addToUplift(touchLayout, _zOrder)
        end
    end
end

return GameGuideCtrl
