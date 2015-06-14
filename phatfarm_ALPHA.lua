--[[ 
*** phatfarm - (cp) 2015 phat34 ***
[ Thanxs to all the gw2ca Deities for the incredible API]
[ ...for profit in your GW2 Gaming!!! ]
]]--

include("ClosestWayPointToXYZ.lua") --modified for phatfarm

--Global Definitions Start
timer = false
qm = 0
clwp = ClosestWayPointToXYZ
rtTrig = false
nodeAgent = nil
nodeState = false
lenemy = nil
lenemyPos = WorldPos(0, 0, 0)
lmove = nil
prtlmove = WorldPos(0, 0, 0)
movState = 0
weaponState = 1
battleState = 0
refreshState = 0
RefreshPos = WorldPos(0, 0, 0)
wpState = 0
skipRf = false
minutes = 0
ReLoop = 0
TELE = false
TELEcords = WorldPos(0, 0, 0)
--Global Definitions End

--function clwp( aPos , aMvOpt ) -- shortcut (not needed)
  -- local pos , distance = ClosestWayPointToXYZ( aPos , aMvOpt )
  --return pos , distance
-- end

function GetWP()
debug("Getting Closest WP!")
   local currTable = Client:GetPoiMgr():GetWaypoints(Client:GetMapId())
   local wpId
   local count = 0
   local myDist = 100000
   Pos = agentMgr:GetOwnAgent():GetPosition()
   for v in currTable do
      count = count + 1
      euDist = GetEuclideanDistance(Pos, v.pos)
      if euDist < myDist then
         myDist = euDist
         wpState = count
         wpId = v
      end
   end
   debug("Closest Current WP -> ",wpState, " GW2 ID -> ",wpId.id, "***")
   return wpState , wpId.id
end


function NextNode()
   StillInBattle()
   if battleState == 1 or ((nodeState and (refreshState ~=0 )) == true) then return end
   clnode,dist,nodeAgent = clNodeXYZ()
   if dist < 3000 then
      lmove = clnode
      nodeState = true
      if dist > 100 then
         print("New Node id: " .. nodeAgent:GetAgentId() .. " at " .. tostring(nodeAgent:GetPosition()))
         mv(clnode)
      elseif dist < 10 then
         myPos = agentMgr:GetOwnAgent():GetPosition()
         navMgr:SetTarget(myPos,7,0)
      else
         navMgr:SetTarget(clnode,7,0)
      end
   else
      nodeState = false
      nodeAgent = nil
      Client:GetAgentMgr():RemoveTrigger(AgentMgr.OnAgentSpawned, agSpawned)
      Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentSpawned, agSpawned)
      if lmove ~= nil then
         mv( lmove )
      end
   end
end

function highestAggroInRange(aRange)
   local lPos = agentMgr:GetOwnAgent():GetPosition()
   local lhAggro = 0
   local lagentAggro = 0
   if aRange == nil then 
      aRange = 2500
   end
   agentTable = GetCharacters()
   for v in agentTable do
      if v:GetAttitude() == 1 then
         dist = GetEuclideanDistance( lPos , v:GetPosition() )
         if dist <= aRange then
            lagentAggro = cc:GetAggroValue(v)
            if lagentAggro > lhAggro then
               lhAggro = lagentAggro
            end
         end   
      end
   end
   return lhAggro
end

function closestFoeToXYZ(aPos)
   local agentAttitude_ = { " Friendly ", " Hostile ", " Neutral " , " UnAttackable " }
   local clAgId = nil
   local myDist = 100000
   if aPos == nil then 
      aPos = agentMgr:GetOwnAgent():GetPosition()
   end
   agentTable = GetCharacters()
   for v in agentTable do
      if v:GetAttitude() == 1 then
         euDist = GetEuclideanDistance( aPos , v:GetPosition() )
         if euDist < myDist then
            myDist = euDist
            clAgId = v
         end
      end
   end
   if myDist == 100000 then myDist = 0 end
   return clAgId , myDist
end

function GetCharacters()
   return Client:GetAgentMgr():GetAgentsByFilter(function(agent)
   return agent:GetType() == AgentBase.Type.Character end)
end

