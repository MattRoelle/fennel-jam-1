{:upgrades
 {:shop! {}
  :gold! {}
  :reroll! {}
  :bump! {}
  :ability-dmg! {}
  :heal! {}
  :shoot! {}
  :spawn! {}}
 :unit-types
 ;; tier 99, spawns
 {:lildoink
  {:tier 99 
   :defense 1
   :classes [:spawner]
   :hp 3
   :damage 2
   :shape-type :circle
   :radius 6
   :mass 1
   :color :bumper
   :bump-timer 2}
  ;; tier 1
  :banker
  {:tier 1 
   :defense 1
   :hp 4
   :damage 4
   :classes [:traders]
   :shape-type :circle
   :radius 20
   :mass 5
   :color :merchant
   :bump-timer 2}
  :shopkeeper
  {:tier 1 
   :defense 1
   :hp 50
   :damage 3
   :classes [:traders]
   :shape-type :circle
   :radius 20
   :mass 5
   :color :merchant
   :bump-timer 2}
  :fighter
  {:tier 1 
   :defense 1
   :hp 7
   :damage 6
   :classes [:bumpers]
   :shape-type :circle
   :radius 20
   :mass 5
   :color :bumper
   :bump-timer 2}
  :spinner
  {:tier 1 
   :defense 1
   :hp 4
   :damage 1
   :classes [:spawners]
   :shape-type :circle
   :radius 16
   :mass 5
   :color :bumper
   :bump-timer 2}
  :spawner
  {:tier 1 
   :defense 0
   :hp 3
   :damage 3
   :mass 1
   :ability-speed 2.5
   :classes [:spawners]
   :shape-type :polygon
   :points [-12 0 -12 -12 0 -12 18 18]
   :color :healer}
  :healer
  {:tier 1 
   :defense 0
   :hp 5
   :damage 1
   :mass 1
   :ability-speed 2.5
   :classes [:bumpers]
   :shape-type :polygon
   :points [-12 4 -12 -12 0 -12 10 0 0 12]
   :color :healer}
  :bomber
  {:tier 1
   :defense 1
   :hp 5
   :damage 1
   :mass 1
   :ai-type :float-ability
   :ability :drop-bomb
   :color :shooter
   :classes [:spawners]
   :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
   :linear-damping 0.001
   :range 0.7
   :fire-speed 50
   :ability-speed 0.3}
  :sniper
  {:tier 1
   :defense 1
   :hp 4
   :damage 1
   :mass 1
   :ai-type :float-ability
   :ability :snipe
   :color :shooter
   :classes [:shooters]
   :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
   :linear-damping 0.001
   :range 0.7
   :fire-speed 50
   :ability-speed 3}
  :shooter
  {:tier 1
   :defense 1
   :hp 5
   :damage 1
   :mass 1
   :ai-type :float-ability
   :ability :shoot
   :color :shooter
   :classes [:shooters]
   :points [-10 0 -10 -10 0 -10 10 0 10 10 0 10]
   :linear-damping 0.001
   :range 0.7
   :fire-speed 50
   :ability-speed 2}}
 ;; tier 2
 ;; :shotgunner {:ai-type :shoot :hp 15 :damage 3 :tier 2}
 ;; :pulse {:ai-type :bump :hp 15 :damage 3 :linear-damping 0 :tier 2}}
 :enemy-types
 {:basic-1
  {:hp 4
   :damage 1
   :defense 0
   :shape-type :polygon
   :points [-14 0 -10 -10 0 -10 10 0 10 10 0 10]
   :radius [9 14]
   :color :enemy
   :bump-force 128
   :ai-type :enemy}
  :basic-2
  {:hp 4
   :damage 1
   :defense 0
   :shape-type :polygon
   :points [-14 0 -10 -10 0 -10 10 0 10 10 0 10]
   :radius [9 14]
   :color :enemy
   :bump-force 128
   :ai-type :enemy}
  :brute
  {:hp 8
   :damage 2
   :defense 0
   :shape-type :circle
   :radius [60 70]
   :color :enemy
   :bump-force 128
   :ai-type :enemy}
  :boss-1
  {:hp 30
   :damage 2
   :defense 0
   :shape-type :circle
   :shape-type :polygon
   :points [-70 -20 0 -90 50 20 20 -110]
   :radius [30 40]
   :color :enemy
   :bump-force 128
   :ai-type :enemy}}
 :levels
 [{:type :combat
   :options [[:basic-2 :basic-1 :basic-1 :basic-1]
             [:basic-2 :basic-2 :basic-2 :basic-1]]}
  {:type :combat
   :options [[:basic-2 :basic-1 :basic-1 :basic-1 :basic-1 :basic-2 :basic-1]]}
  {:type :upgrade}
  {:type :combat
   :options [[:basic-1 :basic-1 :basic-1 :basic-2 :basic-1 :brute]]}
  {:type :combat
   :options [[:basic-1 :basic-1 :basic-1 :brute :brute :brute]]}
  {:type :combat
   :options [[:boss-1]]}
  {:type :upgrade}]}
