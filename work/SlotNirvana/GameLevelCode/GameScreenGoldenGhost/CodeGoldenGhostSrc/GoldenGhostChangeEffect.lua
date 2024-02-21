
local GoldenGhostChangeEffect = class("GoldenGhostChangeEffect", util_require("base.BaseView"))

function GoldenGhostChangeEffect:onExit()
    self.m_machine.changeEffect = nil
end


function GoldenGhostChangeEffect:initUI()
    self.spinAni = util_spineCreate("GoldenGhost_guochang",true,true)
    self:addChild(self.spinAni)

    self.mask = util_createAnimation("GoldenGhost_Choose_dark.csb")
    self:addChild(self.mask,-1)
end

function GoldenGhostChangeEffect:setExtraInfo(machine)
    self.m_machine = machine
end

function GoldenGhostChangeEffect:play(midCallBack,endCallBack,actionReturn)
    local actionframeName = "actionframe"
    local actionTime = 100/30

    if actionReturn then
        actionframeName = "actionframe2"
        actionTime = 80/30
    end

    util_spinePlay(self.spinAni, actionframeName, false)
    util_spineEndCallFunc(self.spinAni, actionframeName,function ( ... )
        
        if endCallBack ~= nil then
            endCallBack()
        end

        performWithDelay(self,function ( )
            self:removeFromParent()
        end,0.1)
    end)

    performWithDelay(self,function ( ... )
        self.mask:playAction("start",false)
    end,10 / 60)

    performWithDelay(self,function ( ... )
        self.mask:playAction("over",false)

        if midCallBack ~= nil then
            midCallBack()
        end
    end, 30/30)


    -- performWithDelay(self,function ( ... )
    --     -- body
    --     if endCallBack ~= nil then
    --         endCallBack()
    --     end
    -- end, actionTime)
end


return GoldenGhostChangeEffect