--[[ 
*** phatfarm - (cp) 2015 phat34 ***
[ Thanxs to all the gw2ca Deities for the incredible API]
[ ...for profit in your GW2 Gaming!!! ]
]]--

--include("ClosestWayPointToXYZ.lua") --modified for phatfarm an added to main program code
function GlobalDef()
--Global Definitions Start
--OTR = false --On Target Reached State
timer = true
qm = 0
--clwp = ClosestWayPointToXYZ
rtTrig = false
nodeAgent = nil
nodeState = false
lenemy = nil
myPos = WorldPos(0, 0, 0)
lenemyPos = WorldPos(0, 0, 0)
lmove = nil
prtlmove = WorldPos(0, 0, 0)
movState = 0
buMoveState = 0
weaponState = 1
abortState = 0
battleState = 0
refreshState = 0
RefreshPos = WorldPos(0, 0, 0)
wpState = 0
skipRf = false
minutes = 0
ReLoop = 0
TELE = false
TELEcords = WorldPos(0, 0, 0)
retreat = 500
--Global Definitions End
end

--function clwp( aPos , aMvOpt ) -- shortcut (not needed)
   --local pos , distance = ClosestWayPointToXYZ( aPos , aMvOpt )
   --return pos , distance
--end

function clwp( aPos, aMvOpt ) --ClosestWayPointToXYZ()
--[[ by -> Phat34 ]]
   --nodeAgent = nil
   local closestWP = 100000
   local euDist
   local clCords
   local clULWPID
   local result
   if aPos == nil then 
      aPos = Client:GetAgentMgr():GetOwnAgent():GetPosition()
   end
   local currTable = Client:GetPoiMgr():GetWaypoints()
   for v in currTable do
      if aMvOpt ~= "Dead" and aMvOpt ~= "Next" then 
         euDist = GetEuclideanDistance(aPos, v.pos)
         if euDist < closestWP then 
            closestWP = euDist
            clCords = v.pos
         end
      elseif v.locked == false and aMvOpt ~= "Next" and Client:GetPoiMgr():IsContested(v.id) ~= true then
         euDist = GetEuclideanDistance(aPos, v.pos)
         if euDist < closestWP then 
            closestWP = euDist
            clCords = v.pos
            clULWPID = v.id
         end
      elseif aMvOpt == "Next" and v.locked == true then --Opens Locked WayPoint / Next
         euDist = GetEuclideanDistance(aPos, v.pos)
         if euDist < closestWP then 
            closestWP = euDist
            clCords = v.pos
         end
      end
   end
   if aMvOpt == nil or aMvOpt == "None" then
      return clCords , closestWP
   elseif aMvOpt == "Walk" then
      Client:GetNavigationMgr():SetTarget(clCords,0,0)
      return clCords , closestWP
   elseif aMvOpt == "Tele" then
      Client:GetNavigationMgr():Teleport(clCords)
      return clCords , closestWP
   elseif aMvOpt == "Next" then
      if closestWP == 100000 then 
         debug ("All Way Points On This Map UnLocked!")
      else 
         Client:GetNavigationMgr():SetTarget(clCords,0,0)
         return clCords , closestWP
      end
   elseif aMvOpt == "Dead" then
      result = Client:GetPoiMgr():UseWaypoint(clULWPID)
      if result ~= PoiMgr.WaypointError.Success then
         information("Failed to use Waypoint with id " .. clULWPID)
      end
      return clCords , closestWP
   end
end

function GetEuclideanDistance(pt1, pt2)
   if pt1 == nil or pt2 == nil then
      return 0
   end
   return math.sqrt((pt1.x - pt2.x)^2 + (pt1.y - pt2.y)^2 + (pt1.z - pt2.z)^2)
end