function agSpawned(ag)
   if ag==nil then return end
   local toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
   if toonDead then clwp(nil, "Dead") end
   Client:GetAgentMgr():RemoveTrigger(AgentMgr.OnAgentSpawned, agSpawned)
   if Client:GetAgentMgr():GetOwnAgent():GetAgentId() == ag:GetAgentId() then
      print("New Respawn")
      Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentKilled, resurectToon)
      if lmove==nil then
         local nm , dist = ncWP()
         mv ( nm )
      else
         mv ( lmove )
      end
   end
   if ag:GetType() == AgentBase.Type.Gadget then
      if ag:GetResourceType() ~= AgentGadget.ResourceType.None then
         print("new node id: " .. ag:GetAgentId() .. " at " .. tostring(ag:GetPosition()))
         nodeAgent = ag
         nodeState = true
         lmove = ag:GetPosition()
         mv(ag:GetPosition())
      else
         nodeState = false
      end
   else
      nodeState = false
   end
end

function clNodeXYZ( aPos )
   --[[ by -> Phat34 ]]
   local clndDist = 100000
   local euDist
   local ncWPCords
   local nAgent
   local validNodePos
   if aPos == nil then 
      aPos = Client:GetAgentMgr():GetOwnAgent():GetPosition()
   end
   local tNodes = agentMgr:GetAgentsByFilter(function(agent)
      return agent:GetType() == AgentBase.Type.Gadget;
   end)
   for v in tNodes do
      local closestNodePos = v:GetPosition()
      local validNodePos = navMgr:GetClosestValidPos(closestNodePos)
      if GetEuclideanDistance(closestNodePos, validNodePos) < 100 then
         euDist = GetEuclideanDistance(aPos, validNodePos)
         if euDist < clndDist and v:IsGatherable() then 
            clndDist = euDist
            nodeCords = v:GetPosition()
            nAgent = v
         end
      end
   end
   return nodeCords , clndDist , nAgent
end

function gadgetCollected(ag)
   if ag == nil or ag ~= nodeAgent then
      skipRf = false
      return
   end
   if check(ag) then
      if not ag:IsGatherable() then
         print("node depleted. id: " .. ag:GetAgentId())
         nodeAgent = nil
         nodeState = false
         if nodeState == false then
            local nm , dist = ncWP()
            mv ( nm )
         end
      end
   else
      nodeState = false
   end
   skipRf = false
end

function UseGadget()
   local chkNodeCords
   local chkDist
   local chkNodeAgent
   chkNodeCords,chkDist,nodeAgent = clNodeXYZ()
   if chkDist > 100 and chkDist < 250 then
      print("In Range of Node")
   end
   local nodemove = chkNodeCords
   if nodeAgent ~= nil and check(nodeAgent) and nodeState then
      local okGather =  nodeAgent:IsGatherable()
      if nodeState == false then
         nodeState = true
         navMgr:SetTarget(nodemove,7,0)
      end
      if okGather then
         print("...at Node")
         lmove = nodemove
         skipRf = true
         Client:GetTimer():RegisterTrigger(function() 
           farm()
         end, 2000, 0)
         Client:GetTimer():RegisterTrigger(function() 
           farm()
         end, 5000, 0)
         Client:GetTimer():RegisterTrigger(function() 
            farm()
         end, 10000, 0)
      else
         nodeAgent = nil
         print ("Ok to Gather -> ",okGather)
         nodeAgent = nil
         nodeState = false
         local nm , dist = clwp( nil )
         lmove = nm
         sleep(5)
         navMgr:SetTarget ( nm, 7, 0 )
      end
   else
      local nm , dist = ncWP( nil )
      lmove = nm
      --print("No Node!")
      sleep(5)
      navMgr:SetTarget ( nm, 7, 0 )
   end
end

function farm()
   if nodeAgent ~= nil and check(nodeAgent) then
      okGather =  nodeAgent:IsGatherable()
      if okGather and nodeState == true then
         Client:GetControlledCharacter():Interact(nodeAgent)
      else
         nodeAgent = nil
         nodeState = false
         if okGather == false then
            local nm , dist = ncWP(nil)
            mv ( nm )
         end
      end
   else
      nodeState = false
   end
end

function TakeLoot(loot,lootAg)
   print("NW- take loot " .. tostring(loot) .. "  " .. tostring(puLoot));
end

function PickupLoot(loot)
   if loot==nil then return end
   print("Picking Up Item: " .. tostring(loot))
   puLoot = loot
   Client:GetLootMgr():RegisterTrigger(LootMgr.OnLootDisplayed,TakeLoot)
   loot:OpenLoot(true)
