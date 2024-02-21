local LeftFrameGuideTips = class("LeftFrameGuideTips", util_require("base.BaseView"))

function LeftFrameGuideTips:initUI()

    self:createCsbNode("LeftFrame/LeftFrameDragGuideTips_2.csb")
    self.m_nums = nums
    self:runCsbAction("show",true)
end

function LeftFrameGuideTips:addMask(  )
    local mask =  util_newMaskLayer()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch( function(event)
        if not isTouch then
            return true
        end
        if event.name == "ended" then
            print("LeftFrameGuideTips:addMask  ended ~~~ 应该移除这个layer")
            self:removeFromParent()
        end
        
        return true
    end, false, false)

    performWithDelay(self,function()
        isTouch = true
    end,0.5)

    self.m_mask  = mask
    gLobalViewManager:getViewLayer():addChild(self.m_mask,ViewZorder.ZORDER_GUIDE)
end


function LeftFrameGuideTips:onEnter(  )
end


function LeftFrameGuideTips:onExit()
    if self.m_mask then
        self.m_mask:removeFromParent()
    end
end
return LeftFrameGuideTips