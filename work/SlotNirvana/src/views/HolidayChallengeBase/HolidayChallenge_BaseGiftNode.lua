
local BaseView = require("base.BaseView")
local HolidayChallenge_BaseGiftNode = class("HolidayChallenge_BaseGiftNode", BaseView)

function HolidayChallenge_BaseGiftNode:getCsbName()
    if self.m_activityConfig.ROAD_CONFIG.ROAD_NODE_USE_SINGLE_CSD then
        if self.m_useBig then
            if self.m_bLastNode then
                return self.m_activityConfig.RESPATH.GIFT_NODE_H
            else
                return self.m_activityConfig.RESPATH.GIFT_NODE_B
            end
        end
        return self.m_activityConfig.RESPATH.GIFT_NODE_S
    else
        return self.m_activityConfig.RESPATH.GIFT_NODE
    end
end

function HolidayChallenge_BaseGiftNode:initDatas(index)
    self.m_index = index
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()

    self.m_isLight = false
    self.m_useBig = false
    self.m_isFrontBig = false
    self.m_initData = false
    self.m_rewardPointKey = nil
    

    local actData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    if actData then
        self.m_initData = true
        local currPoint = actData:getCurrentPoints()
        local tbRewardPoint = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getHasPayRewardPoint()
        local rewardPointKey = table_keyof(tbRewardPoint,index)
        self.m_rewardPointKey = rewardPointKey
        self.m_bLastNode = false
        if index <= currPoint then --如果当前南瓜坐标比 当前进度小，证明已经走过了，可以亮
            self.m_isLight = true
        end
        if index == actData:getMaxPoints() then
            self.m_bLastNode = true
        end
        self:addSpineNode(not not rewardPointKey)
        if rewardPointKey then -- 当前坐标是有奖励的，所以设置成大的
            self.m_useBig = true
        end
        if index > 1 then
            local rewardPointKey_Front = table_keyof(tbRewardPoint,index - 1)
            if rewardPointKey_Front then -- 当前坐标是有奖励的，所以设置成大的
                self.m_isFrontBig = true
            end
        end
    end
end

function HolidayChallenge_BaseGiftNode:initUI(_index)
    HolidayChallenge_BaseGiftNode.super.initUI(self)

    -- _index 指的是当前这是第几个南瓜
    self:initView(_index)
end

function HolidayChallenge_BaseGiftNode:initCsbNodes()
    -- board奖励板子
    self.m_nodeBoardPay         = self:findChild("node_board_pay")
    self.m_nodeBoardFree        = self:findChild("node_board_free")

    self.m_labNum               = self:findChild("lb_number")
    self.m_labNumLast           = self:findChild("lb_number_last")

    self.m_nodeEat = self:findChild("node_eat")

    self.m_node_small_gift          = self:findChild("node_small_gift")
    self.m_node_big_gift          = self:findChild("node_big_gift")

    self.m_node_small_gift_spine           = self:findChild("node_small_gift_spine")
    self.m_node_big_gift_spine          = self:findChild("node_big_gift_spine")
    self.m_node_big_gift_spine_35          = self:findChild("node_big_gift_spine_35")

    
    self.m_sp_gui_lan         = self:findChild("gui_lan")
    self.m_sp_gui_hong         = self:findChild("gui_hong")
    self.m_sp_gui_fen         = self:findChild("gui_fen")
    self.m_sp_gui_huang        = self:findChild("gui_huang")

    self.m_particle1 = self:findChild("lizi")
    self.m_particle2 = self:findChild("lizi_0")
    self.m_particle3 = self:findChild("lizi_0_0")
    if self.m_particle1 then
        self.m_particle1:stopSystem()
    end
    if self.m_particle2 then
        self.m_particle2:stopSystem()
    end
    if self.m_particle3 then
        self.m_particle3:stopSystem()
    end
end

function HolidayChallenge_BaseGiftNode:initView(_index)
    if self.m_initData then
        self:addSpineNode(self.m_useBig)
        if self.m_useBig then -- 当前坐标是有奖励的，所以设置成大的
            if self.m_sp_gui_lan then
                self.m_sp_gui_lan:setVisible(self.m_rewardPointKey == 1)
            end
            if self.m_sp_gui_hong then
                self.m_sp_gui_hong:setVisible(self.m_rewardPointKey == 2)
            end
            if self.m_sp_gui_fen then
                self.m_sp_gui_fen:setVisible(self.m_rewardPointKey == 3)
            end
            if self.m_sp_gui_huang then
                self.m_sp_gui_huang:setVisible(self.m_rewardPointKey == 4)
            end
            self:updateStatus(self.m_isLight,true,self.m_index)
            self:addBoardNode(self.m_rewardPointKey)
        else
            self:updateStatus(self.m_isLight,false,nil)
        end
    end