end

function TestGather()
   local toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
   if toonDead then clwp(nil, "Dead") end
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentHealthChange, OnAgentHealthChange)
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentRevived, agSpawned)
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnGadgetCollected, gadgetCollected)
   Client:GetLootMgr():RegisterTrigger(lootMgr.OnLootDisplayed,TakeLoot)
   Client:GetLootMgr():RegisterTrigger(lootMgr.OnLootDropped,PickupLoot)
   Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnTargetReached, UseGadget)
   Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnAbort, OnAbort)
   Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnStopped, botStopped)
   GetWP()
   Client:GetTimer():RegisterTrigger(Refresh, 3000, 0)
   NextNode()
   if nodeState == false then
      local nm , dist = ncWP(nil)
      mv ( nm )
   end
end

function Refresh()
   Client:GetTimer():RegisterTrigger(Refresh, 15000, 0)
   qm = qm + 1
   if battleState == 1 then
      if qm >= 4 then
         qm = 0 
      end   
      StillInBattle()
      aattack()
      return
   end
   if TELE == true and nodeState == false then
      rtTrig = true
      rt()
      print("Teleporting...")
      lmove = TELEcords
      Client:GetTimer():RegisterTrigger(function() Client:GetNavigationMgr():Teleport(TELEcords) end, 5000, 0)
      TELE = false
      sleep(10)
      return
   end
   NextNode()
   if qm < 4 then
      return
   else
      qm = 0  
      minutes = minutes + 1
      clnode,dist,RFnodeAgent = clNodeXYZ()
      if dist < 3000 then
         nodeState = true
         return
      else
         local toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
         if toonDead then
             print("Toon Died - Rezing")
             clwp(nil, "Dead")
         end
         if minutes >= 6 and battleState == 0 and nodeState == false then
            print("Switching Waypoints")
            minutes = minutes - 6
            refreshState = 1
            weaponState = 1
            movState = 0
            nodeAgent = 0
            NextWP()
            if ReLoop == 1 then NextWP() end
         end  
         local NewPos = agentMgr:GetOwnAgent():GetPosition()
         if GetEuclideanDistance(RefreshPos,NewPos) < 300 and skipRf ~= true then
            refreshState = refreshState + 1
            if refreshState == 1 then
               if GetEuclideanDistance(RefreshPos,NewPos) > 100 then
                  refreshState = refreshState -1
               end
               mv( lmove )
            else
               if refreshState == 2 then
                  if GetEuclideanDistance(lmove,NewPos) < 100 then
                     local nm, dist = clwp(nil)
                     if navMgr:SetTarget(nm,7,0) ~= true then
                        local nm, dist = ncWP(nil)
                        mv( nm )
                        refreshState = refreshState - 1
                     else
                        refreshState = refreshState - 2   
                     end
                     lmove = nm
                  else   
                     if navMgr:SetTarget( lmove, 7, 0) ~= true then
                        local nm , dist = ncWP(nil)
                        --navMgr:SetTarget( nm, 0,0 0)
                        mv( nm )
                        lmove = nm
                        refreshState = refreshState - 1
                     else
                        refreshState = refreshState - 2   
                     end
                  end
               end
               if refreshState == 3 then
                  refreshState = 0
                  if battleState == 0 then
                     NextWP()
                     if ReLoop == 1 then NextWP() end
                  end
               end   
            end
         end
      end
      skipRf = false
      RefreshPos = NewPos
   end
end

function NextWP()
   debug("Function NextWP!")
   local currTable = Client:GetPoiMgr():GetWaypoints(Client:GetMapId())
   local NumWps = currTable:size()
   local count = 0
   ReLoop = 0
   for v in currTable do
      count = count + 1
      if count == wpState + 1 and Client:GetPoiMgr():IsContested(v.id) ~= true then
         debug("New Waypoint in ~ 15 seconds-> ",count, " GW2 ID -> ",v.id, "***")
         wpState = wpState + 1
         if wpState > NumWps then wpState = 1 end
         rtTrig = true
         rt()
         TELE = true
         TELEcords = v.pos
         movState = 0
         weaponState = 1
         nodeAgent = nil
         return
      elseif count == wpState and Client:GetPoiMgr():IsContested(v.id) == true then
         wpState = wpState + 1
         if wpState > NumWps then
            wpState = 1
            ReLoop = 1
         end
      end
   end
