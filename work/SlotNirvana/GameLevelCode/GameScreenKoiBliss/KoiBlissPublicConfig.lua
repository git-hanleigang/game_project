local KoiBlissPublicConfig = {}

KoiBlissPublicConfig.SoundConfig = {
    baseBgm = "KoiBlissSounds/sound_KoiBlis_baseBgm.mp3",-- CTS关卡-金鱼宝盆-Base配乐1.0(60,D)-05
    freeBgm = "KoiBlissSounds/sound_KoiBlis_freeBgm.mp3",--CTS关卡-金鱼宝盆-Free配乐1.0(109,Bm)-05
    pickBgm = "KoiBlissSounds/sound_KoiBlis_pickBgm.mp3",--CTS关卡-金鱼宝盆-Pick配乐1.0(196,D)-07
    rsBgm = "KoiBlissSounds/sound_KoiBlis_rsBgm.mp3",--CTS关卡-金鱼宝盆-Respin配乐1.0(123,D)-02
    collFK = "KoiBlissSounds/sound_KoiBlis_collFK.mp3",--WILD图标上方收集区反馈
    click = "KoiBlissSounds/sound_KoiBlis_click.mp3",--CTS关卡-金鱼宝盆-点击
    --连线
    base_winLine_1 = "KoiBlissSounds/sound_base_winLine_1.mp3",
    base_winLine_2 = "KoiBlissSounds/sound_base_winLine_2.mp3",
    base_winLine_3 = "KoiBlissSounds/sound_base_winLine_3.mp3",
    free_winLine_1 = "KoiBlissSounds/sound_free_winLine_1.mp3",
    free_winLine_2 = "KoiBlissSounds/sound_free_winLine_2.mp3",
    free_winLine_3 = "KoiBlissSounds/sound_free_winLine_3.mp3",
    --scatter落地
    scatter_buling_1 = "KoiBlissSounds/sound_KoiBlis_scatter_buling_1.mp3",
    scatter_buling_2 = "KoiBlissSounds/sound_KoiBlis_scatter_buling_2.mp3",
    scatter_buling_3 = "KoiBlissSounds/sound_KoiBlis_scatter_buling_3.mp3",

    music_KoiBliss_enter = "KoiBlissSounds/music_KoiBliss_enter.mp3",                               --进入关卡+Koi Fish Blessings
    sound_KoiBliss_shengji_1 = "KoiBlissSounds/sound_KoiBliss_shengji_1.mp3",                       --收集区1-2
    sound_KoiBliss_shengji_2 = "KoiBlissSounds/sound_KoiBliss_shengji_2.mp3",                       --收集区2-3
    sound_KoiBliss_shengji_3 = "KoiBlissSounds/sound_KoiBliss_shengji_3.mp3",                       --收集区1-3
    sound_KoiBliss_scatter_trigger = "KoiBlissSounds/sound_KoiBliss_scatter_trigger.mp3",           --BG里Scatter图标触发+Free Prize!
    sound_KoiBliss_baseToFree_guochang = "KoiBlissSounds/sound_KoiBliss_baseToFree_guochang.mp3",   --BG进入FG过场动画
    sound_KoiBliss_freeStart_show = "KoiBlissSounds/sound_KoiBliss_freeStart_show.mp3",             --FG开始弹板弹出
    sound_KoiBliss_freeStart_hide = "KoiBlissSounds/sound_KoiBliss_freeStart_hide.mp3",             --FG开始弹板收回
    sound_KoiBliss_door_trigger = "KoiBlissSounds/sound_KoiBliss_door_trigger.mp3",                 --开场触发开门
    sound_KoiBliss_door_show = "KoiBlissSounds/sound_KoiBliss_door_show.mp3",                       --开门动画
    sound_KoiBliss_bigWin_yuGao = "KoiBlissSounds/sound_KoiBliss_bigWin_yuGao.mp3",                 --大赢前预告中奖
    sound_KoiBliss_freeOver_show = "KoiBlissSounds/sound_KoiBliss_freeOver_show.mp3",               --FG结算弹板弹出+Rolling in it!
    sound_KoiBliss_freeOver_hide = "KoiBlissSounds/sound_KoiBliss_freeOver_hide.mp3",               --FG结算弹板收回
    sound_KoiBliss_freeToBase_guoChang = "KoiBlissSounds/sound_KoiBliss_freeToBase_guoChang.mp3",   --FG回到BG过场动画
    sound_KoiBliss_bonus_trigger = "KoiBlissSounds/sound_KoiBliss_bonus_trigger.mp3",               --Bonus图标触发+Gold Strikes！(free)
    sound_KoiBliss_bonus_trigger2 = "KoiBlissSounds/sound_KoiBliss_bonus_trigger2.mp3",             --Bonus图标触发+Leap to success(base)
    sound_KoiBliss_wenan_show = "KoiBlissSounds/sound_KoiBliss_wenan_show.mp3",                     --EACH WINS文案弹出
    sound_KoiBliss_bonus_collect = "KoiBlissSounds/sound_KoiBliss_bonus_collect.mp3",               --Bonus收集到上方EACH WINS反馈
    sound_KoiBliss_toRespin_guochang = "KoiBlissSounds/sound_KoiBliss_toRespin_guochang.mp3",       --进入RS过场动画
    sound_KoiBliss_rsStart_show = "KoiBlissSounds/sound_KoiBliss_rsStart_show.mp3",                 --RS开始弹板弹出
    sound_KoiBliss_rsStart_hide = "KoiBlissSounds/sound_KoiBliss_rsStart_hide.mp3",                 --RS开始弹板收回
    sound_KoiBliss_rsNum_update = "KoiBlissSounds/sound_KoiBliss_rsNum_update.mp3",                 --RS次数更新
    sound_KoiBliss_bonus_collect_fankui = "KoiBlissSounds/sound_KoiBliss_bonus_collect_fankui.mp3", --Bouns收集到上方collected栏反馈
    sound_KoiBliss_rsTotal_win = "KoiBlissSounds/sound_KoiBliss_rsTotal_win.mp3",                   --RS总奖金栏中奖
    sound_KoiBliss_rsOver_show = "KoiBlissSounds/sound_KoiBliss_rsOver_show.mp3",                   --RS结算弹板弹出+Fortune comes from all sides
    sound_KoiBliss_rsOver_hide = "KoiBlissSounds/sound_KoiBliss_rsOver_hide.mp3",                   --RS结算弹板收回
    sound_KoiBliss_respin_guochang = "KoiBlissSounds/sound_KoiBliss_respin_guochang.mp3",           --退出RS过场动画
    sound_KoiBliss_toPick_guochang = "KoiBlissSounds/sound_KoiBliss_toPick_guochang.mp3",           --进入多福多彩过场动画
    sound_KoiBliss_pick_click = "KoiBlissSounds/sound_KoiBliss_pick_click.mp3",                     --点击PICK反馈
    sound_KoiBliss_pick_Noclick_show = "KoiBlissSounds/sound_KoiBliss_pick_Noclick_show.mp3",       --未选中的翻转
    sound_KoiBliss_pick_jackpot = "KoiBlissSounds/sound_KoiBliss_pick_jackpot.mp3",                 --JP中奖
    sound_KoiBliss_jackpot_mini = "KoiBlissSounds/sound_KoiBliss_jackpot_mini.mp3",                 --JP弹板弹出+MINI JACKPOT!
    sound_KoiBliss_jackpot_minor = "KoiBlissSounds/sound_KoiBliss_jackpot_minor.mp3",               --JP弹板弹出+MINOR JACKPOT!
    sound_KoiBliss_jackpot_major = "KoiBlissSounds/sound_KoiBliss_jackpot_major.mp3",               --JP弹板弹出+MAJOR JACKPOT!
    sound_KoiBliss_jackpot_grand = "KoiBlissSounds/sound_KoiBliss_jackpot_grand.mp3",               --JP弹板弹出+GRAND JACKPOT!
    sound_KoiBliss_jump_coins = "KoiBlissSounds/sound_KoiBliss_jump_coins.mp3",                     --JP数字滚动
    sound_KoiBliss_jump_coins_end = "KoiBlissSounds/sound_KoiBliss_jump_coins_end.mp3",             --JP数字滚动结束音
    sound_KoiBliss_jackpot_hide = "KoiBlissSounds/sound_KoiBliss_jackpot_hide.mp3",                 --JP弹板收回
    sound_KoiBliss_pick_guochang = "KoiBlissSounds/sound_KoiBliss_pick_guochang.mp3",               --退出多福多彩玩法过场动画
    sound_KoiBliss_pick_again = "KoiBlissSounds/sound_KoiBliss_pick_again.mp3",                     --EXTRA GAME触发+Incredible 
    sound_KoiBliss_pick_reset = "KoiBlissSounds/sound_KoiBliss_pick_reset.mp3",                     --棋盘选项翻新
    sound_KoiBliss_bet_lock = "KoiBlissSounds/sound_KoiBliss_bet_lock.mp3",                         --BET锁定
    sound_KoiBliss_bet_unLock = "KoiBlissSounds/sound_KoiBliss_bet_unLock.mp3",                     --BET解锁
    sound_KoiBliss_bet_show = "KoiBlissSounds/sound_KoiBliss_bet_show.mp3",                         --玩法弹板弹出
    sound_KoiBliss_bet_hide = "KoiBlissSounds/sound_KoiBliss_bet_hide.mp3",                         --玩法弹板收回
    sound_KoiBliss_free_more = "KoiBlissSounds/sound_KoiBliss_free_more.mp3",                       --FG里Scatter图标触发+Free Prize!
    sound_KoiBliss_free_more_show = "KoiBlissSounds/sound_KoiBliss_free_more_show.mp3",             -- FGmore弹板弹出+收回More free games?
    sound_KoiBliss_free_num_add = "KoiBlissSounds/sound_KoiBliss_free_num_add.mp3",                 --FG次数增加
    sound_KoiBliss_respin_yuGao = "KoiBlissSounds/sound_KoiBliss_respin_yuGao.mp3",                 --RS预告中奖+Wow, you're gonna be rich
    sound_KoiBliss_free_yuGao = "KoiBlissSounds/sound_KoiBliss_free_yuGao.mp3",                     --FG预告中奖+Wow, you're gonna be rich
    sound_KoiBliss_yuGao_your_day = "KoiBlissSounds/sound_KoiBliss_yuGao_your_day.mp3",             --It's your day
    sound_KoiBliss_yuGao_good_luck = "KoiBlissSounds/sound_KoiBliss_yuGao_good_luck.mp3",           --Good luck
    sound_KoiBliss_wild_collect_up = "KoiBlissSounds/sound_KoiBliss_wild_collect_up.mp3",           --新增《WILD图标收集到上方》
    sound_KoiBliss_pick_collect_jp = "KoiBlissSounds/sound_KoiBliss_pick_collect_jp.mp3",           -- 新增《JP收集到上方+反馈》
    sound_KoiBliss_bonus_update_win = "KoiBlissSounds/sound_KoiBliss_bonus_update_win.mp3",         -- 新增《上方bonus won栏数字上涨》
    sound_KoiBliss_pick_trigger = "KoiBlissSounds/sound_KoiBliss_pick_trigger.mp3",                 -- 新增《触发多福多彩+I'm in charge of my life》
    sound_KoiBliss_collect_faker = "KoiBlissSounds/sound_KoiBliss_collect_faker.mp3",               -- CTS关卡-金鱼宝盆-上方收集区假动作
    sound_KoiBliss_collect_bonus_move = "KoiBlissSounds/sound_KoiBliss_collect_bonus_move.mp3",     -- CTS关卡-金鱼宝盆-bonus拖拽动画
}

