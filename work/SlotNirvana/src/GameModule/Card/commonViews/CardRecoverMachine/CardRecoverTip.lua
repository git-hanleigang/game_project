--[[-- 
    回收机第一个界面上方气泡
]]
local CardRecoverTip = class("CardRecoverTip", BaseView)

function CardRecoverTip:initUI()
    CardRecoverTip.super.initUI(self)
    self:initView()
end

function CardRecoverTip:getCsbName()
    return string.format(CardResConfig.commonRes.CardRecoverTip3Res, "common"..CardSysRuntimeMgr:getCurAlbumID())
end

function CardRecoverTip:initView()

    local mul = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_LOTTO_COIN_BONUS)
    if mul and mul > 0 then
        self:showStatueBuff()
    else
        self:showNormal()
    end

end

function CardRecoverTip:showNormal()
    self:runCsbAction("normal", false, nil, 60)
end

function CardRecoverTip:showStatueBuff()
    self:runCsbAction("buff", false, nil, 60)
end

function CardRecoverTip:onEnter()
    CardRecoverTip.super.onEnter(self)

    -- -- TODO:MAQUN 赛季结束发送消息刷新buff标签
    -- gLobalNoticManager:addObserver(self, function(target, params)
    --     self:initView()
    -- end, "CARD_SEASON_OVER")
end

function CardRecoverTip:onExit()
    CardRecoverTip.super.onExit(self)
end

return CardRecoverTip
