function ClosestWayPointToXYZ( aPos, aMvOpt )
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
   local currTable = Client:GetPoiMgr():GetWaypoints(Client:GetMapId())
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
      elseif aMvOpt == "Next" and v.locked == true then --Closes Locked WayPoint / Next
         euDist = GetEuclideanDistance(aPos, v.pos)
         if euDist < closestWP then 
            closestWP = euDist
            clCords = v.pos
            -- clULWPID = v.id
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
      local miAmi, wpDist = ClosestWayPointToXYZ( mePos, "Dead" )
      information ( "WayPoint Position:" , miAmi )
      information ( "Teleport Distance:" , wpDist)
      toonDead = Client:GetAgentMgr():GetOwnAgent():IsDead()
      print ("My toon is dead? -> " .. tostring(toonDead))
      movState = 0
      weaponState = 1
      nodeAgent = nil
      NextNode()
      --if nodeState==false then
       --  local nm , dist = clwp(nil)
       --  mv ( nm )
      --end
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

function oldresetTrigs()
   Client:GetAgentMgr():RemoveTrigger(AgentMgr.OnAgentSpawned, resetTrigs)
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentKilled, resurectToon)
   print ("Reset/Spawned")
end

--function StartBot()
  -- print ("Bot Started")
  -- Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentKilled, resurectToon)
--end

--function init()
   -- debug("Test Function ClosestWayPointToXYZ")
   -- Client:RegisterTrigger(Gw2Client.OnWorldReveal,StartBot)
   --[[local mePos = Client:GetAgentMgr():GetOwnAgent():GetPosition()
   Client:GetAgentMgr():RegisterTrigger(AgentMgr.OnAgentKilled, resurectToon)]]
--end
