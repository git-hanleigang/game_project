local GamePusherPropLoadingBarView = class("GamePusherPropLoadingBarView", util_require("base.BaseView"))

function GamePusherPropLoadingBarView:initUI()

    local resourceFilename = "CandyPusher_wall.csb"
    self:createCsbNode(resourceFilename)

    self.m_progress = self:findChild("LoadingBar_1") 

    self:resetBar( )
end

function GamePusherPropLoadingBarView:resetBar( )
    self:setBarPercent(1)
    local lab = self:findChild("m_lb_time")
    if lab then
        lab:setString("")
    end
end

function GamePusherPropLoadingBarView:setBarPercent(_percent)
    self.m_progress:setPercent(_percent * 100)
end

function GamePusherPropLoadingBarView:updateBarPercent(currTime,totalTime )

    local lab = self:findChild("m_lb_time")
    if totalTime and totalTime > 0 then
        self:setBarPercent(currTime/ totalTime)
        if lab then
            lab:setString( math.floor( currTime))
        end
    else
        self:resetBar( )
    end
    
    
end

return GamePusherPropLoadingBarView