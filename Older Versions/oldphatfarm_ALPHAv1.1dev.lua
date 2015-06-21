--[[ 
*** phatfarm - (cp) 2015 phat34 ***
[ Thanxs to all the gw2ca Deities for the incredible API]
[ ...for profit in your GW2 Gaming!!! ]
]]--

include("ClosestWayPointToXYZ.lua") --modified for phatfarm

--Global Definitions Start
--OTR = false
timer = false
qm = 0
clwp = ClosestWayPointToXYZ
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
--reCurse = 0
skipRf = false
--frun = true
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
   --local NumWps = currTable:size()
   local wpId
   local count = 0
   local myDist = 100000
   Pos = agentMgr:GetOwnAgent():GetPosition()
   for v in currTable do
      count = count + 1
      --print(NumWps,v,count,wpState,Client:GetPoiMgr():IsContested(v.id))
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
   print("NN") --"Last Move",lmove)
   StillInBattle()
   if battleState == 1 or ((nodeState and (refreshState ~=0 )) == true) then return end
   print("pass")
   --if OTR == false then
      --OTR = true
      --Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnTargetReached, UseGadget)
   --end
   --print("RC",reCurse)
   --if reCurse == 1 then return end
   --reCurse = 1
   myPos = agentMgr:GetOwnAgent():GetPosition()
   clnode,dist,nodeAgent = clNodeXYZ()
   if dist < 6500 then
      lmove = clnode
      nodeState = true
      if dist > 100 then
         print("New Node id: " .. nodeAgent:GetAgentId() .. " at " .. tostring(nodeAgent:GetPosition()))
         mv(clnode)
      elseif dist < 6 then
         navMgr:SetTarget(myPos,2,0)
      else
         navMgr:SetTarget(clnode,2,0)
      end
         --myPos = agentMgr:GetOwnAgent():GetPosition()
         --navMgr:SetTarget(myPos)
         --navMgr:SetTarget(lmove,0,0)
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
            --prtlmove = myPos
            --mv( lmove )
         end
      end
   end
   --reCurse = 0
end

function highestAggroInRange(aRange)
   --Client:GetTimer():RegisterTrigger(closestFoeToXYZ, 15000, 0)
   --local agentAttitude_ = { " Friendly ", " Hostile ", " Neutral " , " UnAttackable " }
   --if aPos == nil then 
   local lPos = agentMgr:GetOwnAgent():GetPosition()
   local lhAggro = 0
   local lagentAggro = 0
   --end
   if aRange == nil then 
      aRange = 2500
   end
   agentTable = GetCharacters()
   for v in agentTable do
      if v:GetAttitude() == 1 then
         dist = GetEuclideanDistance( lPos , v:GetPosition() )
         --[[information( v:GetAgentId() .. agentAttitude_[ v:GetAttitude() + 1 ] 
             .. dist .. " " .. cc:GetAggroValue(v) ) ]]--
         if dist <= aRange then
            lagentAggro = cc:GetAggroValue(v)
            if lagentAggro > lhAggro then
               lhAggro = lagentAggro
            end
         end   
         --tostring(v:GetPosition()) .. " " ..
      end
   end
   return lhAggro
end

function closestFoeToXYZ(aPos)
   local agentAttitude_ = { " Friendly ", " Hostile ", " Neutral " , " UnAttackable " }
   local clAgId = nil
   --local count = 0
   local myDist = 100000
   if aPos == nil then 
      aPos = agentMgr:GetOwnAgent():GetPosition()
   end
   agentTable = GetCharacters()
   for v in agentTable do
      if v:GetAttitude() == 1 then
         euDist = GetEuclideanDistance( aPos , v:GetPosition() )
         --[[information( v:GetAgentId() .. agentAttitude_[ v:GetAttitude() + 1 ] 
             .. dist .. " " .. cc:GetAggroValue(v) ) 
           ]]--
         --tostring(v:GetPosition()) .. " " ..
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
      --Client:GetNavigationMgr():RegisterSingleshot(NavigationMgr.OnTargetReached, UseGadget)
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
         --print(tostring(ag) .. " node id: " .. ag:GetAgentId())
         nodeAgent = ag
         nodeState = true
         lmove = ag:GetPosition()
         --reCurse = 1
         --Client:GetNavigationMgr():RegisterSingleshot(NavigationMgr.OnTargetReached, UseGadget)
         mv(ag:GetPosition())
      else
         nodeState = false
         --NextNode()
      end
   else
      nodeState = false
      --NextNode()
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
   print("Gadget Collected ", tostring(nodeAgent))
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
         --reCurse = 0
         --NextNode()
         --Client:GetNavigationMgr():RegisterSingleshot(NavigationMgr.OnTargetReached, UseGadget)
         if nodeState == false then
            local nm , dist = ncWP()
            mv ( nm )
         end
      end
   else
      nodeState = false
      --reCurse = 0
      --NextNode()
   end
   skipRf = false
