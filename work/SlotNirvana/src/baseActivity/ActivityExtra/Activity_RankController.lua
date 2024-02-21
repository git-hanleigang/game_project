
-- 排行榜数据管理器

local Activity_RankController = class("Activity_RankController")

function Activity_RankController:ctor( activity_ref )
    self.activity_ref = activity_ref
    assert(self.activity_ref, "Activity_RankController 创建失败")
end

function Activity_RankController:getRefData()
    local act_data = G_GetActivityDataByRef(self.activity_ref)
    if act_data and act_data:isRunning() then
        return act_data
    end
end

function Activity_RankController:setData( data )
    self.data = data
end

function Activity_RankController:setRankWidget( lb_rank )
    self.lb_rank = lb_rank
    assert(self.lb_rank, "setRankWidget")
end

function Activity_RankController:setCoinWidget( lb_coin )
    self.lb_coin = lb_coin
end

function Activity_RankController:start()
    local act_data = self:getRefData()
    if act_data then
    else
        self.lb_coin:setString("0")
        self.lb_rank:setString("NO RANK")
    end
end

function Activity_RankController:remove()
    
end

return Activity_RankController