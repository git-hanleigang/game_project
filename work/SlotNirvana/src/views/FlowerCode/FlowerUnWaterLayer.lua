local FlowerUnWaterLayer = class("FlowerUnWaterLayer", BaseView)

function FlowerUnWaterLayer:initUI()
    local path = "Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_1.csb"
    if globalData.slotRunData.isPortrait then
        path = "Activity/csd/EasterSeason_mainUI/EasterSeason_mainUI_vertical/EasterSeason_mainUI_vertical_1.csb"
    end
    self:createCsbNode(path)
    self.ManGer = G_GetMgr(G_REF.Flower)
    self.m_data = G_GetMgr(G_REF.Flower):getData()
    self.config = G_GetMgr(G_REF.Flower):getConfig()
    self:initView()
end

function FlowerUnWaterLayer:initCsbNodes()
    self.sl_prossLabel = self:findChild("txt_putongp")
    self.gl_prossLabel = self:findChild("txt_goldp")
    self.wt_text1 = self:findChild("txt_desc1")
    self.wt_text2 = self:findChild("txt_desc2")
    self.wt_text3 = self:findChild("txt_desc3")
    self.sl_flower = self:findChild("node_flower1")
    self.gl_flower = self:findChild("node_flower2")
    self.node_nowt = self:findChild("Node_nowt")
    self.node_wt = self:findChild("Node_wt")
    self.node_end = self:findChild("Node_end")
    self.time_text = self:findChild("txt_time")
end

function FlowerUnWaterLayer:initView()
    self:registerListener()
    self:updataAll()
end

function FlowerUnWaterLayer:setTimer()
    local time = util_get_today_lefttime()
    local tt = util_count_down_str(time)
    self.time_text:setString(tt)
    self.timer_schedule =
            schedule(
            self,
            function()
               time = time - 1
               if time <= 0 then
                    if self.timer_schedule then
                        self:stopAction(self.timer_schedule)
                        self.timer_schedule = nil
                    end
                    self.m_data:setIsWateringDay()
                    self:updataAll()
               else
                    local tt1 = util_count_down_str(time)
                    self.time_text:setString(tt1)
               end
            end,
            1
    )
end

function FlowerUnWaterLayer:updataAll()
    local sl_result = self.m_data.silverResult
    local gl_result = self.m_data.goldResult
    if not sl_result or not gl_result then
        return
    end
    local sl_complete = sl_result.complete
    local gl_complete = gl_result.complete
    self:updataSilver(sl_result)
    self:updataGold(gl_result)
    self:checkWater(sl_complete,gl_complete)
end

function FlowerUnWaterLayer:updataSilver(_data)
    local sp_prl = self:findChild("sp_progress1")
    if _data.complete then
        sp_prl:setVisible(false)
    else
        sp_prl:setVisible(true)
    end
    local str = _data.kettleNum.."/7"
    self.sl_prossLabel:setString(str)
    if not self.sl_FlowerLayer then
        self.sl_FlowerLayer = util_createView("views.FlowerCode.FlowerItem",1)
        self.sl_flower:addChild(self.sl_FlowerLayer)
    else
        self.sl_FlowerLayer:updataItem(_data.complete)
    end
    local qipao_node = self:findChild("node_qipao1")
    if not self.sl_qipao then
        self.sl_qipao = util_createView("views.FlowerCode.FlowerQiPao",1)
        qipao_node:addChild(self.sl_qipao)
    end
end

function FlowerUnWaterLayer:updataGold(_data)
    local sp_prl = self:findChild("sp_progress2")
    if _data.complete then
        sp_prl:setVisible(false)
    else
        sp_prl:setVisible(true)
    end
    local str = _data.kettleNum.."/7"
    self.gl_prossLabel:setString(str)
    if not self.gl_FlowerLayer then
        self.gl_FlowerLayer = util_createView("views.FlowerCode.FlowerItem",2)
        self.gl_flower:addChild(self.gl_FlowerLayer)
    else
        self.gl_FlowerLayer:updataItem(_data.complete)
    end
    local qipao_node = self:findChild("node_qipao2")
    if not self.gl_qipao then
        self.gl_qipao = util_createView("views.FlowerCode.FlowerQiPao",2)
        qipao_node:addChild(self.gl_qipao)
    end
end

function FlowerUnWaterLayer:checkWater(complete1,complete2)
    if complete1 and complete2 then
        --完成状态
        self.node_nowt:setVisible(false)
        self.node_wt:setVisible(false)
        self.node_end:setVisible(true)
        if self.timer_schedule then
            self:stopAction(self.timer_schedule)
            self.timer_schedule = nil
        end
    elseif self.m_data:getIsWateringDay() then
        --浇水日
        self.node_nowt:setVisible(false)
        self.node_wt:setVisible(true)
        self.node_end:setVisible(false)
        if not self.timer_schedule then
            self:setTimer()
        end
        --self.ManGer:sendReward()
    else
        --初始
        self.node_nowt:setVisible(true)
        self.node_wt:setVisible(false)
        self.node_end:setVisible(false)
    end
end

function FlowerUnWaterLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(sender, _type)
            self:updataQipao(_type)
        end,
        self.config.EVENT_NAME.ITEM_CLICK_GIFT
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _type)
            local qipao_node1 = self:findChild("node_qipao1")
            local qipao_node2 = self:findChild("node_qipao2")
            if self.sl_qipao and not tolua.isnull(self.sl_qipao) then
                qipao_node1:removeChild(self.sl_qipao)
            end
            if self.gl_qipao and not tolua.isnull(self.gl_qipao) then
                qipao_node2:removeChild(self.gl_qipao)
            end
            local view = util_createView("views.FlowerCode.FlowerWaterLayer",_type)
            self:addChild(view)
        end,
        self.config.EVENT_NAME.ITEM_CLICK_WATER
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _type)
            self:updataAll()
        end,
        self.config.EVENT_NAME.NOTIFY_REWARD_BIG
    )

    gLobalNoticManager:addObserver(
        self,
        function(sender, _type)
            --新手引导暂时去掉，代码不删，没准哪天就加回来了
            --self:openGuide()
        end,
        self.config.EVENT_NAME.NOTIFY_FLOWER_GUIDE
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, _index)
            if _index > 2 then
                self:resetGuideNode()
                local qipao_node1 = self:findChild("node_qipao2")
                local qipao_node2 = self:findChild("node_qipao1")
                util_changeNodeParent(qipao_node1:getParent(), qipao_node1, qipao_node1:getZOrder())
                util_changeNodeParent(qipao_node2:getParent(), qipao_node2, qipao_node2:getZOrder())
                self.sl_FlowerLayer:setBtnTouch(true)
                self.gl_FlowerLayer:setBtnTouch(true)
            else
                self:setOpenGuide(_index)
            end
        end,
        self.config.EVENT_NAME.NOTIFY_UNWATER_GUIDE
    )
end

function FlowerUnWaterLayer:updataQipao(_type)
    local qipao_node = self:findChild("node_qipao".._type)
    if _type == 1 then
        self:setQiPaoV(self.sl_qipao,qipao_node,_type)
    else
        self:setQiPaoV(self.gl_qipao,qipao_node,_type)
    end
end

function FlowerUnWaterLayer:setQiPaoV(layer,layer_parent,_type)
    if layer and not tolua.isnull(layer) then
        local staus = layer:getStatus()
        if staus then
            layer:showAction()
        else
            layer:showEnd()
            layer = nil
        end
    else
        local view = util_createView("views.FlowerCode.FlowerQiPao",_type)
        layer_parent:addChild(view)
        view:showAction()
        if _type == 1 then
            self.sl_qipao = view
        else
            self.gl_qipao = view
        end
    end
end

function FlowerUnWaterLayer:clickStartFunc(sender)
end

function FlowerUnWaterLayer:clickFunc(sender)
    local name = sender:getName()
end

function FlowerUnWaterLayer:openGuide()
    if not self.m_data:getIsGuide() then
        return
    end
    self.sl_FlowerLayer:setBtnTouch(false)
    self.gl_FlowerLayer:setBtnTouch(false)
    self.guideLayer = util_createView("views.FlowerCode.FlowerGuideLayer",1)
    local guide1 = self:findChild("node_guide1")
    local guide2 = self:findChild("node_guide2")
    local stepRefNodes = {guide1,guide2,self:findChild("node_guide3"),self:findChild("node_guide4"),self:findChild("node_guide5")}
    self.guideLayer:setGuideRefNodes(stepRefNodes)
    self.ManGer:sendWaterGuide("main")
end

function FlowerUnWaterLayer:setOpenGuide(_index)
    local sp_prl = self:findChild("sp_progress1")
    local sp_grl = self:findChild("sp_progress2")
    if _index == 1 then
       self.guide_data = {}
       self:setGuideDate(sp_prl)
       self:setGuideDate(sp_grl)
    elseif _index == 2 then
        self:resetGuideNode()
        self.guide_data = {}
        self:setGuideDate(self.node_nowt)
        self:setGuideDate(self.node_wt)
    end
end

function FlowerUnWaterLayer:setGuideDate(node)
     local item = {}
     item.node = node
     item.zorder = node:getZOrder()
     item.parent = node:getParent()
     item.pos = cc.p(node:getPosition())
     table.insert(self.guide_data, item)
     local wordPos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
     node:setPosition(wordPos)
     self:changeGuideNodeZorder(node,ViewZorder.ZORDER_GUIDE + 3)
end

function FlowerUnWaterLayer:changeGuideNodeZorder(node, zorder)
    local newZorder = zorder and zorder or ViewZorder.ZORDER_GUIDE + 1
    util_changeNodeParent(gLobalViewManager:getViewLayer(), node, newZorder)
    local currLayerScale = self:findChild("root"):getScale()
    node:setScale(currLayerScale)
end

function FlowerUnWaterLayer:resetGuideNode()
    if #self.guide_data > 0 then
        for i,v in ipairs(self.guide_data) do
            util_changeNodeParent(v.parent, v.node, v.zorder)
            v.node:setPosition(v.pos)
            v.node:setScale(1)
        end
    end
end

return FlowerUnWaterLayer