end

function UseGadget()
   print("OTR")
   --if movState > 0 then print("movState > 0") return end
   local chkNodeCords
   local chkDist
   local chkNodeAgent
   --if rtTrig then
   --   print("exit here")
   --   rtTrig = false
   --   return
   --end
   --chkNodeCords,chkDist,nodeAgent = clNodeXYZ()
   --if chkDist > 100 and chkDist < 250 then
   --   print("In Range of Node")
   --end
   --nodeAgent = chkNodeAgent
   --local nodemove = chkNodeCords
   --OTR = false
   --Client:GetNavigationMgr():RemoveTrigger(NavigationMgr.OnTargetReached, UseGadget)
   --navMgr:SetTarget(lmove,0,0)
   
   if nodeAgent ~= nil and check(nodeAgent) and nodeState then
      local okGather =  nodeAgent:IsGatherable()
      if nodeState == false then
         nodeState = true
         navMgr:SetTarget(lmove,0,0)
      end
      if okGather then
         --if not frun then
            print("...at Node")
         --else   
         --   frun = false
         --end
         --lmove = nodemove
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
         --nodeAgent = nil
         print ("Ok to Gather -> ",okGather)
         --print (okGather == nil )
         --print (okGather == "" )
         --pos = agentMgr:GetOwnAgent():GetPosition()
         --print ("Closest Agent -> " .. tostring(agentMgr:GetClosestAgentToPoint(pos)))
         --Client:GetLootMgr():RegisterTrigger(LootMgr.OnLootDisplayed,TakeLoot)
         nodeAgent = nil
         nodeState = false
         --Client:GetNavigationMgr():RegisterSingleshot(NavigationMgr.OnTargetReached, UseGadget)
         local nm , dist = clwp( nil )
         print("OutThisWay")
         lmove = nm
         sleep(5)
         navMgr:SetTarget ( nm, 2, 0 )
         --mv( nm )
      end
      --print("Test2")
      --Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnTargetReached, UseGadget)
   else
      --Client:GetNavigationMgr():RegisterSingleshot(NavigationMgr.OnTargetReached, UseGadget)
      local nm , dist = ncWP( nil )
      lmove = nm
      print("No Node!")
      sleep(5)
      navMgr:SetTarget ( nm, 2, 0 )
      --mv( nm )
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
            --Client:GetNavigationMgr():RegisterSingleshot(NavigationMgr.OnTargetReached, UseGadget)
            local nm , dist = ncWP(nil)
            mv ( nm )
         end
      end
   else
      nodeState = false
      --NextNode()
   end
end

function TakeLoot(loot,lootAg)
   print("NW- take loot " .. tostring(loot) .. "  " .. tostring(puLoot));
   --print("loot size " , loot:size())
   --print("lootAg size ", loogAg:size())
   --test = PickupLoot(loot)
   --lootMgr.AoeLoot() 
   --lootMgr:AoeLoot(puLoot)
   --for i in lootAg do
   -- for i , item in pairs(loot:GetItems()) do
   --if i() and AcceptItem(i) then
   --i = loot
   --printf("Taking Item: %i",i:GetItems());
   --loot:TakeItem(1,1)
   --end
   --end
   --for i in loot do
   --print("Taking Item: ", tostring(lootMgr:GetItems()))
   --loot:TakeItem(loot, lootAg)
   --Client:GetAgentMgr():RemoveTrigger(AgentMgr.OnAgentSpawned, agSpawned)
   --Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentSpawned, agSpawned)
   --end
end

--Client:GetNavigationMgr():SetTarget(33996.6, 8448.2, -855.729)


