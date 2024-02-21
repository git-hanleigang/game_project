local GamePusherRandomData = class("GamePusherRandomData", util_require("CoinCircusSrc.GamePusherData.GamePusherBaseActionData"))


function GamePusherRandomData:ctor(  )
    GamePusherRandomData.super.ctor(self)
end

--重写ActionData 拆分组装ActionData 初始化时候赋值 
function GamePusherRandomData:setActionData(_data)
    self.m_tRunningData.ActionData = _data
    self.m_tRunningData.ActionData.effectData = self.m_pGamePusherMgr:getRandomEffectData()
end

function GamePusherRandomData:getEffectCount(_sType)
    local effetDatas = self:getEffectDatas()
    return effetDatas[_sType]
end

function GamePusherRandomData:getEffectDatas()
    local data = self:getActionData()
    return data.effectData
end

function GamePusherRandomData:getEffectDataByType(_sType)
    local dataEffect = self:getEffectDatas()
    return dataEffect[_sType]
end

function GamePusherRandomData:reduceEffectDataCount(_sType)
    local effectData = self:getEffectDatas()
    effectData[_sType] = effectData[_sType] - 1
    
    for k,v in pairs(effectData) do
        if v > 0 then
            return
        end
    end
    self:setActionState(self.m_pConfig.PlayState.DONE)
end

return GamePusherRandomData