KoiBlissPublicConfig.createGridNode = function(_size,_tarSp,_rect)
    local gridNode = cc.NodeGrid:create()
    local grid3d = cc.Grid3D:create(cc.size(_size.width,_size.height),gridNode:getGridRect())
    grid3d:setActive(true)
    grid3d:set2DProjection()
    gridNode:setGrid(grid3d)
    gridNode:setTarget(_tarSp)
    gridNode:addChild(_tarSp)
    return gridNode,grid3d
end

KoiBlissPublicConfig.fishRippleAction1 = function(_gridNode,_grid3d,_position,_radius,isOriginal)
    _grid3d:calculateVertexPoints()
    _gridNode:stopAllActions()

    if util_isLow_endMachine() then
        return
    end

    local gridNode = _gridNode
    local grid3d = _grid3d
    local size = grid3d:getGridSize()
    local addTime = 0
    local speed = 3
    local radius = _radius or 300;
    local wave = 1.2;
    local amplitude = 10;
    local position = _position ;
    local isOriginal2 = true
    
    util_schedule(gridNode, function()
        addTime = addTime + 0.01;
        for i=1,size.width  do
            for j=1,size.height do
                --
                local v = nil
                if isOriginal then
                    v = util_Grid3D_getOriginalVertex(grid3d,cc.p(i, j))
                else 
                    if isOriginal2 then
                        v = util_Grid3D_getVertex(grid3d,cc.p(i, j))
                    else
                        v = util_Grid3D_getOriginalVertex(grid3d,cc.p(i, j))
                    end
                end
                
                local vect = {}
                vect.x = _position.x - v.x
                vect.y = _position.y - v.y
                local r = math.sqrt(vect.x*vect.x + vect.y*vect.y) 
                if r < _radius then
                    local phaseShift =  radius - r * wave
                    local sinValue = math.sin(speed * math.pi  * addTime + phaseShift) 
                    local curZ = sinValue * amplitude
                    if vect.y > 0 then
                        curZ = curZ * 2.7
                    end
                    v.z =  v.z + curZ;
                    util_Grid3D_setVertex( grid3d,cc.p(i, j), v);
                end
            end 
        end
        isOriginal2 = false
    end, 1/30)