function PickupLoot(loot)
   if loot==nil then return end
   print("PickingUp Item: " .. tostring(loot))
   puLoot = loot
   Client:GetLootMgr():RegisterTrigger(LootMgr.OnLootDisplayed,TakeLoot)
   loot:OpenLoot(true)
   --Client:GetAgentMgr():RemoveTrigger(AgentMgr.OnAgentSpawned, agSpawned)
   --Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentSpawned, agSpawned)
   --Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentSpawned, agSpawned)
   --test = loot:GetItems()
   --print("PickingUp Item: " .. tostring(test))
   --loot:TakeItem()
   -- Client:GetLootMgr():RegisterTrigger(LootMgr.OnLootDisplayed,TakeLoot)
   --NextNode()
end

function TestGather()
   --Client:GetTimer():RegisterTrigger(function() trace("heartbeat") end,1000*60,1000*60)
   local toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
   if toonDead then clwp(nil, "Dead") end
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentHealthChange, OnAgentHealthChange)
   --Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentSpawned, agSpawned)
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentRevived, agSpawned)
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnGadgetCollected, gadgetCollected)
   Client:GetLootMgr():RegisterTrigger(lootMgr.OnLootDisplayed,TakeLoot)
   Client:GetLootMgr():RegisterTrigger(lootMgr.OnLootDropped,PickupLoot)
   Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnTargetReached, UseGadget)
   Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnAbort, OnAbort)
   Client:GetNavigationMgr():RegisterTrigger(NavigationMgr.OnStopped, botStopped)
   GetWP()
   --Client:GetTimer():RegisterTrigger(function() mv(pos) end, 5000, 0)
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
         debug("RF! " .. "nS-" .. tostring(nodeState) .. " rS-" .. refreshState .. " bS-" .. battleState .. " wS-" .. weaponState .. " nA-" .. tostring(nodeAgent) .. " " .. tostring(lmove) .. " " .. tostring(agentMgr:GetOwnAgent():GetPosition()))
         qm = 0 
      end   
      StillInBattle()
      aattack()
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
      end
      --clnode,dist,RFnodeAgent = clNodeXYZ()
      --if dist < 6500 then
      if nodeState == true then
         --NextNode()
         return
      else
         --StillInBattle()
         if minutes >= 6 and battleState == 0 and nodeState == false then
            print("Switching Waypoints")
            minutes = minutes - 6
            refreshState = 1
            weaponState = 1
            movState = 0
            --reCurse = 0
            nodeAgent = nil
            nodeState = false
            --if battleState == 0 then
            NextWP()
            if ReLoop == 1 then NextWP() end
            --end
         end  
         local NewPos = agentMgr:GetOwnAgent():GetPosition()
         --print (RefreshPos , NewPos)
         if GetEuclideanDistance(RefreshPos,NewPos) < 300 and skipRf ~= true then
            refreshState = refreshState + 1
            if refreshState == 1 then
               if GetEuclideanDistance(RefreshPos,NewPos) > 100 then
                  refreshState = refreshState -1
               else
               --navMgr:SetTarget(lmove,0,0)
                  prtlmove = RefreshPos
                  mv( lmove )
               end
            else
               if refreshState == 2 then
                  if GetEuclideanDistance(lmove,NewPos) < 100 then
                     local nm, dist = clwp(nil)
                     if navMgr:SetTarget(nm,2,0) ~= true then
                        local nm, dist = ncWP(nil)
                        prtlmove = RefreshPos
                        --navMgr:SetTarget(nm,0,0)
                        prtlmove = RefreshPos
                        mv( nm )
                        refreshState = refreshState - 1
                     else
                        refreshState = refreshState - 2
                        prtlmove = TELEcords
                        mv ( nm )   
                     end
                     lmove = nm
                  else   
                     if navMgr:SetTarget( lmove, 2, 0) ~= true then
                        local nm , dist = ncWP(nil)
                        --navMgr:SetTarget( nm, 0,0 0)
                        prtlmove = TELEcords
                        mv( nm )
                        lmove = nm
                        refreshState = refreshState - 1
                     else
                        refreshState = refreshState - 2
                        prtlmove = TELEcords
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
   local currTable = Client:GetPoiMgr():GetWaypoints(Client:GetMapId())
   local NumWps = currTable:size()
   local count = 0
   ReLoop = 0
   for v in currTable do
      count = count + 1
      --print(NumWps,v,count,wpState,Client:GetPoiMgr():IsContested(v.id))
      if count == wpState + 1 and Client:GetPoiMgr():IsContested(v.id) ~= true then
         debug("New Waypoint in ~ 15 seconds-> ",count, " GW2 ID -> ",v.id, "***")
         wpState = wpState + 1
         if wpState > NumWps then wpState = 1 end
         --rtTrig = true
         --rt()
         TELE = true
         TELEcords = v.pos
         movState = 0
         weaponState = 1
         nodeAgent = nil
         nodeState = false
         --reCurse = 0
         --NextNode()
         --if nodeState == false then
         --   local nm , dist = clwp(nil)
         --   mv ( nm )
         --end
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
    --nodeAgent = nil
    rtTrig = true
    rt()
    local nm, dist = clwp(nil)
    if nm ~= nil then
       lmove = nm
       if not Client:GetNavigationMgr():SetTarget(nm,2,0) and battleState==0 and movState == 6 then
          print("Nav Manager Error")
          nodeAgent = nil
          movState = 0
          print("Teleporting to Current Waypoint")
          --local pos , dist = clwp(nil,"Tele")
          local pos = TELEcords
          navMgr:Teleport(pos)
          prtlmove = pos
          refreshState = 0
          Client:GetTimer():RegisterTrigger(function() mv(pos) end, 6000, 0)
          --CauseRestart()
          --local pos , dist = clwp(nil,"Tele")
          --local pos , dist = clwp(nil)
          --Client:GetTimer():RegisterTrigger(function() mv(pos) end, 5000, 0)
          -- Go to last waypoint or try again later
       end
    else
       --movState = 0
       abortState = 1
       weaponState = 1
       --nodeState = false
       --NextNode()
       return false
    end
    --movState = 0
    --weaponState = 1
