local LeftFrameGuideQiPao = class("LeftFrameGuideQiPao", util_require("base.BaseView"))

function LeftFrameGuideQiPao:initUI(nums)

    self:createCsbNode("LeftFrame/LeftFrameDragGuideTips_1.csb")
    self.m_nums = nums
    
    self:runCsbAction("start",false, function()
        self:runCsbAction("idle",true)
    end)
end

function LeftFrameGuideQiPao:addMask(  )
    local mask =  util_newMaskLayer()
    mask:setOpacity(0)
    local isTouch = false
    mask:onTouch( function(event)
        if not isTouch then
            return true
        end
        if event.name == "ended" then
            -- print("LeftFrameGuideQiPao:addMask  ended ~~~ 应该移除这个layer")
            -- self:removeFromParent()
        end
        
        return true
    end, false, false)

    performWithDelay(self,function()
        isTouch = true
    end,0.5)

    self.m_mask  = mask
    gLobalViewManager:getViewLayer():addChild(self.m_mask,ViewZorder.ZORDER_GUIDE)
end


function LeftFrameGuideQiPao:onEnter(  )
end


function LeftFrameGuideQiPao:onExit()
    if self.m_mask then
        self.m_mask:removeFromParent()
    end
end
return LeftFrameGuideQiPao