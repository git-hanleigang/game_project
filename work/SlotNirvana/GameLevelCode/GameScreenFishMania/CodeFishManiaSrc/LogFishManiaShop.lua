-- 商店打点

local NetworkLog = require "network.NetworkLog"
local LogFishManiaShop = class("LogFishManiaShop", NetworkLog)
LogFishManiaShop.m_modeName = ""
function LogFishManiaShop:ctor()
    NetworkLog.ctor(self)
    self.m_modeName = ""
end

-- 商店道具打点shop
function LogFishManiaShop:sendGameUILog(_type, _actionType, _pginfo,_num,_iInfo,_rewardCoins)

    gL_logData:syncUserData()
    gL_logData:syncEventData("GameUi")

    local log_data = {}
    log_data.tp = _type --[[ Shop=商店、Item=道具--]]
    log_data.atp = _actionType --[[Shop:Open=界面，Buy=道具购买，Get=道具置换；Item:Up=+,Down=-,Recovery=回收，Move=移动 --]]
    log_data.game = self.m_modeName --关卡名称
    log_data.pginfo = _pginfo --[[ {收集等級 level=1,当前积分 Points =1} --]]
    
    if _num then
        log_data.num = _num --购买道具消耗的积分
    end
    if _iInfo then
        log_data.iInfo = _iInfo --[[ {道具名称 name=1,道具所在等级页码 level =1} --]]
    end
    
    if _rewardCoins then
        log_data.rcu = _rewardCoins --[[ 奖励金币 --]]
    end
    gL_logData.p_data = log_data
    self:sendLogData()

end


return LogFishManiaShop
