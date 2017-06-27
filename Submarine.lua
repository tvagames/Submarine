--------------------
-- 潜水オプション
--------------------
ALTITUDE = -300 -- 巡行高度（深度）
ABOVE_TERRAIN = 30 --地形からの距離
TERRAIN_RANGE = 200 -- 何mまで先の地形を検知するか
CRUISE_ANGLE = 10 -- 巡行時の調整角度
MAX_ANGLE = 40 -- 最大角度

--------------------
-- 周回レーダーブイ軌道オプション
--------------------
AROUND_RADAR_BUOY_ENABLED = true -- 周回レーダーブイ機能を有効にするか否か
HEIGHT_OFFSET = 100 -- 目標の頭上何mを回るか
AROUND_DISTANCE = 200 -- 周回半径

--------------------
-- 周回レーダーブイ自爆用オプション
--------------------
RADAR_BUOY_AI_MAINFRAME = 0 -- レーダーブイのAIチャンネル
DETONATE_BY_TIME = false -- 時間経過で自爆するかどうか
REGULATOR_COUNT = 3 -- ミサイルのRegulatorの数
FUEL_TANK = 5 -- ミサイルのFuel tankの数
TPS = 50 -- Variable ThrusterのThrust per second
TANK_CAPA = 5000
DETONATE_IN_WATER = false -- 水没したら自爆するかどうか

DEBUG = 1

--------------------
-- 0～360を-180～180に変換（オイラー）
--------------------
function ZeroOrigin(a)
  if a == 0 then
    return 0
  end
  return ((a + 180) % 360) - 180
end

--------------------
-- ラディアンをオイラー角に変換
--------------------
function ToEulerAngle(radian)
  return radian * Mathf.Rad2Deg
end

--------------------
-- 範囲内に丸める
--------------------
function Clamp(val, min, max)
  if val < min then
    return min
  elseif val > max then
    return max
  else
    return val
  end
end

-------------------
-- ハイドロフォイル操作
--------------------
function SetHydrofoils(I, atcual, target)
  count = I:Component_GetCount(8) -- hydrofoils
  for index = 0, count - 1, 1 do
    c = I:Component_GetBlockInfo(8,index)
    com = c.LocalPositionRelativeToCom
    angle = target - atcual
    if com.z > 0 then
      -- 前の方
      I:Component_SetFloatLogic(8,index, -angle)
    else
      -- 後ろの方
      I:Component_SetFloatLogic(8,index, angle)
    end
  end
end

-------------------
-- エアポンプ操作
--------------------
function SetAirPump(I, isActive)
  count = I:Component_GetCount(2) -- air pump
  for index = 0, count - 1 , 1 do
    I:Component_SetFloatLogic(2,index,isActive)
  end
end


--------------------
-- ピッチ調整
--------------------
function AdjuastPitch(I, atcual, target)
  angle = Clamp(target, -MAX_ANGLE, MAX_ANGLE)
  SetHydrofoils(I, atcual, angle)
end


--------------------
-- レーダーブイ周回
--------------------
function AroundRardarBuoy(I, targetPosition)
  targetPosition.y = targetPosition.y + HEIGHT_OFFSET
  fuelTime = FUEL_TANK * TANK_CAPA / TPS
  lifeTime = Mathf.Min(fuelTime, 60 + REGULATOR_COUNT * 180)
  time = I:GetTime()
  transCount = I:GetLuaTransceiverCount()
  for transIndex = 0, transCount - 1, 1 do
    mc = I:GetLuaControlledMissileCount(transIndex)
    for mi = 0, mc - 1, 1 do
      m = I:GetLuaControlledMissileInfo(transIndex,mi)
      if DETONATE_BY_TIME and m.TimeSinceLaunch > lifeTime then
        if DEBUG then
          I:LogToHud("レーダーブイ寿命につき自爆。生存時間は" .. m.TimeSinceLaunch .. "秒でした")
        end
        I:DetonateLuaControlledMissile(transIndex,mi)
      elseif DETONATE_IN_WATER and m.Position.y < 0 then
        -- 水没したら自爆
        if DEBUG then
          I:LogToHud("レーダーブイ水没につき自爆。生存時間は" .. m.TimeSinceLaunch .. "秒でした")
        end
        I:DetonateLuaControlledMissile(transIndex,mi)
      else
        mpos = m.Position
        mpos.y = targetPosition.y
        -- 目標から見たミサイルへのベクトル
        v = mpos - tp 
        vn = v.normalized
        p = Quaternion.Euler(0, 45, 0) * vn
        aimpos = tp + (p * AROUND_DISTANCE)
        I:SetLuaControlledMissileAimPoint(transIndex,mi,aimpos.x,targetPosition.y,aimpos.z)
      end
    end
  end
end


--------------------
-- FromTheDepths
--------------------
function Update(I)
  I:ClearLogs()

  pos = I:GetConstructPosition()
  alt = pos.y
  tc = I:GetNumberOfTargets(0)
  dim = I:GetConstructMaxDimensions()
  fvec = I:GetConstructForwardVector()
  terrain = I:GetTerrainAltitudeForPosition(pos)
  distance = 0
  for i = 0, TERRAIN_RANGE, 1 do
    temp = I:GetTerrainAltitudeForPosition(pos + (fvec * (dim.z + i)))
    if temp > terrain then
      terrain = temp
      distance = i
    end
  end
  pitch = ZeroOrigin(I:GetConstructPitch())

  if DEBUG then
    I:Log(MAX_ANGLE)
  end

  angle = 0
  pump = -1
  if DEBUG then
    I:Log("alt"..alt .. ", " .. terrain .. ", "  .. dim.z)
  end

  if alt - ABOVE_TERRAIN < terrain  then
    -- 地形が近いので浮上
    angle = -ToEulerAngle(Mathf.Atan2(terrain + ABOVE_TERRAIN - alt, distance))
    pump = 1
    if DEBUG then
      I:LogToHud("地形が近いので浮上" .. pitch .. ", " .. angle)
    end
  elseif alt < ALTITUDE then
    -- 沈みすぎたので浮上
    angle = -CRUISE_ANGLE
    pump = 1
    if DEBUG then
      I:LogToHud("沈みすぎたので浮上" .. pitch .. ", " .. angle)
    end
  elseif tc > 0 and alt > ALTITUDE then
    -- 敵がいるので急速潜航
    angle = MAX_ANGLE
    pump = 0
    if DEBUG then
      I:LogToHud("敵がいるので急速潜航" .. pitch .. ", " .. angle)
    end
  elseif alt > ALTITUDE then
    -- 浮きすぎたので沈降
    angle = CRUISE_ANGLE
    pump = 0
    if DEBUG then
      I:LogToHud("浮きすぎたので沈降" .. pitch .. ", " .. angle)
    end
  else
    -- まっすぐ
    angle = 0
  end

  angle = Clamp(angle, -MAX_ANGLE, MAX_ANGLE)
  AdjuastPitch(I, pitch, angle)
  if pump >= 0 then
    SetAirPump(I, pump)
  end


  -- レーダーブイ操作
  if AROUND_RADAR_BUOY_ENABLED and I:GetNumberOfTargets(RADAR_BUOY_AI_MAINFRAME) > 0 then
    -- 敵がいるとき
    ti = I:GetTargetInfo(RADAR_BUOY_AI_MAINFRAME, 0)
    tp = ti.Position
    AroundRardarBuoy(I, tp)
  end

end
