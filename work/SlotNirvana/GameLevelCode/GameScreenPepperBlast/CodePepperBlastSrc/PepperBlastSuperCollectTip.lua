local PepperBlastSuperCollectTip = class("PepperBlastSuperCollectTip", util_require("base.BaseView"))
--点击隐藏提示的节点
local hideClickNode = "Panel_1"

function PepperBlastSuperCollectTip:initUI()
    local csbName = "PepperBlastShoujitiaotip.csb"
    self:createCsbNode(csbName)
    
    local clickNode = self:findChild(hideClickNode)
    self:addClick(clickNode)
end

function PepperBlastSuperCollectTip:onEnter()
end

function PepperBlastSuperCollectTip:onExit()
end

function PepperBlastSuperCollectTip:ShowTip()
    if(not self:isVisible())then
        self:setVisible(true)
        self:runCsbAction("start",false,
            function()
                self:runCsbAction("idle",false)
            end
        )
    end
end
function PepperBlastSuperCollectTip:HideTip()
    if(self:isVisible())then
        self:runCsbAction("over",false,
            function()
                self:setVisible(false)
            end
        )
    end
end
function PepperBlastSuperCollectTip:clickFunc(sender)
    local name = sender:getName()

    if name == hideClickNode then
        self:HideTip()
    end
end


function PepperBlastSuperCollectTip:getTipSize()
    local bg = self:findChild("PepperBlast_tip_1")
    return bg:getContentSize()
end

return PepperBlastSuperCollectTip