end

--[[ Client:GetNavigationMgr():SetTarget(14757.9, 16142.1, -394.471)]]

-- TODO: add item filters
local function AcceptItem(i)
   return true;
end
--[[
function TakeLoot(loot)
   print("take loot");
   for i in List(loot:GetFirstItem(),loot:GetLastItem()) do
   if i() and AcceptItem(i) then
   printf("Taking Item: %i",i:GetId());
   loot:TakeItem(i);
   end
   end
end

function OnLoot(loot)
   print("open loot");
   loot:OpenLoot(false);
end
function Initialize()
   Client:GetLootMgr():RegisterTrigger(LootMgr.OnLootDropped,"LootEngine.OnLoot");
   Client:GetLootMgr():RegisterTrigger(LootMgr.OnLootDisplayed,"LootEngine.TakeLoot");
end

]]

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
      --local pos , dist = clwp(nil)
      lmove = pos
      battleState = 0
      weaponState = 1
      nodeState = false
      movState = 0
      Client:GetTimer():RegisterTrigger(function() mv(pos) end, 5000, 0)     
   end
   --print("agentid=" .. agentid .. "; srcagentid=" .. srcagentid .. "; delta=" .. deltaHealth)
   Client:GetControlledCharacter():RegisterTrigger(ControlledCharacter.OnAggroChange, OnAggroChange)
end

function aattack()
   --print ("Weapon State -> ", weaponState)
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
   --local isEnemy = lenemy:IsMonster()
   if lenemy:GetType() == 0 then
      if lenemy:IsDead() == false then
         StillInBattle()
         --[[lenemyPos = lenemy:GetPosition()
         myPos = agentMgr:GetOwnAgent():GetPosition()
         if GetEuclideanDistance(myPos,lenemyPos) > 2000 then --or lenemy:IsDead() then
            battleState = 0
            rtTrig = true
            rt()
            movState = 0
            weaponState = 1
            nodeAgent = nil
            nodeState = false
            NextNode()
            if nodeState == false then
               local nm , dist = clwp(nil)
               mv ( nm )
            end ]] --
         --end
      else
         resurectToon(lenemy)
         StillInBattle()
         --battleState = 0
         --movState = 0
         --weaponState = 1
         --nodeAgent = nil
         --nodeState = false
         --NextNode()  
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

