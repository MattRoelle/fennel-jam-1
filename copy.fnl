(local copy
       {:en
        {:upgrades
         {:shop! "Shop Inventory#plus 1"
          :gold! "plus 2 gold#per turn"
          :bump! "plus 1 to all#bump damage"
          :ability-dmg! "plus 1 to#all non-bump damage"
          :heal! "plus 1 to all heals"
          :shoot! "plus 1 to number of#projectiles fired#by shooters"
          :spawn! "plus 1 to number of#objects spawned#by spawners"}
         :units
         {:banker "BANKER#Gives +1/2/3 extra#gold per turn"
          :shooter "SHOOTER#Shoots... duh"
          :shopkeeper "SHOPKEEPER#Sell a unit#+HP to a random teammate"
          :fighter "FIGHTER#Really good at doinking"
          :mommer "MOMMER#Releases 2/4/6 lil'#doinks on death"
          :healer "HEALER#When bumps into a friend#Heal"
          :bomber "BOMBER#Periodically drop#1/2/3 bombs"
          :spinner "SPINNER#Has 1/2/3#rotating death balls"
          :sniper "SNIPER#Periodically snipes a#random enemy#1/2/3 time(s)"}
         :classes
         {:spawners "SPAWNERS#2 : +1 spawns to spawners#4 : +2 spawns to spawners#6 : +3 spawns to spawners"
          :bumpers "BUMPERS#2 : +1 bump dmg to bumpers#4: +2 bump dmg to bumpers#6: +3 bump dmg to bumpers"
          :shooters "SHOOTERS#2 : +1 projectile#4: +2 projectiles#6: +3 projectiles"
          :traders "TRADERS#2 : +1 gold per turn#4: +2 gold per turn#6: +3 gold per turn"}}})


(λ get-copy-str [lang category ...]
  (?. copy lang category ...))

{: copy
 : get-copy-str}
