local SidekicksStdCfg_honor = class("SidekicksStdCfg_honor")

function SidekicksStdCfg_honor:ctor(_data)
    self._level = _data.level or 0 -- 系统等级
    self._needExp = _data.exp or 0 -- 升级到下一级需要的经验
    self._coe = _data.coe or 0 -- 获得道具加成
end

function SidekicksStdCfg_honor:getLevel()
    return self._level
end
function SidekicksStdCfg_honor:getNextLvExp()
    return self._needExp
end
function SidekicksStdCfg_honor:getCoe()
    return self._coe
end

return SidekicksStdCfg_honor