--[[function init()
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentHealthChange, OnAgentHealthChange)
end]]
function StillInBattle()
      if battleState == 1 then
         local lhAgrInRange = highestAggroInRange()
         --[[myPos = agentMgr:GetOwnAgent():GetPosition()
         if lenemy ~= nil and check(lenemy) ~= false then
            lenemyPos = lenemy:GetPosition()
         end
         if GetEuclideanDistance(myPos,lenemyPos) > 2000 then --or lenemy:IsDead() then ]]--
         if lhAgrInRange == 0 then
            print("No Aggro")
            battleState = 0
            rtTrig = true
            rt()
            movState = 0
            --weaponState = 1
            --navMgr:SetTarget( lmove, 0, 0 )
         end
            --[[ nodeAgent = nil
            nodeState = false
            NextNode()
            if nodeState == false then
               local nm , dist = clwp(nil)
               mv ( nm )
            end
         end ]]--
      end
end

function OnAggroChange(agent, amount)
   lenemy = agent
   if agent==nil or amount==nil then return end
   --if movState == 0 then
     --print(agent:GetAgentId() .. " has now " .. amount .. " aggro on you");
   --end
   if amount <= 0 then
      battleState = 0
      rtTrig = true
      rt()
      mv(lmove)
   end
end

function Heal()
   --local heal = 6
   Client:GetControlledCharacter():UseSkillbarSlot(GW2.SkillSlot.Heal)
end

function botStopped()
   print ("Bot Stopped??")
   if battleState > 0 then
      aattack()
   else
      abortState = 1
      --mv(lmove)
   end
   --local stopGadget = NextNode()
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
   --pc( "Juldia Chillstreak" )
end

function mv(pos)
   StillInBattle()
   --print(battleState,pos,prtlmove)
   if battleState == 1 then return end
   if pos == nil then return end
   if pos ~= prtlmove and prtlmove ~= nil  then
      local dist = GetEuclideanDistance(pos,prtlmove)
      if dist > 100 then
         print ("Moving to -> ", pos)
         --print("nS-",nodeState,"rS-",refreshState,"bS-",battleState,"nA-",nodeAgent,lmove,agentMgr:GetOwnAgent():GetPosition(),dist)
         lmove = pos
         prtlmove = pos
         rtTrig = true
         rt()
         sleep()
         --Client:GetNavigationMgr():RegisterSingleshot(NavigationMgr.OnTargetReached, UseGadget)
      end   
      local canMv = Client:GetNavigationMgr():SetTarget(pos,2,0)
      --[[Client:GetTimer():RegisterTrigger(function()
      canMv = Client:GetNavigationMgr():SetTarget(pos,0,0)
      end, 5000, 0)]]
      if canMv == false then
         print("canMv == False")
         return rndMove()
      else
         movState = 0
            --[[ rtTrig = true
            rt()
            Client:GetTimer():RegisterTrigger(function()
            canMv = Client:GetNavigationMgr():SetTarget((pos),0,0)
            end, 2000, 0)]]
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
      --movState = 0
      return OnAbort()
   end
   if nPos ~= nil then 
      nm = navMgr:GetClosestValidPos(nPos)
      prtlmove = nm
      print(nm)
      movState = movState + 1
      if movState == 1 then
         --refreshState = 0
         --myPos = navMgr:GetClosestValidPos(myPos) -- use last know valid pos instead
         rtTrig = true
         rt()
         sleep(10)
         local pos = TELEcords
         -- navMgr:Teleport(pos)
         prtlmove = pos
         Client:GetTimer():RegisterTrigger(function() navMgr:SetTarget(lmove,0,0) end, 5000, 0)
      end  
      if nm ~= nil then
         local canMv = navMgr:SetTarget(nm,2,0)
         if canMv then
            movState = 0
            print("Re-Trying in 3ms - " .. tostring(lmove))
            lmove = navMgr:GetClosestValidPos(lmove)
            sleep(10)
            navMgr:SetTarget(lmove,2,0)
         end
         return canMv
      end
   else
      prtlmove = agentMgr:GetOwnAgent():GetPosition()
      Client:GetTimer():RegisterTrigger(function() mv(lmove) end, 3000, 0)
   end   
end

function sleep(time)
   --print("...time delay Start")
   timer = false
   if time == nil then time = 1 end
   Client:GetTimer():RegisterTrigger(pause, time * 500 , 0)
   if timer == false then
      delay1()
   end
end

function delay1()
   if timer == false then
      --print("delay1")
      Client:GetTimer():RegisterTrigger(delay2, 100 , 0)
   end
end

function delay2()
   if timer == false then
      --print("delay2")
      Client:GetTimer():RegisterTrigger(delay1, 100 , 0)
   end
end

function pause()
   timer = true
   --print("Timer Delay End")
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