end

KoiBlissPublicConfig.fishRippleAction2 = function(_gridNode,_grid3d,_position,_radius)

    _grid3d:calculateVertexPoints()
    _gridNode:stopAllActions()
    local gridNode = _gridNode
    local grid3d = _grid3d
    local size = grid3d:getGridSize()
    local addTime = 0
    local speed = 3.2
    local radius = _radius or 300;
    local newRadius = 0;
    local wave = 0.1;
    local amplitude = 20;
    local position = _position ;
    
    util_schedule(gridNode, function()
        addTime = addTime + 0.03;

        for i=1,size.width  do
            for j=1,size.height do
                local v = util_Grid3D_getOriginalVertex(grid3d,cc.p(i, j));
                local vect = {}
                vect.x = _position.x - v.x
                vect.y = _position.y - v.y
                local r = math.sqrt(vect.x*vect.x + vect.y*vect.y) 
                if r < _radius then
                    newRadius = newRadius + 0.05
                    if newRadius > _radius then
                        newRadius = _radius  
                    end
                    local phaseShift =  (newRadius - r) * wave
                    local temp = speed * math.pi  * addTime + phaseShift
                    local sinValue = math.sin(temp) 
                    amplitude = amplitude - 0.01
                    if amplitude < 1 then
                        amplitude = 1
                    end
                    local curZ = sinValue * amplitude
                    if vect.y > 0 then
                        curZ = curZ * 2.7
                    end
                    v.z =  v.z + curZ;
                    util_Grid3D_setVertex( grid3d,cc.p(i, j), v);
                end
            end 
        end
    end, 1/30)