end 

function OnAbort()
    print("On Abort ---")
    nodeAgent = nil
    rtTrig = true
    rt()
    local nm, dist = clwp(nil)
    if nm ~= nil then
       lmove = nm
       if not Client:GetNavigationMgr():SetTarget(nm,7,0) and battleState==0 then
          print("Nav Manager Error")
          nodeAgent = nil
          CauseRestart()
       end
    else
       weaponState = 1
       nodeState = false
       return false
    end
end

local function AcceptItem(i)
   return true;
end

function ncWP( aPos )
   --[[ by -> Phat34 ]]
   nodeAgent = nil
   local ncWPDist = 100000
   local euDist
   local ncWPCords
   if aPos == nil then 
      aPos = Client:GetAgentMgr():GetOwnAgent():GetPosition()
   end
   local currTable = Client:GetPoiMgr():GetWaypoints(Client:GetMapId())
   for v in currTable do
      euDist = GetEuclideanDistance(aPos, v.pos)
      if euDist > 1000 and euDist < ncWPDist and Client:GetPoiMgr():IsContested(v.id) ~= true then 
         ncWPDist = euDist
         ncWPCords = v.pos
      end
   end
   return ncWPCords , ncWPDist
end

function OnAgentHealthChange(agent, deltaHealth, source)
   battleState = 1
   if agent==nil or source==nil then return end
   local myid = agentMgr:GetOwnAgent():GetAgentId()
   local agentid = agent:GetAgentId()
   local srcagentid = source:GetAgentId()
   if myid == srcagentid then return end
   lenemy = source
   lenemyPos = source:GetPosition()
   rtTrig = true
   rt()
   health = Client:GetAgentMgr():GetOwnAgent():GetHealth()
   maxhealth = Client:GetAgentMgr():GetOwnAgent():GetMaxHealth()
   if maxhealth - health > 500 then Heal() end
   aattack()
   if health < 275 then
      print("Teleporting to Closest Waypoint to avoid certain doom!")
      rtTrig = true
      rt()
      nodeAgent = nil
      local pos , dist = clwp(nil,"Tele")
      lmove = pos
      battleState = 0
      weaponState = 1
      nodeState = false
      movState = 0
      Client:GetTimer():RegisterTrigger(function() mv(pos) end, 5000, 0)     
   end
   cc:RegisterTrigger(ControlledCharacter.OnAggroChange, OnAggroChange)
end

function aattack()
   if weaponState==1 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Weapon1)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(2) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==2 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Utility1)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(10) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==3 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Weapon2)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(1) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==4 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Weapon3)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(4) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==5 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Weapon5)
      weaponState = weaponState + 1
   elseif weaponState==6 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Weapon1)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(2) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==7 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Utility1)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(3) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==8 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Utility3)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(4) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==9 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Profession1)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(7) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==10 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Profession2)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(1) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==11 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Profession3)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(2) end, 3000, 0)
      weaponState = weaponState + 1
   elseif weaponState==12 then
      Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Profession4)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(3) end, 3000, 0)
      Client:GetTimer():RegisterTrigger(function() delayedAttack(4) end, 6000, 0)
      weaponState = 1
   end
   if lenemy == nil or check(lenemy) == false then return end
   if lenemy:GetType() == 0 then
      if lenemy:IsDead() == false then
         StillInBattle()
      else
         resurectToon(lenemy)
         StillInBattle()
      end
   end
   sleep(2)         
end

function delayedAttack(aAttack)
   if aAttack == nil then aAttack = 1 end
   if aAttack == 1 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Weapon1)
   elseif aAttack == 2 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Weapon2)
   elseif aAttack == 3 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Weapon3)
   elseif aAttack == 4 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Weapon4)
   elseif aAttack == 5 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Weapon5)
   elseif aAttack == 6 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Utility1)
   elseif aAttack == 7 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Utility2)
   elseif aAttack == 8 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Utility3)
   elseif aAttack == 9 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Utility4)
   elseif aAttack == 10 then
      cc:UseSkillbarSlot(GW2.SkillSlot.Elite)
   end
end