function resurectToon(agent)
   if agent == nil then return end
   local wpDist
   if Client:GetAgentMgr():GetOwnAgent():GetAgentId() == agent:GetAgentId() then
      Client:GetAgentMgr():RemoveTrigger(AgentMgr.OnAgentKilled, resurectToon)
      local mePos = Client:GetAgentMgr():GetOwnAgent():GetPosition()
      information ( "      My Position:" , mePos )
      Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentSpawned, agSpawned)
      local miAmi, wpDist = clwp( mePos, "Dead" )
      information ( "WayPoint Position:" , miAmi )
      information ( "Teleport Distance:" , wpDist)
      toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
      print ("My toon is dead? -> " .. tostring(toonDead))
      movState = 0
      weaponState = 1
      nodeAgent = nil
      NextNode()
   else
      if lenemy == nil then return end
      if check(agent) and check(lenemy) then
         if agent:GetAgentId() == lenemy:GetAgentId() then
            print("another one ( " .. agent:GetAgentId() .. " ) bites the dust!")
            battleState = 0
            rtTrig = true
            rt()
            movState = 0
            weaponState = 1
            nodeAgent = nil
            nodeState = false
            NextNode()
            mv(lmove)
         end
      end
   end
   weaponState = 1
end

function GetWP()
   debug("Getting Closest WP!")
   local currTable = Client:GetPoiMgr():GetWaypoints()
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
         TELEcords = v.pos
      end
   end
   debug("Closest Current WP -> ",wpState, " GW2 ID -> ",wpId.id, "***")
   return wpState , wpId.id
end


function NextNode()
   --   print("NextNode func()".." Timer ".. tostring(timer)) --"Last Move",lmove)
   StillInBattle()
   if not timer or battleState == 1 or ((nodeState and (refreshState ~=0 )) == true) then return end
   --   print("pass")
   myPos = agentMgr:GetOwnAgent():GetPosition()
   clnode,dist,nodeAgent = clNodeXYZ()
   --if check(nodeAgent) == false then return end
   if dist < 6500 then
      lmove = clnode
      nodeState = true
      if dist > 100 then
         print("New Node id: " .. nodeAgent:GetAgentId() .. " at " .. tostring(nodeAgent:GetPosition()))
         mv(clnode)
      elseif dist < 6 then
         navMgr:SetTarget(myPos,0,0)
      else
         navMgr:SetTarget(clnode,0,0)
      end
   else
      nodeState = false
      nodeAgent = nil
      Client:GetAgentMgr():RemoveTrigger(AgentMgr.OnAgentSpawned, agSpawned)
      Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentSpawned, agSpawned)
      buMoveState = buMoveState + 1
      if lmove ~= nil and buMoveState >= 3 then
         buMoveState = buMoveState - 3
         if battleState == 0 or abortState == 1 then
            abortState = 0
            print("...like this and like that, ya'll!")
            navMgr:SetTarget(lmove,0,0)
         end
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
   local nAgent
   local validVectorPath
   if aPos == nil then 
      aPos = Client:GetAgentMgr():GetOwnAgent():GetPosition()
   end
   local tNodes = agentMgr:GetAgentsByFilter(function(agent)
      return agent:GetType() == AgentBase.Type.Gadget;
   end)
   for v in tNodes do
      local closestNodePos = v:GetPosition()
      euDist = GetEuclideanDistance(aPos, closestNodePos)
      local zchk = math.sqrt((aPos.z - closestNodePos.z)^2)
      if euDist < 10000 and zchk < 1000 then
         local validVectorPath = Client:GetNavigationMgr():FindPath(aPos, closestNodePos, 0, 0, 0)
         if validVectorPath:size() < 15 then
            if euDist < clndDist and v:IsGatherable() then 
               clndDist = euDist
               nodeCords = v:GetPosition()
               nAgent = v
               print("Node " .. tostring(nAgent:GetAgentId()) .. " VVS -> " .. validVectorPath:size() .. " Distance " .. euDist)
            end
         end   
      end
   end
   return nodeCords , clndDist , nAgent
end

function gadgetCollected(ag)
   --print("Gadget Collected ", tostring(nodeAgent))
   if nodeAgent == nil or ag == nil then return end
   if check(nodeAgent) and check(ag) then
      if ag == nil or ag:GetAgentId() ~= nodeAgent:GetAgentId() then
         skipRf = false
         return
      end
      if not ag:IsGatherable() then
         print("node depleted. id: " .. ag:GetAgentId())
         nodeAgent = nil
         nodeState = false
         --if nodeState == false then
         local nm , dist = ncWP()
         mv ( nm )
         --end
      end
   else
      nodeState = false
   end
   skipRf = false
end

