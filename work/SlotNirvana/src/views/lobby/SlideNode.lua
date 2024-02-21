--轮播图
local SlideNode = class("SlideNode", util_require("base.BaseView"))

function SlideNode:initUI(data)
    self:createCsbNode(data.p_slideImage)
    self:runCsbAction("idle",true)
    self.m_data = data
    self:initView()
    self:updateView()
end

function SlideNode:initView()
    
end
function SlideNode:updateView()
    
end

function SlideNode:onEnter()
    --刷新轮播图数据
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.UPDATE_SLIDEANDHALL_FINISH
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.NOTIFY_ACTIVITY_CLOSE
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updateView()
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function SlideNode:onExit(  )
    gLobalNoticManager:removeAllObservers(self)

end

-- 点击是否播点击音效
function SlideNode:isClickPlaySound()
    return false    
end 

return SlideNode