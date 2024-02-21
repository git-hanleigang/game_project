local GamePusherPropLoadingBarView = class("GamePusherPropLoadingBarView", util_require("base.BaseView"))

local PROGRESS_WIDTH = 87

function GamePusherPropLoadingBarView:initUI()

    local resourceFilename = "CoinCircus_wall_down.csb"
    self:createCsbNode(resourceFilename)

    self:runCsbAction("idle")

    self.m_progress = self:findChild("Node_8") 

    self:resetProgress()

end


function GamePusherPropLoadingBarView:resetProgress(_func)

    self:setBarPercent(0)
       
end

function GamePusherPropLoadingBarView:setBarPercent(_percent)

    self.m_progress:setPositionX(_percent * PROGRESS_WIDTH) 

end

function GamePusherPropLoadingBarView:onEnter()

end

function GamePusherPropLoadingBarView:onExit()


end

return GamePusherPropLoadingBarView