function UseGadget()
   --print("OTR")
   local chkNodeCords
   local chkDist
   local chkNodeAgent
   if nodeAgent ~= nil and check(nodeAgent) and nodeState then
      local okGather =  nodeAgent:IsGatherable()
      --navMgr:SetTarget(lmove,0,0)
      if okGather then
         print("...at Node")
         skipRf = true
         Client:GetTimer():RegisterTrigger(function() farm() end, 2000, 0)
         Client:GetTimer():RegisterTrigger(function() farm() end, 5000, 0)
         Client:GetTimer():RegisterTrigger(function() farm() end, 10000, 0)
      else
         print ("Ok to Gather -> ",okGather)
         nodeAgent = nil
         nodeState = false
         local nm , dist = clwp( nil )
         --print("OutThisWay")
         lmove = nm
         sleep(5)
         navMgr:SetTarget ( nm, 1, 0 )
      end
   else
      local nm , dist = ncWP( nil )
      lmove = nm
--      print("No Node!")
      sleep(5)
      navMgr:SetTarget ( nm, 1, 0 )
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
   print("PickingUp Item: " .. tostring(loot))
   puLoot = loot
   Client:GetLootMgr():RegisterTrigger(LootMgr.OnLootDisplayed,TakeLoot)
   loot:OpenLoot(true)
end

function TestGather()
   --Client:GetTimer():RegisterTrigger(function() trace("heartbeat") end,1000*60,1000*60)
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
   local currLevel = Client:GetAgentMgr():GetOwnAgent():GetScaledLevel() 
   retreat = currLevel * 30
   print("Retreating when Health is below " .. retreat .. " pips.")
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
   local toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
   if toonDead then
      print("Toon Died - Rezing")
      clwp(nil, "Dead")
      sleep(10)
   end
   if battleState == 1 then
      if qm >= 4 then
         debug("RF! " .. "nS-" .. tostring(nodeState) .. " rS-" .. refreshState .. " bS-" .. battleState .. " wS-" .. weaponState .. " nA-" .. tostring(nodeAgent) .. " " .. tostring(lmove) .. " " .. tostring(agentMgr:GetOwnAgent():GetPosition()))
         qm = 0 
      end   
      StillInBattle()
      if battleState > 0 then
         aattack()
      end
      return
   end
   if TELE == true and nodeState == false then
      rtTrig = true
      rt()
      sleep(10)
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
      debug("RF! " .. "nS-" .. tostring(nodeState) .. " rS-" .. refreshState .. " bS-" .. battleState .. " wS-" .. weaponState .. " nA-" .. tostring(nodeAgent) .. " " .. tostring(lmove) .. " " .. tostring(agentMgr:GetOwnAgent():GetPosition()))
      minutes = minutes + 1
      local toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
      if toonDead then
         print("Toon Died - Rezing")
         clwp(nil, "Dead")
         sleep(10)
      else
         if minutes >= 6 and battleState == 0 and nodeState == false then
            print("Switching Waypoints")
            minutes = minutes - 6
            refreshState = 1
            weaponState = 1
            movState = 0
            nodeAgent = nil
            nodeState = false
            NextWP()
            if ReLoop == 1 then NextWP() end
         end  
         local NewPos = agentMgr:GetOwnAgent():GetPosition()
         if GetEuclideanDistance(RefreshPos,NewPos) < 400 and skipRf ~= true then
            refreshState = refreshState + 1
            if refreshState == 1 then
               if GetEuclideanDistance(RefreshPos,NewPos) > 200 then
                  refreshState = refreshState -1
               else
                  prtlmove = RefreshPos
                  mv( lmove )
               end
            else
               if refreshState == 2 then
                  if GetEuclideanDistance(lmove,NewPos) < 200 then
                     local nm, dist = clwp(nil)
                     if navMgr:SetTarget(nm,1,0) ~= true then
                        local nm, dist = ncWP(nil)
                        prtlmove = RefreshPos
                        nodeState = false
                        nodeAgent = nil
                        mv( nm )
                     else
                        refreshState = refreshState - 2
                        prtlmove = TELEcords
                        nodeState = false
                        nodeAgent = nil
                        mv ( nm )   
                     end
                     lmove = nm
                  else   
                     if navMgr:SetTarget( lmove, 1, 0) ~= true then
                        local nm , dist = ncWP(nil)
                        prtlmove = TELEcords
                        nodeState = false
                        nodeAgent = nil
                        mv( nm )
                     else
                        refreshState = refreshState - 2
                        prtlmove = TELEcords
                        nodeState = false
                        nodeAgent = nil
                        mv ( nm )
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
   local currTable = Client:GetPoiMgr():GetWaypoints()
   local NumWps = currTable:size()
   local count = 0
   ReLoop = 0
   for v in currTable do
      count = count + 1
      if count == wpState + 1 and Client:GetPoiMgr():IsContested(v.id) ~= true then
         debug("New Waypoint in ~ 15 seconds-> ",count, " GW2 ID -> ",v.id, "***")
         wpState = wpState + 1
         if wpState > NumWps then wpState = 1 end
         TELE = true
         TELEcords = v.pos
         movState = 0
         weaponState = 1
         nodeAgent = nil
         nodeState = false
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
   local pos = TELEcords
   print("On Abort --- State - > " .. abortState)
   abortState = abortState + 1
   rtTrig = true
   rt()
   if abortState > 14 then
      init()
      return
   end
   local nm, dist = clwp(nil)
   if nm ~= nil then
      lmove = nm
      if not Client:GetNavigationMgr():SetTarget(nm,1,0) and battleState==0 and movState == 6 then
         print("Nav Manager Error")
         nodeAgent = nil
         movState = 0
         print("Teleporting to Current Waypoint")
         if navMgr:Teleport(pos) then
            refreshState = 0
            Client:GetTimer():RegisterTrigger(function() mv(pos) end, 6000, 0)
            abortState = 0
         end
         return true
      else
         weaponState = 1
         return false
      end
      weaponState = 1
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
   local currTable = Client:GetPoiMgr():GetWaypoints()
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
   if health < retreat then
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
   Client:GetControlledCharacter():RegisterTrigger(ControlledCharacter.OnAggroChange, OnAggroChange)
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
         print("No Aggro")
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
   if not rtTrig then
      print ("Bot Stopped??")
   end
   StillInBattle()
   if battleState > 0 then
      aattack()
   else
      abortState = 1
   end