end

function HolidayChallenge_BaseGiftNode:addSpineNode(_big)
    local useSpine = false
    if _big then
        if self.m_bLastNode then
            if self.m_node_big_gift_spine_35 and self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_H_LIGHT"] then
                self.m_SpineAct_light = util_spineCreate(self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_H_LIGHT"], true, true, 1)
                self.m_SpineAct_light:setScale(1)
                self.m_node_big_gift_spine_35:addChild(self.m_SpineAct_light)
            end

            if self.m_node_big_gift_spine_35 and self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_H"] then
                self.m_SpineAct = util_spineCreate(self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_H"], true, true, 1)
                self.m_SpineAct:setScale(1)
                self.m_node_big_gift_spine_35:addChild(self.m_SpineAct)
                useSpine = true
            end
        else
            if self.m_node_big_gift_spine and self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_B"] then
                self.m_SpineAct = util_spineCreate(self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_B"], true, true, 1)
                self.m_SpineAct:setScale(1)
                self.m_node_big_gift_spine:addChild(self.m_SpineAct)
                useSpine = true
            end
        end
    else
        if self.m_node_small_gift_spine and self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_S"] then
            self.m_SpineAct = util_spineCreate(self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_S"], true, true, 1)
            self.m_SpineAct:setScale(1)
            self.m_node_small_gift_spine:addChild(self.m_SpineAct)
            useSpine = true
        end
    end
    if useSpine then
        if self.m_node_small_gift then
            self.m_node_small_gift:setVisible(false)
        end
        if self.m_node_big_gift then
            self.m_node_big_gift:setVisible(false)
        end
    end
end

--外部调用 
function HolidayChallenge_BaseGiftNode:updateStatus(_light,_big,_progress)
    -- 当前南瓜是大南瓜还是小南瓜
    self.m_isBigStar = _big
    local actName = nil
    if _big then
        -- 当前南瓜是否为点亮状态
        if _light then
            actName = "idle_b_man"
            if self.m_bLastNode then
                if self.m_SpineAct then
                    actName = "idle2"
                else
                    actName = "idle_h_man"
                end
            end
        else
            actName = "idle_b_kong"
            if self.m_bLastNode then
                if self.m_SpineAct then
                    actName = "idle"
                else
                    actName = "idle_h_kong"
                end
            end
        end

        if self.m_labNum then
            self.m_labNum:setString(_progress)
        end
        if self.m_bLastNode and self.m_labNumLast then
            self.m_labNumLast:setString(_progress)
        end
    else
        -- 当前南瓜是否为点亮状态
        if _light then
            actName = "idle_s_man"
        else
            actName = "idle_s_kong"
        end
    end
    actName = "idle_s_man"
    if actName then
        if self.m_SpineAct then
            util_spinePlay(self.m_SpineAct, actName, true)
            if self.m_SpineAct_light then
                util_spinePlay(self.m_SpineAct_light, actName, true)
            end
        else
            self:runCsbAction(actName,true)
        end
    end
end

--[[
    --@_firstShow:是否为第一个展示动画的节点
	--@_overFunc:动画完毕回调
	--@_isFuncAction: 当前调用是否要等到动画播放回调 - 可自由决定回调时间
]]
function HolidayChallenge_BaseGiftNode:playShow(_firstShow,_overFunc,_isFuncAction)
    self:playShowAct(_firstShow,_overFunc,_isFuncAction)
end

function HolidayChallenge_BaseGiftNode:playShowAct(_firstShow,_overFunc,_isFuncAction)
    local _actName = ""
    local usePar = nil
    if self.m_isBigStar then
        _actName = "show_b"
        usePar = self.m_particle2
        if self.m_bLastNode then
            _actName = "show_h"
            usePar = self.m_particle3
        end
    else
        _actName = "show_s"
        usePar = self.m_particle1
        if _firstShow and self.m_activityConfig.ROAD_CONFIG.ROAD_NODE_FLY_USE_FIRSTSHOW  then
            _actName = "show_s_zhuanji"
        end
    end

    if self.m_SpineAct then
        util_spinePlay(self.m_SpineAct, _actName, false)
        if self.m_SpineAct_light then
            util_spinePlay(self.m_SpineAct_light, _actName, false)
        end
        util_spineEndCallFunc(
        self.m_SpineAct,
        _actName,
        function()
            if not _isFuncAction and _overFunc then
                _overFunc()
            end
            if self.m_isBigStar then
                _actName = "idle_b_man"
                if self.m_bLastNode then
                    _actName = "idle2"
                end
            else
                _actName = "idle_s_man"
            end
            util_spinePlay(self.m_SpineAct, _actName, true)
            if self.m_SpineAct_light then
                util_spinePlay(self.m_SpineAct_light, _actName, true)
            end
            self:updateBoard()
        end
    )
    else
        local callback = function()
            if not _isFuncAction and _overFunc then
                _overFunc()
            end
            if self.m_isBigStar then
                _actName = "idle_b_man"
                if self.m_bLastNode then
                    _actName = "idle_h_man"
                end
            else
                _actName = "idle_s_man"
            end
            self:updateBoard()
            self:runCsbAction(_actName,false,nil,60)
        end
        self:runCsbAction(_actName,false,callback,60)
        if usePar then
            performWithDelay(self, function (  )
                usePar:resetSystem()
            end, 25/60)
        end
    end

    if _isFuncAction and _overFunc then
        performWithDelay(self,function(  )
            _overFunc()
        end,1/30*(62/3) )
    end
end

function HolidayChallenge_BaseGiftNode:createLightSpine()
    if self.m_node_big_gift_spine_35 and self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_H_LIGHT"] then
        self.m_node_big_gift_spine_35:removeAllChildren()
        self.m_SpineAct = util_spineCreate(self.m_activityConfig.RESPATH["SPINE_PATH_GIFTNODE_H_LIGHT"], true, true, 1)
        self.m_SpineAct:setScale(1)
        self.m_node_big_gift_spine_35:addChild(self.m_SpineAct)
        util_spinePlay(self.m_SpineAct, "idle2", false)
        return true
    end
    return false
end

function HolidayChallenge_BaseGiftNode:playSpineAction(node,_actName,_loop,_callback)
    if node then
        util_spinePlay(node, _actName, _loop)
        if _callback then
            util_spineEndCallFunc(
            node,
            _actName,
            function()
                _callback()
            end
        )
        end
    end
end

function HolidayChallenge_BaseGiftNode:addBoardNode(_index)
    local payBoardPath =  "views.HolidayChallengeBase.HolidayChallenge_BaseMap_DoubleRewardNode"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.MAP_DOUBLEREWARD_NODE then
        payBoardPath = self.m_activityConfig.CODE_PATH.MAP_DOUBLEREWARD_NODE
    end

    self.m_boardPayNode = util_createView(payBoardPath,{type = "pay", index = _index})
    self.m_nodeBoardPay:addChild(self.m_boardPayNode)

    self.m_boardFreeNode = util_createView(payBoardPath,{type = "free", index = _index})
    self.m_nodeBoardFree:addChild(self.m_boardFreeNode)

    if self.m_bLastNode and self.m_activityConfig.ROAD_CONFIG.ROAD_NODE_LAST_REWARDBOARD_UP then
        self.m_boardPayNode:setPositionY(self.m_boardPayNode:getPositionY() + self.m_activityConfig.ROAD_CONFIG.ROAD_NODE_LAST_REWARDBOARD_UP)
        self.m_boardFreeNode:setPositionY(self.m_boardFreeNode:getPositionY() + self.m_activityConfig.ROAD_CONFIG.ROAD_NODE_LAST_REWARDBOARD_UP)
    end
end

--[[
    @desc: 每个南瓜播放完动画之后,需要检测一次当前奖励板子的动画
]]
function HolidayChallenge_BaseGiftNode:updateBoard()
    if self.m_isBigStar then
        self.m_boardPayNode:playArriveCollectAction()
        self.m_boardFreeNode:playArriveCollectAction()
    end
end

--[[
    @desc: 高亮的时候切换时间线
]]
function HolidayChallenge_BaseGiftNode:changeGuideNodeZorder(_up)
    if self.m_activityConfig.ROAD_CONFIG.GUIDE_GIFT_NO_ACTION then
        return 
    end

    local actName = ""
    if _up then
        actName = "idle_b_man"
        if self.m_bLastNode then
            actName = "idle_h_man"
        end
    else
        actName = "idle_b_kong"
        if self.m_bLastNode then
            actName = "idle_h_kong"
        end
    end
    if self.m_SpineAct then
        util_spinePlay(self.m_SpineAct, actName, false)
    else
        self:runCsbAction(actName,false,nil,60)
    end
end

function HolidayChallenge_BaseGiftNode:getIsBigPoint()
    return self.m_isBigStar and not self.m_bLastNode
end

function HolidayChallenge_BaseGiftNode:getIsForntBigPoint()
    return self.m_isFrontBig
end

function HolidayChallenge_BaseGiftNode:isLastBigPoint()
    return self.m_bLastNode
end

return HolidayChallenge_BaseGiftNode