end

KoiBlissPublicConfig.fishRippleActionForRespin = function(_gridNode,_grid3d,_position)
    _grid3d:calculateVertexPoints()
    _gridNode:stopAllActions()
    local gridNode = _gridNode
    local grid3d = _grid3d
    local addTime = 0
    local newRadius = 0
    local i, j
    local _radius = 300
    local wave = 0.07
    local amplitude = 60
    local size = grid3d:getGridSize()
    util_schedule(gridNode, function()
        
        addTime = addTime + 0.07
        
        newRadius = newRadius + 15
        if newRadius > _radius then
            newRadius = _radius  
        end
        local totalNums = 0

        for i=1,size.width do
            for j=1,size.height do
                local v = util_Grid3D_getOriginalVertex(grid3d,cc.p(i, j));
                local r = cc.pGetDistance(_position,v)
                
                
                if r < newRadius then
                    totalNums = totalNums + 1
                    r = _radius - r 

                    local temp = addTime * math.pi  + r * wave
                    if temp >= 5 * math.pi then
                        temp = 0
                        totalNums = totalNums - 1
                    end
                    amplitude = amplitude - 0.005
                    if amplitude < 1 then
                        amplitude = 1
                    end
                    local sinNum = math.sin(temp)
                    local curZ = sinNum * amplitude
                    v.z = v.z + curZ;
                    util_Grid3D_setVertex( grid3d,cc.p(i, j), v);
                end
            end 
        end
        
        if totalNums == 0 and newRadius == _radius then
            _gridNode:stopAllActions()
        end
    end, 1/60)