function StillInBattle()
   if battleState == 1 then
      local lhAgrInRange = highestAggroInRange()
      if lhAgrInRange == 0 then
         --print("No Aggro")
         battleState = 0
         rtTrig = true
         rt()
         movState = 0
      end
   end
end

function OnAggroChange(agent, amount)
   lenemy = agent
   if agent==nil or amount==nil then return end
   if amount <= 0 then
      battleState = 0
      rtTrig = true
      rt()
      mv(lmove)
   end
end

function Heal()
   Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Heal)
end

function botStopped()
   print ("Bot Stopped??")
   if battleState > 0 then
      aattack()
   else
      --mv(lmove)
   end
end

function init()
   debug("P34-BotInit")
   navMgr = Client:GetNavigationMgr()
   lootMgr = Client:GetLootMgr()
   agentMgr = Client:GetAgentMgr()
   cc = Client:GetControlledCharacter()
   Client:RegisterTrigger(Gw2Client.OnWorldReveal, TestGather)
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentKilled, resurectToon)
   Client:GetTimer():RegisterTrigger(function() pc() end, 5000, 0)
end

function mv(pos)
   StillInBattle()
   if battleState == 1 then return end
   if pos == nil then return end
   if pos ~= prtlmove and prtlmove ~= nil  then
      local dist = GetEuclideanDistance(pos,prtlmove)
      if dist > 100 then
         print ("Moving to -> ", pos)
         lmove = pos
         prtlmove = pos
         rtTrig = true
         rt()
         sleep()
      end   
      local canMv = Client:GetNavigationMgr():SetTarget(pos,7,0)
      if canMv == false then
         --print("canMv == False")
         return rndMove()
      else
         movState = 0
         return canMv
      end
   end
end

function rndMove()
   myPos = agentMgr:GetOwnAgent():GetPosition()
   local nPos = myPos
   print(lmove , "Move State -> " .. movState)
   if movState == 1 then
      local nPos = WorldPos( myPos.x - 500 , myPos.y - 500 , myPos.z - 20 )
   elseif movState == 2 then
      local nPos = WorldPos( myPos.x + 500 , myPos.y - 500 , myPos.z - 20 )
   elseif movState == 3 then
      local nPos = WorldPos( myPos.x + 500 , myPos.y + 500 , myPos.z - 20 )
   elseif movState == 4 then
      local nPos = WorldPos( myPos.x - 500 , myPos.y + 500 , myPos.z - 20 )
   elseif movState == 5 then
      movState = 0
      return OnAbort()
   end
   if nPos ~= nil then 
      nm = navMgr:GetClosestValidPos(nPos)
      prtlmove = nm
      --print(nm)
      movState = movState + 1
      if nm ~= nil then
         local canMv = navMgr:SetTarget(nm,7,0)
         if canMv then
            sleep(20)
            movState = 0
            lmove = WorldPos(lmove.x + myPos.x - nPos.x , lmove.y + myPos.y - nPos.y , lmove.z - 30)
            print("Re-Trying move to - " .. tostring(lmove))
            lmove = navMgr:GetClosestValidPos(lmove)
            sleep(20)
            canMv = navMgr:SetTarget(lmove,10,0)
            if canMv then
               movState = 0
            else
               nm,dist = clwp(nPos)
               mv(nm)
               sleep(20)
            end
         end
         return canMv
      end
   else
      prtlmove = agentMgr:GetOwnAgent():GetPosition()
      Client:GetTimer():RegisterTrigger(function() mv(lmove) end, 3000, 0)
   end   
end

function sleep(time)
   timer = false
   if time == nil then time = 1 end
   Client:GetTimer():RegisterTrigger(pause, time * 500 , 0)
   if timer == false then
      delay1()
   end
end

function delay1()
   if timer == false then
      Client:GetTimer():RegisterTrigger(delay2, 100 , 0)
   end
end

function delay2()
   if timer == false then
      Client:GetTimer():RegisterTrigger(delay1, 100 , 0)
   end
end

function pause()
   timer = true
end

function rt()
   Client:GetNavigationMgr():RemoveTarget()
end

function pc(cname)
   if cname == nil or cname == "" then
      cname = "Juldia Chillstreak"
   end
   Client:PlayCharacter(cname)
end

function CauseRestart()
   local firstrun = true
   while true do
      if firstrun then
         print("Trap Delay to Error.Restart")
         firstrun = false 
      end
   end
end