end

function init()
   debug("LogoutToCharselect...")
   Client:LogoutToCharselect( )
   debug("** P34-BotInit")
   GlobalDef()
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
   if not timer or battleState == 1 then return end
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
      local canMv = Client:GetNavigationMgr():SetTarget(pos,1,0)
      if canMv == false then
         print("canMv == False")
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
   if movState == 2 then
      local nPos = WorldPos( myPos.x - 500 , myPos.y - 500 , myPos.z - 50 )
   elseif movState == 3 then
      local nPos = WorldPos( myPos.x + 500 , myPos.y - 500 , myPos.z - 50 )
   elseif movState == 4 then
      local nPos = WorldPos( myPos.x + 500 , myPos.y + 500 , myPos.z - 50 )
   elseif movState == 5 then
      local nPos = WorldPos( myPos.x - 500 , myPos.y + 500 , myPos.z - 50 )
   elseif movState == 6 then
      return OnAbort()
   end
   if nPos ~= nil then 
      nm = navMgr:GetClosestValidPos(nPos)
      prtlmove = nm
      print(nm)
      movState = movState + 1
      if movState == 1 then
         rtTrig = true
         rt()
         sleep(10)
         local pos = TELEcords
         prtlmove = pos
         Client:GetTimer():RegisterTrigger(function() navMgr:SetTarget(lmove,0,0) end, 5000, 0)
      end  
      if nm ~= nil then
         local canMv = navMgr:SetTarget(nm,1,0)
         if canMv then
            print("Re-Trying in 3ms - " .. tostring(lmove))
            lmove = navMgr:GetClosestValidPos(lmove)
            sleep(10)
            navMgr:SetTarget(lmove,1,0)
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
      Client:GetTimer():RegisterTrigger(delay2, 300 , 0)
   end
end

function delay2()
   if timer == false then
      Client:GetTimer():RegisterTrigger(delay1, 300 , 0)
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
      cname = "Your Char Name Here"
   end
   Client:PlayCharacter(cname)
end

function CauseRestart() -- Using init() to restart
   local firstrun = true
   while true do
      if firstrun then
         print("Cause.Restart") -- No Longer Fatal
         firstrun = false 
      end
   end
end
