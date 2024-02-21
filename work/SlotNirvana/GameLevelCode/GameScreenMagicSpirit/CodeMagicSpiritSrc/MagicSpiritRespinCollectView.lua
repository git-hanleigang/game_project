local MagicSpiritRespinCollectView = class("MagicSpiritRespinCollectView", util_require("base.BaseView"))

MagicSpiritRespinCollectView.perList = {12,22,32,41,51,61,70,80,91,100}
MagicSpiritRespinCollectView.lightMoveY = 485/100

function MagicSpiritRespinCollectView:initUI(data)
    self:createCsbNode("MagicSpirit_jindutiao.csb")

    self.m_machine = data.machine

    self.m_loadingBar = self:findChild("LoadingBar_1")
    self.m_loadLightNode = self:findChild("jindutiao_L") 
    local light = util_createAnimation("MagicSpirit_jindutiao_L.csb")
    self.m_loadLightNode:addChild(light)
    light:runCsbAction("idle",true)

    self.m_lb_count = self:findChild("m_lb_num_0")

    self:restCollectView()
end

function MagicSpiritRespinCollectView:onEnter()
end

function MagicSpiritRespinCollectView:onExit()
end

function MagicSpiritRespinCollectView:restCollectView()

    self.m_loadingBar:setPercent(0)
    self.m_loadLightNode:setVisible(false)
    self.m_lb_count:setString("0")
end

function MagicSpiritRespinCollectView:setCollectNum(_num )
    local isShowLightNode = _num >= 1

    self.m_loadLightNode:stopAllActions()
    self.m_loadLightNode:setVisible(isShowLightNode)

    local endPer = 0
    
    if isShowLightNode then
        endPer = self.perList[_num]
        self.m_loadLightNode:setPositionY(self.lightMoveY*endPer)
    end

    self.m_loadingBar:setPercent(endPer)

    self.m_lb_count:setString(tostring(_num))
end
--@_fun : reSpin继续滚动
function MagicSpiritRespinCollectView:updataCollectNum(_num, _fun)
    if _num > 10 then
        if  _fun then
            _fun()
        end
        return
    end

    --收集后进度条反馈动画
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle")
        --grand弹板
        if 10 == _num then
            self.m_machine:playGrandJueseAnim(_fun)
        else
            if  _fun then
                _fun()
            end
        end
    end)

    self.m_loadLightNode:stopAllActions()
  
    local endPer = self.perList[_num]
    schedule(self.m_loadLightNode,function(  )

        local oldPer = self.m_loadingBar:getPercent()

        if oldPer >= 1 then
            self.m_loadLightNode:setVisible(true)
        end

        if oldPer >= endPer then
            self.m_lb_count:setString(tostring(_num))
            self.m_loadLightNode:stopAllActions()
        else
            self.m_loadingBar:setPercent(oldPer + 1)
            self.m_loadLightNode:setPositionY(self.lightMoveY*(oldPer + 1))
        end
        
    end,0.05)

end

function MagicSpiritRespinCollectView:getCollectPos()
    local collectNode = self:findChild("m_lb_num_0")

    local pos = collectNode:getParent():convertToWorldSpace(cc.p(collectNode:getPosition()))
    return pos
end

function MagicSpiritRespinCollectView:getCollectFlyNode()
    return self:findChild("m_lb_num_0")
end

return MagicSpiritRespinCollectView