end

KoiBlissPublicConfig.fishRippleActionForJackpot = function(_gridNode,_grid3d,_position)
    _grid3d:calculateVertexPoints()
    _gridNode:stopAllActions()
    local gridNode = _gridNode
    local grid3d = _grid3d
    local addTime = 0
    local newRadius = 0
    local i, j
    local _radius = 400
    local wave = 0.07
    local amplitude = 60
    local size = grid3d:getGridSize()
    util_schedule(gridNode, function()
        
        addTime = addTime + 0.07
        
        newRadius = newRadius + 25
        if newRadius > _radius then
            newRadius = _radius  
        end
        local totalNums = 0

        for i=1,size.width do
            for j=1,size.height do
                local v = util_Grid3D_getOriginalVertex(grid3d,cc.p(i, j));
                local r = cc.pGetDistance(_position,v)
                
                
                if r < newRadius then
                    totalNums = totalNums + 1
                    r = 200 - r 

                    local temp = addTime * math.pi  + r * wave
                    if temp >= 5 * math.pi then
                        temp = 0
                        totalNums = totalNums - 1
                    end
                    amplitude = amplitude - 0.005
                    if amplitude < 1 then
                        amplitude = 1
                    end
                    local sinNum = math.sin(temp)
                    local curZ = sinNum * amplitude
                    v.z = v.z + curZ;
                    util_Grid3D_setVertex( grid3d,cc.p(i, j), v);
                end
            end 
        end
        
        if totalNums == 0 and newRadius == _radius then
            _gridNode:stopAllActions()
        end
    end, 1/60)

end

KoiBlissPublicConfig.selfRippleAction = function(_gridNode,_grid3d,_position)

    _grid3d:calculateVertexPoints()
    _gridNode:stopAllActions()
    local gridNode = _gridNode
    local grid3d = _grid3d
    -- local size = grid3d:getGridSize()
    local addTime = 0
    -- local speed = 3.2
    -- local radius = _radius or 300;
    -- local newRadius = 0;
    -- local wave = 0.07;
    -- local amplitude = 30;
    -- local position = _position ;
    
    util_schedule(gridNode, function()
        
        addTime = addTime + 0.1;
        local i, j;
        local _radius = 300;
        local wave = 0.07;
        local amplitude = 30;
        
        -- local _position = cc.p(display.width/2,display.height/2);
        for i=1,60 do
            for j=1,60 do
                local v = util_Grid3D_getOriginalVertex(grid3d,cc.p(i, j));
                local r = cc.pGetDistance(_position,v)
                if r < _radius then
                    r = _radius - r 

                    local temp = addTime * math.pi  + r * wave
                    if temp >= 5 * math.pi then
                        temp = 0
                    end
                    
                    local sinNum = math.sin(temp)
                    local curZ = sinNum * amplitude
                    v.z = v.z + curZ;
                    grid3d:setVertex(cc.p(i, j), v);
                end
    
                
            end 
        end
        

    end, 1/60)

end

KoiBlissPublicConfig.base = 0
KoiBlissPublicConfig.fs = 1
KoiBlissPublicConfig.rs = 2
KoiBlissPublicConfig.pick = 3

KoiBlissPublicConfig.collectNumTab = {20,50} -- wild 收集阶段

KoiBlissPublicConfig.fsStart = 1
KoiBlissPublicConfig.rsStart = 2
KoiBlissPublicConfig.pickStart = 3
KoiBlissPublicConfig.fsOver = 4
KoiBlissPublicConfig.rsOver = 5
KoiBlissPublicConfig.pickOver = 6

KoiBlissPublicConfig.wlildPlayId = {
    1,4,7,10,13,
    2,5,8,11,14,
    3,6,9,12,15,
} 

KoiBlissPublicConfig.fishZOrder = {
    top = 3,
    mid = 2,
    down = 1,

}
return KoiBlissPublicConfig